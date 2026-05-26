BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe API Key Manager Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.APIKeyManager'
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
        $TestContractID = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestCollectionName = "Akamai PowerShell - $Timestamp"
        $TestCollectionName2 = "Akamai PowerShell 2 - $Timestamp"
        $TestCollectionJSON = @"
{
    "contractId": "$TestContractID",
    "groupId": $TestGroupID,
    "collectionName": "$TestCollectionName",
    "collectionDescription": "powershell testing"
}
"@
        $TestCollection = $TestCollectionJSON | ConvertFrom-Json
        $TestAPIEndpointID = $env:PesterAPIEndpointID
        $TestKey = (New-Guid).Guid
        $TestKey2 = (New-Guid).Guid
        $TestImportKeys = '[{"value":"7131e629-41fa-4dfb-9ab9-5e556221b8d5","label":"premium","tags":["external","premium"]}]'
        $TestCounterName = "Akamai PowerShell counter - $Timestamp"
        $TestCounterJSON = @"
{
    "throttlingCounterEnabled": true,
    "groupId": $TestGroupID,
    "throttlingCounterName": "$TestCounterName",
    "throttlingLimit": 50,
    "contractId": "$TestContractID",
    "throttlingLimitExceededAction": "DENY",
    "throttlingCounterDescription": "powershell testing"
}
"@
        $TestJSONFile = "TestDrive:/keys-$Timestamp.json"
        $TestCSVFile = "TestDrive:/keys-$Timestamp.csv"
        $TestXMLFile = "TestDrive:/keys-$Timestamp.xml"
        $PD = @{}
        
    }

    AfterAll {
        Get-ApiKeyCollection @CommonParams | Where-Object collectionName -in $TestCollectionName, $TestCollectionName2 | Remove-APIKeyCollection @CommonParams
        Get-APIThrottlingCounter @CommonParams | Where-Object throttlingCounterName -eq $TestCounterName | Remove-APIThrottlingCounter @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }


    #-------------------------------------------------
    #               Key Collections                   
    #-------------------------------------------------
    
    Context 'New-APIKeyCollection' {
        It 'creates successfully by param' {
            $TestParams = @{
                'CollectionName'        = $TestCollectionName
                'CollectionDescription' = "powershell testing"
                'ContractID'            = $TestContractID
                'GroupID'               = $TestGroupID
            }
            $PD.NewCollection = New-APIKeyCollection @TestParams @CommonParams
            $PD.NewCollection.collectionName | Should -Be $TestCollectionName
        }
        It 'creates successfully' {
            $TestCollection.CollectionName = $TestCollectionName2
            $PD.NewCollectionByPipeline = $TestCollection | New-APIKeyCollection @CommonParams
            $PD.NewCollectionByPipeline.collectionName | Should -Be $TestCollectionName2
        }
    }
    
    Context 'Get-APIKeyCollection' {
        It 'returns a list' {
            $PD.KeyCollections = Get-APIKeyCollection @CommonParams
            $PD.KeyCollections[0].collectionId | Should -Not -BeNullOrEmpty
            $PD.KeyCollections[0].collectionName | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct collection' {
            $PD.Collection = $PD.NewCollection.collectionId | Get-APIKeyCollection @CommonParams
            $PD.Collection.collectionName | Should -Be $TestCollectionName
        }
    }


    Context 'Set-APIKeyCollection by pipeline' {
        It 'updates successfully by pipeline' {
            $PD.CollectionByPipeline = $PD.NewCollection | Set-APIKeyCollection @CommonParams
            $PD.CollectionByPipeline.collectionName | Should -Be $TestCollectionName
            $PD.CollectionByPipeline.collectionId | Should -Be $PD.NewCollection.collectionId
        }
        It 'updates successfully by body' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
                'Body'         = (ConvertTo-Json -depth 100 $PD.NewCollection)
            }
            $PD.CollectionByBody = Set-APIKeyCollection @TestParams @CommonParams
            $PD.CollectionByBody.collectionName | Should -Be $TestCollectionName
            $PD.CollectionByPipeline.collectionId | Should -Be $PD.NewCollection.collectionId
        }
    }

    #-------------------------------------------------
    #              Collection Endpoints
    #-------------------------------------------------

    Context 'Get-APIKeyCollectionEndpoints' {
        It 'returns the correct information' {
            $PD.Endpoints = $PD.NewCollection.collectionId | Get-APIKeyCollectionEndpoints @CommonParams
            $PD.Endpoints[0].endpointId | Should -Not -BeNullOrEmpty
            $PD.Endpoints[0].endpointName | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                  ACLS
    #-------------------------------------------------

    Context 'Set-APIKeyCollectionACL' {
        It 'updates successfully by pipeline' {
            $PD.NewACL = @{
                'endpointIds' = @($PD.Endpoints.endpointId)
                'methodIds'   = @()
                'resourceIds' = @()
            }
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
            }
            $PD.ACLByPipeline = $PD.NewACL | Set-APIKeyCollectionACL @TestParams @CommonParams
            $PD.ACLByPipeline.endpointIds | Sort-Object | Should -Be ( @($PD.Endpoints.endpointId) | Sort-Object )
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
                'Body'         = $PD.NewACL
            }
            $PD.ACLByBody = Set-APIKeyCollectionACL @TestParams @CommonParams
            $PD.ACLByBody.endpointIds | Sort-Object | Should -Be ( @($PD.Endpoints.endpointId) | Sort-Object )
        }
    }

    Context 'Get-APIKeyCollectionACL' {
        It 'returns the correct information' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
            }
            $PD.ACL = Get-APIKeyCollectionACL @TestParams @CommonParams
            $PD.ACL.endpointIds | Sort-Object | Should -Be ( @($PD.Endpoints.endpointId) | Sort-Object )
        }
    }

    #-------------------------------------------------
    #               Collection Keys
    #-------------------------------------------------

    Context 'Import-APIKey by params' {
        It 'imports successfully to collection' {
            $TestParams = @{
                'CollectionID'   = $PD.NewCollection.collectionId
                'KeyValue'       = $TestKey2
                'KeyDescription' = 'testing'
                'Label'          = 'powershell'
                'Tags'           = @('pwsh', 'testing', 'pester')
            }
            $PD.ImportKeys = Import-APIKey @TestParams @CommonParams
            $PD.ImportKeys[0].KeyValue | Should -Be $TestKey2
        }
    }
    
    Context 'Export-APIKey' {
        It 'exports all keys from a single collection to object successfully' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
            }
            $PD.ExportCollectionKeys = @(Export-APIKey @TestParams @CommonParams)
            $PD.ExportCollectionKeys[0].KeyValue | Should -Be $TestKey2
        }
        It 'exports all keys from all collections to object successfully' {
            $PD.ExportKeys = @(Export-APIKey @CommonParams)
            $PD.ExportKeys.count | Should -Be $PD.ExportCollectionKeys.count
            $PD.ExportKeys[0].KeyValue | Should -Not -BeNullOrEmpty
        }
        It 'exports keys to a JSON file' {
            $TestParams = @{
                'CollectionID'   = $PD.NewCollection.collectionId
                'OutputFileName' = $TestJSONFile
            }
            Export-APIKey @TestParams @CommonParams
            $TestJSONFile | Should -Exist
            $TestJSONFile | Should -FileContentMatch '^(\[|\{)'
        }
        It 'exports keys to a CSV file' {
            $TestParams = @{
                'CollectionID'   = $PD.NewCollection.collectionId
                'OutputFileName' = $TestCSVFile
            }
            Export-APIKey @TestParams @CommonParams
            $TestCSVFile | Should -Exist
        }
        It 'exports keys to a XML file' {
            $TestParams = @{
                'CollectionID'   = $PD.NewCollection.collectionId
                'OutputFileName' = $TestXMLFile
            }
            Export-APIKey @TestParams @CommonParams
            $TestXMLFile | Should -Exist
            $TestXMLFile | Should -FileContentMatch '^<keys>'
        }
    }

    Context 'Import-APIKey from files' {
        BeforeAll {
            # Re-export files as the test drive is cleared after the above block
            $TestParams = @{
                'CollectionID'   = $PD.NewCollection.collectionId
                'OutputFileName' = $TestJSONFile
            }
            Export-APIKey @TestParams @CommonParams
            $TestParams.OutputFileName = $TestCSVFile
            Export-APIKey @TestParams @CommonParams
            $TestParams.OutputFileName = $TestXMLFile
            Export-APIKey @TestParams @CommonParams
        }
        It 'fails as expected' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
                'InputFile'    = $TestJSONFile
            }
            $JSONError = { Import-APIKey @TestParams @CommonParams } | Should -Throw -PassThru
            $JSONErrorMessage = $JSONError.Exception.Data.errors[0].detail
            $JSONErrorMessage | Should -Match "A key with value .* already exists"
            $TestParams.InputFile = $TestXMLFile
            $XMLError = { Import-APIKey @TestParams @CommonParams } | Should -Throw -PassThru
            $XMLErrorMessage = $XMLError.Exception.Data.errors[0].detail
            $XMLErrorMessage | Should -Match "A key with value .* already exists"
            $TestParams.InputFile = $TestCSVFile
            $CSVError = { Import-APIKey @TestParams @CommonParams } | Should -Throw -PassThru
            $CSVErrorMessage = $CSVError.Exception.Data.errors[0].detail
            $CSVErrorMessage | Should -Match "A key with value .* already exists"
        }
    }

    #-------------------------------------------------
    #                Quota Settings
    #-------------------------------------------------

    Context 'Get-APIKeyCollectionQuota' {
        It 'gets the correct information' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
            }
            $PD.Quota = Get-APIKeyCollectionQuota @TestParams @CommonParams
            $PD.Quota.isEnabled | Should -Be $false
            $PD.Quota.requestLimit | Should -Not -BeNullOrEmpty
            $PD.Quota.resetInterval | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIKeyCollectionQuota' {
        It 'updates successfullyby pipeline' {
            $PD.Quota.isEnabled = $true
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
            }
            $PD.QuotaByPipeline = $PD.Quota | Set-APIKeyCollectionQuota @TestParams @CommonParams
            $PD.QuotaByPipeline.isEnabled | Should -Be $true
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
                'Body'         = $PD.Quota
            }
            $PD.QuotaByParam = Set-APIKeyCollectionQuota @TestParams @CommonParams
            $PD.QuotaByParam.isEnabled | Should -Be $true
        }
    }
    #-------------------------------------------------
    #                   Counters
    #-------------------------------------------------

    Context 'New-APIThrottlingCounter' {
        It 'creates successfully' {
            $TestParams = @{
                'Body' = $TestCounterJSON
            }
            $PD.NewCounter = New-APIThrottlingCounter @TestParams @CommonParams
            $PD.NewCounter.throttlingCounterName | Should -Be $TestCounterName
        }
    }

    Context 'Get-APIThrottlingCounter' {
        It 'returns a list in the right format' {
            $PD.Counters = Get-APIThrottlingCounter @CommonParams
            $PD.Counters[0].throttlingCounterId | Should -Not -BeNullOrEmpty
            $PD.Counters[0].throttlingCounterName | Should -Not -BeNullOrEmpty
        }
        It 'finds the correct counter' {
            $TestParams = @{
                'CounterID' = $PD.NewCounter.throttlingCounterId
            }
            $PD.Counter = Get-APIThrottlingCounter @TestParams @CommonParams
            $PD.Counter.throttlingCounterName | Should -Be $TestCounterName
            $PD.Counter.throttlingCounterId | Should -Be $PD.NewCounter.throttlingCounterId
        }
    }

    Context 'Set-APIThrottlingCounter' {
        It 'updates correctly by pipeline' {
            $PD.CounterByPipeline = $PD.NewCounter | Set-APIThrottlingCounter @CommonParams
            $PD.CounterByPipeline.throttlingCounterName | Should -Be $TestCounterName
            $PD.CounterByPipeline.throttlingCounterId | Should -Be $PD.NewCounter.throttlingCounterId
        }
        It 'updates correctly by param' {
            $TestParams = @{
                'CounterID' = $PD.NewCounter.throttlingCounterId
                'Body'      = $PD.NewCounter
            }
            $PD.CounterByParam = Set-APIThrottlingCounter @TestParams @CommonParams
            $PD.CounterByParam.throttlingCounterName | Should -Be $TestCounterName
            $PD.CounterByParam.throttlingCounterId | Should -Be $PD.NewCounter.throttlingCounterId
        }
    }

    Context 'Get-APIThrottlingCounterEndpoints' {
        It 'returns the correct data' {
            $TestParams = @{
                'CounterID' = $PD.NewCounter.throttlingCounterId
            }
            $PD.CounterEndpoints = Get-APIThrottlingCounterEndpoints @TestParams @CommonParams
            $PD.CounterEndpoints[0].endpointId | Should -Not -BeNullOrEmpty
            $PD.CounterEndpoints[0].endpointName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIThrottlingCounterKeys' {
        It 'returns the correct data' {
            $TestParams = @{
                'CounterID' = $PD.NewCounter.throttlingCounterId
            }
            $PD.CounterKeys = Get-APIThrottlingCounterKeys @TestParams @CommonParams
            $PD.CounterKeys[0].keyId | Should -Not -BeNullOrEmpty
            $PD.CounterKeys[0].keyStatus | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-APIThrottlingCounterKeyCollections' {
        It 'returns the correct data' {
            $TestParams = @{
                'CounterID' = $PD.NewCounter.throttlingCounterId
            }
            $PD.CounterKeyCollections = Get-APIThrottlingCounterKeyCollections @TestParams @CommonParams
            $PD.CounterKeyCollections[0].collectionId | Should -Not -BeNullOrEmpty
            $PD.CounterKeyCollections[0].collectionName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-APIThrottlingCounter' {
        It 'removes successfully' {
            $TestParams = @{
                'CounterID' = $PD.NewCounter.throttlingCounterId
            }
            Remove-APIThrottlingCounter @TestParams @CommonParams
        }
    }

    #-------------------------------------------------
    #                   Keys
    #-------------------------------------------------

    Context 'New-APIKey' {
        It 'creates with value successfully' {
            $TestParams = @{
                'CollectionID'   = $PD.NewCollection.collectionId
                'KeyValues'      = $TestKey
                'KeyDescription' = 'powershell testing with value'
                'Label'          = 'pwsh'
                'Tags'           = @('pwsh', 'pester')
            }
            $PD.NewKeyWithValue = New-APIKey @TestParams @CommonParams
            $PD.NewKeyWithValue.keyValue | Should -Be $TestKey
        }
        It 'creates without value successfully' {
            $TestParams = @{
                'CollectionID'   = $PD.NewCollection.collectionId
                'Count'          = 3
                'KeyDescription' = 'powershell testing without value'
                'Label'          = 'pwsh'
                'Tags'           = @('pwsh', 'pester')
            }
            $PD.NewKeyNoValue = New-APIKey @TestParams @CommonParams
            $PD.NewKeyNoValue[0].keyDescription | Should -Be 'powershell testing without value'
        }
    }

    Context 'Get-APIKey' {
        It 'returns all keys in the collection' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
            }
            $PD.GetKeys = Get-APIKey @TestParams @CommonParams
            $PD.GetKeys.Count | Should -BeGreaterThan 0
            $PD.GetKeys[0].keyId | Should -Not -BeNullOrEmpty
            $PD.GetKeys[0].keyValue | Should -Not -BeNullOrEmpty
        }
        It 'returns a specific key' {
            $TestParams = @{
                'KeyID' = $PD.GetKeys[0].keyId
            }
            $PD.GetKey = Get-APIKey @TestParams @CommonParams
            $PD.GetKey.keyId | Should -Be $PD.GetKeys[0].keyId
            $PD.GetKey.keyValue | Should -Be $PD.GetKeys[0].keyValue
        }
    }
    

    Context 'Set-APIKey' {
        It 'updates correctly by pipeline' {
            $PD.SetKeyByPipeline = $PD.GetKey | Set-APIKey @CommonParams
            $PD.SetKeyByPipeline.keyValue | Should -Be $PD.GetKey.keyValue
        }
        It 'updates correctly by param' {
            $TestParams = @{
                'KeyID' = $PD.GetKey.keyId
                'Body'  = $PD.GetKey
            }
            $PD.SetKeyByParam = Set-APIKey @TestParams @CommonParams
            $PD.SetKeyByParam.keyValue | Should -Be $PD.GetKey.keyValue
        }
    }

    Context 'Revoke-APIKey' {
        It 'completes successfully' {
            $TestParams = @{
                'KeyIDs' = $PD.GetKeys.keyId
            }
            Revoke-APIKey @TestParams @CommonParams
        }
    }

    Context 'Restore-APIKey' {
        It 'completes successfully' {
            $TestParams = @{
                'KeyIDs' = $PD.GetKeys.keyId
            }
            Restore-APIKey @TestParams @CommonParams
        }
    }
    
    Context 'Add-APIKeyToCollection' {
        It 'completes successfully' {
            $TestParams = @{
                'CollectionIDs' = $PD.NewCollectionByPipeline.CollectionID
                'KeyIDs'        = $PD.GetKeys.keyId
            }
            $PD.Assign = Add-APIKeyToCollection @TestParams @CommonParams
            $PD.Assign.count | Should -Be $PD.GetKeys.keyId.count
            $PD.Assign[0].keyId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Remove-APIKeyFromCollection' {
        It 'completes successfully' {
            $TestParams = @{
                'CollectionIDs' = $PD.NewCollection.CollectionID
                'KeyIDs'        = $PD.GetKeys.keyId
            }
            $PD.Unassign = Remove-APIKeyFromCollection @TestParams @CommonParams
            $PD.Unassign.count | Should -Be $PD.GetKeys.keyId.count
            $PD.Unassign[0].keyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Move-APIKey' {
        It 'completes successfully' {
            $TestParams = @{
                'KeyIDs'                  = $PD.GetKeys.keyId
                'DestinationCollectionID' = $PD.NewCollection.CollectionID
            }
            $PD.MoveKeys = Move-APIKey @TestParams @CommonParams
            $PD.MoveKeys.movedKeyIds | Should -Be $PD.GetKeys.keyId
            $PD.MoveKeys.destinationCollectionId | Should -Be $PD.NewCollection.CollectionID
        }
    }

    #-------------------------------------------------
    #                   Reset Keys
    #-------------------------------------------------

    Context 'Reset-APIKeyQuota' {
        It 'completes successfully' {
            $TestParams = @{
                'KeyIDs' = $PD.GetKeys.keyId
            }
            Reset-APIKeyQuota @TestParams @CommonParams
        }
    }

    #-------------------------------------------------
    #               Reset Collections
    #-------------------------------------------------

    Context 'Reset-APIKeyCollectionQuota' {
        It 'completes successfully' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
                'KeyIDs'       = $PD.GetKeys.keyId
            }
            Reset-APIKeyCollectionQuota @TestParams @CommonParams
        }
    }

    #-------------------------------------------------
    #                     Tags
    #-------------------------------------------------
    
    Context 'Get-APITag' {
        It 'returns the correct format' {
            $PD.Tags = Get-APITag @CommonParams
            $PD.Tags | Should -Not -BeNullOrEmpty
            $PD.Tags.count | Should -Not -Be 0
        }
    }

    #-------------------------------------------------
    #                  Removals
    #-------------------------------------------------

    Context 'Remove-APIKeyCollection' {
        It 'removes primary collection successfully' {
            $TestParams = @{
                'CollectionID' = $PD.NewCollection.collectionId
            }
            Remove-APIKeyCollection @TestParams @CommonParams
        }
        It 'removes pipeline collection successfully' {
            $PD.NewCollectionByPipeline | Remove-APIKeyCollection @CommonParams 
        }
    }
}