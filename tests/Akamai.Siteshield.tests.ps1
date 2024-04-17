Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Siteshield/Akamai.Siteshield.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID

Describe 'Safe Akamai.Siteshield Tests' {

    BeforeDiscovery {
        
    }

    ### Get-SiteShieldMap - All
    $Script:GetSiteShieldMapAll = Get-SiteShieldMap -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-SiteShieldMap returns the correct data' {
        $GetSiteShieldMapAll[0].ID | Should -Not -BeNullOrEmpty
    }

    ### Get-SiteShieldMap - Single
    $Script:GetSiteShieldMapSingle = Get-SiteShieldMap -ID $GetSiteShieldMapAll[0].id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-SiteShieldMap returns the correct data' {
        $GetSiteShieldMapSingle[0].ID | Should -Be $GetSiteShieldMapAll[0].ID
    }

    AfterAll {
        
    }

}

Describe 'Unsafe Akamai.Siteshield Tests' {

    BeforeDiscovery {
        
    }

    ### Confirm-SiteShieldMap
    $Script:ConfirmSiteShieldMap = Confirm-SiteShieldMap -ID 123456789 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Confirm-SiteShieldMap returns the correct data' {
        $ConfirmSiteShieldMap.ruleName | Should -Not -BeNullOrEmpty
    }


    AfterAll {
        
    }

}
