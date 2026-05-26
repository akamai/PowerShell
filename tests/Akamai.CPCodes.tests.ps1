BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.CPCodes Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.CPCodes'
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
        $TestGroupID = $env:PesterGroupID
        $TestCPCode = $env:PesterCPCode
        $TestReportingGroup = $env:PesterReportingGroup
        $TestReportingGroupName = 'akamaipowershell-testing'

        $TestReportingGroupBody = @"
{
    "reportingGroupName": "akamaipowershell-testing",
    "contracts": [
        {
        "contractId": "$TestContractID",
        "cpcodes": [
            {
            "cpcodeId": $TestCPCode,
            "cpcodeName": "akamaipowershell-testing"
            }
        ]
        }
    ],
    "accessGroup": {
        "groupId": $TestGroupID,
        "contractId": "$TestContractID"
    }
}
"@
        $TestReportingGroupObject = ConvertFrom-Json $TestReportingGroupBody
        $TestReportingGroupNamePipeline = $TestReportingGroupName + '-pipeline'
        $TestReportingGroupObject.reportingGroupName = $TestReportingGroupNamePipeline
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.CPCodes"

        $PD = @{}
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 CPCode                  
    #------------------------------------------------

    Context 'Get-CPCode - Parameter Set single' {
        It 'returns a list of CP Codes' {
            $PD.GetCPCodeAll = Get-CPCode @CommonParams
            $PD.GetCPCodeAll[0].cpcodeId | Should -Not -BeNullOrEmpty
        }
        It 'returns a specific CP Code by ID' {
            $PD.GetCPCodeSingle = Get-CPCode -CPCodeID $TestCPCode @CommonParams
            $PD.GetCPCodeSingle.cpcodeId | Should -Be $TestCPCode
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CPCode
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-CPCode' {
        It 'updates successfully by parameter' {
            $PD.SetCPCodeByParam = Set-CPCode -Body $PD.GetCPCodeSingle -CPCodeID $TestCPCode @CommonParams
            $PD.SetCPCodeByParam.cpcodeId | Should -Be $TestCPCode
        }
        It 'updates successfully by pipeline' {
            $PD.SetCPCodeByPipeline = $PD.GetCPCodeSingle | Set-CPCode @CommonParams
            $PD.SetCPCodeByPipeline.cpcodeId | Should -Be $TestCPCode
        }
    }

    #------------------------------------------------
    #                 CPCodeWatermarkLimit                  
    #------------------------------------------------

    Context 'Get-CPCodeWatermarkLimit' {
        It 'returns the correct data' {
            $PD.GetCPCodeWatermarkLimit = $TestContractID | Get-CPCodeWatermarkLimit @CommonParams
            $PD.GetCPCodeWatermarkLimit.limit | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CPCodeWatermarkLimit
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 CPReportingGroup                  
    #------------------------------------------------

    Context 'Get-CPReportingGroup' {
        It 'returns a list of reporting groups' {
            $PD.GetCPReportingGroupAll = Get-CPReportingGroup @CommonParams
            $PD.GetCPReportingGroupAll[0].ReportingGroupId | Should -Not -BeNullOrEmpty
        }
        It 'returns a single reporting group by ID' {
            $PD.GetCPReportingGroupSingle = $TestReportingGroup | Get-CPReportingGroup @CommonParams
            $PD.GetCPReportingGroupSingle.ReportingGroupId | Should -Be $TestReportingGroup
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CPReportingGroup
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-CPReportingGroup' {
        It 'updates successfully by parameter' {
            $PD.SetCPReportingGroupByParam = Set-CPReportingGroup -Body $PD.GetCPReportingGroupSingle -ReportingGroupID $TestReportingGroup @CommonParams
            $PD.SetCPReportingGroupByParam.ReportingGroupId | Should -Be $TestReportingGroup
        }
        It 'updates successfully by pipeline' {
            $PD.SetCPReportingGroupByPipeline = $PD.GetCPReportingGroupSingle | Set-CPReportingGroup @CommonParams
            $PD.SetCPReportingGroupByPipeline.ReportingGroupId | Should -Be $TestReportingGroup
        }
    }
    
    #------------------------------------------------
    #                 CPReportingGroupProducts                  
    #------------------------------------------------

    Context 'Get-CPReportingGroupProducts' {
        It 'returns the correct data' {
            $PD.GetCPReportingGroupProducts = $TestReportingGroup | Get-CPReportingGroupProducts @CommonParams
            $PD.GetCPReportingGroupProducts[0].productId | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CPReportingGroupProducts
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 CPReportingGroupWatermarkLimit                  
    #------------------------------------------------

    Context 'Get-CPReportingGroupWatermarkLimit' {
        It 'returns the correct data' {
            $PD.GetCPReportingGroupWatermarkLimit = $TestContractID | Get-CPReportingGroupWatermarkLimit @CommonParams
            $PD.GetCPReportingGroupWatermarkLimit.limit | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CPReportingGroupWatermarkLimit
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 CPReportingGroup                  
    #------------------------------------------------

    Context 'New-CPReportingGroup' {
        It 'creates successfully by parameter' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CPReportingGroup.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $TestReportingGroupBody
            }
            $NewCPReportingGroupByParam = New-CPReportingGroup @TestParams
            $NewCPReportingGroupByParam.reportingGroupName | Should -Not -BeNullOrEmpty
        }
        It 'creates successfully by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CPReportingGroup.json"
                return $Response | ConvertFrom-Json
            }
            $NewCPReportingGroupByPipeline = $TestReportingGroupObject | New-CPReportingGroup
            $NewCPReportingGroupByPipeline.reportingGroupName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-CPReportingGroup' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-CPReportingGroup.json"
                return $Response | ConvertFrom-Json
            }
            Remove-CPReportingGroup -ReportingGroupID 123456 
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPCodes -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-CPReportingGroup
            $Result | Should -Not -Be 'IAR executed'
        }
    }
}

