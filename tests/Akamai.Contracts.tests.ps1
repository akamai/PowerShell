BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.Contracts Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.Contracts'
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
        $TestReportingGroupID = $env:PesterReportingGroup
        $PD = @{}
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
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
            $PD.GetProductsPerContract = $TestContractID | Get-ProductsPerContract @CommonParams
            $PD.GetProductsPerContract[0].marketingProductId | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Contracts -MockWith { return 'IAR executed' }
            $Result = & {} | Get-ProductsPerContract
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 ReportingGroup                  
    #------------------------------------------------

    Context 'Get-ContractReportingGroup' {
        It 'returns the correct data' {
            $PD.ContractReportingGroup = Get-ContractReportingGroup @CommonParams
            $PD.ContractReportingGroup[0] | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ContractReportingGroupIdentifier' {
        It 'returns the correct data' {
            $PD.ContractReportingGroupIdentifier = Get-ContractReportingGroupIdentifier @CommonParams
            $PD.ContractReportingGroupIdentifier[0] | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ProductsPerReportingGroup                  
    #------------------------------------------------

    Context 'Get-ProductsPerReportingGroup' {
        It 'returns the correct data' {
            $PD.GetProductsPerReportingGroup = $TestReportingGroupID | Get-ProductsPerReportingGroup @CommonParams
            $PD.GetProductsPerReportingGroup[0].marketingProductId | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Contracts -MockWith { return 'IAR executed' }
            $Result = & {} | Get-ProductsPerReportingGroup
            $Result | Should -Not -Be 'IAR executed'
        }
    }
}