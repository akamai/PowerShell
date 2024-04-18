Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Contracts/Akamai.Contracts.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestReportingGroupID = $env:PesterReportingGroup

Describe 'Safe Akamai.Contracts Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 Contract                  
    #------------------------------------------------

    ### Get-Contract
    $Script:GetContract = Get-Contract -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-Contract returns the correct data' {
        $GetContract[0] | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 ProductsPerContract                  
    #------------------------------------------------

    ### Get-ProductsPerContract
    $Script:GetProductsPerContract = Get-ProductsPerContract -ContractID $TestContract -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-ProductsPerContract returns the correct data' {
        $GetProductsPerContract[0].marketingProductId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 ProductsPerReportingGroup                  
    #------------------------------------------------

    ### Get-ProductsPerReportingGroup
    $Script:GetProductsPerReportingGroup = Get-ProductsPerReportingGroup -ReportingGroupID $TestReportingGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-ProductsPerReportingGroup returns the correct data' {
        $GetProductsPerReportingGroup[0].marketingProductId | Should -Not -BeNullOrEmpty
    }


    AfterAll {
        
    }

}
