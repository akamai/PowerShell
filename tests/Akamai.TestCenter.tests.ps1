BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.TestCenter Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.TestCenter'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        # Set timestamp for unique asset creation
        $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)

        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestPropertyName = $env:PesterPropertyName
        $TestPropertyID = $env:PesterPropertyID
        $TestPropertyVersion = 7
        $SuiteNamePrefix = "akamaipowershell-$Timestamp"
        $TestSuiteName1 = "$SuiteNamePrefix-1"
        $TestSuiteName2 = "$SuiteNamePrefix-2"
        $TestSuiteName3 = "$SuiteNamePrefix-3"
        $TestRequestURL1 = "http://$env:PesterHostname/"
        $TestRequestURL2 = "http://$env:PesterHostname/api"
        $TestVariableName1 = 'var1'
        $TestVariableName2 = 'var2'
        $TestVariableName3 = 'var3'
        
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
        $BuildTestSuiteJSON = @"
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
        Get-TestSuite @CommonParams | Where-Object testSuiteName -in $TestSuiteName1, $TestSuiteName2, $TestSuiteName3 | Remove-TestSuite @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }


    #------------------------------------------------
    #                 TestSuite                  
    #------------------------------------------------

    Context 'New-TestSuite' {
        It 'creates a test suite with request body' {
            $TestParams = @{
                'Body' = $TestSuite
            }
            $PD.NewTestSuiteBasic = New-TestSuite @TestParams @CommonParams
            $PD.NewTestSuiteBasic.testSuiteName | Should -Be $TestSuiteName1
        }
        It 'creates a test suite with objects' {
            $PD.NewTestSuiteChild = $TestSuiteWithObjects | New-TestSuite @CommonParams
            $PD.NewTestSuiteChild.testSuiteName | Should -Be $TestSuiteName2
            $PD.NewTestSuiteChild.testCases.count | Should -Not -Be 0
        }
        It 'creates a test suite with parameters' {
            $Description = 'Testing PowerShell'
            $TestParams = @{
                'TestSuiteName'        = $TestSuiteName3
                'TestSuiteDescription' = $Description
                'IsStateful'           = $true
                'PropertyName'         = $TestPropertyName
                'PropertyVersion'      = $TestPropertyVersion
            }
            $PD.NewTestSuiteParams = New-TestSuite @TestParams @CommonParams
            $PD.NewTestSuiteParams.testSuiteName | Should -Be $TestSuiteName3
            $PD.NewTestSuiteParams.testSuiteDescription | Should -Be $Description
            $PD.NewTestSuiteParams.IsStateful | Should -Be $true
            $PD.NewTestSuiteParams.IsLocked | Should -Be $false
        }
    }
    
    Context 'Initialize-TestSuite' {
        It 'initializes successfully by param' {
            $TestParams = @{
                'Body' = $BuildTestSuiteJSON
            }
            $PD.BuildTestSuite = Initialize-TestSuite @TestParams @CommonParams
            $PD.BuildTestSuite.configs.propertyManager.propertyName | Should -Be $TestPropertyName
        }
        It 'initializes successfully by pipeline' {
            $BuildTestSuite = $BuildTestSuiteJSON | Initialize-TestSuite @CommonParams
            $BuildTestSuite.configs.propertyManager.propertyName | Should -Be $TestPropertyName
        }
    }

    Context 'Get-TestSuite' {
        It 'gets a list of test suites' {
            $PD.GetTestSuiteAll = Get-TestSuite @CommonParams
            $PD.GetTestSuiteAll[0].testSuiteId | Should -Not -BeNullOrEmpty
            $PD.GetTestSuiteAll.count | Should -BeGreaterThan 0
        }
        It 'gets a specific test suite by ID' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.GetTestSuiteSingle = Get-TestSuite @TestParams @CommonParams
            $PD.GetTestSuiteSingle.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
        }
        It 'gets a specific test suite with child objects' {
            $TestParams = @{
                'TestSuiteID'         = $PD.NewTestSuiteChild.testSuiteId
                'IncludeChildObjects' = $true
            }
            $PD.GetTestSuiteChild = Get-TestSuite @TestParams @CommonParams
            $PD.GetTestSuiteChild.testSuiteId | Should -Be $PD.NewTestSuiteChild.testSuiteId
            $PD.GetTestSuiteChild.testCases.count | Should -BeGreaterThan 0
        }
    }
 
    Context 'Set-TestSuite' {
        It 'updates a basic suite by parameter' {
            $TestParams = @{
                'Body'        = $PD.NewTestSuiteBasic
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.SetTestSuiteByParam = Set-TestSuite @TestParams @CommonParams
            $PD.SetTestSuiteByParam.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
        }
        It 'updates a basic suite by pipeline' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.SetTestSuiteByPipeline = $PD.NewTestSuiteBasic | Set-TestSuite @TestParams @CommonParams
            $PD.SetTestSuiteByPipeline.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
        }
        It 'updates a suite with child objects' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteChild.testSuiteId
                'Body'        = $PD.NewTestSuiteChild
            }
            $PD.SetTestSuiteWithChild = Set-TestSuite @TestParams @CommonParams
            $PD.SetTestSuiteWithChild.testSuiteId | Should -Be $PD.NewTestSuiteChild.testSuiteId
        }
    }

    Context 'Remove/Restore-TestSuite by parameter' {
        Context 'Remove-TestSuite' {
            It 'Throws no errors' {
                $TestParams = @{
                    'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
                }
                Remove-TestSuite @TestParams @CommonParams
                # Give deletion a chance to complete
                Start-Sleep -s 5
            }
        }
    
        Context 'Restore-TestSuite' {
            It 'restores the correct test suite' {
                $TestParams = @{
                    'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
                }
                $PD.RestoreTestSuite = Restore-TestSuite @TestParams @CommonParams
                $PD.RestoreTestSuite.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
            }
        }
    }

    Context 'Remove/Restore-TestSuite by pipeline' {
        Context 'Remove-TestSuite' {
            It 'Throws no errors' {
                $PD.NewTestSuiteBasic | Remove-TestSuite @CommonParams
                # Give deletion a chance to complete
                Start-Sleep -s 5
            }
        }
    
        Context 'Restore-TestSuite' {
            It 'restores the correct test suite' {
                $PD.RestoreTestSuite = $PD.NewTestSuiteBasic | Restore-TestSuite @CommonParams
                $PD.RestoreTestSuite.testSuiteId | Should -Be $PD.NewTestSuiteBasic.testSuiteId
            }
        }
    }

    #------------------------------------------------
    #                 TestCase                  
    #------------------------------------------------

    Context 'New-TestCase' {
        It 'creates a case by request body' {
            $TestParams = @{
                'Body'        = $TestCaseJSON
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.NewTestCaseByParam = New-TestCase @TestParams @CommonParams
            $PD.NewTestCaseByParam.testRequest.testRequestUrl | Should -Be $TestRequestURL1
        }
        It 'creates a case by pipeline' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.NewTestCaseByPipeline = $TestCase | New-TestCase @TestParams @CommonParams
            $PD.NewTestCaseByPipeline.testRequest.testRequestUrl | Should -Be $TestRequestURL2
        }
        It 'creates a case by attributes' {
            $TestParams = @{
                'TestSuiteID'         = $PD.NewTestSuiteParams.testSuiteId
                'RequestMethod'       = 'GET'
                'TestRequestURL'      = $TestRequestURL1
                'ConditionExpression' = 'Response code is one of "200"'
                'Client'              = 'CHROME'
                'IPVersion'           = 'IPV4'
                'GeoLocation'         = 'US'
                'RequestHeaders'      = @(
                    @{
                        'headerAction' = 'ADD'
                        'headerName'   = 'X-Test'
                        'headerValue'  = 'true'
                    }
                )
                'Tags'                = @( 'pester', 'powershell')
            }
            $PD.NewTestCaseByAttributes = New-TestCase @TestParams @CommonParams
            $PD.NewTestCaseByAttributes.testRequest.testRequestUrl | Should -Be $TestRequestURL1
        }
    }

    Context 'Get-TestCase' {
        It 'gets a list of test cases' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.GetTestCaseAll = Get-TestCase @TestParams @CommonParams
            $PD.GetTestCaseAll[0].testCaseId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific test case by ID' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
                'TestCaseID'  = $PD.NewTestCaseByParam.testCaseId
            }
            $PD.GetTestCase = Get-TestCase @TestParams @CommonParams
            $PD.GetTestCase.testCaseId | Should -Be $PD.NewTestCaseByParam.testCaseId
        }
    }

    Context 'Set-TestCase' {
        It 'updates a case by parameter, include status' {
            $TestParams = @{
                'Body'          = $PD.GetTestCase
                'TestSuiteID'   = $PD.NewTestSuiteBasic.testSuiteId
                'IncludeStatus' = $true
            }
            $PD.SetTestCaseByParam = Set-TestCase @TestParams @CommonParams
            $PD.SetTestCaseByParam.successes[0].testCaseId | Should -Not -BeNullOrEmpty
        }
        It 'updates a case by pipeline' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.SetTestCaseByPipeline = $PD.GetTestCase | Set-TestCase @TestParams @CommonParams
            $PD.SetTestCaseByPipeline[0].testCaseId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove/Restore-TestCase by Param' {
        Context 'Remove-TestCase' {
            It 'deletes multiple cases, include status' {
                $TestParams = @{
                    'TestSuiteID'   = $PD.NewTestSuiteBasic.testSuiteId
                    'IncludeStatus' = $true
                    'TestCaseID'    = $PD.NewTestCaseByParam.testCaseId
                }
                $PD.RemoveTestCase = Remove-TestCase @TestParams @CommonParams
                $PD.RemoveTestCase.successes | Should -Be $PD.NewTestCaseByParam.testCaseId
            }
        }
    
        Context 'Restore-TestCase' {
            It 'restores multiple cases' {
                $TestParams = @{
                    'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
                    'TestCaseID'  = $PD.NewTestCaseByParam.testCaseId
                }
                $PD.RestoreTestCase = Restore-TestCase @TestParams @CommonParams
                $PD.RestoreTestCase.testCaseId | Should -Contain $PD.NewTestCaseByParam.testCaseId
            }
        }
    }

    Context 'Remove/Restore-TestCase by pipeline' {
        Context 'Remove-TestCase' {
            It 'deletes multiple cases, include status' {
                $TestParams = @{
                    'TestSuiteID'   = $PD.NewTestSuiteBasic.testSuiteId
                    'IncludeStatus' = $true
                }
                $RemoveTestCase = $PD.NewTestCaseByPipeline | Remove-TestCase @TestParams @CommonParams
                $RemoveTestCase.successes | Should -Be $PD.NewTestCaseByPipeline.testCaseId
            }
        }
    
        Context 'Restore-TestCase' {
            It 'restores multiple cases' {
                $TestParams = @{
                    'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
                }
                $RestoreTestCase = $PD.NewTestCaseByPipeline | Restore-TestCase @TestParams @CommonParams
                $RestoreTestCase.testCaseId | Should -Contain $PD.NewTestCaseByPipeline.testCaseId
            }
        }
    }

    #------------------------------------------------
    #                 TestCaseOrder                  
    #------------------------------------------------

    
    Context 'Set-TestCaseOrder' {
        It 'sets order by parameter' {
            $PD.TestCaseOrder = $PD.GetTestCaseAll | Select-Object order, testCaseId
            $TestParams = @{
                'Body'        = $PD.TestCaseOrder
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.SetTestCaseOrderByParam = Set-TestCaseOrder @TestParams @CommonParams
            $TestParams = @{
                'Body'        = $PD.TestCaseOrder
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.SetTestCaseOrderByParam = Set-TestCaseOrder @TestParams @CommonParams
            $PD.SetTestCaseOrderByParam[0].testCaseId | Should -Be $PD.GetTestCaseAll[0].testCaseId
        }
        It 'sets order by pipeline' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.SetTestCaseOrderByPipeline = $PD.TestCaseOrder | Set-TestCaseOrder @TestParams @CommonParams
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

    Context 'New-TestVariable' {
        It 'creates a variable by parameter' {
            $TestParams = @{
                'Body'        = $TestVariableJSON
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.NewTestVariableByParam = New-TestVariable @TestParams @CommonParams
            $PD.NewTestVariableByParam.variableName | Should -Be $TestVariableName1
        }
        It 'creates a variable by pipeline' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.NewTestVariableByPipeline = $TestVariable2 | New-TestVariable @TestParams @CommonParams
            $PD.NewTestVariableByPipeline.variableName | Should -Be $TestVariableName2
        }
        It 'creates a variable by attributes' {
            $TestParams = @{
                'TestSuiteID'   = $PD.NewTestSuiteBasic.testSuiteId
                'VariableName'  = $TestVariableName3
                'VariableValue' = 'www.test.com'
            }
            $PD.NewTestVariableByAttributes = New-TestVariable @TestParams @CommonParams
            $PD.NewTestVariableByAttributes.variableName | Should -Be $TestVariableName3
        }
    }

    Context 'Get-TestVariable' {
        It 'gets a list of variables' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.GetTestVariableAll = Get-TestVariable @TestParams @CommonParams
            $PD.GetTestVariableAll[0].variableName | Should -Not -BeNullOrEmpty
        }
        It 'gets a single variable by ID' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
                'VariableID'  = $PD.NewTestVariableByParam.variableId
            }
            $PD.GetTestVariableSingle = Get-TestVariable @TestParams @CommonParams
            $PD.GetTestVariableSingle.variableName | Should -Be $TestVariableName1
        }
    }

    Context 'Set-TestVariable' {
        It 'updates a variable by parameter, include status' {
            $TestParams = @{
                'Body'          = $PD.GetTestVariableSingle
                'TestSuiteID'   = $PD.NewTestSuiteBasic.testSuiteId
                'IncludeStatus' = $true
            }
            $PD.SetTestVariableByParam = Set-TestVariable @TestParams @CommonParams
            $PD.SetTestVariableByParam.successes[0].variableId | Should -Be $PD.GetTestVariableSingle.variableId
        }
        It 'updates a variable by pipeline' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $PD.SetTestVariableByPipeline = $PD.GetTestVariableSingle | Set-TestVariable @TestParams @CommonParams
            $PD.SetTestVariableByPipeline[0].variableId | Should -Be $PD.GetTestVariableSingle.variableId
        }
    }

    Context 'Remove-TestVariable' {
        It 'removes by param' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
                VariableID    = $PD.NewTestVariableByParam.variableId
            }
            $PD.RemoveTestVariable = Remove-TestVariable @TestParams @CommonParams
            $PD.RemoveTestVariable[0] | Should -Match '[\d]+'
        }
        It 'removes by pipeline' {
            $TestParams = @{
                'TestSuiteID' = $PD.NewTestSuiteBasic.testSuiteId
            }
            $RemoveTestVariable = $PD.NewTestVariableByPipeline, $PD.NewTestVariableByAttributes | Remove-TestVariable @TestParams @CommonParams
            $RemoveTestVariable[0] | Should -Match '[\d]+'
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

    Context 'Start-Test' {
        It 'starts a test run by request body' {
            $TestRun.functional.testSuiteExecutions[0].testSuiteId = $PD.NewTestSuiteChild.testSuiteId
            $TestParams = @{
                'Body' = $TestRun
            }
            $PD.NewTestRunByParam = Start-Test @TestParams @CommonParams
            $PD.NewTestRunByParam.testRunId | Should -Not -BeNullOrEmpty
        }
        It 'starts a test run by parameters' {
            $TestParams = @{
                'Client'              = 'CHROME'
                'IPVersion'           = 'IPV4'
                'GeoLocation'         = 'US'
                'TestRequestURL'      = $TestRequestURL1
                'RequestMethod'       = 'GET'
                'TargetEnvironment'   = 'STAGING'
                'ConditionExpression' = 'Response code is one of "200"'
                'RequestHeaders'      = @(
                    @{
                        'headerAction' = 'ADD'
                        'headerName'   = 'X-Test'
                        'headerValue'  = 'true'
                    }
                )
                'Note'                = 'Testing Start-Test by attributes'
                'Tags'                = @('pester', 'powershell')
            }
            $PD.NewTestRunByAttributes = Start-Test @TestParams @CommonParams
            $PD.NewTestRunByAttributes.testRunId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Start-TestSuite' {
        It 'starts a test suite run' {
            $TestParams = @{
                'TestSuiteID'       = $PD.NewTestSuiteChild.testSuiteId
                'TestCaseID'        = @($PD.NewTestSuiteChild.testCases[0].testCaseId)
                'TargetEnvironment' = 'STAGING'
                'Note'              = 'Testing Start-TestSuite'
                'PurgeOnstaging'    = $true
            }
            $PD.NewTestSuiteRun = Start-TestSuite @TestParams @CommonParams
            $PD.NewTestSuiteRun.testRunId | Should -Not -BeNullOrEmpty
        }
    }
    Context 'Start-PropertyVersionTest' {
        It 'starts a property version test run using property name' {
            $TestParams = @{
                TestSuiteID       = $PD.NewTestSuiteParams.testSuiteId
                PropertyName      = $TestPropertyName
                PropertyVersion   = $TestPropertyVersion
                TargetEnvironment = 'STAGING'
                Note              = 'Testing Start-PropertyVersionTest'
                PurgeOnstaging    = $true
            }
            $PD.NewPropertyVersionTestRunByName = Start-PropertyVersionTest @TestParams @CommonParams
            $PD.NewPropertyVersionTestRunByName.testRunId | Should -Not -BeNullOrEmpty
        }
        It 'starts a property version test run using property name' {
            $TestParams = @{
                TestSuiteID       = $PD.NewTestSuiteParams.testSuiteId
                PropertyID        = $TestPropertyID
                PropertyVersion   = $TestPropertyVersion
                TargetEnvironment = 'STAGING'
                Note              = 'Testing Start-PropertyVersionTest'
                PurgeOnstaging    = $true
            }
            $PD.NewPropertyVersionTestRunByID = Start-PropertyVersionTest @TestParams @CommonParams
            $PD.NewPropertyVersionTestRunByID.testRunId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-TestRun' {
        It 'lists tests' {
            $PD.TestRuns = Get-TestRun @CommonParams
            $PD.TestRuns[0].testRunId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific test run by ID by param' {
            $TestParams = @{
                'TestRunID' = $PD.NewTestRunByParam.testRunId
            }
            $PD.GetTestRun = Get-TestRun @TestParams @CommonParams
            $PD.GetTestRun.testRunId | Should -Be $PD.NewTestRunByParam.testRunId
        }
        It 'gets a specific test run by ID by pipeline' {
            $TestRun = $PD.NewTestRunByParam | Get-TestRun @CommonParams
            $TestRun.testRunId | Should -Be $PD.NewTestRunByParam.testRunId
        }
    }

    #------------------------------------------------
    #                 TestFunction                  
    #------------------------------------------------

    Context 'Test-TestFunction' -Tag 'Test-TestFunction' {
        BeforeAll {
            $TestBody = @{
                'functionExpression' = 'fn_getResponseHeaderValue(Server)'
                'responseData'       = @{
                    'response' = @{
                        'statusText'  = 'OK'
                        'httpVersion' = 'HTTP/1.1'
                        'headers'     = @(
                            @{
                                'name'  = 'Server'
                                'value' = 'Pester'
                            }
                        )
                        'cookies'     = @(
                            @{
                                'name'  = 'cookie1'
                                'value' = 'value1'
                            }
                        )
                    }
                }
                'variables'          = @(
                    @{
                        'variableName'  = 'var1'
                        'variableValue' = 'val1'
                    }
                )
            }
            $TestBodyString = $TestBody | ConvertTo-Json -Depth 10
        }
        It 'tests a function by attributes' {
            $TestParams = @{
                'FunctionExpression' = 'fn_getResponseHeaderValue(Server)'
                'StatusText'         = 'OK'
                'HTTPVersion'        = 'HTTP/1.1'
                'Headers'            = @('server=Pester')
                'Cookies'            = @('cookie1=value1')
                'Variables'          = @('var1=val1')
            }
            $TestFunction = Test-TestFunction @TestParams @CommonParams
            $TestFunction.functionExpression | Should -Be 'fn_getResponseHeaderValue(Server)'
            $TestFunction.responseData.response.httpVersion | Should -Be 'HTTP/1.1'
            $TestFunction.responseData.response.statusText | Should -Be 'OK'
            $TestFunction.responseData.response.headers[0].name | Should -Be 'Server'
            $TestFunction.responseData.response.headers[0].value | Should -Be 'Pester'
            $TestFunction.responseData.response.cookies[0].name | Should -Be 'cookie1'
            $TestFunction.responseData.response.cookies[0].value | Should -Be 'value1'
        }
        It 'tests a function by body as parameter' {
            $TestFunction = Test-TestFunction -Body $TestBodyString @CommonParams
            $TestFunction.functionExpression | Should -Be 'fn_getResponseHeaderValue(Server)'
            $TestFunction.responseData.response.httpVersion | Should -Be 'HTTP/1.1'
            $TestFunction.responseData.response.statusText | Should -Be 'OK'
            $TestFunction.responseData.response.headers[0].name | Should -Be 'Server'
            $TestFunction.responseData.response.headers[0].value | Should -Be 'Pester'
            $TestFunction.responseData.response.cookies[0].name | Should -Be 'cookie1'
            $TestFunction.responseData.response.cookies[0].value | Should -Be 'value1'
        }
        It 'tests a function by piped body' {
            $TestFunction = $TestBody | Test-TestFunction @CommonParams
            $TestFunction.functionExpression | Should -Be 'fn_getResponseHeaderValue(Server)'
            $TestFunction.responseData.response.httpVersion | Should -Be 'HTTP/1.1'
            $TestFunction.responseData.response.statusText | Should -Be 'OK'
            $TestFunction.responseData.response.headers[0].name | Should -Be 'Server'
            $TestFunction.responseData.response.headers[0].value | Should -Be 'Pester'
            $TestFunction.responseData.response.cookies[0].name | Should -Be 'cookie1'
            $TestFunction.responseData.response.cookies[0].value | Should -Be 'value1'
        }
    }

    #------------------------------------------------
    #                 Removals                  
    #------------------------------------------------

    Context 'Remove-TestSuite' {
        It 'removes by param' {
            Remove-TestSuite -TestSuiteID $PD.NewTestSuiteBasic.testSuiteId @CommonParams 
        }
        It 'removes by pipeline' {
            $PD.NewTestSuiteChild, $PD.NewTestSuiteParams | Remove-TestSuite @CommonParams
        }
    }
}