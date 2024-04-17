Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.TestCenter/Akamai.TestCenter.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:TestPropertyName = $env:PesterPropertyName
$Script:TestPropertyVersion = 126
$Script:TestSuiteName1 = 'Akamai PowerShell Testing 1'
$Script:TestSuiteName2 = 'Akamai PowerShell Testing 2'
$Script:TestRequestURL1 = "http://$env:PesterHostname/"
$Script:TestRequestURL2 = "http://$env:PesterHostname/api"
$Script:TestVariableName1 = 'var1'
$Script:TestVariableName2 = 'var2'
$Script:TestHeaderValue = 'Powershell'

# Test suite objects
# ---- Case
$Script:TestCaseJSON = @"
{
    "testRequest": {
      "testRequestUrl": "$TestRequestURL1",
      "requestMethod": "GET"
    },
    "clientProfile": {
      "client": "CHROME",
      "ipVersion": "IPV4",
      "geoLocation": "US"
    },
    "condition": {
      "conditionExpression": "Response code is one of \"200\""
    }
}
"@
$Script:TestCase = ConvertFrom-Json $TestCaseJSON
$TestCase.testRequest.testRequestUrl = $TestRequestURL2

# ---- Variable
$Script:TestVariableJSON = @"
{
    "variableName": "$TestVariableName1",
    "variableValue": "www.example.com"
}
"@
$Script:TestVariable1 = ConvertFrom-Json $TestVariableJSON
$Script:TestVariable2 = ConvertFrom-Json $TestVariableJSON
$Script:TestVariable2.variableName = $TestVariableName2

# ---- Suites
$Script:TestSuiteWithObjectsJSON = @"
{
    "testSuiteName": "$TestSuiteName2",
    "testSuiteDescription": "Nothing to see here",
    "isLocked": false,
    "isStateful": false,
    "testCases": [
    ],
    "variables": []
}
"@
$Script:TestSuiteWithObjects = ConvertFrom-Json $TestSuiteWithObjectsJSON
$TestSuiteWithObjects.testCases += $TestCase
$TestSuiteWithObjects.variables += $TestVariable1
$TestSuiteWithObjects.variables += $TestVariable2
$Script:TestSuite = ConvertFrom-Json $TestSuiteWithObjectsJSON
$TestSuite.testSuiteName = $TestSuiteName1

$TestSuite.PSObject.Members.Remove('testCases')
$TestSuite.PSObject.Members.Remove('variables')
$Script:TestSuiteAutoJSON = @"
{
    "configs": {
      "propertyManager": {
        "propertyName": "$TestPropertyName",
        "propertyVersion": $TestPropertyVersion
      }
    },
    "testRequestUrls": [
      "$TestRequestURL1"
    ]
}
"@

# ---- Run
$Script:TestRunJSON = @"
{
  "functional": {
    "testSuiteExecutions": [
      {
        "testSuiteId": 0
      }
    ]
  },
  "targetEnvironment": "STAGING",
  "note": "Testing as part of Akamai PowerShell Pester testing",
  "sendEmailOnCompletion": false
}
"@
$Script:TestRun = ConvertFrom-Json $TestRunJSON

Describe 'Safe Akamai.TestCenter Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 TestSuite                  
    #------------------------------------------------

    ### New-TestSuite, basic
    $Script:NewTestSuiteBasic = New-TestSuite -Body $TestSuite -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-TestSuite, basic returns the correct data' {
        $NewTestSuiteBasic.testSuiteName | Should -Be $TestSuiteName1
    }

    ### New-TestSuite, with objects
    $Script:NewTestSuiteChild = ($TestSuiteWithObjects | New-TestSuite -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-TestSuite, with objects returns the correct data' {
        $NewTestSuiteChild.testSuiteName | Should -Be $TestSuiteName2
        $NewTestSuiteChild.testCases.count | Should -Not -Be 0
    }
    
    ### New-TestSuite, auto generated
    $Script:NewTestSuiteAuto = ($TestSuiteAutoJSON | New-TestSuite -AutoGenerate -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-TestSuite, auto generated returns the correct data' {
        $NewTestSuiteAuto.configs.propertyManager.propertyName | Should -Be $TestPropertyName
    }

    ### Get-TestSuite - Parameter Set 'all'
    $Script:GetTestSuiteAll = Get-TestSuite -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestSuite (all) returns the correct data' {
        $GetTestSuiteAll[0].testSuiteId | Should -Not -BeNullOrEmpty
        $GetTestSuiteAll.count | Should -BeGreaterThan 0
    }

  
    ### Get-TestSuite - Parameter Set 'single'
    $Script:GetTestSuiteSingle = Get-TestSuite -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestSuite (single) returns the correct data' {
        $GetTestSuiteSingle.testSuiteId | Should -Be $NewTestSuiteBasic.testSuiteId
    }
  
    ### Get-TestSuite - Parameter Set 'child'
    $Script:GetTestSuiteChild = Get-TestSuite -TestSuiteID $NewTestSuiteChild.testSuiteId -IncludeChildObjects -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestSuite (child) returns the correct data' {
        $GetTestSuiteChild.testSuiteId | Should -Be $NewTestSuiteChild.testSuiteId
        $GetTestSuiteChild.testCases.count | Should -BeGreaterThan 0
    }

    ### Set-TestSuite by parameter
    $Script:SetTestSuiteByParam = Set-TestSuite -Body $NewTestSuiteBasic -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-TestSuite by param returns the correct suite' {
        $SetTestSuiteByParam.testSuiteId | Should -Be $NewTestSuiteBasic.testSuiteId
    }

    ### Set-TestSuite by pipeline
    $Script:SetTestSuiteByPipeline = ($NewTestSuiteBasic | Set-TestSuite -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-TestSuite by pipeline returns the correct suite' {
        $SetTestSuiteByPipeline.testSuiteId | Should -Be $NewTestSuiteBasic.testSuiteId
    }
    
    ### Set-TestSuite with child objects
    $Script:SetTestSuiteWithChild = Set-TestSuite -TestSuiteID $NewTestSuiteChild.testSuiteId -Body $NewTestSuiteChild -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-TestSuite with child objects returns the correct suite' {
        $SetTestSuiteWithChild.testSuiteId | Should -Be $NewTestSuiteChild.testSuiteId
    }

    ### Remove-TestSuite
    it 'Remove-TestSuite throws no errors' {
        { Remove-TestSuite -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
        # Give deletion a chance to complete
        Start-Sleep -s 5
    }

    ### Restore-TestSuite
    it 'Restore-TestSuite returns the correct test suite' {
        $Script:RestoreTestSuite = Restore-TestSuite -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
        $RestoreTestSuite.testSuiteId | Should -Be $NewTestSuiteBasic.testSuiteId
    }

    #------------------------------------------------
    #                 TestCase                  
    #------------------------------------------------

    ### New-TestCase by parameter
    $Script:NewTestCaseByParam = New-TestCase -Body $TestCaseJSON -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-TestCase by param returns the correct data' {
        $NewTestCaseByParam.testRequest.testRequestUrl | Should -Be $TestRequestURL1
    }

    ### New-TestCase by pipeline
    $Script:NewTestCaseByPipeline = ($TestCase | New-TestCase -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-TestCase by pipeline returns the correct data' {
        $NewTestCaseByPipeline.testRequest.testRequestUrl | Should -Be $TestRequestURL2
    }

    ### Get-TestCase, all
    $Script:GetTestCaseAll = Get-TestCase -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestCase, all, returns the correct data' {
        $GetTestCaseAll[0].testCaseId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-TestCase, single
    $Script:GetTestCase = Get-TestCase -TestSuiteID $NewTestSuiteBasic.testSuiteId -TestCaseID $NewTestCaseByParam.testCaseId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestCase, single, returns the correct data' {
        $GetTestCase.testCaseId | Should -Be $NewTestCaseByParam.testCaseId
    }

    ### Set-TestCase by parameter. Include status
    $Script:SetTestCaseByParam = Set-TestCase -Body $GetTestCaseAll -TestSuiteID $NewTestSuiteBasic.testSuiteId -IncludeStatus -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-TestCase by param returns the correct data' {
        $SetTestCaseByParam.successes[0].testCaseId | Should -Not -BeNullOrEmpty
    }

    ### Set-TestCase by pipeline
    $Script:SetTestCaseByPipeline = ($GetTestCaseAll | Set-TestCase -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-TestCase by pipeline returns the correct data' {
        $SetTestCaseByPipeline[0].testCaseId | Should -Not -BeNullOrEmpty
    }

    ### Remove-TestCase with multiple IDs, include status
    $Script:RemoveTestCase = ($NewTestCaseByParam.testCaseId, $NewTestCaseByPipeline.testCaseId | Remove-TestCase -TestSuiteID $NewTestSuiteBasic.testSuiteId -IncludeStatus -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Remove-TestCase by pipeline returns the correct data' {
        $RemoveTestCase.successes | Should -Be @($NewTestCaseByParam.testCaseId, $NewTestCaseByPipeline.testCaseId)
    }

    ### Restore-TestCase with multiple IDs
    $Script:RestoreTestCase = ($NewTestCaseByParam.testCaseId, $NewTestCaseByPipeline.testCaseId | Restore-TestCase -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Restore-TestCase by param returns the correct data' {
        $RestoreTestCase.testCaseId | Should -Contain $NewTestCaseByParam.testCaseId
        $RestoreTestCase.testCaseId | Should -Contain $NewTestCaseByPipeline.testCaseId
    }

    #------------------------------------------------
    #                 TestCaseOrder                  
    #------------------------------------------------

    $Script:TestCaseOrder = $GetTestCaseAll | Select-Object order, testCaseId

    ### Set-TestCaseOrder by parameter
    $Script:SetTestCaseOrderByParam = Set-TestCaseOrder -Body $TestCaseOrder -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-TestCaseOrder by param returns the correct data' {
        $SetTestCaseOrderByParam[0].testCaseId | Should -Be $GetTestCaseAll[0].testCaseId
    }

    ### Set-TestCaseOrder by pipeline
    $Script:SetTestCaseOrderByPipeline = ($TestCaseOrder | Set-TestCaseOrder -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-TestCaseOrder by pipeline returns the correct data' {
        $SetTestCaseOrderByPipeline[0].testCaseId | Should -Be $GetTestCaseAll[0].testCaseId
    }

    #------------------------------------------------
    #                 TestCondition                  
    #------------------------------------------------

    ### Get-TestCondition
    $Script:GetTestCondition = Get-TestCondition -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestCondition returns the correct data' {
        $GetTestCondition[0].conditionExpression | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 TestCatalogTemplate                  
    #------------------------------------------------

    ### Get-TestCatalogTemplate
    $Script:GetTestCatalogTemplate = Get-TestCatalogTemplate -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestCatalogTemplate returns the correct data' {
        $GetTestCatalogTemplate[0].conditionType | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 TestVariable                  
    #------------------------------------------------

    ### New-TestVariable by parameter
    $Script:NewTestVariableByParam = New-TestVariable -Body $TestVariableJSON -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-TestVariable by param returns the correct data' {
        $NewTestVariableByParam.variableName | Should -Be $TestVariableName1
    }

    ### New-TestVariable by pipeline
    $Script:NewTestVariableByPipeline = ($TestVariable2 | New-TestVariable -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-TestVariable by pipeline returns the correct data' {
        $NewTestVariableByPipeline.variableName | Should -Be $TestVariableName2
    }

    ### Get-TestVariable, all
    $Script:GetTestVariableAll = Get-TestVariable -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestVariable, all returns the correct data' {
        $GetTestVariableAll[0].variableName | Should -Not -BeNullOrEmpty
    }
    
    ### Get-TestVariable, single
    $Script:GetTestVariableSingle = Get-TestVariable -TestSuiteID $NewTestSuiteBasic.testSuiteId -VariableID $NewTestVariableByParam.variableId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestVariable, single returns the correct data' {
        $GetTestVariableSingle.variableName | Should -Be $TestVariableName1
    }

    ### Set-TestVariable by parameter, include status
    $Script:SetTestVariableByParam = Set-TestVariable -Body $GetTestVariableSingle -TestSuiteID $NewTestSuiteBasic.testSuiteId -IncludeStatus -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-TestVariable by param returns the correct data' {
        $SetTestVariableByParam.successes[0].variableId | Should -Be $GetTestVariableSingle.variableId
    }

    ### Set-TestVariable by pipeline
    $Script:SetTestVariableByPipeline = ($GetTestVariableSingle | Set-TestVariable -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-TestVariable by pipeline returns the correct data' {
        $SetTestVariableByPipeline[0].variableId | Should -Be $GetTestVariableSingle.variableId
    }

    ### Remove-TestVariable by parameter
    $Script:RemoveTestVariable = $GetTestVariableAll.variableId | Remove-TestVariable -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-TestVariable returns the correct data' {
        $RemoveTestVariable[0] | Should -Match '[\d]+'
    }

    #------------------------------------------------
    #                 TestRequest                  
    #------------------------------------------------

    ### Get-TestRequest
    $Script:GetTestRequest = Get-TestRequest -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestRequest returns the correct data' {
        $GetTestRequest[0].testRequestUrl | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 TestRun                  
    #------------------------------------------------

    ### New-TestRun by parameter
    $Script:TestRun.functional.testSuiteExecutions[0].testSuiteId = $NewTestSuiteChild.testSuiteId
    $Script:NewTestRunByParam = New-TestRun -Body $TestRun -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-TestRun by param returns the correct data' {
        $NewTestRunByParam.testRunId | Should -Not -BeNullOrEmpty
    }

    ### Get-TestRun
    $Script:GetTestRun = Get-TestRun -TestRunID $NewTestRunByParam.testRunId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-TestRun returns the correct data' {
        $GetTestRun.testRunId | Should -Be $NewTestRunByParam.testRunId
    }

    #------------------------------------------------
    #                 Removals                  
    #------------------------------------------------

    ### Remove-TestSuite
    it 'Remove-TestSuite throws no errors' {
        { Remove-TestSuite -TestSuiteID $NewTestSuiteBasic.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
        { Remove-TestSuite -TestSuiteID $NewTestSuiteChild.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
        # { Remove-TestSuite -TestSuiteID $NewTestSuiteAuto.testSuiteId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }


    AfterAll {
        
    }

}
