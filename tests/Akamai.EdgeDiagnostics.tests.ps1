Describe 'Safe Akamai.EdgeDiagnostics Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeDiagnostics/Akamai.EdgeDiagnostics.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestIPAddress = '1.2.3.4'
        $TestHostname = $env:PesterHostname
        $TestESIURL = "https://$TestHostname/ns/esi/include.html"
        $1HourAgo = (Get-Date).AddHours(-1)
        $EpochTime = [Math]::Floor([decimal](Get-Date($1HourAgo).ToUniversalTime() -uformat "%s"))
        $TestErrorCode = "9.44ae3017.$($EpochTime).38e4d065"
        $TestDiagnosticsNote = 'AkamaiPowerShell testing. Please ignore'
        $PD = @{}
    }

    AfterAll {
        
    }

    Context 'Get-EdgeDiagnosticsLocations' {
        It 'returns a list' {
            $PD.EdgeLocations = Get-EdgeDiagnosticsLocations @CommonParams
            $PD.EdgeLocations.count | Should -Not -Be 0
        }
    }

    Context 'Get-EdgeDiagnosticsIPAHostnames' {
        It 'returns a list' {
            $PD.IPAHostnames = Get-EdgeDiagnosticsIPAHostnames @CommonParams
            $PD.IPAHostnames.count | Should -Not -Be 0
        }
    }

    Context 'Find-IPAddress' {
        It 'returns the correct data' {
            $PD.IPLocation = Find-IPAddress -IPAddress $TestIPAddress @CommonParams
            $PD.IPLocation.geolocation | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsDig' {
        It 'returns the correct data' {
            $PD.Dig = New-EdgeDiagnosticsDig -Hostname $TestHostname -QueryType CNAME -EdgeLocation $PD.EdgeLocations[0].id @CommonParams
            $PD.Dig.result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsCurl' {
        It 'returns the correct data' {
            $PD.Curl = New-EdgeDiagnosticsCurl -URL "https://$TestHostname" -IPVersion IPV4 -EdgeLocation $PD.EdgeLocations[0].id @CommonParams
            $PD.Curl.result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsMTR' {
        It 'returns the correct data' {
            $PD.MTR = New-EdgeDiagnosticsMTR -Destination $TestHostname -DestinationType HOST -PacketType TCP -Port 80 -ResolveDNS -Source $PD.EdgeLocations[0].id -SourceType LOCATION @CommonParams
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
            $PD.NewTrace = New-EdgeDiagnosticsMetadataTrace -URL "https://$TestHostname" -HTTPMethod GET -MDTLocationID $PD.MDTLocations[0].id @CommonParams
            $PD.NewTrace.requestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeDiagnosticsMetadataTrace' {
        It 'returns the correct data' {
            $PD.GetTrace = Get-EdgeDiagnosticsMetadataTrace -RequestID $PD.NewTrace.requestId @CommonParams
            $PD.GetTrace.requestId | Should -Be $PD.NewTrace.requestId
        }
    }

    Context 'Test-EdgeDiagnosticsIP' {
        It 'executes successfully' {
            $TestIP = Test-EdgeDiagnosticsIP -IPAddress $TestIPAddress @CommonParams
            $TestIP.executionStatus | Should -Be 'SUCCESS'
            $TestIP.request.ipAddresses[0] | Should -Be $TestIPAddress
        }
    }
   
    Context 'Test-EdgeDiagnosticsIP with location' {
        It 'executes successfully' {
            $TestIPWithLocation = Test-EdgeDiagnosticsIP -IPAddress $TestIPAddress -IncludeLocation @CommonParams
            $TestIPWithLocation.executionStatus | Should -Be 'SUCCESS'
            $TestIPWithLocation.request.ipAddress | Should -Be $TestIPAddress
            $TestIPWithLocation.result.geoLocation.countryCode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsErrorTranslation' {
        It 'executes successfully' {
            $PD.NewErrorTranslation = New-EdgeDiagnosticsErrorTranslation -ErrorCode $TestErrorCode @CommonParams
            $PD.NewErrorTranslation.executionStatus | Should -Be 'IN_PROGRESS'
        }
    }

    Context 'Get-EdgeDiagnosticsErrorTranslation' {
        It 'executes successfully' {
            $PD.GetErrorTranslation = Get-EdgeDiagnosticsErrorTranslation -RequestID $PD.NewErrorTranslation.requestId @CommonParams
            $PD.GetErrorTranslation.requestId | Should -Be $PD.NewErrorTranslation.requestId
        }
    }

    Context 'New-EdgeDiagnosticsLink' {
        It 'executes successfully' {
            $PD.DiagLink = New-EdgeDiagnosticsLink -URL "https://$TestHostname" -Note $TestDiagnosticsNote  @CommonParams
            $PD.DiagLink.note | Should -Be $TestDiagnosticsNote
        }
    }

    Context 'Get-EdgeDiagnosticsGroup, all' {
        It 'returns a list' {
            $PD.DiagGroups = Get-EdgeDiagnosticsGroup @CommonParams
            $PD.DiagGroups[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeDiagnosticsGroup, single' {
        It 'returns the correct data' {
            $PD.DiagGroup = Get-EdgeDiagnosticsGroup -GroupID $PD.DiagGroups[0].groupId @CommonParams
            $PD.DiagGroup.groupId | Should -Be $PD.DiagGroups[0].groupId
        }
    }
    
    Context 'New-EdgeDiagnosticsConnectivityProblem' {
        It 'returns the correct data' {
            $PD.NewConnectivityProblem = New-EdgeDiagnosticsConnectivityProblem -URL "https://$TestHostname" -Port 443 -IPVersion IPV4 -EdgeLocationID $PD.EdgeLocations[0].id @CommonParams
            $PD.NewConnectivityProblem.requestId | Should -Not -BeNullOrEmpty
            $PD.NewConnectivityProblem.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
    
    Context 'Get-EdgeDiagnosticsConnectivityProblem' {
        It 'returns the correct data' {
            $PD.GetConnectivityProblem = Get-EdgeDiagnosticsConnectivityProblem -RequestID $PD.NewConnectivityProblem.requestId @CommonParams
            $PD.GetConnectivityProblem.request.url | Should -Be "https://$TestHostname"
            $PD.GetConnectivityProblem.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
    
    Context 'New-EdgeDiagnosticsContentProblem' {
        It 'returns the correct data' {
            $PD.NewContentProblem = New-EdgeDiagnosticsContentProblem -URL "https://$TestHostname" -IPVersion IPV4 -EdgeLocationID $PD.EdgeLocations[0].id @CommonParams
            $PD.NewContentProblem.requestId | Should -Not -BeNullOrEmpty
            $PD.NewContentProblem.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
    
    Context 'Get-EdgeDiagnosticsContentProblem' {
        It 'returns the correct data' {
            $PD.GetContentProblem = Get-EdgeDiagnosticsContentProblem -RequestID $PD.NewContentProblem.requestId @CommonParams
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
            $PD.GTMPropertyIPs = Get-EdgeDiagnosticsGTMPropertyIPs -Domain $PD.GTMProperties[0].domain -Property $PD.GTMProperties[0].property @CommonParams
            $PD.GTMPropertyIPs.domain | Should -Be $PD.GTMProperties[0].domain
            $PD.GTMPropertyIPs.property | Should -Be $PD.GTMProperties[0].property
            $PD.GTMPropertyIPs.testIps | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsESIDebug' {
        It 'returns the correct data' {
            $PD.ESI = New-EdgeDiagnosticsESIDebug -URL $TestESIUrl @CommonParams
            $PD.ESI.sourceDebugPage | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsURLHealthCheck' {
        It 'returns the correct data' {
            $PD.NewHealthCheck = New-EdgeDiagnosticsURLHealthCheck -URL "https://$TestHostname" -IPVersion IPV4 -EdgeLocationID $PD.EdgeLocations[0].id @CommonParams
            $PD.NewHealthCheck.requestId | Should -Not -BeNullOrEmpty
            $PD.NewHealthCheck.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
    
    Context 'Get-EdgeDiagnosticsURLHealthCheck' {
        It 'returns the correct data' {
            $PD.GetHealthCheck = Get-EdgeDiagnosticsURLHealthCheck -RequestID $PD.NewHealthCheck.requestId @CommonParams
            $PD.GetHealthCheck.request.url | Should -Be "https://$TestHostname"
            $PD.GetHealthCheck.executionStatus | Should -Be "IN_PROGRESS"
        }
    }
}

Describe 'Unsafe Akamai.EdgeDiagnostics Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeDiagnostics/Akamai.EdgeDiagnostics.psd1 -Force
        
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
    
    Context 'Get-EdgeDiagnosticsErrorStatistics' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeDiagnosticsErrorStatistics.json"
                return $Response | ConvertFrom-Json
            }
            $EStats = Get-EdgeDiagnosticsErrorStatistics -CPCode 123456 -ErrorType EDGE_ERRORS -Delivery ENHANCED_TLS
            $EStats.result | Should -Not -BeNullOrEmpty
        }
    }
    

    Context 'Get-EdgeDiagnosticsLogs' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeDiagnosticsLogs.json"
                return $Response | ConvertFrom-Json
            }
            $Logs = Get-EdgeDiagnosticsLogs -EdgeIP 1.2.3.4 -CPCode 123456 -ClientIP 3.4.5.6 -LogType F -Start 2022-12-20 -End 2022-12-21
            $Logs.result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeDiagnosticsGrep' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeDiagnosticsGrep.json"
                return $Response | ConvertFrom-Json
            }
            $NewGrep = New-EdgeDiagnosticsGrep -Body $TestGrepJSON
            $NewGrep.executionStatus | Should -Be "Success"
            $NewGrep.requestId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-EdgeDiagnosticsGrep' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeDiagnostics -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeDiagnosticsGrep.json"
                return $Response | ConvertFrom-Json
            }
            $GetGrep = Get-EdgeDiagnosticsGrep -RequestID 123
            $GetGrep.executionStatus | Should -Be "Success"
        }
    }
}

