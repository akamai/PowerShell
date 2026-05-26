BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Akamai.Siteshield Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.Siteshield'
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
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Siteshield"
        $PD = @{}
    }
    
    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'Get-SiteShieldMap' {
        It 'gets a list of maps' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Siteshield -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-SiteShieldMap_1.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetSiteShieldMapAll = Get-SiteShieldMap @CommonParams
            $PD.GetSiteShieldMapAll[0].ID | Should -Not -BeNullOrEmpty
        }
        It 'gets a single map by ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Siteshield -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-SiteShieldMap.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetSiteShieldMapSingle = $PD.GetSiteShieldMapAll[0] | Get-SiteShieldMap @CommonParams
            $PD.GetSiteShieldMapSingle.ID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Confirm-SiteShieldMap' {
        It 'Returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Siteshield -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Confirm-SiteShieldMap.json"
                return $Response | ConvertFrom-Json
            }
            $ConfirmSiteShieldMap = $PD.GetSiteShieldMapSingle | Confirm-SiteShieldMap
            $ConfirmSiteShieldMap.ruleName | Should -Not -BeNullOrEmpty
        }
    }
}