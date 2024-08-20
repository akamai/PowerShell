Describe 'Safe Akamai.Contracts Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Contracts/Akamai.Contracts.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestReportingGroupID = $env:PesterReportingGroup
        $PD = @{}
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 Contract                  
    #------------------------------------------------

    Context 'Get-Contract' {
        It 'returns the correct data' {
            $PD.GetContract = Get-Contract @CommonParams
            $PD.GetContract[0] | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ProductsPerContract                  
    #------------------------------------------------

    Context 'Get-ProductsPerContract' {
        It 'returns the correct data' {
            $PD.GetProductsPerContract = Get-ProductsPerContract -ContractID $TestContract @CommonParams
            $PD.GetProductsPerContract[0].marketingProductId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ProductsPerReportingGroup                  
    #------------------------------------------------

    Context 'Get-ProductsPerReportingGroup' {
        It 'returns the correct data' {
            $PD.GetProductsPerReportingGroup = Get-ProductsPerReportingGroup -ReportingGroupID $TestReportingGroupID @CommonParams
            $PD.GetProductsPerReportingGroup[0].marketingProductId | Should -Not -BeNullOrEmpty
        }
    }
}