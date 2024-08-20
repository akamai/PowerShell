Describe 'Safe API Key Manager Tests' {
    
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.APIKeyManager/Akamai.APIKeyManager.psm1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestCollectionName = "Akamai PowerShell"
        $TestCollectionName2 = "Akamai PowerShell 2"
        $TestCollectionJSON = @"
{
    "contractId": "$TestContract",
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
        $TestCounterName = 'Akamai PowerShell counter'
        $TestCounterJSON = @"
{
    "throttlingCounterEnabled": true,
    "groupId": $TestGroupID,
    "throttlingCounterName": "$TestCounterName",
    "throttlingLimit": 50,
    "contractId": "$TestContract",
    "throttlingLimitExceededAction": "DENY",
    "throttlingCounterDescription": "powershell testing"
}
"@
        $TestJSONFile = 'keys.json'
        $TestCSVFile = 'keys.csv'
        $TestXMLFile = 'keys.xml'
        $PD = @{}
        
    }

    AfterAll {
        Get-ApiKeyCollection @CommonParams | Where-Object collectionName -eq $TestCollectionName | ForEach-Object {
            Remove-APIKeyCollection -CollectionID $_.collectionId @CommonParams
        }
        Get-APIThrottlingCounter @CommonParams | Where-Object throttlingCounterName -eq $TestCounterName | ForEach-Object {
            Remove-APIThrottlingCounter -CounterID $_.throttlingCounterId @CommonParams
        }
        
        if ((Test-Path $TestJSONFile)) {
            Remove-Item -Path $TestJSONFile -Force
        }
        if ((Test-Path $TestCSVFile)) {
            Remove-Item -Path $TestCSVFile -Force
        }
        if ((Test-Path $TestXMLFile)) {
            Remove-Item -Path $TestXMLFile -Force
        }
    }

    #-------------------------------------------------
    #               Key Collections                   
    #-------------------------------------------------
    
    Context 'New-APIKeyCollection' {
        It 'creates successfully' {
            $PD.NewCollection = New-APIKeyCollection -Body $TestCollectionJSON @CommonParams
            $PD.NewCollection.collectionName | Should -Be $TestCollectionName
        }
    }
    
    Context 'New-APIKeyCollection by Pipeline' {
        It 'creates successfully' {
            $TestCollection.CollectionName = $TestCollectionName2
            $PD.NewCollectionByPipeline = ($TestCollection | New-APIKeyCollection @CommonParams)
            $PD.NewCollectionByPipeline.collectionName | Should -Be $TestCollectionName2
        }
    }
    
    Context 'Get-APIKeyCollection - all' {
        It 'returns a list' {
            $PD.KeyCollections = Get-APIKeyCollection @CommonParams
            $PD.KeyCollections[0].collectionId | Should -Not -BeNullOrEmpty
            $PD.KeyCollections[0].collectionName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIKeyCollection - Single' {
        It 'returns the correct collection' {
            $PD.Collection = Get-APIKeyCollection -CollectionID $PD.NewCollection.collectionId @CommonParams
            $PD.Collection.collectionName | Should -Be $TestCollectionName
        }
    }

    Context 'Set-APIKeyCollection by pipeline' {
        It 'updates successfully' {
            $PD.CollectionByPipeline = ( $PD.NewCollection | Set-APIKeyCollection @CommonParams )
            $PD.CollectionByPipeline.collectionName | Should -Be $TestCollectionName
            $PD.CollectionByPipeline.collectionId | Should -Be $PD.NewCollection.collectionId
        }
    }

    Context 'Set-APIKeyCollection by body' {
        It 'updates successfully' {
            $PD.CollectionByBody = Set-APIKeyCollection -CollectionID $PD.NewCollection.collectionId -Body (ConvertTo-Json -depth 100 $PD.NewCollection) @CommonParams
            $PD.CollectionByBody.collectionName | Should -Be $TestCollectionName
            $PD.CollectionByPipeline.collectionId | Should -Be $PD.NewCollection.collectionId
        }
    }

    #-------------------------------------------------
    #              Collection Endpoints
    #-------------------------------------------------

    Context 'Get-APIKeyCollectionEndpoints' {
        It 'returns the correct information' {
            $PD.Endpoints = Get-APIKeyCollectionEndpoints -CollectionID $PD.NewCollection.collectionId @CommonParams
            $PD.Endpoints[0].endpointId | Should -Not -BeNullOrEmpty
            $PD.Endpoints[0].endpointName | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                  ACLS
    #-------------------------------------------------

    Context 'Set-APIKeyCollectionACL by pipeline' {
        It 'updates successfully' {
            $PD.NewACL = @{
                'endpointIds' = @($PD.Endpoints.endpointId)
                'methodIds'   = @()
                'resourceIds' = @()
            }
            $PD.ACLByPipeline = ($PD.NewACL | Set-APIKeyCollectionACL -CollectionID $PD.NewCollection.collectionId @CommonParams)
            $PD.ACLByPipeline.endpointIds | Should -Be @($PD.Endpoints.endpointId)
        }
    }

    Context 'Set-APIKeyCollectionACL by param' {
        It 'updates successfully' {
            $PD.ACLByBody = Set-APIKeyCollectionACL -CollectionID $PD.NewCollection.collectionId -Body $PD.NewACL @CommonParams
            $PD.ACLByBody.endpointIds | Should -Be @($PD.Endpoints.endpointId)
        }
    }

    Context 'Get-APIKeyCollectionACL' {
        It 'returns the correct information' {
            $PD.ACL = Get-APIKeyCollectionACL -CollectionID $PD.NewCollection.collectionId @CommonParams
            $PD.ACL.endpointIds | Should -Be @($PD.Endpoints.endpointId)
        }
    }

    #-------------------------------------------------
    #               Collection Keys
    #-------------------------------------------------

    Context 'Import-APIKey by params' {
        It 'imports successfully' {
            $TestParams = @{
                CollectionID   = $PD.NewCollection.collectionId
                KeyValue       = $TestKey2
                KeyDescription = 'testing'
                Label          = 'powershell'
                Tags           = 'pwsh,testing,pester'
            }
            $PD.ImportKeys = Import-APIKey @TestParams @CommonParams
            $PD.ImportKeys[0].KeyValue | Should -Be $TestKey2
        }
    }
    
    Context 'Export-APIKey, collection, to object' {
        It 'exports all keys successfully' {
            $PD.ExportCollectionKeys = Export-APIKey -CollectionID $PD.NewCollection.collectionId @CommonParams
            $PD.ExportCollectionKeys[0].KeyValue | Should -Be $TestKey2
        }
    }
    
    Context 'Export-APIKey, collection, to file' {
        It 'creates a json file' {
            Export-APIKey -CollectionID $PD.NewCollection.collectionId -OutputFileName $TestJSONFile @CommonParams
            Export-APIKey -CollectionID $PD.NewCollection.collectionId -OutputFileName $TestCSVFile @CommonParams
            Export-APIKey -CollectionID $PD.NewCollection.collectionId -OutputFileName $TestXMLFile @CommonParams
            $TestJSONFile | Should -Exist
            $TestJSONFile | Should -FileContentMatch '^(\[|\{)'
            $TestCSVFile | Should -Exist
            $TestXMLFile | Should -Exist
            $TestXMLFile | Should -FileContentMatch '^<keys>'
        }
    }
    
    Context 'Export-APIKey, all' {
        It 'returns the correct information' {
            $PD.ExportKeys = Export-APIKey @CommonParams
            $PD.ExportKeys.count | Should -BeGreaterThan $PD.ExportCollectionKeys.count
            $PD.ExportKeys[0].KeyValue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Import-APIKey from files' {
        It 'fails as expected' {
            $JSONError = { Import-APIKey -CollectionID $PD.NewCollection.collectionId -InputFile $TestJSONFile @CommonParams } | Should -Throw -PassThru
            $JSONErrorMessage = $JSONError.ErrorDetails.Message | ConvertFrom-Json
            $JSONErrorMessage.errors[0].detail | Should -Match "A key with value .* already exists"
            $XMLError = { Import-APIKey -CollectionID $PD.NewCollection.collectionId -InputFile $TestXMLFile @CommonParams } | Should -Throw -PassThru
            $XMLErrorMessage = $XMLError.ErrorDetails.Message | ConvertFrom-Json
            $XMLErrorMessage.errors[0].detail | Should -Match "A key with value .* already exists"
            $CSVError = { Import-APIKey -CollectionID $PD.NewCollection.collectionId -InputFile $TestCSVFile @CommonParams } | Should -Throw -PassThru
            $CSVErrorMessage = $CSVError.ErrorDetails.Message | ConvertFrom-Json
            $CSVErrorMessage.errors[0].detail | Should -Match "A key with value .* already exists"
        }
    }

    #-------------------------------------------------
    #                Quota Settings
    #-------------------------------------------------

    Context 'Get-APIKeyCollectionQuota' {
        It 'gets the correct information' {
            $PD.Quota = Get-APIKeyCollectionQuota -CollectionID $PD.NewCollection.collectionId @CommonParams
            $PD.Quota.isEnabled | Should -Be $false
            $PD.Quota.requestLimit | Should -Not -BeNullOrEmpty
            $PD.Quota.resetInterval | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIKeyCollectionQuota by pipeline' {
        It 'updates successfully' {
            $PD.Quota.isEnabled = $true
            $PD.QuotaByPipeline = ($PD.Quota | Set-APIKeyCollectionQuota -CollectionID $PD.NewCollection.collectionId @CommonParams)
            $PD.QuotaByPipeline.isEnabled | Should -Be $true
        }
    }

    Context 'Set-APIKeyCollectionQuota by param' {
        It 'updates successfully' {
            $PD.QuotaByParam = Set-APIKeyCollectionQuota -CollectionID $PD.NewCollection.collectionId -Body $PD.Quota @CommonParams
            $PD.QuotaByParam.isEnabled | Should -Be $true
        }
    }

    #-------------------------------------------------
    #                   Counters
    #-------------------------------------------------

    Context 'New-APIThrottlingCounter' {
        It 'creates successfully' {
            $PD.NewCounter = New-APIThrottlingCounter -Body $TestCounterJSON @CommonParams
            $PD.NewCounter.throttlingCounterName | Should -Be $TestCounterName
        }
    }

    Context 'Get-APIThrottlingCounter - all' {
        It 'returns a list in the right format' {
            $PD.Counters = Get-APIThrottlingCounter @CommonParams
            $PD.Counters[0].throttlingCounterId | Should -Not -BeNullOrEmpty
            $PD.Counters[0].throttlingCounterName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIThrottlingCounter - Single' {
        It 'finds the correct counter' {
            $PD.Counter = Get-APIThrottlingCounter -CounterID $PD.NewCounter.throttlingCounterId @CommonParams
            $PD.Counter.throttlingCounterName | Should -Be $TestCounterName
            $PD.Counter.throttlingCounterId | Should -Be $PD.NewCounter.throttlingCounterId
        }
    }

    Context 'Set-APIThrottlingCounter by pipeline' {
        It 'updates correctly' {
            $PD.CounterByPipeline = ($PD.NewCounter | Set-APIThrottlingCounter @CommonParams)
            $PD.CounterByPipeline.throttlingCounterName | Should -Be $TestCounterName
            $PD.CounterByPipeline.throttlingCounterId | Should -Be $PD.NewCounter.throttlingCounterId
        }
    }

    Context 'Set-APIThrottlingCounter by param' {
        It 'updates correctly' {
            $PD.CounterByParam = Set-APIThrottlingCounter -CounterID $PD.NewCounter.throttlingCounterId -Body $PD.NewCounter @CommonParams
            $PD.CounterByParam.throttlingCounterName | Should -Be $TestCounterName
            $PD.CounterByParam.throttlingCounterId | Should -Be $PD.NewCounter.throttlingCounterId
        }
    }

    Context 'Get-APIThrottlingCounterEndpoints' {
        It 'returns the correct data' {
            $PD.CounterEndpoints = Get-APIThrottlingCounterEndpoints -CounterID $PD.NewCounter.throttlingCounterId @CommonParams
            $PD.CounterEndpoints[0].endpointId | Should -Not -BeNullOrEmpty
            $PD.CounterEndpoints[0].endpointName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIThrottlingCounterKeys' {
        It 'returns the correct data' {
            $PD.CounterKeys = Get-APIThrottlingCounterKeys -CounterID $PD.NewCounter.throttlingCounterId @CommonParams
            $PD.CounterKeys[0].keyId | Should -Not -BeNullOrEmpty
            $PD.CounterKeys[0].keyStatus | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-APIThrottlingCounterKeyCollections' {
        It 'returns the correct data' {
            $PD.CounterKeyCollections = Get-APIThrottlingCounterKeyCollections -CounterID $PD.NewCounter.throttlingCounterId @CommonParams
            $PD.CounterKeyCollections[0].collectionId | Should -Not -BeNullOrEmpty
            $PD.CounterKeyCollections[0].collectionName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-APIThrottlingCounter' {
        It 'removes successfully' {
            Remove-APIThrottlingCounter -CounterID $PD.NewCounter.throttlingCounterId @CommonParams 
        }
    }

    #-------------------------------------------------
    #                   Keys
    #-------------------------------------------------

    Context 'New-APIKey - With Value' {
        It 'creates successfully' {
            $TestParams = @{
                CollectionID   = $PD.NewCollection.collectionId
                KeyValues      = $TestKey
                KeyDescription = 'powershell testing with value'
                Label          = 'pwsh'
                Tags           = 'pwsh,pester'
            }
            $PD.NewKeyWithValue = New-APIKey @TestParams @CommonParams
            $PD.NewKeyWithValue.keyValue | Should -Be $TestKey
        }
    }
    
    Context 'New-APIKey - Without Value' {
        It 'creates successfully' {
            $TestParams = @{
                CollectionID   = $PD.NewCollection.collectionId
                Count          = 3
                KeyDescription = 'powershell testing without value'
                Label          = 'pwsh'
                Tags           = 'pwsh,pester'
            }
            $PD.NewKeyNoValue = New-APIKey @TestParams @CommonParams
            $PD.NewKeyNoValue[0].keyDescription | Should -Be 'powershell testing without value'
        }
    }

    Context 'Get-APIKey - All' {
        It 'returns all keys in the collection' {
            $PD.GetKeys = Get-APIKey -CollectionID $PD.NewCollection.collectionId @CommonParams
            $PD.GetKeys.Count | Should -BeGreaterThan 0
            $PD.GetKeys[0].keyId | Should -Not -BeNullOrEmpty
            $PD.GetKeys[0].keyValue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-APIKey - Single' {
        It 'returns a specific key' {
            $PD.GetKey = Get-APIKey -KeyID $PD.GetKeys[0].keyId @CommonParams
            $PD.GetKey.keyId | Should -Be $PD.GetKeys[0].keyId
            $PD.GetKey.keyValue | Should -Be $PD.GetKeys[0].keyValue
        }
    }

    Context 'Set-APIKey by pipeline' {
        It 'updates correctly' {
            $PD.SetKeyByPipeline = ($PD.GetKey | Set-APIKey @CommonParams)
            $PD.SetKeyByPipeline.keyValue | Should -Be $PD.GetKey.keyValue
        }
    }

    Context 'Set-APIKey by param' {
        It 'updates correctly' {
            $PD.SetKeyByParam = Set-APIKey -KeyID $PD.GetKey.keyId -Body $PD.GetKey @CommonParams
            $PD.SetKeyByParam.keyValue | Should -Be $PD.GetKey.keyValue
        }
    }

    Context 'Revoke-APIKey' {
        It 'completes successfully' {
            Revoke-APIKey -KeyIDs $PD.GetKeys.keyId @CommonParams
        }
    }

    Context 'Restore-APIKey' {
        It 'completes successfully' {
            Restore-APIKey -KeyIDs $PD.GetKeys.keyId @CommonParams
        }
    }
    
    Context 'Add-APIKeyToCollection' {
        It 'completes successfully' {
            $PD.Assign = Add-APIKeyToCollection -CollectionIDs $PD.NewCollectionByPipeline.CollectionID -KeyIDs $PD.GetKeys.keyId @CommonParams
            $PD.Assign.count | Should -Be $PD.GetKeys.keyId.count
            $PD.Assign[0].keyId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Remove-APIKeyFromCollection' {
        It 'completes successfully' {
            $PD.Unassign = Remove-APIKeyFromCollection -CollectionIDs $PD.NewCollection.CollectionID -KeyIDs $PD.GetKeys.keyId @CommonParams
            $PD.Unassign.count | Should -Be $PD.GetKeys.keyId.count
            $PD.Unassign[0].keyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Move-APIKey' {
        It 'completes successfully' {
            $PD.MoveKeys = Move-APIKey -KeyIDs $PD.GetKeys.keyId -DestinationCollectionID $PD.NewCollection.CollectionID @CommonParams
            $PD.MoveKeys.movedKeyIds | Should -Be $PD.GetKeys.keyId
            $PD.MoveKeys.destinationCollectionId | Should -Be $PD.NewCollection.CollectionID
        }
    }

    #-------------------------------------------------
    #                   Reset Keys
    #-------------------------------------------------

    Context 'Reset-APIKeyQuota' {
        It 'completes successfully' {
            Reset-APIKeyQuota -KeyIDs $PD.GetKeys.keyId @CommonParams
        }
    }

    #-------------------------------------------------
    #               Reset Collections
    #-------------------------------------------------

    Context 'Reset-APIKeyCollectionQuota' {
        It 'completes successfully' {
            Reset-APIKeyCollectionQuota -CollectionID $PD.NewCollection.collectionId -KeyIDs $PD.GetKeys.keyId @CommonParams
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
            Remove-APIKeyCollection -CollectionID $PD.NewCollection.collectionId @CommonParams 
        }
        It 'removes pipeline collection successfully' {
            $PD.NewCollectionByPipeline | Remove-APIKeyCollection @CommonParams 
        }
    }
}
