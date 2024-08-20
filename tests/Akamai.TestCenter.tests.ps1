Describe 'Safe Akamai.TestCenter Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.TestCenter/Akamai.TestCenter.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestPropertyName = $env:PesterPropertyName
        $TestPropertyVersion = 126
        $TestSuiteName1 = 'Akamai PowerShell Testing 1'
        $TestSuiteName2 = 'Akamai PowerShell Testing 2'
        $TestRequestURL1 = "http://$env:PesterHostname/"
        $TestRequestURL2 = "http://$env:PesterHostname/api"
        $TestVariableName1 = 'var1'
        $TestVariableName2 = 'var2'
        
        # Test suite objects
        # ---- Case
        $TestCaseJSON = @"
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
        $TestCase = ConvertFrom-Json $TestCaseJSON
        $TestCase.testRequest.testRequestUrl = $TestRequestURL2
        
        # ---- Variable
        $TestVariableJSON = @"
{
    "variableName": "$TestVariableName1",
    "variableValue": "www.example.com"
}
"@
        $TestVariable1 = ConvertFrom-Json $TestVariableJSON
        $TestVariable2 = ConvertFrom-Json $TestVariableJSON
        $TestVariable2.variableName = $TestVariableName2
        
        # ---- Suites
        $TestSuiteWithObjectsJSON = @"
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
        $TestSuiteWithObjects = ConvertFrom-Json $TestSuiteWithObjectsJSON
        $TestSuiteWithObjects.testCases += $TestCase
        $TestSuiteWithObjects.variables += $TestVariable1
        $TestSuiteWithObjects.variables += $TestVariable2
        $TestSuite = ConvertFrom-Json $TestSuiteWithObjectsJSON
        $TestSuite.testSuiteName = $TestSuiteName1
        
        $TestSuite.PSObject.Members.Remove('testCases')
        $TestSuite.PSObject.Members.Remove('variables')
        $TestSuiteAutoJSON = @"
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
        $TestRunJSON = @"
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
        $TestRun = ConvertFrom-Json $TestRunJSON

        # Persistent Data
        $PD = @{}
        
    }

    AfterAll {
        Get-TestSuite @CommonParams | Where-Object testSuiteName -in $TestSuiteName1, $TestSuiteName2 | Remove-TestSuite @CommonParams
    }


    #------------------------------------------------
    #                 TestSuite                  
    #------------------------------------------------

    Context 'New-TestSuite, basic' {
        It 'Returns the correct data' {
            $PD.NewTestSuiteBasic = New-TestSuite -Body $TestSuite @CommonParams
            $PD.NewTestSuiteBasic.testSuiteName | Should -Be $TestSuiteName1
        }
    }

    Context 'New-TestSuite, with objects' {
        It 'Returns the correct data' {
            $PD.NewTestSuiteChild = ($TestSuiteWithObjects | New-TestSuite @CommonParams)
            $PD.NewTestSuiteChild.testSuiteName | Should -Be $TestSuiteName2
            $PD.NewTestSuiteChild.testCases.count | Should -Not -Be 0
        }
    }
    
    Context 'New-TestSuite, auto generated' {
        It 'Returns the correct data' {
            $PD.NewTestSuiteAuto = ($TestSuiteAutoJSON | New-TestSuite -AutoGenerate @CommonParams)
            $PD.NewTestSuiteAuto.configs.propertyManager.propertyName | Should -Be $TestPropertyName
        }
    }

    Context 'Get-TestSuite - Parameter Set all' {
        It 'Returns the correct data' {
            $PD.GetTestSuiteAll = Get-TestSuite @CommonParams
            $PD.GetTestSuiteAll[0].testSuiteId | Should -Not -BeNullOrEmpty
            $PD.GetTestSuiteAll.count | Should -BeGreaterThan 0
        }
    }

  
    Context 'Get-TestSuite - Parameter Set single' {
        It 'Returns the correct data' {
            $PD.GetTestSuiteSingle = Get-TestSuite -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.GetTestSuiteSingle.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
        }
    }
  
    Context 'Get-TestSuite - Parameter Set child' {
        It 'Returns the correct data' {
            $PD.GetTestSuiteChild = Get-TestSuite -TestSuiteID $PD.NewTestSuiteChild.testSuiteId -IncludeChildObjects @CommonParams
            $PD.GetTestSuiteChild.testSuiteId | Should -Be $PD.NewTestSuiteChild.testSuiteId
            $PD.GetTestSuiteChild.testCases.count | Should -BeGreaterThan 0
        }
    }

    Context 'Set-TestSuite by parameter' {
        It 'Returns the correct suite' {
            $PD.SetTestSuiteByParam = Set-TestSuite -Body $PD.NewTestSuiteBasic -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.SetTestSuiteByParam.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
        }
    }

    Context 'Set-TestSuite by pipeline' {
        It 'Returns the correct suite' {
            $PD.SetTestSuiteByPipeline = ($PD.NewTestSuiteBasic | Set-TestSuite -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams)
            $PD.SetTestSuiteByPipeline.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
        }
    }
    
    Context 'Set-TestSuite with child objects' {
        It 'Returns the correct suite' {
            $PD.SetTestSuiteWithChild = Set-TestSuite -TestSuiteID $PD.NewTestSuiteChild.testSuiteId -Body $PD.NewTestSuiteChild @CommonParams
            $PD.SetTestSuiteWithChild.testSuiteId | Should -Be $PD.NewTestSuiteChild.testSuiteId
        }
    }

    Context 'Remove-TestSuite' {
        It 'Throws no errors' {
            Remove-TestSuite -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            # Give deletion a chance to complete
            Start-Sleep -s 5
        }
    }

    Context 'Restore-TestSuite' {
        It 'Returns the correct test suite' {
            $PD.RestoreTestSuite = Restore-TestSuite -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.RestoreTestSuite.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
        }
    }

    #------------------------------------------------
    #                 TestCase                  
    #------------------------------------------------

    Context 'New-TestCase by parameter' {
        It 'Returns the correct data' {
            $PD.NewTestCaseByParam = New-TestCase -Body $TestCaseJSON -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.NewTestCaseByParam.testRequest.testRequestUrl | Should -Be $TestRequestURL1
        }
    }

    Context 'New-TestCase by pipeline' {
        It 'Returns the correct data' {
            $PD.NewTestCaseByPipeline = ($TestCase | New-TestCase -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams)
            $PD.NewTestCaseByPipeline.testRequest.testRequestUrl | Should -Be $TestRequestURL2
        }
    }

    Context 'Get-TestCase, all' {
        It 'Returns the correct data' {
            $PD.GetTestCaseAll = Get-TestCase -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.GetTestCaseAll[0].testCaseId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-TestCase, single' {
        It 'Returns the correct data' {
            $PD.GetTestCase = Get-TestCase -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId -TestCaseID $PD.NewTestCaseByParam.testCaseId @CommonParams
            $PD.GetTestCase.testCaseId | Should -Be $PD.NewTestCaseByParam.testCaseId
        }
    }

    Context 'Set-TestCase by parameter, include status' {
        It 'Returns the correct data' {
            $PD.SetTestCaseByParam = Set-TestCase -Body $PD.GetTestCase -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId -IncludeStatus @CommonParams
            $PD.SetTestCaseByParam.successes[0].testCaseId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-TestCase by pipeline' {
        It 'Returns the correct data' {
            $PD.SetTestCaseByPipeline = ($PD.GetTestCase | Set-TestCase -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams)
            $PD.SetTestCaseByPipeline[0].testCaseId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-TestCase with multiple IDs, include status' {
        It 'Returns the correct data' {
            $PD.RemoveTestCase = ($PD.NewTestCaseByParam.testCaseId, $PD.NewTestCaseByPipeline.testCaseId | Remove-TestCase -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId -IncludeStatus @CommonParams)
            $PD.RemoveTestCase.successes | Should -Be @($PD.NewTestCaseByParam.testCaseId, $PD.NewTestCaseByPipeline.testCaseId)
        }
    }

    Context 'Restore-TestCase with multiple IDs' {
        It 'Returns the correct data' {
            $PD.RestoreTestCase = ($PD.NewTestCaseByParam.testCaseId, $PD.NewTestCaseByPipeline.testCaseId | Restore-TestCase -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams)
            $PD.RestoreTestCase.testCaseId | Should -Contain $PD.NewTestCaseByParam.testCaseId
            $PD.RestoreTestCase.testCaseId | Should -Contain $PD.NewTestCaseByPipeline.testCaseId
        }
    }

    #------------------------------------------------
    #                 TestCaseOrder                  
    #------------------------------------------------

    
    Context 'Set-TestCaseOrder by parameter' {
        It 'Returns the correct data' {
            $PD.TestCaseOrder = $PD.GetTestCaseAll | Select-Object order, testCaseId
            $PD.SetTestCaseOrderByParam = Set-TestCaseOrder -Body $PD.TestCaseOrder -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.SetTestCaseOrderByParam[0].testCaseId | Should -Be $PD.GetTestCaseAll[0].testCaseId
        }
    }

    Context 'Set-TestCaseOrder by pipeline' {
        It 'Returns the correct data' {
            $PD.SetTestCaseOrderByPipeline = ($PD.TestCaseOrder | Set-TestCaseOrder -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams)
            $PD.SetTestCaseOrderByPipeline[0].testCaseId | Should -Be $PD.GetTestCaseAll[0].testCaseId
        }
    }

    #------------------------------------------------
    #                 TestCondition                  
    #------------------------------------------------

    Context 'Get-TestCondition' {
        It 'Returns the correct data' {
            $PD.GetTestCondition = Get-TestCondition @CommonParams
            $PD.GetTestCondition[0].conditionExpression | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 TestCatalogTemplate                  
    #------------------------------------------------

    Context 'Get-TestCatalogTemplate' {
        It 'Returns the correct data' {
            $PD.GetTestCatalogTemplate = Get-TestCatalogTemplate @CommonParams
            $PD.GetTestCatalogTemplate[0].conditionType | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 TestVariable                  
    #------------------------------------------------

    Context 'New-TestVariable by parameter' {
        It 'Returns the correct data' {
            $PD.NewTestVariableByParam = New-TestVariable -Body $TestVariableJSON -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.NewTestVariableByParam.variableName | Should -Be $TestVariableName1
        }
    }

    Context 'New-TestVariable by pipeline' {
        It 'Returns the correct data' {
            $PD.NewTestVariableByPipeline = ($TestVariable2 | New-TestVariable -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams)
            $PD.NewTestVariableByPipeline.variableName | Should -Be $TestVariableName2
        }
    }

    Context 'Get-TestVariable, all' {
        It 'Returns the correct data' {
            $PD.GetTestVariableAll = Get-TestVariable -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.GetTestVariableAll[0].variableName | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-TestVariable, single' {
        It 'Returns the correct data' {
            $PD.GetTestVariableSingle = Get-TestVariable -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId -VariableID $PD.NewTestVariableByParam.variableId @CommonParams
            $PD.GetTestVariableSingle.variableName | Should -Be $TestVariableName1
        }
    }

    Context 'Set-TestVariable by parameter, include status' {
        It 'Returns the correct data' {
            $PD.SetTestVariableByParam = Set-TestVariable -Body $PD.GetTestVariableSingle -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId -IncludeStatus @CommonParams
            $PD.SetTestVariableByParam.successes[0].variableId | Should -Be $PD.GetTestVariableSingle.variableId
        }
    }

    Context 'Set-TestVariable by pipeline' {
        It 'Returns the correct data' {
            $PD.SetTestVariableByPipeline = ($PD.GetTestVariableSingle | Set-TestVariable -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams)
            $PD.SetTestVariableByPipeline[0].variableId | Should -Be $PD.GetTestVariableSingle.variableId
        }
    }

    Context 'Remove-TestVariable by parameter' {
        It 'Returns the correct data' {
            $PD.RemoveTestVariable = $PD.GetTestVariableAll.variableId | Remove-TestVariable -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            $PD.RemoveTestVariable[0] | Should -Match '[\d]+'
        }
    }

    #------------------------------------------------
    #                 TestRequest                  
    #------------------------------------------------

    Context 'Get-TestRequest' {
        It 'Returns the correct data' {
            $PD.GetTestRequest = Get-TestRequest @CommonParams
            $PD.GetTestRequest[0].testRequestUrl | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 TestRun                  
    #------------------------------------------------

    Context 'New-TestRun by parameter' {
        It 'Returns the correct data' {
            $TestRun.functional.testSuiteExecutions[0].testSuiteId = $PD.NewTestSuiteChild.testSuiteId
            $PD.NewTestRunByParam = New-TestRun -Body $TestRun @CommonParams
            $PD.NewTestRunByParam.testRunId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-TestRun' {
        It 'Returns the correct data' {
            $PD.GetTestRun = Get-TestRun -TestRunID $PD.NewTestRunByParam.testRunId @CommonParams
            $PD.GetTestRun.testRunId | Should -Be $PD.NewTestRunByParam.testRunId
        }
    }

    #------------------------------------------------
    #                 Removals                  
    #------------------------------------------------

    Context 'Remove-TestSuite' {
        It 'Throws no errors' {
            Remove-TestSuite -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams
            Remove-TestSuite -TestSuiteID $PD.NewTestSuiteChild.testSuiteId @CommonParams
            #Remove-TestSuite -TestSuiteID $NewTestSuiteAuto.testSuiteId @CommonParams
        }
    }
}