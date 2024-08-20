Describe 'Safe Akamai.Siteshield Tests' {
    
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Siteshield/Akamai.Siteshield.psd1 -Force
        
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $PD = @{}
    }
    
    AfterAll {
        
    }

    Context 'Get-SiteShieldMap - All' {
        It 'Returns the correct data' {
            $PD.GetSiteShieldMapAll = Get-SiteShieldMap @CommonParams
            $PD.GetSiteShieldMapAll[0].ID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-SiteShieldMap - Single' {
        It 'Returns the correct data' {
            $GetSiteShieldMapSingle = Get-SiteShieldMap -ID $PD.GetSiteShieldMapAll[0].id @CommonParams
            $GetSiteShieldMapSingle[0].ID | Should -Be $PD.GetSiteShieldMapAll[0].ID
        }
    }
}

Describe 'Unsafe Akamai.Siteshield Tests' {

    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Siteshield/Akamai.Siteshield.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Siteshield"
        $PD = @{}
    }

    AfterAll {
        
    }

    Context 'Confirm-SiteShieldMap' {
        It 'Returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Siteshield -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Confirm-SiteShieldMap.json"
                return $Response | ConvertFrom-Json
            }
            $ConfirmSiteShieldMap = Confirm-SiteShieldMap -ID 123456789
            $ConfirmSiteShieldMap.ruleName | Should -Not -BeNullOrEmpty
        }
    }

}


