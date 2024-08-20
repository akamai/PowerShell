Describe 'Safe Akamai.EdgeHostnames Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeHostnames/Akamai.EdgeHostnames.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestEHNRecordName = $env:PesterEHNPrefix
        $TestEHNDNSZone = 'edgesuite.net'
        $PD = @{}
        
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 EdgeHostname                  
    #------------------------------------------------

    Context 'Get-EdgeHostname - Parameter Set all' {
        It 'returns the correct data' {
            $PD.GetEdgeHostnameAll = Get-EdgeHostname @CommonParams
            $PD.GetEdgeHostnameAll[0].edgeHostnameId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeHostname - Parameter Set single-components' {
        It 'returns the correct data' {
            $PD.GetEdgeHostnameSingleComponents = Get-EdgeHostname -RecordName $TestEHNRecordName -DNSZone $TestEHNDNSZone @CommonParams
            $PD.GetEdgeHostnameSingleComponents.recordName | Should -Be $TestEHNRecordName
        }
    }

    Context 'Get-EdgeHostname - Parameter Set single-id' {
        It 'returns the correct data' {
            $PD.GetEdgeHostnameSingleId = Get-EdgeHostname -EdgeHostnameID $PD.GetEdgeHostnameSingleComponents.EdgeHostnameID @CommonParams
            $PD.GetEdgeHostnameSingleId.edgeHostnameId | Should -Be $PD.GetEdgeHostnameSingleComponents.EdgeHostnameID
        }
    }

    #------------------------------------------------
    #                 EdgeHostnameLocalizationData                  
    #------------------------------------------------

    Context 'Get-EdgeHostnameLocalizationData' {
        It 'returns the correct data' {
            $PD.GetEdgeHostnameLocalizationData = Get-EdgeHostnameLocalizationData -Language en_US @CommonParams
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
}


Describe 'Unsafe Akamai.EdgeHostnames Tests' {

    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeHostnames/Akamai.EdgeHostnames.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.EdgeHostnames"
        $PD = @{}
    }

    #------------------------------------------------
    #                 EdgeHostnameChangeRequest                  
    #------------------------------------------------

    Context 'Get-EdgeHostnameChangeRequest - Parameter Set single-id' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeHostnameChangeRequest.json"
                return $Response | ConvertFrom-Json
            }
            $ChangeRequestSingleId = Get-EdgeHostnameChangeRequest -ChangeID 123456
            $ChangeRequestSingleId.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeHostnameChangeRequest - Parameter Set single-components' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeHostnameChangeRequest_1.json"
                return $Response | ConvertFrom-Json
            }
            $ChangeRequestSingleComponents = Get-EdgeHostnameChangeRequest -DNSZone edgekey.net -RecordName testing
            $ChangeRequestSingleComponents[0].action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeHostnameChangeRequest - Parameter Set all' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeHostnameChangeRequest_1.json"
                return $Response | ConvertFrom-Json
            }
            $ChangeRequestAll = Get-EdgeHostnameChangeRequest
            $ChangeRequestAll[0].action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-EdgeHostname' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-EdgeHostname.json"
                return $Response | ConvertFrom-Json
            }
            $SetEdgeHostnamePostbody = Set-EdgeHostname -DNSZone edgekey.net -RecordName testing -Attribute ttl -Value 60
            $SetEdgeHostnamePostbody.action | Should -Be "EDIT"
        }
    }

    Context 'Remove-EdgeHostname' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-EdgeHostname.json"
                return $Response | ConvertFrom-Json
            }
            $RemoveEdgeHostname = Remove-EdgeHostname -DNSZone edgekey.net -RecordName testing
            $RemoveEdgeHostname.action | Should -Be "DELETE"
        }
    }

    #------------------------------------------------
    #                 EdgeHostnameCertificate                  
    #------------------------------------------------

    Context 'Get-EdgeHostnameCertificate' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeHostnames -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeHostnameCertificate.json"
                return $Response | ConvertFrom-Json
            }
            $GetEdgeHostnameCertificate = Get-EdgeHostnameCertificate -DNSZone edgekey.net -RecordName testing
            $GetEdgeHostnameCertificate.slotNumber | Should -Not -BeNullOrEmpty
        }
    }

    AfterAll {
        
    }

}

