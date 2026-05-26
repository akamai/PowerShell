BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.EdgeDiagnostics Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.EdgeDiagnostics'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContractID = $env:PesterContractID
        $TestIPAddress = '1.1.1.1'
        $TestHostname = $env:PesterHostname
        $TestESIURL = "http://$TestHostname/esi/include.html"
        $1HourAgo = (Get-Date).AddHours(-1)
        $EpochTime = [Math]::Floor([decimal](Get-Date($1HourAgo).ToUniversalTime() -uformat "%s"))
        $TestErrorCode = "9.44ae3017.$($EpochTime).38e4d065"
        $TestDiagnosticsNote = 'AkamaiPowerShell testing. Please ignore'
        $TestGrepJSON = @"
{
    "httpStatusCodes": {
        "comparison": "EQUALS",
        "value": [
        "200"
        ]
    },
    "logType": "R",
    "edgeIp": "192.0.2.0",
    "start": "2022-03-15T06:08:40.000Z",
    "end": "2022-03-15T06:08:43.000Z"
}
"@
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.EdgeDiagnostics"
        $PD = @{}
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'Get-EdgeDiagnosticsLocations' {
        It 'returns a list' {
            $PD.EdgeLocations = Get-EdgeDiagnosticsLocations @CommonParams
            $PD.EdgeLocations.count | Should -Not -Be 0
        }
    }

    Context 'Get-EdgeDiagnosticsIPAHostnames' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeDiagnosticsIPAHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $PD.IPAHostnames = Get-EdgeDiagnosticsIPAHostnames @CommonParams
            $PD.IPAHostnames.count | Should -Not -Be 0
        }
    }

    Context 'Find-IPAddress' {
        It 'returns the correct data' {
            $TestParams = @{
                'IPAddress' = $TestIPAddress
            }
            $PD.IPLocation = Find-IPAddress @TestParams @CommonParams
            $PD.IPLocation.geolocation | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsDig' {
        It 'returns the correct data' {
            $TestParams = @{
                'Hostname'     = $TestHostname
                'QueryType'    = 'CNAME'
                'EdgeLocation' = $PD.EdgeLocations[0].id
            }
            $PD.Dig = New-EdgeDiagnosticsDig @TestParams @CommonParams
            $PD.Dig.result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsCurl' {
        It 'returns the correct data' {
            $TestParams = @{
                'URL'               = "https://$TestHostname"
                'IPVersion'         = 'IPV4'
                'EdgeLocation'      = $PD.EdgeLocations[0].id
                'RequestHeaders'    = @('User-Agent: AkamaiPowerShellTest/1.0', 'Accept: */*')
                'RunFromSiteshield' = $true
            }
            $PD.Curl = New-EdgeDiagnosticsCurl @TestParams @CommonParams
            $PD.Curl.result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsMTR' {
        It 'returns the correct data' {
            $TestParams = @{
                'Destination'     = $TestHostname
                'DestinationType' = 'HOST'
                'PacketType'      = 'TCP'
                'Port'            = 80
                'ResolveDNS'      = $true
                'Source'          = $PD.EdgeLocations[0].id
                'SourceType'      = 'LOCATION'
            }
            $PD.MTR = New-EdgeDiagnosticsMTR @TestParams @CommonParams
            $PD.MTR.result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeDiagnosticsMetadataTraceLocations' {
        It 'returns the correct data' {
            $PD.MDTLocations = Get-EdgeDiagnosticsMetadataTraceLocations @CommonParams
            $PD.MDTLocations[0].id | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'New-EdgeDiagnosticsMetadataTrace' {
        It 'returns the correct data' {
            $TestParams = @{
                'URL'                        = "https://$TestHostname"
                'HTTPMethod'                 = 'GET'
                'MDTLocationID'              = $PD.MDTLocations[0].id
                'RequestHeaders'             = @('User-Agent: AkamaiPowerShellTest/1.0', 'Accept: */*')
                'SensitiveRequestHeaderKeys' = @('User-Agent')
            }
            $PD.NewTrace = New-EdgeDiagnosticsMetadataTrace @TestParams @CommonParams
            $PD.NewTrace.requestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeDiagnosticsMetadataTrace' {
        It 'returns the correct data' {
            $TestParams = @{
                'RequestID' = $PD.NewTrace.requestId
            }
            $PD.GetTrace = Get-EdgeDiagnosticsMetadataTrace @TestParams @CommonParams
            $PD.GetTrace.requestId | Should -Be $PD.NewTrace.requestId
        }
    }

    Context 'Test-EdgeDiagnosticsIP' {
        It 'tests successfully' {
            $TestParams = @{
                'IPAddress' = $TestIPAddress
            }
            $TestIP = Test-EdgeDiagnosticsIP @TestParams @CommonParams
            $TestIP.executionStatus | Should -Be 'SUCCESS'
            $TestIP.request.ipAddresses[0] | Should -Be $TestIPAddress
        }
        It 'tests successfully with location' {
            $TestParams = @{
                'IPAddress'       = $TestIPAddress
                'IncludeLocation' = $true
            }
            $TestIPWithLocation = Test-EdgeDiagnosticsIP @TestParams @CommonParams
            $TestIPWithLocation.executionStatus | Should -Be 'SUCCESS'
            $TestIPWithLocation.request.ipAddress | Should -Be $TestIPAddress
            $TestIPWithLocation.result.geoLocation.countryCode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsErrorTranslation' {
        It 'executes successfully' {
            $TestParams = @{
                'ErrorCode' = $TestErrorCode
            }
            $PD.NewErrorTranslation = New-EdgeDiagnosticsErrorTranslation @TestParams @CommonParams
            $PD.NewErrorTranslation.executionStatus | Should -Be 'IN_PROGRESS'
        }
    }

    Context 'Get-EdgeDiagnosticsErrorTranslation' {
        It 'executes successfully' {
            $TestParams = @{
                'RequestID' = $PD.NewErrorTranslation.requestId
            }
            $PD.GetErrorTranslation = Get-EdgeDiagnosticsErrorTranslation @TestParams @CommonParams
            $PD.GetErrorTranslation.requestId | Should -Be $PD.NewErrorTranslation.requestId
        }
    }

    Context 'New-EdgeDiagnosticsLink' {
        It 'executes successfully' {
            $TestParams = @{
                'URL'  = "https://$TestHostname"
                'Note' = $TestDiagnosticsNote
            }
            $PD.DiagLink = New-EdgeDiagnosticsLink @TestParams @CommonParams
            $PD.DiagLink.note | Should -Be $TestDiagnosticsNote
        }
    }

    Context 'Get-EdgeDiagnosticsGroup' {
        It 'gets a list of groups' {
            $PD.DiagGroups = Get-EdgeDiagnosticsGroup @CommonParams
            $PD.DiagGroups[0].groupId | Should -Not -BeNullOrEmpty
        }
        It 'gets a single group by ID' {
            $TestParams = @{
                'GroupID' = $PD.DiagGroups[0].groupId
            }
            $PD.DiagGroup = Get-EdgeDiagnosticsGroup @TestParams @CommonParams
            $PD.DiagGroup.groupId | Should -Be $PD.DiagGroups[0].groupId
        }
    }
    
    Context 'New-EdgeDiagnosticsConnectivityProblem' {
        It 'returns the correct data' {
            $TestParams = @{
                'URL'                        = "https://$TestHostname"
                'Port'                       = 443
                'IPVersion'                  = 'IPV4'
                'EdgeLocationID'             = $PD.EdgeLocations[0].id
                'RequestHeaders'             = @('User-Agent: AkamaiPowerShellTest / 1.0', 'Accept: * / * ')
                'RunFromSiteshield'          = $true
                'SensitiveRequestHeaderKeys' = @('User-Agent')
            }
            $PD.NewConnectivityProblem = New-EdgeDiagnosticsConnectivityProblem @TestParams @CommonParams
            $PD.NewConnectivityProblem.requestId | Should -Not -BeNullOrEmpty
            $PD.NewConnectivityProblem.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
    
    Context 'Get-EdgeDiagnosticsConnectivityProblem' {
        It 'returns the correct data' {
            $TestParams = @{
                'RequestID' = $PD.NewConnectivityProblem.requestId
            }
            $PD.GetConnectivityProblem = Get-EdgeDiagnosticsConnectivityProblem @TestParams @CommonParams
            $PD.GetConnectivityProblem.request.url | Should -Be "https://$TestHostname"
            $PD.GetConnectivityProblem.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
    
    Context 'New-EdgeDiagnosticsContentProblem' {
        It 'returns the correct data' {
            $TestParams = @{
                'URL'                        = "https://$TestHostname"
                'IPVersion'                  = 'IPV4'
                'EdgeLocationID'             = $PD.EdgeLocations[0].id
                'RequestHeaders'             = @('User-Agent: AkamaiPowerShellTest / 1.0', 'Accept: * / * ')
                'RunFromSiteshield'          = $true
                'SensitiveRequestHeaderKeys' = @('User-Agent')
            }
            $PD.NewContentProblem = New-EdgeDiagnosticsContentProblem @TestParams @CommonParams
            $PD.NewContentProblem.requestId | Should -Not -BeNullOrEmpty
            $PD.NewContentProblem.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
    
    Context 'Get-EdgeDiagnosticsContentProblem' {
        It 'returns the correct data' {
            $TestParams = @{
                'RequestID' = $PD.NewContentProblem.requestId
            }
            $PD.GetContentProblem = Get-EdgeDiagnosticsContentProblem @TestParams @CommonParams
            $PD.GetContentProblem.request.url | Should -Be "https://$TestHostname"
            $PD.GetContentProblem.executionStatus | Should -Be "IN_PROGRESS"
            $PD.GetContentProblem.internalIp | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-EdgeDiagnosticsGTMProperties' {
        It 'returns the correct data' {
            $PD.GTMProperties = Get-EdgeDiagnosticsGTMProperties @CommonParams
            $PD.GTMProperties[0].domain | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-EdgeDiagnosticsGTMPropertyIPs' {
        It 'returns the correct data' {
            $TestParams = @{
                'Domain'   = $PD.GTMProperties[0].domain
                'Property' = $PD.GTMProperties[0].property
            }
            $PD.GTMPropertyIPs = Get-EdgeDiagnosticsGTMPropertyIPs @TestParams @CommonParams
            $PD.GTMPropertyIPs.domain | Should -Be $PD.GTMProperties[0].domain
            $PD.GTMPropertyIPs.property | Should -Be $PD.GTMProperties[0].property
            Should -ActualValue $PD.GTMPropertyIPs.testIps -Not -Be $null
        }
    }

    Context 'New-EdgeDiagnosticsESIDebug' {
        It 'returns the correct data' {
            $TestParams = @{
                'URL'                  = $TestESIUrl
                'ClientRequestHeaders' = @('User-Agent: AkamaiPowerShellTest/1.0', 'Accept: */*')
            }
            $PD.ESI = New-EdgeDiagnosticsESIDebug @TestParams @CommonParams
            $PD.ESI.sourceDebugPage | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsURLHealthCheck' {
        It 'returns the correct data' {
            $TestParams = @{
                'URL'                        = "https://$TestHostname"
                'IPVersion'                  = 'IPV4'
                'EdgeLocationID'             = $PD.EdgeLocations[0].id
                'RequestHeaders'             = @('User-Agent: AkamaiPowerShellTest / 1.0', 'Accept: * / * ')
                'RunFromSiteshield'          = $true
                'SensitiveRequestHeaderKeys' = @('User-Agent')
            }
            $PD.NewHealthCheck = New-EdgeDiagnosticsURLHealthCheck @TestParams @CommonParams
            $PD.NewHealthCheck.requestId | Should -Not -BeNullOrEmpty
            $PD.NewHealthCheck.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
    
    Context 'Get-EdgeDiagnosticsURLHealthCheck' {
        It 'returns the correct data' {
            $TestParams = @{
                'RequestID' = $PD.NewHealthCheck.requestId
            }
            $PD.GetHealthCheck = Get-EdgeDiagnosticsURLHealthCheck @TestParams @CommonParams
            $PD.GetHealthCheck.request.url | Should -Be "https://$TestHostname"
            $PD.GetHealthCheck.executionStatus | Should -Be "IN_PROGRESS"
        }
    }

    Context 'Get-EdgeDiagnosticsURLTranslation' {
        It 'returns the correct data' {
            $TestParams = @{
                'Url' = $TestESIURL
            }
            $PD.URLTranslation = Get-EdgeDiagnosticsURLTranslation @TestParams @CommonParams
            $PD.URLTranslation.typeCode | Should -Not -BeNullOrEmpty
            $PD.URLTranslation.cacheKeyHostname | Should -Not -BeNullOrEmpty
            $PD.URLTranslation.cpCode | Should -Not -BeNullOrEmpty
            $PD.URLTranslation.serialNumber | Should -Not -BeNullOrEmpty
            $PD.URLTranslation.ttl | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-EdgeDiagnosticsErrorStatistics' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeDiagnosticsErrorStatistics.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CPCode'    = 123456
                'Delivery'  = 'ENHANCED_TLS'
                'ErrorType' = 'EDGE_ERRORS'
            }
            $EStats = Get-EdgeDiagnosticsErrorStatistics @TestParams
            $EStats.result | Should -Not -BeNullOrEmpty
        }
    }
    

    Context 'Get-EdgeDiagnosticsLogs' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeDiagnosticsLogs.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'EdgeIP'   = '1.2.3.4'
                'ClientIP' = '3.4.5.6'
                'CPCode'   = 123456
                'LogType'  = 'F'
                'Start'    = '2022-12-20'
                'End'      = '2022-12-21'
            }
            $Logs = Get-EdgeDiagnosticsLogs - @TestParams
            $Logs.result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsGrep' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeDiagnosticsGrep.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $TestGrepJSON
            }
            $NewGrep = New-EdgeDiagnosticsGrep @TestParams
            $NewGrep.executionStatus | Should -Be "Success"
            $NewGrep.requestId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-EdgeDiagnosticsGrep' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeDiagnosticsGrep.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'RequestID' = 123
            }
            $GetGrep = Get-EdgeDiagnosticsGrep @TestParams
            $GetGrep.executionStatus | Should -Be "Success"
        }
    }
}

