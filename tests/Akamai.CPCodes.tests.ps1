Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.CPCodes/Akamai.CPCodes.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:TestCPCode = $env:PesterCPCode
$Script:TestReportingGroup = $env:PesterReportingGroup
$Script:TestReportingGroupBody = @"
{
    "reportingGroupName": "akamaipowershell-testing",
    "contracts": [
      {
        "contractId": "$env:PesterContractID",
        "cpcodes": [
          {
            "cpcodeId": $env:PesterCPCode,
            "cpcodeName": "akamaipowershell-testing"
          }
        ]
      }
    ],
    "accessGroup": {
      "groupId": $env:PesterGroupID,
      "contractId": "$env:PesterContractID"
    }
}
"@
$Script:TestReportingGroupObject = ConvertFrom-Json $TestReportingGroupBody
$Script:TestReportingGroupName = 'akamaipowershell-testing'
$Script:TestReportingGroupNamePipeline = $TestReportingGroupName + '-pipeline'
$TestReportingGroupObject.reportingGroupName = $TestReportingGroupNamePipeline

Describe 'Safe Akamai.CPCodes Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 CPCode                  
    #------------------------------------------------

    ### Get-CPCode - Parameter Set 'single'
    $Script:GetCPCodeSingle = Get-CPCode -CPCodeID $TestCPCode -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPCode (single) returns the correct data' {
        $GetCPCodeSingle.cpcodeId | Should -Be $TestCPCode
    }

    ### Get-CPCode - Parameter Set 'all'
    $Script:GetCPCodeAll = Get-CPCode -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPCode (all) returns the correct data' {
        $GetCPCodeAll[0].cpcodeId | Should -Not -BeNullOrEmpty
    }

    ### Set-CPCode by parameter
    $Script:SetCPCodeByParam = Set-CPCode -Body $GetCPCodeSingle -CPCodeID $TestCPCode -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CPCode by param returns the correct data' {
        $SetCPCodeByParam.cpcodeId | Should -Be $TestCPCode
    }

    ### Set-CPCode by pipeline
    $Script:SetCPCodeByPipeline = ($GetCPCodeSingle | Set-CPCode -CPCodeID $TestCPCode -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-CPCode by pipeline returns the correct data' {
        $SetCPCodeByPipeline.cpcodeId | Should -Be $TestCPCode
    }

    #------------------------------------------------
    #                 CPCodeWatermarkLimit                  
    #------------------------------------------------

    ### Get-CPCodeWatermarkLimit
    $Script:GetCPCodeWatermarkLimit = Get-CPCodeWatermarkLimit -ContractID $TestContract -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPCodeWatermarkLimit returns the correct data' {
        $GetCPCodeWatermarkLimit.limit | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 CPReportingGroup                  
    #------------------------------------------------

    ### Get-CPReportingGroup - Parameter Set 'all'
    $Script:GetCPReportingGroupAll = Get-CPReportingGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPReportingGroup (all) returns the correct data' {
        $GetCPReportingGroupAll[0].ReportingGroupId | Should -Not -BeNullOrEmpty
    }

    ### Get-CPReportingGroup - Parameter Set 'single'
    $Script:GetCPReportingGroupSingle = Get-CPReportingGroup -ReportingGroupID $TestReportingGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPReportingGroup (single) returns the correct data' {
        $GetCPReportingGroupSingle.ReportingGroupId | Should -Be $TestReportingGroup
    }

    ### Set-CPReportingGroup by parameter
    $Script:SetCPReportingGroupByParam = Set-CPReportingGroup -Body $GetCPReportingGroupSingle -ReportingGroupID $TestReportingGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CPReportingGroup by param returns the correct data' {
        $SetCPReportingGroupByParam.ReportingGroupId | Should -Be $TestReportingGroup
    }

    ### Set-CPReportingGroup by pipeline
    $Script:SetCPReportingGroupByPipeline = ($GetCPReportingGroupSingle | Set-CPReportingGroup -ReportingGroupID $TestReportingGroup -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-CPReportingGroup by pipeline returns the correct data' {
        $SetCPReportingGroupByPipeline.ReportingGroupId | Should -Be $TestReportingGroup
    }

    
    #------------------------------------------------
    #                 CPReportingGroupProducts                  
    #------------------------------------------------

    ### Get-CPReportingGroupProducts
    $Script:GetCPReportingGroupProducts = Get-CPReportingGroupProducts -ReportingGroupID $TestReportingGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPReportingGroupProducts returns the correct data' {
        $GetCPReportingGroupProducts[0].productId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 CPReportingGroupWatermarkLimit                  
    #------------------------------------------------

    ### Get-CPReportingGroupWatermarkLimit
    $Script:GetCPReportingGroupWatermarkLimit = Get-CPReportingGroupWatermarkLimit -ContractID $TestContract -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPReportingGroupWatermarkLimit returns the correct data' {
        $GetCPReportingGroupWatermarkLimit.limit | Should -Not -BeNullOrEmpty
    }


    AfterAll {
        
    }

}

Describe 'Unsafe Akamai.CPCodes tests' {
    #------------------------------------------------
    #                 CPReportingGroup                  
    #------------------------------------------------

    ### New-CPReportingGroup by parameter
    $Script:NewCPReportingGroupByParam = New-CPReportingGroup -Body $TestReportingGroupBody -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CPReportingGroup by param returns the correct data' {
        $NewCPReportingGroupByParam.reportingGroupName | Should -Not -BeNullOrEmpty
    }

    ### New-CPReportingGroup by pipeline
    $Script:NewCPReportingGroupByPipeline = ($TestReportingGroupObject | New-CPReportingGroup -EdgeRCFile $SafeEdgeRCFile -Section $Section)
    it 'New-CPReportingGroup by pipeline returns the correct data' {
        $NewCPReportingGroupByPipeline.reportingGroupName | Should -Not -BeNullOrEmpty
    }

    ### Remove-CPReportingGroup
    it 'Remove-CPReportingGroup throws no errors' {
        { Remove-CPReportingGroup -ReportingGroupID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }
}