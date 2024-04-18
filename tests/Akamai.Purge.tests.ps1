Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Purge/Akamai.Purge.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID

Describe 'Safe Akamai.Purge Tests' {

    BeforeDiscovery {
        
    }


    AfterAll {
        
    }

}

Describe 'Unsafe Akamai.Purge Tests' {

    BeforeDiscovery {
        
    }

    ### Clear-AkamaiCache - Invalidate - Parameter Set 'cpcode'
    $Script:ClearAkamaiCache = Clear-AkamaiCache -CPCodes "123456, 456789" -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Clear-AkamaiCache (cpcode) returns the correct data' {
        $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
    }

    ### Clear-AkamaiCache - Invalidate - Parameter Set 'tag'
    $Script:ClearAkamaiCache = Clear-AkamaiCache -Tags "tag1" -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Clear-AkamaiCache (tag) returns the correct data' {
        $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
    }

    ### Clear-AkamaiCache - Invalidate - Parameter Set 'url'
    $Script:ClearAkamaiCache = Clear-AkamaiCache -URLs "https://www.example.com/, https://www.example.com/search" -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Clear-AkamaiCache (url) returns the correct data' {
        $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
    }

    ### Clear-AkamaiCache - Delete - Parameter Set 'cpcode'
    $Script:ClearAkamaiCache = Clear-AkamaiCache -CPCodes "123456, 456789" -Method delete -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Clear-AkamaiCache (cpcode) returns the correct data' {
        $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
    }

    ### Clear-AkamaiCache - Delete - Parameter Set 'tag'
    $Script:ClearAkamaiCache = Clear-AkamaiCache -Tags "tag1" -Method delete -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Clear-AkamaiCache (tag) returns the correct data' {
        $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
    }

    ### Clear-AkamaiCache - Delete - Parameter Set 'url'
    $Script:ClearAkamaiCache = Clear-AkamaiCache -URLs "https://www.example.com/, https://www.example.com/search" -Method delete -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Clear-AkamaiCache (url) returns the correct data' {
        $ClearAkamaiCache.purgeId | Should -Not -BeNullOrEmpty
    }


    AfterAll {
        
    }

}