BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Akamai.Purge Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.Purge'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Purge"
        $PD = @{}
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'Clear-AkamaiCache' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Purge -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Clear-AkamaiCache.json"
                return $Response | ConvertFrom-Json
            }
        }
        Context 'CPCode' {
            It 'purges using invalidate method' {
                $TestParams = @{
                    'CPCodes' = 123456
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'purges using delete method' {
                $TestParams = @{
                    'CPCodes' = 123456
                    'Method'  = 'delete'
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'purges using production network' {
                $TestParams = @{
                    'CPCodes' = 123456
                    'Method'  = 'delete'
                    'Network' = 'production'
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'fails when incorrect network is used' {
                $TestParams = @{
                    CPCodes = 123456, 456789
                    Method  = 'delete'
                    Network = 'bananas'
                }
                { Clear-AkamaiCache @TestParams } | Should -Throw
            }
            It 'fails when incorrect method is used' {
                $TestParams = @{
                    CPCodes = 123456, 456789
                    Method  = 'castitintothefire!'
                }
                { Clear-AkamaiCache @TestParams } | Should -Throw
            }
        }
        Context 'URL' {
            It 'purges using invalidate method' {
                $TestParams = @{
                    'URLs' = 'https://www.example.com/'
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'purges using delete method' {
                $TestParams = @{
                    'Method' = 'delete'
                    'URLs'   = 'https://www.example.com/'
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'purges using production network' {
                $TestParams = @{
                    'Method'  = 'delete'
                    'Network' = 'production'
                    'URLs'    = 'https://www.example.com/'
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'fails when incorrect network is used' {
                $TestParams = @{
                    URLs    = 'https://www.example.com/', 'https://www.example.com/search'
                    Method  = 'delete'
                    Network = 'bananas'
                }
                { Clear-AkamaiCache @TestParams } | Should -Throw
            }
            It 'fails when incorrect method is used' {
                $TestParams = @{
                    URLs   = 'https://www.example.com/', 'https://www.example.com/search'
                    Method = 'castitintothefire!'
                }
                { Clear-AkamaiCache @TestParams } | Should -Throw
            }
        }
        Context 'Tags' {
            It 'purges using invalidate method' {
                $TestParams = @{
                    'Tags' = 'tag1'
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'purges using delete method' {
                $TestParams = @{
                    'Method' = 'delete'
                    'Tags'   = 'tag1'
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'purges using production network' {
                $TestParams = @{
                    'Method'  = 'delete'
                    'Network' = 'production'
                    'Tags'    = 'tag1'
                }
                $Result = Clear-AkamaiCache @TestParams
                $Result.purgeId | Should -Not -BeNullOrEmpty
            }
            It 'fails when incorrect network is used' {
                $TestParams = @{
                    Tags    = 'tag1', 'tag2'
                    Method  = 'delete'
                    Network = 'bananas'
                }
                { Clear-AkamaiCache @TestParams } | Should -Throw
            }
            It 'fails when incorrect method is used' {
                $TestParams = @{
                    Tags   = 'tag1', 'tag2'
                    Method = 'castitintothefire!'
                }
                { Clear-AkamaiCache @TestParams } | Should -Throw
            }
        }
    }

    Context 'Get-PurgeLimit' {
        It 'gets purge limits for URL type' {
            $TestParams = @{
                'PurgeType' = 'url'
            }
            $Result = Get-PurgeLimit @TestParams @CommonParams
            $Result | Should -Not -BeNullOrEmpty
            $Result.Limit | Should -Not -BeNullOrEmpty
            $Result.LimitObjects | Should -Not -BeNullOrEmpty
            $Result.Remaining | Should -Not -BeNullOrEmpty
            $Result.RemainingObjects | Should -Not -BeNullOrEmpty
        }
        It 'gets purge limits for CPCode type' {
            $TestParams = @{
                'PurgeType' = 'cpcode'
            }
            $Result = Get-PurgeLimit @TestParams @CommonParams
            $Result | Should -Not -BeNullOrEmpty
            $Result.Limit | Should -Not -BeNullOrEmpty
            $Result.LimitObjects | Should -Not -BeNullOrEmpty
            $Result.Remaining | Should -Not -BeNullOrEmpty
            $Result.RemainingObjects | Should -Not -BeNullOrEmpty
        }
        It 'gets purge limits for Tag type' {
            $TestParams = @{
                'PurgeType' = 'tag'
            }
            $Result = Get-PurgeLimit @TestParams @CommonParams
            $Result | Should -Not -BeNullOrEmpty
            $Result.Limit | Should -Not -BeNullOrEmpty
            $Result.LimitObjects | Should -Not -BeNullOrEmpty
            $Result.Remaining | Should -Not -BeNullOrEmpty
            $Result.RemainingObjects | Should -Not -BeNullOrEmpty
        }
    }
}

