BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.EdgeHostnames Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.EdgeHostnames'
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
        $TestEHNRecordName = $env:PesterEHNPrefix
        $TestEHNDNSZone = 'edgesuite.net'
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.EdgeHostnames"
        $PD = @{}
        
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 EdgeHostname                  
    #------------------------------------------------

    Context 'Get-EdgeHostname' {
        It 'get a list of edge hostnames' {
            $PD.EdgeHostnames = Get-EdgeHostname @CommonParams
            $PD.EdgeHostnames[0].edgeHostnameId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific edge hostname by recordname and dns zone' {
            $TestParams = @{
                'RecordName' = $TestEHNRecordName
                'DNSZone'    = $TestEHNDNSZone
            }
            $PD.EdgeHostname = Get-EdgeHostname @TestParams @CommonParams
            $PD.EdgeHostname.recordName | Should -Be $TestEHNRecordName
        }
        It 'gets a specific edge hostname by ID' {
            $PD.EdgeHostnameId = $PD.EdgeHostname.EdgeHostnameID | Get-EdgeHostname @CommonParams
            $PD.EdgeHostnameId.edgeHostnameId | Should -Be $PD.EdgeHostname.EdgeHostnameID
        }
    }

    #------------------------------------------------
    #                 EdgeHostnameLocalizationData                  
    #------------------------------------------------

    Context 'Get-EdgeHostnameLocalizationData' {
        It 'returns the correct data' {
            $TestParams = @{
                'Language' = 'en_US'
            }
            $PD.GetEdgeHostnameLocalizationData = Get-EdgeHostnameLocalizationData @TestParams @CommonParams
            $PD.GetEdgeHostnameLocalizationData.'access-denied-to-dns-zone' | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 EdgeHostnameProduct                  
    #------------------------------------------------

    Context 'Get-EdgeHostnameProduct' {
        It 'returns the correct data' {
            $PD.GetEdgeHostnameProduct = Get-EdgeHostnameProduct @CommonParams
            $PD.GetEdgeHostnameProduct[0].productId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 EdgeHostnameChangeRequest                  
    #------------------------------------------------

    Context 'Get-EdgeHostnameChangeRequest' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeHostnameChangeRequest_1.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'lists changes' {
            $ChangeRequestAll = Get-EdgeHostnameChangeRequest
            $ChangeRequestAll[0].action | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific change by record name and dns zone' {
            $TestParams = @{
                'DNSZone'    = 'edgekey'
                'RecordName' = 'testing'
            }
            $ChangeRequestSingleComponents = Get-EdgeHostnameChangeRequest @TestParams
            $ChangeRequestSingleComponents[0].action | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific change by ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeHostnameChangeRequest.json"
                return $Response | ConvertFrom-Json
            }
            $ChangeRequestSingleId = 123456 | Get-EdgeHostnameChangeRequest
            $ChangeRequestSingleId.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-EdgeHostname' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-EdgeHostname.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Attribute' = 'ttl'
                'Value'     = 60
            }
            $SetEdgeHostnamePostbody = $PD.EdgeHostname | Set-EdgeHostname @TestParams
            $SetEdgeHostnamePostbody.action | Should -Be "EDIT"
        }
    }

    Context 'Remove-EdgeHostname' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-EdgeHostname.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'DNSZone'    = 'edgekey'
                'RecordName' = 'testing'
            }
            $RemoveEdgeHostname = Remove-EdgeHostname @TestParams
            $RemoveEdgeHostname.action | Should -Be "DELETE"
        }
    }

    #------------------------------------------------
    #                 EdgeHostnameCertificate                  
    #------------------------------------------------

    Context 'Get-EdgeHostnameCertificate' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeHostnameCertificate.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'DNSZone'    = 'edgekey'
                'RecordName' = 'testing'
            }
            $GetEdgeHostnameCertificate = Get-EdgeHostnameCertificate @TestParams
            $GetEdgeHostnameCertificate.slotNumber | Should -Not -BeNullOrEmpty
        }
    }
}
