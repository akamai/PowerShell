BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.EdgeKV Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.EdgeKV', 'Akamai.EdgeWorkers'
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
        $TestNamespaceGroup1 = "group-one-$Timestamp"
        $TestNamespaceGroup2 = "group-two-$Timestamp"
        $TestUploadGroup = "import-$Timestamp"
        $TestNamespace = $env:PesterEKVNamespace
        $TestNamespaceObj = [PSCustomObject] @{
            name               = $TestNameSpace
            retentionInSeconds = 0
            groupId            = $TestGroupID
        }
        $TestNamespaceBody = $TestNamespaceObj | ConvertTo-Json
        $TestTokenName = "akamaipowershell-$Timestamp"
        $TestNewItemID = "pester-$Timestamp"
        $TestNewItemContent = 'new'
        $TestNewItemObject = [PSCustomObject] @{
            'content' = 'new'
        }

        $NewEWParams = @{
            'EdgeWorkerName' = "pester-ekv-$Timestamp"
            'GroupID'        = $TestGroupID
            'ResourceTierID' = 100
        }
        $EdgeWorker = New-EdgeWorker @NewEWParams @CommonParams
        $EdgeWorkers = Get-EdgeWorker @CommonParams
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.EdgeKV"
        $PD = @{}
    }

    AfterAll {
        $CleanupParams = @{
            Network     = 'STAGING'
            NamespaceID = $TestNamespace
        }

        foreach ($Group in $TestNamespaceGroup1, $TestNamespaceGroup2) {
            try {
                Get-EdgeKVItem -GroupID $Group @CleanupParams @CommonParams | Remove-EdgeKVItem -GroupID $Group @CleanupParams @CommonParams
            }
            catch {  }
        }

        # Remove EW
        $EdgeWorker | Remove-EdgeWorker @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 Access Tokens
    #------------------------------------------------

    Context 'New-EdgeKVAccessToken' {
        It 'creates a token' {
            $TestParams = @{
                'Name'                    = $TestTokenName
                'AllowOnStaging'          = $true
                'Namespace'               = $TestNameSpace
                'Permissions'             = 'r'
                'RestrictToEdgeWorkerIds' = @($EdgeWorkers[0].edgeWorkerId)
            }
            $PD.Token = New-EdgeKVAccessToken @TestParams @CommonParams
            $PD.Token.name | Should -Be $TestTokenName
        }
    }

    Context 'Get-EdgeKVAccessToken' {
        It 'returns list of tokens' {
            $PD.Tokens = Get-EdgeKVAccessToken @CommonParams
            $PD.Tokens.count | Should -Not -Be 0
        }
        It 'returns a single token' {
            $TestParams = @{
                'TokenName' = $TestTokenName
            }
            $PD.Token = Get-EdgeKVAccessToken @TestParams @CommonParams
            $PD.Token.name | Should -Be $TestTokenName
        }
    }
    
    Context 'Update-EdgeKVAccessToken' {
        It 'refreshes a token' {
            $PD.RefreshedToken = $PD.Token | Update-EdgeKVAccessToken @CommonParams
            $PD.RefreshedToken.name | Should -Be $TestTokenName
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Update-EdgeKVAccessToken @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-EdgeKVAccessToken' {
        It 'removes token successfully' {
            $PD.TokenRemoval = $PD.Token | Remove-EdgeKVAccessToken @CommonParams
            $PD.TokenRemoval.name | Should -Be $TestTokenName
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-EdgeKVAccessToken @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 Status
    #------------------------------------------------

    Context 'Get-EdgeKVInitializationStatus' {
        It 'returns status' {
            $PD.Status = Get-EdgeKVInitializationStatus @CommonParams
            $PD.Status.accountStatus | Should -Be "INITIALIZED"
        }
    }

    Context 'Initialize-EdgeKV' {
        It 'initializes the DB (mocked)' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeKV -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Initialize-EdgeKV.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'AllowNamespacePolicyOverride' = $true
                'RestrictDataAccess'           = $true
            }
            $Initialize = Initialize-EdgeKV @TestParams
            $Initialize.accountStatus | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #              Permission Groups
    #------------------------------------------------

    Context 'Get-EdgeKVGroup' {
        It 'lists groups' {
            $PD.Groups = Get-EdgeKVGroup @CommonParams
            $PD.Groups[0].groupId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct group by ID' {
            $TestParams = @{
                'GroupID' = $TestGroupID
            }
            $PD.Group = Get-EdgeKVGroup @TestParams @CommonParams
            $PD.Group.groupId | Should -Be $TestGroupID
        }
    }

    #------------------------------------------------
    #                 Items
    #------------------------------------------------

    Context 'New-EdgeKVItem' {
        It 'creates successfully by param' {
            $TestParams = @{
                'ItemID'      = $TestNewItemID
                'Value'       = $TestNewItemContent
                'Network'     = 'STAGING'
                'NamespaceID' = $TestNameSpace
                'GroupID'     = $TestNamespaceGroup1
            }
            $PD.NewItemByParam = New-EdgeKVItem @TestParams @CommonParams
            $PD.NewItemByParam | Should -Match 'Item was upserted in database'
        }
        It 'creates successfully by pipeline' {
            $TestParams = @{
                'ItemID'      = $TestNewItemID
                'Network'     = 'STAGING'
                'NamespaceID' = $TestNameSpace
                'GroupID'     = $TestNamespaceGroup2
            }
            $PD.NewItemByPipeline = $TestNewItemObject | New-EdgeKVItem @TestParams @CommonParams
            $PD.NewItemByPipeline | Should -Match 'Item was upserted in database'
        }
    }

    Context 'Get-EdgeKVItem' {
        It 'returns list of items' {
            $TestParams = @{
                'Network'     = 'STAGING'
                'NamespaceID' = $TestNameSpace
                'GroupID'     = $TestNamespaceGroup1
            }
            $PD.Items = Get-EdgeKVItem @TestParams @CommonParams
            $PD.Items.count | Should -Not -Be 0
        }
        It 'returns item data by ID' {
            $TestParams = @{
                'ItemID'      = $TestNewItemID
                'Network'     = 'STAGING'
                'NamespaceID' = $TestNameSpace
                'GroupID'     = $TestNamespaceGroup1
            }
            $PD.Item = Get-EdgeKVItem @TestParams @CommonParams
            $PD.Item | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                Namespaces
    #------------------------------------------------

    Context 'Set-EdgeKVDefaultAccessPolicy' {
        It 'updates successfully (mocked)' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeKV -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-EdgeKVDefaultAccessPolicy.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'AllowNamespacePolicyOverride' = $true
                'RestrictDataAccess'           = $true
            }
            $SetNamespaceAccess = Set-EdgeKVDefaultAccessPolicy @TestParams
            $SetNamespaceAccess.dataAccessPolicy.allowNamespacePolicyOverride | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Move-EdgeKVNamespace' {
        It 'moves a namespace' {
            $TestParams = @{
                'NamespaceID' = $TestNamespace
                'GroupID'     = $TestGroupID
            }
            $PD.MoveNamespace = Move-EdgeKVNamespace @TestParams @CommonParams
            $PD.MoveNamespace.groupId | Should -Be $TestGroupID
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'GroupID' = $TestGroupID
            }
            $Result = & {} | Move-EdgeKVNamespace @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'New-EdgeKVNamespace' {
        It 'creates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeKV -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeKVNamespace.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Network'            = 'PRODUCTION'
                'GeoLocation'        = 'GLOBAL'
                'Name'               = 'MyNamespace'
                'RetentionInSeconds' = 123
                'RestrictDataAccess' = $false
                'GroupID'            = 12345
            }
            $SafeNamespace = New-EdgeKVNamespace @TestParams
            $SafeNamespace.namespace | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeKVNamespace' {
        It 'returns list of namespaces' {
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $PD.Namespaces = Get-EdgeKVNamespace @TestParams @CommonParams
            $PD.Namespaces[0].namespace | Should -Not -BeNullOrEmpty
        }
        It 'returns a namespace by ID' {
            $TestParams = @{
                'Network'     = 'STAGING'
                'NamespaceID' = $TestNamespace
            }
            $PD.Namespace = Get-EdgeKVNamespace @TestParams @CommonParams
            $PD.Namespace.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Get-EdgeKVNamespaceGroup' {
        It 'returns a list of groups' {
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $PD.NamespaceGroups = $PD.Namespace | Get-EdgeKVNamespaceGroup @TestParams @CommonParams
            $TestNamespaceGroup1 | Should -BeIn $PD.NamespaceGroups
            $TestNamespaceGroup2 | Should -BeIn $PD.NamespaceGroups
        }
    }

    Context 'Set-EdgeKVNamespace' {
        It 'updates a namespace by attributes' {
            $TestParams = @{
                'Network'            = 'STAGING'
                'NamespaceID'        = $TestNamespace
                'Name'               = $TestNameSpace
                'RetentionInSeconds' = 0
                'GroupID'            = $TestGroupID
            }
            $PD.SetNamespaceByAttr = Set-EdgeKVNamespace @TestParams @CommonParams
            $PD.SetNamespaceByAttr.namespace | Should -Be $TestNamespace
        }
        It 'updates a namespace by pipeline' {
            $TestParams = @{
                'Network'     = 'STAGING'
                'NamespaceID' = $TestNamespace
            }
            $PD.SetNamespaceByObj = $TestNamespaceObj | Set-EdgeKVNamespace @TestParams @CommonParams
            $PD.SetNamespaceByObj.namespace | Should -Be $TestNamespace
        }
        It 'updates a namespace by body' {
            $TestParams = @{
                'Network'     = 'STAGING'
                'NamespaceID' = $TestNamespace
                'Body'        = $TestNamespaceBody
            }
            $PD.SetNamespaceByBody = Set-EdgeKVNamespace @TestParams @CommonParams
            $PD.SetNamespaceByBody.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Remove-EdgeKVNamespace' {
        It 'creates a deletion request' {
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $PD.RemoveNamespace = $PD.Namespace | Remove-EdgeKVNamespace @TestParams @CommonParams
            $PD.RemoveNamespace.scheduledDeleteTime | Should -BeOfType 'DateTime'
        }
        It 'waits 1m for the deletion to be created' {
            Start-Sleep -s 60
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $Result = & {} | Remove-EdgeKVNamespace @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }
    
    Context 'Get-EdgeKVNamespaceDelete' {
        It 'retrieves a deletion request' {
            $TestParams = @{
                'Network'     = 'STAGING'
                'NamespaceID' = $PD.Namespace.namespace
            }
            $PD.GetNamespaceDelete = Get-EdgeKVNamespaceDelete @TestParams @CommonParams
            $PD.GetNamespaceDelete.scheduledDeleteTime | Should -BeOfType 'DateTime'
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $Result = & {} | Get-EdgeKVNamespaceDelete @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }
    
    Context 'Set-EdgeKVNamespaceDelete' {
        It 'updates a deletion request' {
            $PD.GetNamespaceDelete.scheduledDeleteTime = $PD.GetNamespaceDelete.scheduledDeleteTime.AddDays(-1)
            $TestParams = @{
                'Network'     = 'STAGING'
                'NamespaceID' = $PD.Namespace.namespace
            }
            $PD.SetNamespaceDelete = $PD.GetNamespaceDelete | Set-EdgeKVNamespaceDelete @TestParams @CommonParams
            $PD.SetNamespaceDelete.scheduledDeleteTime.Year | Should -Be $PD.GetNamespaceDelete.scheduledDeleteTime.Year
            $PD.SetNamespaceDelete.scheduledDeleteTime.Month | Should -Be $PD.GetNamespaceDelete.scheduledDeleteTime.Month
            $PD.SetNamespaceDelete.scheduledDeleteTime.Day | Should -Be $PD.GetNamespaceDelete.scheduledDeleteTime.Day
            $PD.SetNamespaceDelete.scheduledDeleteTime.Hour | Should -Be $PD.GetNamespaceDelete.scheduledDeleteTime.Hour
            $PD.SetNamespaceDelete.scheduledDeleteTime.Minute | Should -Be $PD.GetNamespaceDelete.scheduledDeleteTime.Minute
        }
    }
    
    Context 'Restore-EdgeKVNamespace' {
        It 'removes a deletion request' {
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $PD.Namespace | Restore-EdgeKVNamespace @TestParams @CommonParams
        }
        It 'waits 1m for the deletion to be undone' {
            Start-Sleep -s 60
            { Get-EdgeKVNamespaceDelete -Network STAGING -NamespaceID $PD.Namespace.namespace @CommonParams } | Should -Throw
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $Result = & {} | Restore-EdgeKVNamespace @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                Removals
    #------------------------------------------------

    Context 'Remove-EdgeKVItem' {
        It 'removes successfully' {
            $TestParams = @{
                'ItemID'      = $TestNewItemID
                'Network'     = 'STAGING'
                'NamespaceID' = $TestNamespace
            }
            $TestParamsOne = @{
                'GroupID' = $TestNamespaceGroup1
            }
            $TestParamsTwo = @{
                'GroupID' = $TestNamespaceGroup2
            }
            $PD.RemovalOne = Remove-EdgeKVItem @TestParamsOne @TestParams @CommonParams
            $PD.RemovalTwo = Remove-EdgeKVItem @TestParamsTwo @TestParams @CommonParams
            $PD.RemovalOne | Should -Match 'Item was marked for deletion from database'
            $PD.RemovalTwo | Should -Match 'Item was marked for deletion from database'
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'GroupID'     = 'testgroup'
                'Network'     = 'PRODUCTION'
                'NamespaceID' = 'anyolnamespace'
            }
            $Result = & {} | Remove-EdgeKVItem @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                Import/Exports
    #------------------------------------------------

    Context 'Imports/Exports' -Tag 'Import/Export' {
        BeforeAll {
            $ImportItem1 = "$TestUploadGroup,item1-$Timestamp,importedvalue1"
            $ImportItem2 = "$TestUploadGroup,item2-$Timestamp,importedvalue2"
            $ImportItem3 = "$TestUploadGroup,item3-$Timestamp,importedvalue3"
            $ImportItem4 = "$TestUploadGroup,item4-$Timestamp,importedvalue4"
            $ImportContent = @(
                $ImportItem1
                $ImportItem2
                $ImportItem3
                $ImportItem4
            ) -join "`n"
            $ImportContent | Out-File -FilePath "TestDrive:/upload.csv" -Encoding utf8
        }

        Context 'Import-EdgeKVData' {
            It 'Uploads successfully' {
                $TestParams = @{
                    'NamespaceID' = $TestNamespace
                    'Network'     = 'STAGING'
                    'InputFile'   = "TestDrive:/upload.csv"
                    'MaxItems'    = 10
                }
                $PD.UploadResult = Import-EdgeKVData @TestParams @CommonParams
                $PD.UploadResult.jobType | Should -Be 'UPLOAD'
                $PD.UploadResult.jobStatus | Should -Be 'STARTED'
            }
        }

        Context 'Get-EdgeKVUpload' {
            It 'lists upload jobs' {
                $TestParams = @{
                    'NamespaceID' = $TestNamespace
                    'Network'     = 'STAGING'
                }
                $PD.UploadJobs = Get-EdgeKVUpload @TestParams @CommonParams
                $PD.UploadJobs[0].jobType | Should -Be 'UPLOAD'
                $PD.UploadJobs[0].jobStatus | Should -Not -BeNullOrEmpty
                $PD.UploadJobs[0].jobId | Should -Not -BeNullOrEmpty
            }
    
            It 'gets a specific upload job by ID' {
                $TestUploadJobID = $PD.UploadJobs[0].jobId
                $TestParams = @{
                    'NamespaceID'  = $TestNamespace
                    'Network'      = 'STAGING'
                    'BulkUploadID' = $TestUploadJobID
                }
                $PD.UploadJob = Get-EdgeKVUpload @TestParams @CommonParams
                $PD.UploadJob.jobId | Should -Be $TestUploadJobID
            }
        }

        Context 'Export-EdgeKVData' {
            It 'exports all data successfully' {
                $TestParams = @{
                    'NamespaceID' = $TestNamespace
                    'Network'     = 'STAGING'
                    'MaxItems'    = 10
                    'OutputFile'  = "TestDrive:/export-all.csv"
                }
                Export-EdgeKVData @TestParams @CommonParams
            }
            It 'waits 30s to foil the rate control' {
                Start-Sleep -Seconds 30
            }
            It 'exports group data successfully' {
                $TestParams = @{
                    'NamespaceID' = $TestNamespace
                    'Network'     = 'STAGING'
                    'GroupID'     = $TestUploadGroup
                    'MaxItems'    = 10
                    'OutputFile'  = "TestDrive:/export-group.csv"
                }
                Export-EdgeKVData @TestParams @CommonParams
                "TestDrive:/export-group.csv" | Should -FileContentMatch $ImportItem1
                "TestDrive:/export-group.csv" | Should -FileContentMatch $ImportItem2
                "TestDrive:/export-group.csv" | Should -FileContentMatch $ImportItem3
                "TestDrive:/export-group.csv" | Should -FileContentMatch $ImportItem4
            }
        }

        AfterAll {
            Get-EdgeKVItem -GroupID $TestUploadGroup -Network STAGING -NamespaceID $TestNamespace @CommonParams | Remove-EdgeKVItem -GroupID $TestUploadGroup -Network STAGING -NamespaceID $TestNamespace @CommonParams
        }
    }
}
