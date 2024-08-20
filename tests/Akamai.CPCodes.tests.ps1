Describe 'Safe Akamai.CPCodes Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.CPCodes/Akamai.CPCodes.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestCPCode = $env:PesterCPCode
        $TestReportingGroup = $env:PesterReportingGroup
        $TestReportingGroupName = 'akamaipowershell-testing'
        $PD = @{}
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 CPCode                  
    #------------------------------------------------

    Context 'Get-CPCode - Parameter Set single' {
        It 'Get-CPCode (single) returns the correct data' {
            $PD.GetCPCodeSingle = Get-CPCode -CPCodeID $TestCPCode @CommonParams
            $PD.GetCPCodeSingle.cpcodeId | Should -Be $TestCPCode
        }
    }

    Context 'Get-CPCode - Parameter Set all' {
        It 'Get-CPCode (all) returns the correct data' {
            $PD.GetCPCodeAll = Get-CPCode @CommonParams
            $PD.GetCPCodeAll[0].cpcodeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-CPCode by parameter' {
        It 'Set-CPCode by param returns the correct data' {
            $PD.SetCPCodeByParam = Set-CPCode -Body $PD.GetCPCodeSingle -CPCodeID $TestCPCode @CommonParams
            $PD.SetCPCodeByParam.cpcodeId | Should -Be $TestCPCode
        }
    }

    Context 'Set-CPCode by pipeline' {
        It 'returns the correct data' {
            $PD.SetCPCodeByPipeline = ($PD.GetCPCodeSingle | Set-CPCode -CPCodeID $TestCPCode @CommonParams)
            $PD.SetCPCodeByPipeline.cpcodeId | Should -Be $TestCPCode
        }
    }

    #------------------------------------------------
    #                 CPCodeWatermarkLimit                  
    #------------------------------------------------

    Context 'Get-CPCodeWatermarkLimit' {
        It 'returns the correct data' {
            $PD.GetCPCodeWatermarkLimit = Get-CPCodeWatermarkLimit -ContractID $TestContract @CommonParams
            $PD.GetCPCodeWatermarkLimit.limit | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CPReportingGroup                  
    #------------------------------------------------

    Context 'Get-CPReportingGroup - Parameter Set all' {
        It 'Get-CPReportingGroup (all) returns the correct data' {
            $PD.GetCPReportingGroupAll = Get-CPReportingGroup @CommonParams
            $PD.GetCPReportingGroupAll[0].ReportingGroupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CPReportingGroup - Parameter Set single' {
        It 'Get-CPReportingGroup (single) returns the correct data' {
            $PD.GetCPReportingGroupSingle = Get-CPReportingGroup -ReportingGroupID $TestReportingGroup @CommonParams
            $PD.GetCPReportingGroupSingle.ReportingGroupId | Should -Be $TestReportingGroup
        }
    }

    Context 'Set-CPReportingGroup by parameter' {
        It 'Set-CPReportingGroup by param returns the correct data' {
            $PD.SetCPReportingGroupByParam = Set-CPReportingGroup -Body $PD.GetCPReportingGroupSingle -ReportingGroupID $TestReportingGroup @CommonParams
            $PD.SetCPReportingGroupByParam.ReportingGroupId | Should -Be $TestReportingGroup
        }
    }

    Context 'Set-CPReportingGroup by pipeline' {
        It 'returns the correct data' {
            $PD.SetCPReportingGroupByPipeline = ($PD.GetCPReportingGroupSingle | Set-CPReportingGroup -ReportingGroupID $TestReportingGroup @CommonParams)
            $PD.SetCPReportingGroupByPipeline.ReportingGroupId | Should -Be $TestReportingGroup
        }
    }

    
    #------------------------------------------------
    #                 CPReportingGroupProducts                  
    #------------------------------------------------

    Context 'Get-CPReportingGroupProducts' {
        It 'returns the correct data' {
            $PD.GetCPReportingGroupProducts = Get-CPReportingGroupProducts -ReportingGroupID $TestReportingGroup @CommonParams
            $PD.GetCPReportingGroupProducts[0].productId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CPReportingGroupWatermarkLimit                  
    #------------------------------------------------

    Context 'Get-CPReportingGroupWatermarkLimit' {
        It 'returns the correct data' {
            $PD.GetCPReportingGroupWatermarkLimit = Get-CPReportingGroupWatermarkLimit -ContractID $TestContract @CommonParams
            $PD.GetCPReportingGroupWatermarkLimit.limit | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Unsafe Akamai.CPCodes tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.CPCodes/Akamai.CPCodes.psd1 -Force
        
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestCPCode = $env:PesterCPCode
        $TestReportingGroupBody = @"
{
    "reportingGroupName": "akamaipowershell-testing",
    "contracts": [
        {
        "contractId": "$TestContract",
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
        "contractId": "$TestContract"
    }
}
"@
        $TestReportingGroupObject = ConvertFrom-Json $TestReportingGroupBody
        $TestReportingGroupNamePipeline = $TestReportingGroupName + '-pipeline'
        $TestReportingGroupObject.reportingGroupName = $TestReportingGroupNamePipeline
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.CPCodes"
        $PD = @{}
    }

    #------------------------------------------------
    #                 CPReportingGroup                  
    #------------------------------------------------

    Context 'New-CPReportingGroup by parameter' {
        It 'New-CPReportingGroup by param returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CPCodes -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CPReportingGroup.json"
                return $Response | ConvertFrom-Json
            }
            $NewCPReportingGroupByParam = New-CPReportingGroup -Body $TestReportingGroupBody
            $NewCPReportingGroupByParam.reportingGroupName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-CPReportingGroup by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CPCodes -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CPReportingGroup.json"
                return $Response | ConvertFrom-Json
            }
            $NewCPReportingGroupByPipeline = ($TestReportingGroupObject | New-CPReportingGroup)
            $NewCPReportingGroupByPipeline.reportingGroupName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-CPReportingGroup' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CPCodes -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-CPReportingGroup.json"
                return $Response | ConvertFrom-Json
            }
            Remove-CPReportingGroup -ReportingGroupID 123456 
        }
    }
}

