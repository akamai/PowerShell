BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.EdgeKV Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeKV/Akamai.EdgeKV.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestGroupID = $env:PesterGroupID
        $TestNamespaceGroup1 = "group-one"
        $TestNamespaceGroup2 = "group-two"
        $TestNamespace = $env:PesterEKVNamespace
        $TestNamespaceObj = [PSCustomObject] @{
            name               = $TestNameSpace
            retentionInSeconds = 0
            groupId            = $TestGroupID
        }
        $TestNamespaceBody = $TestNamespaceObj | ConvertTo-Json
        $TestTokenName = 'akamaipowershell-testing'
        $Tomorrow = (Get-Date).AddDays(7)
        $TestTommorowsDate = Get-Date $Tomorrow -Format yyyy-MM-dd
        $TestNewItemID = 'pester'
        $TestNewItemContent = 'new'
        $TestNewItemObject = [PSCustomObject] @{
            'content' = 'new'
        }
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.EdgeKV"
        $PD = @{}
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 Access Tokens
    #------------------------------------------------

    Context 'New-EdgeKVAccessToken' {
        It 'creates a token' {
            $PD.Token = New-EdgeKVAccessToken -Name $TestTokenName -AllowOnStaging -Expiry $TestTommorowsDate -Namespace $TestNameSpace -Permissions r @CommonParams
            $PD.Token.name | Should -Be $TestTokenName
        }
    }

    Context 'Get-EdgeKVAccessToken, all' {
        It 'returns list of tokens' {
            $PD.Tokens = Get-EdgeKVAccessToken @CommonParams
            $PD.Tokens.count | Should -Not -Be 0
        }
    }

    Context 'Get-EdgeKVAccessToken, single' {
        It 'returns a single token' {
            $PD.Token = Get-EdgeKVAccessToken -TokenName $TestTokenName @CommonParams
            $PD.Token.name | Should -Be $TestTokenName
        }
    }
    
    Context 'Update-EdgeKVAccessToken' {
        It 'refreshes a token' {
            $PD.RefreshedToken = Update-EdgeKVAccessToken -TokenName $TestTokenName @CommonParams
            $PD.RefreshedToken.name | Should -Be $TestTokenName
        }
    }

    Context 'Remove-EdgeKVAccessToken' {
        It 'removes token successfully' {
            $PD.TokenRemoval = Remove-EdgeKVAccessToken -TokenName $TestTokenName @CommonParams
            $PD.TokenRemoval.name | Should -Be $TestTokenName
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
            $Initialize = Initialize-EdgeKV
            $Initialize.accountStatus | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #              Permission Groups
    #------------------------------------------------

    Context 'Get-EdgeKVGroup, all' {
        It 'lists groups' {
            $PD.Groups = Get-EdgeKVGroup @CommonParams
            $PD.Groups[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeKVGroup, single' {
        It 'returns the correct group' {
            $PD.Group = Get-EdgeKVGroup -GroupID $TestGroupID @CommonParams
            $PD.Group.groupId | Should -Be $TestGroupID
        }
    }

    #------------------------------------------------
    #                 Items
    #------------------------------------------------

    Context 'New-EdgeKVItem by parameter' {
        It 'creates successfully' {
            $PD.NewItemByParam = New-EdgeKVItem -ItemID $TestNewItemID -Value $TestNewItemContent -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestNamespaceGroup1 @CommonParams
            $PD.NewItemByParam | Should -Match 'Item was upserted in database'
        }
    }
    
    Context 'New-EdgeKVItem by pipeline' {
        It 'creates successfully' {
            $PD.NewItemByPipeline = $TestNewItemObject | New-EdgeKVItem -ItemID $TestNewItemID -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestNamespaceGroup2 @CommonParams
            $PD.NewItemByPipeline | Should -Match 'Item was upserted in database'
        }
    }

    Context 'Get-EdgeKVItem, all' {
        It 'returns list of items' {
            $PD.Items = Get-EdgeKVItem -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestNamespaceGroup1 @CommonParams
            $PD.Items.count | Should -Not -Be 0
        }
    }

    Context 'Get-EdgeKVItem, single' {
        It 'returns item data' {
            $PD.Item = Get-EdgeKVItem -ItemID $TestNewItemID -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestNamespaceGroup1 @CommonParams
            $PD.Item | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeKVNamespaceGroup' {
        It 'returns a list of groups' {
            $PD.NamespaceGroups = Get-EdgeKVNamespaceGroup -Network STAGING -NamespaceID $TestNamespace @CommonParams
            $TestNamespaceGroup1 | Should -BeIn $PD.NamespaceGroups
            $TestNamespaceGroup2 | Should -BeIn $PD.NamespaceGroups
        }
    }

    Context 'Remove-EdgeKVItem' {
        It 'removes successfully' {
            $TestParams = @{
                ItemID      = $TestNewItemID
                Network     = 'STAGING'
                NamespaceID = $TestNamespace
            }
            $PD.RemovalOne = Remove-EdgeKVItem -GroupID $TestNamespaceGroup1 @TestParams @CommonParams
            $PD.RemovalTwo = Remove-EdgeKVItem -GroupID $TestNamespaceGroup2 @TestParams @CommonParams
            $PD.RemovalOne | Should -Match 'Item was marked for deletion from database'
            $PD.RemovalTwo | Should -Match 'Item was marked for deletion from database'
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
            $SetNamespaceAccess = Set-EdgeKVDefaultAccessPolicy -AllowNamespacePolicyOverride -RestrictDataAccess
            $SetNamespaceAccess.dataAccessPolicy.allowNamespacePolicyOverride | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Move-EdgeKVNamespace' {
        It 'moves a namespace' {
            $PD.MoveNamespace = Move-EdgeKVNamespace -NamespaceID $TestNamespace -GroupID $TestGroupID @CommonParams
            $PD.MoveNamespace.groupId | Should -Be $TestGroupID
        }
    }

    Context 'New-EdgeKVNamespace' {
        It 'creates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeKV -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeKVNamespace.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                Network            = 'PRODUCTION'
                GeoLocation        = 'US'
                Name               = 'MyNamespace'
                RetentionInSeconds = 123
                RestrictDataAccess = $false
                GroupID            = 12345
            }
            $SafeNamespace = New-EdgeKVNamespace @TestParams
            $SafeNamespace.namespace | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeKVNamespace, all' {
        It 'returns list of namespaces' {
            $PD.Namespaces = Get-EdgeKVNamespace -Network STAGING @CommonParams
            $PD.Namespaces[0].namespace | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeKVNamespace, single' {
        It 'returns namespace' {
            $PD.Namespace = Get-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace @CommonParams
            $PD.Namespace.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Set-EdgeKVNamespace with attributes' {
        It 'updates a namespace' {
            $PD.SetNamespaceByAttr = Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace -Name $TestNameSpace -RetentionInSeconds 0 -GroupID $TestGroupID @CommonParams
            $PD.SetNamespaceByAttr.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Set-EdgeKVNamespace with pipeline' {
        It 'updates a namespace' {
            $PD.SetNamespaceByObj = $TestNamespaceObj | Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace @CommonParams
            $PD.SetNamespaceByObj.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Set-EdgeKVNamespace with body' {
        It 'updates a namespace' {
            $PD.SetNamespaceByBody = Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace -Body $TestNamespaceBody @CommonParams
            $PD.SetNamespaceByBody.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Remove-EdgeKVNamespace' {
        It 'creates a deletion request' {
            $PD.RemoveNamespace = $PD.Namespace | Remove-EdgeKVNamespace -Network STAGING @CommonParams
            # Wait a bit for deletion request to create
            Write-Host "Wating 1m for deletion request to create"
            Start-Sleep -s 60
            $PD.RemoveNamespace.scheduledDeleteTime | Should -BeOfType 'DateTime'
        }
    }
    
    Context 'Get-EdgeKVNamespaceDelete' {
        It 'retrieves a deletion request' {
            $PD.GetNamespaceDelete = Get-EdgeKVNamespaceDelete -Network STAGING -NamespaceID $PD.Namespace.namespace @CommonParams
            $PD.GetNamespaceDelete.scheduledDeleteTime | Should -BeOfType 'DateTime'
        }
    }
    
    Context 'Set-EdgeKVNamespaceDelete' {
        It 'updates a deletion request' {
            $UpdatedDeleteTime = $PD.GetNamespaceDelete.scheduledDeleteTime.AddDays(-1)
            $PD.SetNamespaceDelete = $UpdatedDeleteTime | Set-EdgeKVNamespaceDelete -Network STAGING -NamespaceID $PD.Namespace.namespace @CommonParams
            $PD.SetNamespaceDelete.scheduledDeleteTime.Year | Should -Be $UpdatedDeleteTime.Year
            $PD.SetNamespaceDelete.scheduledDeleteTime.Month | Should -Be $UpdatedDeleteTime.Month
            $PD.SetNamespaceDelete.scheduledDeleteTime.Day | Should -Be $UpdatedDeleteTime.Day
            $PD.SetNamespaceDelete.scheduledDeleteTime.Hour | Should -Be $UpdatedDeleteTime.Hour
            $PD.SetNamespaceDelete.scheduledDeleteTime.Minute | Should -Be $UpdatedDeleteTime.Minute
        }
    }
    
    Context 'Restore-EdgeKVNamespace' {
        It 'removes a deletion request' {
            Restore-EdgeKVNamespace -Network STAGING -NamespaceID $PD.Namespace.namespace @CommonParams
            Write-Host "Waiting 1m for deletion request to delete"
            Start-Sleep -Seconds 60
            { Get-EdgeKVNamespaceDelete -Network STAGING -NamespaceID $PD.Namespace.namespace @CommonParams } | Should -Throw
        }
    }
}
