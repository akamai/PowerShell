BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.NetworkLists Tests' {

    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'

        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.NetworkLists'
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
        $TestGroupID = $env:PesterGroupID
        $TestContract = $env:PesterContractID
        $TestListName1 = "pester-1-$Timestamp"
        $TestListName2 = "pester-2-$Timestamp"
        $TestElement1 = '1.1.1.1'
        $TestElement2 = '2.2.2.2'
        $TestElement3 = '3.3.3.3'
        $TestElement4 = '4.4.4.4'
        $TestNewElements = '11.11.11.11', '12.12.12.12'
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.NetworkLists"
        $PD = @{}
    }

    AfterAll {
        Get-NetworkList @CommonParams | Where-Object name -in $TestListName1, $TestListName2 | Remove-NetworkList @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'New-NetworkList' {
        It 'creates a list successfully without items' {
            $TestParams = @{
                'Name'        = $TestListName1
                'Type'        = 'IP'
                'Description' = 'testing'
                'ContractId'  = $TestContract
                'GroupID'     = $TestGroupID
            }
            $PD.NewList = New-NetworkList @TestParams @CommonParams
            $PD.NewList.name | Should -Be $TestListName1
        }
        It 'creates a list successfully with items' {
            $TestParams = @{
                'Name'        = $TestListName2
                'Type'        = 'IP'
                'Description' = 'testing'
                'ContractId'  = $TestContract
                'GroupID'     = $TestGroupID
                'Items'       = $TestElement1, $TestElement2, $TestElement3
            }
            $PD.NewListWithItems = New-NetworkList @TestParams @CommonParams
            $PD.NewListWithItems.name | Should -Be $TestListName2
            $PD.NewListWithItems.list | Should -Contain $TestElement1
            $PD.NewListWithItems.list | Should -Contain $TestElement2
            $PD.NewListWithItems.list | Should -Contain $TestElement3
        }
    }

    Context 'Add-NetworkListItem' {
        It 'adds items by parameter' {
            $TestParams = @{
                'NetworkListID' = $PD.NewList.uniqueId
                'Items'         = $TestElement1
            }
            $PD.AddItems = Add-NetworkListItem @TestParams @CommonParams
            $PD.AddItems.list | Should -Contain $TestElement1
        }
        It 'adds items by piped items' {
            $TestParams = @{
                'NetworkListID' = $PD.NewList.uniqueId
            }
            $PD.AddItemsByPipeline = $TestElement2, $TestElement3 | Add-NetworkListItem @TestParams @CommonParams
            $PD.AddItemsByPipeline.list | Should -Contain $TestElement2
            $PD.AddItemsByPipeline.list | Should -Contain $TestElement3
        }
        It 'adds items by piped network list' {
            $TestParams = @{
                'Items' = $TestElement4
            }
            $PD.AddItemsByPipelineList = $PD.NewList | Add-NetworkListItem @TestParams @CommonParams
            $PD.AddItemsByPipelineList.list | Should -Contain $TestElement4
        }
    }

    Context 'Get-NetworkList' {
        It 'returns a list of lists' {
            $TestParams = @{
                'Extended'        = $true
                'IncludeElements' = $true
            }
            $PD.NetworkLists = Get-NetworkList @TestParams @CommonParams
            $PD.NetworkLists.count | Should -BeGreaterThan 0
        }
        It 'returns specific list by parameter' {
            $TestParams = @{
                'NetworkListID' = $PD.NewList.uniqueId
            }
            $PD.List = Get-NetworkList @TestParams @CommonParams -IncludeElements
            $PD.List.name | Should -Be $TestListName1
            $PD.List.list | Should -Not -BeNullorEmpty
        }
        It 'returns a specific list by pipeline' {
            $PD.ListByPipeline = $PD.NewList | Get-NetworkList @CommonParams
            $PD.ListByPipeline.name | Should -Be $TestListName1
        }
    }

    Context 'Set-NetworkList' {
        It 'updates successfully by pipeline' {
            $PD.SetListByPipeline = $PD.List | Set-NetworkList @CommonParams
            $PD.SetListByPipeline.name | Should -Be $TestListName1
        }
        It 'updates successfully by body' {
            $TestParams = @{
                'NetworkListID' = $PD.NewList.uniqueId
                'Body'          = $PD.List
            }
            $PD.SetListByBody = Set-NetworkList @TestParams @CommonParams
            $PD.SetListByBody.name | Should -Be $TestListName1
        }
    }

    Context 'Remove-NetworkListItem' {
        It 'removes items by parameter' {
            $TestParams = @{
                'NetworkListID' = $PD.NewList.uniqueId
                'Items'         = $TestElement1
            }
            $PD.RemoveItems = Remove-NetworkListItem @TestParams @CommonParams
            $PD.RemoveItems.list | Should -Not -Contain $TestElement1
        }
        It 'removes items by piped items' {
            $TestParams = @{
                'NetworkListID' = $PD.NewList.uniqueId
            }
            $Remove1, $Remove2 = $TestElement2, $TestElement3 | Remove-NetworkListItem @TestParams @CommonParams
            $Remove1.list | Should -Not -Contain $TestElement2
            $Remove2.list | Should -Not -Contain $TestElement3
        }
        It 'removes items by piped network list' {
            $TestParams = @{
                'Items' = $TestElement4
            }
            $PD.RemoveItemsByPipelineList = $PD.NewList | Remove-NetworkListItem @TestParams @CommonParams
            $PD.RemoveItemsByPipelineList.list | Should -Not -Contain $TestElement4
        }
    }

    Context 'New-NetworkListSubscription' {
        It 'throws no errors' {
            $TestParams = @{
                'Recipients' = 'mail@example.com', 'noreply@example.com'
                'UniqueIDs'  = $PD.NewList.uniqueId
            }
            New-NetworkListSubscription @TestParams @CommonParams
        }
    }

    Context 'Remove-NetworkListSubscription' {
        It 'throws no errors' {
            $TestParams = @{
                'Recipients' = 'mail@example.com', 'noreply@example.com'
                'UniqueIDs'  = $PD.NewList.uniqueId
            }
            Remove-NetworkListSubscription @TestParams @CommonParams
        }
    }

    Context 'New-NetworkListSubscription (old param alias)' {
        It 'throws no errors' {
            $TestParams = @{
                'Recipients' = 'mail@example.com', 'noreply@example.com'
                'UniquedIDs' = $PD.NewList.uniqueId
            }
            New-NetworkListSubscription @TestParams @CommonParams
        }
    }

    Context 'Remove-NetworkListSubscription (old param alias)' {
        It 'throws no errors' {
            $TestParams = @{
                'Recipients' = 'mail@example.com', 'noreply@example.com'
                'UniquedIDs' = $PD.NewList.uniqueId
            }
            Remove-NetworkListSubscription @TestParams @CommonParams
        }
    }

    Context 'Remove-NetworkList' {
        It 'removes list by parameter' {
            $TestParams = @{
                'NetworkListID' = $PD.NewList.uniqueId
            }
            $PD.Removal = Remove-NetworkList @TestParams @CommonParams
            $PD.Removal.status | Should -Be 200
            $PD.Removal.uniqueId | Should -Be $PD.NewList.uniqueId
        }
        It 'removes list by piped network list' {
            $PD.RemovalByPipeline = $PD.NewListWithItems | Remove-NetworkList @CommonParams
            $PD.RemovalByPipeline.status | Should -Be 200
            $PD.RemovalByPipeline.uniqueId | Should -Be $PD.NewListWithItems.uniqueId
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.NetworkLists -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetworkList
            $Result | Should -Not -Be 'IAR executed'
        }
    }


    Context 'New-NetworkListActivation' {
        It 'activates correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.NetworkLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetworkListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'NetworkListID'          = '123_EXAMPLE'
                'Environment'            = 'STAGING'
                'Comments'               = 'Activating'
                'NotificationRecipients' = 'email@example.com', 'email2@example.com'
            }
            $Activate = New-NetworkListActivation @TestParams
            $Activate.activationStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetworkListActivationStatus' {
        It 'returns status' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.NetworkLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetworkListActivationStatus.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Environment'   = 'STAGING'
                'NetworkListID' = 123
            }
            $Status = Get-NetworkListActivationStatus @TestParams
            $Status.activationStatus | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.NetworkLists -MockWith { return 'IAR executed' }
            $TestParams = @{
                'Environment' = 'STAGING'
            }
            $Result = & {} | Get-NetworkListActivationStatus @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-NetworkListActivation' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.NetworkLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetworkListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ActivationID' = 123456
            }
            $Activation = Get-NetworkListActivation @TestParams
            $Activation.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetworkListSnapshot' {
        It 'returns a snapshot' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.NetworkLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetworkListSnapshot.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'NetworkListID' = '123_EXAMPLE'
                'SyncPoint'     = 1
            }
            $PD.Snapshot = Get-NetworkListSnapshot @TestParams @CommonParams
            $PD.Snapshot.name | Should -Not -BeNullOrEmpty
            $PD.Snapshot.syncPoint | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.NetworkLists -MockWith { return 'IAR executed' }
            $Result = & {} | Get-NetworkListSnapshot
            $Result | Should -Not -Be 'IAR executed'
        }
    }
}

