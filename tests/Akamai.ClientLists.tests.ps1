BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw 'Required environment variables are missing'
    }
}

Describe 'Akamai.ClientLists Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'

        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.ClientLists'
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
        $TestClientListName1 = "pester-1-$Timestamp"
        $TestClientListName2 = "pester-2-$Timestamp"
        $TestListType = 'IP'
        $TestClientListJSON = @"
{
    "type": "$TestListType",
    "contractId": "$TestContractID",
    "groupId": $TestGroupID,
    "name": "$TestClientListName1",
    "notes": "PowerShell pester testing",
    "tags": [
        "pester",
        "body"
    ]
}
"@
        $TestFileName = "TestDrive:/cl-$Timestamp.csv"
        $TestCSVContent = "value,description,tags,expirationDate`n1.1.1.1,testing,powershell,`n2.2.2.2,testing,powershell,"
        $TestCSVContent | Set-Content -Path $TestFileName
        $TestItems = '3.3.3.3', '4.4.4.4'
        $TestItemsAll = '1.1.1.1', '2.2.2.2', '3.3.3.3', '4.4.4.4'

        $TestActivationJSON = '{
            "action": "ACTIVATE",
            "network": "STAGING",
            "comments": "Activation of GEO allowlist",
            "notificationRecipients": [
                "mail@example.com"
            ]
        }'
        $TestDeactivation = ConvertFrom-Json $TestActivationJSON
        $TestDeactivation.action = 'DEACTIVATE'
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.ClientLists"

        $PD = @{}
    }

    AfterAll {
        Get-ClientList @CommonParams | Where-Object name -In $TestClientListName1, $TestClientListName2 | Remove-ClientList @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 ClientList
    #------------------------------------------------

    Context 'New-ClientList' {
        It 'creates successfully by pipeline' {
            $PD.NewClientListByBody = $TestClientListJSON | New-ClientList @CommonParams
            $PD.NewClientListByBody.name | Should -Be $TestClientListName1
        }
        It 'creates successfully by attributes' {
            $TestParams = @{
                'ContractID' = $TestContractID
                'GroupID'    = $TestGroupID
                'Name'       = $TestClientListName2
                'Type'       = 'IP'
                'Items'      = @('1.1.1.1', '2.2.2.2')
                'Tags'       = @('pester', 'attributes')
            }
            $PD.NewClientList = New-ClientList @TestParams @CommonParams
            $PD.NewClientList.name | Should -Be $TestClientListName2
        }
    }

    Context 'Get-ClientList' {
        It 'returns a list' {
            $PD.ClientLists = Get-ClientList @CommonParams
            $PD.ClientLists[0].listId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct list by ID' {
            $PD.ClientListByID = $PD.NewClientListByBody.listId | Get-ClientList @CommonParams
            $PD.ClientListByID.listId | Should -Be $PD.NewClientListByBody.listId
        }
        It 'returns the correct list by Name' {
            $TestParams = @{
                'Name' = $PD.NewClientList.name
            }
            $PD.ClientListByName = Get-ClientList @TestParams @CommonParams
            $PD.ClientListByName.listId | Should -Be $PD.NewClientList.listId
        }
    }

    Context 'Set-ClientList' {
        It 'updates successfully by ID' {
            $TestParams = @{
                'NewName' = $TestClientListName1
                'Name'    = $PD.NewClientListByBody.Name
            }
            $PD.SetClientListByParam = Set-ClientList @TestParams @CommonParams
            $PD.SetClientListByParam.listId | Should -Be $PD.NewClientListByBody.listId
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'NewName' = $TestClientListName2
            }
            $PD.SetClientListByPipeline = $PD.NewClientList | Set-ClientList @TestParams @CommonParams
            $PD.SetClientListByPipeline.listId | Should -Be $PD.NewClientList.listId
        }
    }

    #------------------------------------------------
    #                 ClientListDetails
    #------------------------------------------------

    Context 'Expand-ClientListDetails' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.ClientLists/Functions/Private/Expand-ClientListDetails.ps1

            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = 'TestDrive:/options.json'
            # Creat options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache

            $ProductionActiveList = $PD.ClientLists | Where-Object productionActiveVersion | Select-Object -First 1
            $StagingActiveList = $PD.ClientLists | Where-Object stagingActiveVersion | Select-Object -First 1
        }
        It 'finds the right client list' {
            $TestParams = @{
                'Name' = $TestClientListName1
            }
            $PD.ExpandedListID, $null = Expand-ClientListDetails @TestParams @CommonParams
            $PD.ExpandedListID | Should -Be $PD.NewClientListByBody.listId
            $AkamaiDataCache.ClientLists.Lists.$TestClientListName1.ListID | Should -Be $PD.ExpandedListID
        }
        It 'throws when the client list does not exist' {
            $TestParams = @{
                'Name' = 'some-client-list-which-doesnt-exist'
            }
            { Expand-ClientListDetails @TestParams @CommonParams } | Should -Throw 'Client List * not found.'
        }
        It 'finds the latest version' {
            $TestParams = @{
                'Name'    = $TestClientListName1
                'Version' = 'latest'
            }
            $ExpandedListID, $PD.ExpandedVersion = Expand-ClientListDetails @TestParams @CommonParams
            $ExpandedListID | Should -Be $PD.NewClientListByBody.listId
            $PD.ExpandedVersion | Should -Be 1
            $AkamaiDataCache.ClientLists.Lists.$TestClientListName1.ListID | Should -Be $ExpandedListID
        }
        It 'finds the production version' {
            $TestParams = @{
                'ListID'  = $ProductionActiveList.listId
                'Version' = 'production'
            }
            $ProductionListID, $ProductionVersion = Expand-ClientListDetails @TestParams @CommonParams
            $ProductionListID | Should -Be $ProductionActiveList.listId
            $ProductionVersion | Should -Be $ProductionActiveList.productionActiveVersion
        }
        It 'finds the staging version' {
            $TestParams = @{
                'ListID'  = $StagingActiveList.listId
                'Version' = 'staging'
            }
            $StagingListID, $StagingVersion = Expand-ClientListDetails @TestParams @CommonParams
            $StagingListID | Should -Be $StagingActiveList.listId
            $StagingVersion | Should -Be $StagingActiveList.stagingActiveVersion
        }
        It 'throws when there is no production-active version' {
            $TestParams = @{
                'Name'    = $TestClientListName1
                'Version' = 'production'
            }
            { Expand-ClientListDetails @TestParams @CommonParams } | Should -Throw 'No production-active version of client list*'
        }
        It 'throws when there is no staging-active version' {
            $TestParams = @{
                'Name'    = $TestClientListName1
                'Version' = 'staging'
            }
            { Expand-ClientListDetails @TestParams @CommonParams } | Should -Throw 'No staging-active version of client list*'
        }
        AfterAll {
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache

            Remove-Item -Path Function:/Expand-ClientListDetails -Force
        }
    }

    #------------------------------------------------
    #                 ClientListContractsGroups
    #------------------------------------------------

    Context 'Get-ClientListContractsGroups' {
        It 'returns the correct data' {
            $PD.GetClientListContractsGroups = Get-ClientListContractsGroups @CommonParams
            $PD.GetClientListContractsGroups[0].contractId | Should -Be $TestContractID
        }
    }

    #------------------------------------------------
    #                 ClientListItem
    #------------------------------------------------

    Context 'Add-ClientListItem' {
        It 'adds correctly by items' {
            $TestParams = @{
                'ListID' = $PD.NewClientListByBody.listId
            }
            $PD.AddClientListItemByItems = $TestItems | Add-ClientListItem @TestParams @CommonParams
            $PD.AddClientListItemByItems.appended.value | Sort-Object | Should -Be $TestItems
        }
    }

    Context 'Get-ClientListItem' {
        It 'returns the correct data by id' {
            $PD.GetClientListItemID = $PD.NewClientListByBody.listId | Get-ClientListItem @CommonParams
            $PD.GetClientListItemID.count | Should -Be 2
            $PD.GetClientListItemID[0].type | Should -Be $TestListType
        }
        It 'returns the correct data by name' {
            $TestParams = @{
                'Name' = $PD.NewClientListByBody.name
            }
            $PD.GetClientListItemName = Get-ClientListItem @TestParams @CommonParams
            $PD.GetClientListItemID.count | Should -Be 2
            $PD.GetClientListItemID[0].type | Should -Be $TestListType
        }
        It 'handles empty input' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith { return 'IAR executed' }
            $TestParams = @{
                'Debug' = $true
            }
            $Result = & {} | Get-ClientListItem @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-ClientListItem' {
        It 'sets items by body' {
            $TestParams = @{
                'ListID' = $PD.NewClientListByBody.listId
                'Body'   = @{ 'update' = $PD.GetClientListItemID }
            }
            $PD.SetClientListItemByBody = Set-ClientListItem @TestParams @CommonParams
            $PD.SetClientListItemByBody.updated.count | Should -Be 2
            $PD.SetClientListItemByBody.updated[0].value | Should -BeIn $TestItemsAll
        }
        It 'sets items by param without an operation' {
            $TestParams = @{
                'ListID' = $PD.NewClientListByBody.listId
                'Items'  = $PD.GetClientListItemID
            }
            $PD.SetClientListItemByItems = Set-ClientListItem @TestParams @CommonParams
            $PD.SetClientListItemByItems.updated.count | Should -Be 2
            $PD.SetClientListItemByItems.updated[0].value | Should -BeIn $TestItemsAll
        }
        It 'sets items by param with a specified operation' {
            $TestParams = @{
                'ListID'    = $PD.NewClientListByBody.listId
                'Items'     = $PD.GetClientListItemID
                'operation' = 'update'
            }
            $PD.SetClientListItemByItems = Set-ClientListItem @TestParams @CommonParams
            $PD.SetClientListItemByItems.updated.count | Should -Be 2
            $PD.SetClientListItemByItems.updated[0].value | Should -BeIn $TestItemsAll
        }
    }

    Context 'Remove-ClientListItem' {
        It 'returns the correct data' {
            $TestParams = @{
                'ListID' = $PD.NewClientListByBody.listId
            }
            $PD.RemoveClientListItem = $PD.GetClientListItemID[0] | Remove-ClientListItem @TestParams @CommonParams
            $PD.RemoveClientListItem.deleted[0].value | Should -Be $PD.GetClientListItemID[0].value
        }
    }

    Context 'Import-ClientListItem' {
        It 'imports correctly from file' {
            $TestParams = @{
                'Name'    = $TestClientListName1
                'Version' = 'latest'
                'File'    = $TestFileName
                'Action'  = 'MERGE'
            }
            $PD.ImportClientListItemByFile = Import-ClientListItem @TestParams @CommonParams
            $PD.ImportClientListItemByFile.count | Should -Be 2
        }
        It 'imports correctly from file and returns status' {
            $TestParams = @{
                'Name'          = $TestClientListName1
                'Version'       = 'latest'
                'File'          = $TestFileName
                'Action'        = 'REPLACE'
                'IncludeStatus' = $true
            }
            $PD.ImportClientListItemByFile = Import-ClientListItem @TestParams @CommonParams
            $PD.ImportClientListItemByFile.result.count | Should -Be 2
            $PD.ImportClientListItemByFile.itemsImported | Should -Be $true
            $PD.ImportClientListItemByFile.listVersion | Should -Match '^[\d]+$'
        }
        It 'imports correctly by items' {
            $TestParams = @{
                'ListID'  = $PD.NewClientListByBody.listId
                'Version' = 'latest'
                'Items'   = $TestItems
                'Action'  = 'REPLACE'
            }
            $PD.ImportClientListItemByItems = Import-ClientListItem @TestParams @CommonParams
            $PD.ImportClientListItemByItems.count | Should -Be 2
        }
    }

    #------------------------------------------------
    #                 ClientListItems
    #------------------------------------------------

    Context 'Test-ClientListItem' {
        It 'completes successfuly by file' {
            $TestParams = @{
                'File'     = $TestFileName
                'ListType' = $TestListType
            }
            $TestClientListItemsByFile = Test-ClientListItem @TestParams @CommonParams
            $TestClientListItemsByFile.importedCount | Should -Be 2
        }
        It 'completes successfully by items' {
            $TestParams = @{
                'Items'    = $TestItems
                'ListType' = $TestListType
            }
            $TestClientListItemsByItems = Test-ClientListItem @TestParams @CommonParams
            $TestClientListItemsByItems.importedCount | Should -Be 2
        }
    }

    #------------------------------------------------
    #                 ClientListTag
    #------------------------------------------------

    Context 'Get-ClientListTag' {
        It 'returns the correct data' {
            $PD.GetClientListTag = Get-ClientListTag @CommonParams
            $PD.GetClientListTag.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 Subscriptions
    #------------------------------------------------

    Context 'New-ClientListSubscription' {
        It 'subscribes successfully' {
            $TestParams = @{
                'Recipients' = 'mail2@example.com', 'mail2@example.com'
                'UniqueIDs'  = $PD.NewClientListByBody.listId, $PD.NewClientList.listId
            }
            New-ClientListSubscription @TestParams @CommonParams
        }
    }

    Context 'Remove-ClientListSubscription' {
        It 'unsubscribes successfully' {
            $TestParams = @{
                'Recipients' = 'mail2@example.com', 'mail2@example.com'
                'UniqueIDs'  = $PD.NewClientListByBody.listId, $PD.NewClientList.listId
            }
            Remove-ClientListSubscription @TestParams @CommonParams
        }
    }

    #------------------------------------------------
    #                 Removals
    #------------------------------------------------

    Context 'Remove-ClientList' {
        It 'throws no errors by pipeline' {
            $PD.NewClientListByBody | Remove-ClientList @CommonParams
        }
        It 'throws no errors by name' {
            $TestParams = @{
                'Name' = $TestClientListName2
            }
            Remove-ClientList @TestParams @CommonParams
        }
    }

    #------------------------------------------------
    #                 ClientListActivation
    #------------------------------------------------

    Context 'New-ClientListActivation' {
        It 'creates successfully by attributes' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ClientListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ListID'                 = '123456_TESTING'
                'Network'                = 'PRODUCTION'
                'Comments'               = 'testing'
                'NotificationRecipients' = 'mail@example.com'
            }
            $NewClientListActivationByAttributes = New-ClientListActivation @TestParams
            $NewClientListActivationByAttributes.action | Should -Be 'ACTIVATE'
        }
        It 'creates successfully by body' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ClientListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ListID' = '123456_TESTING'
                'Body'   = $TestActivationJSON
            }
            $NewClientListActivationByBody = New-ClientListActivation @TestParams
            $NewClientListActivationByBody.action | Should -Be 'ACTIVATE'
        }
    }

    Context 'New-ClientListDeactivation' {
        It 'creates successfully by attributes' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ClientListDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ListID'                 = '123456_TESTING'
                'Comments'               = 'testing'
                'NotificationRecipients' = 'mail@example.com'
            }
            $NewClientListDeactivationByAttributes = New-ClientListDeactivation @TestParams
            $NewClientListDeactivationByAttributes.action | Should -Be 'ACTIVATE' # Stubbed endpoint doesnt consider POST body, so this will still be ACTIVATE
        }
        It 'creates successfully by body' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ClientListDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ListID' = '123456_TESTING'
                'Body'   = $TestDeactivation
            }
            $NewClientListDeactivationByBody = New-ClientListDeactivation @TestParams
            $NewClientListDeactivationByBody.action | Should -Be 'ACTIVATE' # See above for why this is OK.
        }
    }

    Context 'Get-ClientListActivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ActivationID' = 123
            }
            $GetClientListActivation = Get-ClientListActivation @TestParams
            $GetClientListActivation.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ClientListActivationStatus
    #------------------------------------------------

    Context 'Get-ClientListActivationStatus' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListActivationStatus.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Environment' = 'STAGING'
                'ListID'      = '123456_TESTING'
            }
            $GetClientListActivationStatusID = Get-ClientListActivationStatus @TestParams
            $GetClientListActivationStatusID.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ClientListUsage
    #------------------------------------------------

    Context 'Get-ClientListUsage' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListUsage.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ListID' = '123456_TESTING'
            }
            $GetClientListUsageID = Get-ClientListUsage @TestParams
            $GetClientListUsageID.usage[0].configId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ClientListSnapshot
    #------------------------------------------------

    Context 'Get-ClientListSnapshot' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListSnapshot.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ListID'  = '123456_TESTING'
                'Version' = 1
            }
            $Snapshot = Get-ClientListSnapshot @TestParams
            $Snapshot[0].type | Should -Not -BeNullOrEmpty
        }
    }
}

