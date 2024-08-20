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
        $PD = @{}
    }

    AfterAll {
        
    }

    Context 'New-EdgeKVAccessToken' {
        It 'returns list of tokens' {
            $PD.Token = New-EdgeKVAccessToken -Name $TestTokenName -AllowOnStaging -Expiry $TestTommorowsDate -Namespace $TestNameSpace -Permissions r @CommonParams
            $PD.Token.name | Should -Be $TestTokenName
        }
    }

    Context 'Get-EdgeKVGroup, all' {
        It 'returns the correct data' {
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

    Context 'Get-EdgeKVInitializationStatus' {
        It 'returns status' {
            $PD.Status = Get-EdgeKVInitializationStatus @CommonParams
            $PD.Status.accountStatus | Should -Be "INITIALIZED"
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
        It 'returns namespace' {
            $PD.SetNamespaceByAttr = Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace -Name $TestNameSpace -RetentionInSeconds 0 -GroupID $TestGroupID @CommonParams
            $PD.SetNamespaceByAttr.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Set-EdgeKVNamespace with pipeline' {
        It 'returns namespace' {
            $PD.SetNamespaceByObj = $TestNamespaceObj | Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace @CommonParams
            $PD.SetNamespaceByObj.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Set-EdgeKVNamespace with body' {
        It 'returns namespace' {
            $PD.SetNamespaceByBody = Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace -Body $TestNamespaceBody @CommonParams
            $PD.SetNamespaceByBody.namespace | Should -Be $TestNamespace
        }
    }

    Context 'Move-EdgeKVNamespace' {
        It 'returns the correct group' {
            $PD.MoveNamespace = Move-EdgeKVNamespace -NamespaceID $TestNamespace -GroupID $TestGroupID @CommonParams
            $PD.MoveNamespace.groupId | Should -Be $TestGroupID
        }
    }

    Context 'Get-EdgeKVAccessToken, all' {
        It 'returns list of tokens' {
            $PD.Tokens = Get-EdgeKVAccessToken @CommonParams
            $PD.Tokens.count | Should -Not -Be 0
        }
    }

    Context 'Get-EdgeKVAccessToken, single' {
        It 'returns list of tokens' {
            $PD.Token = Get-EdgeKVAccessToken -TokenName $TestTokenName @CommonParams
            $PD.Token.name | Should -Be $TestTokenName
        }
    }

    Context 'New-EdgeKVItem by parameter' {
        It 'creates successfully' {
            $PD.NewItemByParam = New-EdgeKVItem -ItemID $TestNewItemID -Value $TestNewItemContent -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID @CommonParams
            $PD.NewItemByParam | Should -Match 'Item was upserted in database'
        }
    }
    
    Context 'New-EdgeKVItem by pipeline' {
        It 'creates successfully' {
            $PD.NewItemByPipeline = $TestNewItemObject | New-EdgeKVItem -ItemID $TestNewItemID -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID @CommonParams
            $PD.NewItemByPipeline | Should -Match 'Item was upserted in database'
        }
    }

    Context 'Get-EdgeKVItem, all' {
        It 'returns list of items' {
            $PD.Items = Get-EdgeKVItem -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID @CommonParams
            $PD.Items.count | Should -Not -Be 0
        }
    }

    Context 'Get-EdgeKVItem, single' {
        It 'returns item data' {
            $PD.Item = Get-EdgeKVItem -ItemID $TestNewItemID -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID @CommonParams
            $PD.Item | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-EdgeKVAccessToken' {
        It 'removes token successfully' {
            $PD.TokenRemoval = Remove-EdgeKVAccessToken -TokenName $TestTokenName @CommonParams
            $PD.TokenRemoval.name | Should -Be $TestTokenName
        }
    }

    Context 'Remove-EdgeKVItem' {
        It 'creates successfully' {
            $PD.Removal = Remove-EdgeKVItem -ItemID $TestNewItemID -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID @CommonParams
            $PD.Removal | Should -Match 'Item was marked for deletion from database'
        }
    }
}

Describe 'Unsafe Akamai.EdgeKV Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeKV/Akamai.EdgeKV.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.EdgeKV"
        $PD = @{}
        
    }
    Context 'Initialize-EdgeKV' {
        It 'does not throw' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeKV -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Initialize-EdgeKV.json"
                return $Response | ConvertFrom-Json
            }
            $Initialize = Initialize-EdgeKV
            $Initialize.accountStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeKVNamespace' {
        It 'creates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeKV -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeKVNamespace.json"
                return $Response | ConvertFrom-Json
            }
            $SafeNamespace = New-EdgeKVNamespace -Network PRODUCTION -GeoLocation US -Name MyNamespace -RetentionInSeconds 0
            $SafeNamespace.namespace | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-EdgeKVDefaultAccessPolicy' {
        It 'updates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeKV -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-EdgeKVDefaultAccessPolicy.json"
                return $Response | ConvertFrom-Json
            }
            $SetNamespaceAccess = Set-EdgeKVDefaultAccessPolicy -AllowNamespacePolicyOverride -RestrictDataAccess
            $SetNamespaceAccess.dataAccessPolicy.allowNamespacePolicyOverride | Should -Not -BeNullOrEmpty
        }
    }
    
}

