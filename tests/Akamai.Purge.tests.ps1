Describe 'Unsafe Akamai.Purge Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Purge/Akamai.Purge.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Purge"
        $PD = @{}
    }

    AfterAll {
        
    }

    Context 'Clear-AkamaiCache - Invalidate - Parameter Set cpcode' {
        It 'Clear-AkamaiCache (cpcode) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Purge -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Clear-AkamaiCache.json"
                return $Response | ConvertFrom-Json
            }
            $ClearAkamaiCache = Clear-AkamaiCache -CPCodes "123456, 456789"
            $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Clear-AkamaiCache - Invalidate - Parameter Set tag' {
        It 'Clear-AkamaiCache (tag) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Purge -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Clear-AkamaiCache.json"
                return $Response | ConvertFrom-Json
            }
            $ClearAkamaiCache = Clear-AkamaiCache -Tags "tag1"
            $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Clear-AkamaiCache - Invalidate - Parameter Set url' {
        It 'Clear-AkamaiCache (url) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Purge -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Clear-AkamaiCache.json"
                return $Response | ConvertFrom-Json
            }
            $ClearAkamaiCache = Clear-AkamaiCache -URLs "https://www.example.com/, https://www.example.com/search"
            $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Clear-AkamaiCache - Delete - Parameter Set cpcode' {
        It 'Clear-AkamaiCache (cpcode) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Purge -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Clear-AkamaiCache.json"
                return $Response | ConvertFrom-Json
            }
            $ClearAkamaiCache = Clear-AkamaiCache -CPCodes "123456, 456789" -Method delete
            $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Clear-AkamaiCache - Delete - Parameter Set tag' {
        It 'Clear-AkamaiCache (tag) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Purge -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Clear-AkamaiCache.json"
                return $Response | ConvertFrom-Json
            }
            $ClearAkamaiCache = Clear-AkamaiCache -Tags "tag1" -Method delete
            $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Clear-AkamaiCache - Delete - Parameter Set url' {
        It 'Clear-AkamaiCache (url) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Purge -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Clear-AkamaiCache.json"
                return $Response | ConvertFrom-Json
            }
            $ClearAkamaiCache = Clear-AkamaiCache -URLs "https://www.example.com/, https://www.example.com/search" -Method delete
            $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
        }
    }
}

