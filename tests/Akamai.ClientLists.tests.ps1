
Describe 'Safe Akamai.ClientLists Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.ClientLists/Akamai.ClientLists.psm1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestClientListName1 = 'akamaipowershell-testing1'
        $TestClientListName2 = 'akamaipowershell-testing2'
        $TestListType = 'IP'
        $TestClientListJSON = @"
{
    "type": "$TestListType",
    "contractId": "$TestContract",
    "groupId": $TestGroupID,
    "name": "$TestClientListName1",
    "notes": "PowerShell pester testing"
}
"@
        $TestFileName = 'cl.csv'
        $TestCSVContent = @"
value,description,tags,expirationDate
1.1.1.1,testing,powershell,
2.2.2.2,testing,powershell,
"@
        $TestCSVContent | Set-Content -Path $TestFileName
        $TestItems = '3.3.3.3,4.4.4.4'
        $TestItemsAll = '1.1.1.1', '2.2.2.2', '3.3.3.3', '4.4.4.4'
        
        $PD = @{}
    }

    AfterAll {
        Remove-Item $TestFileName
        Get-ClientList @CommonParams | Where-Object name -in $TestClientListName1, $TestClientListName2 | Remove-ClientList @CommonParams
    }

    #------------------------------------------------
    #                 ClientList                  
    #------------------------------------------------

    Context 'New-ClientList - Parameter Set body, by parameter' {
        it 'returns the correct data' {
            $PD.NewClientListByBody = New-ClientList -Body $TestClientListJSON @CommonParams
            $PD.NewClientListByBody.name | Should -Be $TestClientListName1
        }
    }

    Context 'New-ClientList - Parameter Set attributes' {
        it 'returns the correct data' {
            $PD.NewClientList = New-ClientList -ContractID $TestContract -GroupID $TestGroupID -Name $TestClientListName2 -Type IP @CommonParams
            $PD.NewClientList.name | Should -Be $TestClientListName2
        }
    }

    Context 'Get-ClientList - Parameter Set all' {
        it 'returns the correct data' {
            $PD.GetClientListAll = Get-ClientList @CommonParams
            $PD.GetClientListAll[0].listId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ClientList - Parameter Set single, by parameter' {
        it 'returns the correct data' {
            $PD.GetClientList = Get-ClientList -ListID $PD.NewClientListByBody.listId @CommonParams
            $PD.GetClientList.listId | Should -Be $PD.NewClientListByBody.listId
        }
    }

    Context 'Get-ClientList - Parameter Set single, by pipeline' {
        it 'returns the correct data' {
            $PD.GetClientListByName = Get-ClientList -Name $PD.NewClientList.name @CommonParams
            $PD.GetClientListByName.listId | Should -Be $PD.NewClientList.listId
        }
    }

    Context 'Set-ClientList by parameter' {
        it 'returns the correct data' {
            $PD.SetClientListByParam = Set-ClientList -ListID $PD.NewClientListByBody.listId -NewName $TestClientListName1 @CommonParams
            $PD.SetClientListByParam.listId | Should -Be $PD.NewClientListByBody.listId
        }
    }

    Context 'Set-ClientList - Parameter Set id-body, name-body, by pipeline' {
        it 'returns the correct data' {
            $PD.SetClientListByPipeline = ($PD.NewClientList | Set-ClientList -ListID $PD.NewClientList.listId @CommonParams)
            $PD.SetClientListByPipeline.listId | Should -Be $PD.NewClientList.listId
        }
    }

    #------------------------------------------------
    #                 ClientListDetails                  
    #------------------------------------------------

    Context 'Expand-ClientListDetails' {
        It 'returns the correct data' {
            $PD.ExpandClientListDetails = Expand-ClientListDetails -Name $TestClientListName1 -Version latest @CommonParams
            $PD.ExpandClientListDetails | Should -Be @($PD.NewClientListByBody.listId, 1)
        }
    }

    #------------------------------------------------
    #                 ClientListContractsGroups                  
    #------------------------------------------------

    Context 'Get-ClientListContractsGroups' {
        It 'returns the correct data' {
            $PD.GetClientListContractsGroups = Get-ClientListContractsGroups @CommonParams
            $PD.GetClientListContractsGroups[0].contractId | Should -Be $TestContract
        }
    }

    #------------------------------------------------
    #                 ClientListItem                  
    #------------------------------------------------

    Context 'Add-ClientListItem from file' {
        It 'returns the correct data' {
            $PD.AddClientListItemFromFile = Add-ClientListItem -Name $TestClientListName1 -Action MERGE -File $TestFileName -ListType $TestListType -Version latest @CommonParams
            $PD.AddClientListItemFromFile.value | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Add-ClientListItem by items' {
        It 'returns the correct data' {
            $PD.AddClientListItemByItems = Add-ClientListItem -ListID $PD.NewClientListByBody.listId -Action MERGE -Items $TestItems -Version latest @CommonParams
            $PD.AddClientListItemByItems.value | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ClientListItem - Parameter Set id' {
        it 'returns the correct data' {
            $PD.GetClientListItemID = Get-ClientListItem -ListID $PD.NewClientListByBody.listId @CommonParams
            $PD.GetClientListItemID.count | Should -Be 4
            $PD.GetClientListItemID[0].type | Should -Be $TestListType
        }
    }

    Context 'Get-ClientListItem - Parameter Set name' {
        it 'returns the correct data' {
            $PD.GetClientListItemName = Get-ClientListItem -Name $PD.NewClientListByBody.name @CommonParams
            $PD.GetClientListItemID.count | Should -Be 4
            $PD.GetClientListItemID[0].type | Should -Be $TestListType
        }
    }

    Context 'Set-ClientListItem by body' {
        It 'returns the correct data' {
            $PD.SetClientListItemByBody = Set-ClientListItem -ListID $PD.NewClientListByBody.listId -Body @{ update = $PD.GetClientListItemID } @CommonParams
            $PD.SetClientListItemByBody.updated.count | Should -Be 4
            $PD.SetClientListItemByBody.updated[0].value | Should -BeIn $TestItemsAll
        }
    }

    Context 'Set-ClientListItem by items' {
        it 'returns the correct data' {
            $PD.SetClientListItemByItems = Set-ClientListItem -ListID $PD.NewClientListByBody.listId -Items $PD.GetClientListItemID -Operation update @CommonParams
            $PD.SetClientListItemByItems.updated.count | Should -Be 4
            $PD.SetClientListItemByItems.updated[0].value | Should -BeIn $TestItemsAll
        }
    }
    
    Context 'Remove-ClientListItem' {
        It 'returns the correct data' {
            $PD.RemoveClientListItem = Remove-ClientListItem -ListID $PD.NewClientListByBody.listId -Items $PD.GetClientListItemID[0] -Operation delete @CommonParams
            $PD.RemoveClientListItem.deleted[0].value | Should -Be $PD.GetClientListItemID[0].value
        }
    }

    #------------------------------------------------
    #                 ClientListItems                  
    #------------------------------------------------

    Context 'Test-ClientListItems - Parameter Set file' {
        it 'returns the correct data' {
            $TestClientListItemsByFile = Test-ClientListItems -File $TestFileName -ListType $TestListType @CommonParams
            $TestClientListItemsByFile.importedCount | Should -Be 2
        }
    }

    Context 'Test-ClientListItems - Parameter Set items' {
        it 'returns the correct data' {
            $TestClientListItemsByItems = Test-ClientListItems -Items $TestItems -ListType $TestListType @CommonParams
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
    #                 Removals                  
    #------------------------------------------------

    Context 'Remove-ClientList - Parameter Set id, by parameter' {
        it 'throws no errors' {
            Remove-ClientList -ListID $PD.NewClientListByBody.listId @CommonParams 
        }
    }

    Context 'Remove-ClientList - Parameter Set name' {
        it 'throws no errors' {
            Remove-ClientList -Name $TestClientListName2 @CommonParams 
        }
    }
}

Describe 'Unsafe Akamai.ClientLists Tests' {

    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.ClientLists/Akamai.ClientLists.psm1 -Force
        $TestActivationJSON = @"
{
    "action": "ACTIVATE",
    "network": "STAGING",
    "comments": "Activation of GEO allowlist",
    "notificationRecipients": [
        "mail@example.com"
    ]
}
"@
        $TestDeactivation = ConvertFrom-Json $TestActivationJSON
        $TestDeactivation.action = 'DEACTIVATE'
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.ClientLists"
        $PD = @{}
        
    }

    AfterAll {
        
    }


    #------------------------------------------------
    #                 ClientListActivation                  
    #------------------------------------------------

    Context 'New-ClientListActivation by attributes' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ClientListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $NewClientListActivationByAttributes = New-ClientListActivation -ListID 123456_TESTING -Network PRODUCTION -Comments 'testing' -NotificationRecipients 'mail@example.com'
            $NewClientListActivationByAttributes.action | Should -Be 'ACTIVATE'
        }
    }

    Context 'New-ClientListActivation by body' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ClientListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $NewClientListActivationByBody = New-ClientListActivation -ListID 123456_TESTING -Body $TestActivationJSON
            $NewClientListActivationByBody.action | Should -Be 'ACTIVATE'
        }
    }
    
    Context 'New-ClientListDeactivation by attributes' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ClientListDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $NewClientListDeactivationByAttributes = New-ClientListDeactivation -ListID 123456_TESTING -Network PRODUCTION -Comments 'testing' -NotificationRecipients 'mail@example.com'
            $NewClientListDeactivationByAttributes.action | Should -Be 'ACTIVATE'
        }
    }

    Context 'New-ClientListDeactivation by body' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ClientListDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $NewClientListDeactivationByBody = New-ClientListDeactivation -ListID 123456_TESTING -Body $TestDeactivation
            $NewClientListDeactivationByBody.action | Should -Be 'ACTIVATE' # Stubbed endpoint doesnt consider POST body, so this will still be ACTIVATE
        }
    }

    Context 'Get-ClientListActivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $GetClientListActivation = Get-ClientListActivation -ActivationID 123
            $GetClientListActivation.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ClientListActivationStatus                  
    #------------------------------------------------

    Context 'Get-ClientListActivationStatus' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListActivationStatus.json"
                return $Response | ConvertFrom-Json
            }
            $GetClientListActivationStatusID = Get-ClientListActivationStatus -Environment STAGING -ListID 123456_TESTING
            $GetClientListActivationStatusID.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ClientListUsage                  
    #------------------------------------------------

    Context 'Get-ClientListUsage - Parameter Set id' {
        it 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListUsage.json"
                return $Response | ConvertFrom-Json
            }
            $GetClientListUsageID = Get-ClientListUsage -ListID 123456_TESTING
            $GetClientListUsageID.usage[0].configId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ClientListSnapshot                  
    #------------------------------------------------

    Context 'Get-ClientListSnapshot' {
        it 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListSnapshot.json"
                return $Response | ConvertFrom-Json
            }
            $GetClientListSnapshotID = Get-ClientListSnapshot -ListID 123456_TESTING -Version 1
            $GetClientListSnapshotID[0].type | Should -Not -BeNullOrEmpty
        }

        it 'returns content' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ClientLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ClientListSnapshot.json"
                return $Response | ConvertFrom-Json
            }
            $GetClientListSnapshotName = Get-ClientListSnapshot -ListID 123456_TESTING -Version 1 -IncludeMetadata
            $GetClientListSnapshotName.content | Should -Not -BeNullOrEmpty
        }
    }
}

