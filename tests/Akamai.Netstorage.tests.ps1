Describe 'Safe Akamai.Netstorage Config Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Netstorage/Akamai.Netstorage.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestStorageGroupID = $env:PesterStorageGroupID
        $TestUploadAccountID = 'akamaipowershell'
        $TestFTPKey = 'abcdefg1234'
        $TestRSyncKey = 'abcdefg1234'
        $TestSSHKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQaxsF1OBwZbN/6G2D3P/QritNfPYizc4gJyry3SBQT6lfHojQbjOTG2+3j5/Gx5ve5o05h3+TzECihXHUj2jbc19HzdBs+jPafcJj+w9LAupcKi/WkDG/3GQDrp1zXMnPg/n+QrxeaqZpAawN6bDLpnAnfrmseb1GxL9cKwzNYR9A4uVm5JQaHD0iNGni09SNPdpmJrYLw9aw/AQaMtA35w7eIK+5h15wobW7+A00jVpqBfAfUJByzFueI+uj9ZVJKWN+MOUg6QqppVOjqYKRoWl3rcXOGPBmAvrk5YwseRX3f231ItIY7NsCaWLYpVVcISFICQjTZIUr3GfNf5D9 pester@akamai.com'
        $TestCPCodeID = $env:PesterNSCpCode
        $TestRuleSetID = $env:PesterRuleSetID
        $TestSnapshot = @"
{
    "snapshotId": $env:PesterSnapshotID,
    "snapshotName": "akamaipowershell",
    "cpcodeId": $env:PesterNSCpCode,
    "baseDirectory": "/$env:PesterNSCpCode/snap",
    "dayOfMonth": "*",
    "month": "*",
    "dayOfWeek": "*",
    "executeNow": false,
    "scheduled": false,
    "command": "sst 'http://$env:PesterHostname'",
    "commandConfig": {
        "urls": [
        "http://$env:PesterHostname"
        ]
    },
    "wizard": true,
    "status": "Processing"
}
"@
        $TestOutputDirectory = 'nsconfig-tests'
        $TestDomainName = 'akamaipowershell-nsu.akamaihd.net'
        $TestAuthSection = 'new-section'
        $PD = @{}
    }

    #------------------------------------------------
    #                 NetstorageGroup                  
    #------------------------------------------------

    Context 'Get-NetstorageGroup - Parameter Set all' {
        It 'returns the correct data' {
            $PD.GetNetstorageGroupAll = Get-NetstorageGroup @CommonParams
            $PD.GetNetstorageGroupAll[0].storageGroupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageGroup - Parameter Set single' {
        It 'returns the correct data' {
            $PD.GetNetstorageGroupSingle = Get-NetstorageGroup -StorageGroupID $TestStorageGroupID @CommonParams
            $PD.GetNetstorageGroupSingle.storageGroupId | Should -Be $TestStorageGroupID
        }
    }

    #------------------------------------------------
    #                 NetstorageUploadAccount                  
    #------------------------------------------------

    Context 'Get-NetstorageUploadAccount (all)' {
        It 'returns the correct data' {
            $PD.GetNetstorageUploadAccountAll = Get-NetstorageUploadAccount @CommonParams
            $PD.GetNetstorageUploadAccountAll[0].uploadAccountId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-NetstorageUploadAccount (single)' {
        It 'returns the correct data' {
            $PD.GetNetstorageUploadAccountSingle = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.GetNetstorageUploadAccountSingle.uploadAccountId | Should -Be $TestUploadAccountID
        }
    }

    Context 'Set-NetstorageUploadAccount by parameter' {
        It 'returns the correct data' {
            $PD.SetNetstorageUploadAccountByParam = Set-NetstorageUploadAccount -Body $PD.GetNetstorageUploadAccountSingle -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.SetNetstorageUploadAccountByParam.uploadAccountId | Should -Be $TestUploadAccountID
        }
    }

    Context 'Set-NetstorageUploadAccount by pipeline' {
        It 'returns the correct data' {
            $PD.SetNetstorageUploadAccountByPipeline = ($PD.GetNetstorageUploadAccountSingle | Set-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams)
            $PD.SetNetstorageUploadAccountByPipeline.uploadAccountId | Should -Be $TestUploadAccountID
        }
    }

    Context 'Disable-NetstorageUploadAccount' {
        It 'throws no errors' {
            Disable-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams 
        }
    }

    Context 'Enable-NetstorageUploadAccount' {
        It 'throws no errors' {
            Enable-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams 
        }
    }

    #------------------------------------------------
    #          NetstorageUploadAccountFTPKey
    #------------------------------------------------
    
    Context 'Add-NetstorageUploadAccountFTPKey' {
        It 'returns the correct data' {
            Add-NetstorageUploadAccountFTPKey -Key $TestFTPKey -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.UploadAccount.keys.ftp[0].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Disable-NetstorageUploadAccountFTPKey' {
        It 'throws no errors' {
            Disable-NetstorageUploadAccountFTPKey -Identity $PD.UploadAccount.keys.ftp[0].id -UploadAccountID $TestUploadAccountID @CommonParams 
        }
    }
    
    Context 'Enable-NetstorageUploadAccountFTPKey' {
        It 'throws no errors' {
            Enable-NetstorageUploadAccountFTPKey -Identity $PD.UploadAccount.keys.ftp[0].id -UploadAccountID $TestUploadAccountID @CommonParams 
        }
    }
    
    Context 'Update-NetstorageUploadAccountFTPKey' {
        It 'returns the correct data' {
            $PD.UpdateNetstorageUploadAccountFTPKey = Update-NetstorageUploadAccountFTPKey -Identity $PD.UploadAccount.keys.ftp[0].id -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.UpdateNetstorageUploadAccountFTPKey.message | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-NetstorageUploadAccountFTPKey' {
        It 'throws no errors' {
            Set-NetstorageUploadAccountFTPKey -Identity $PD.UploadAccount.keys.ftp[0].id -UploadAccountID $TestUploadAccountID -Key $TestFTPKey -Comments 'Updating' @CommonParams 
        }
    }
    
    Context 'Remove-NetstorageUploadAccountFTPKey' {
        It 'throws no errors' {
            # Re-retrieve upload account as key ID changes when updated. Obviously...
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.UploadAccount.Keys.FTP | ForEach-Object {
                Remove-NetstorageUploadAccountFTPKey -Identity $_.id -UploadAccountID $TestUploadAccountID @CommonParams
            }
        }
    }

    #------------------------------------------------
    #        NetstorageUploadAccountRSyncKey
    #------------------------------------------------

    Context 'Add-NetstorageUploadAccountRSyncKey' {
        It 'returns the correct data' {
            Add-NetstorageUploadAccountRSyncKey -Key $TestRsyncKey -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.UploadAccount.keys.rsync[0].id | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Disable-NetstorageUploadAccountRSyncKey' {
        It 'throws no errors' {
            Disable-NetstorageUploadAccountRSyncKey -Identity $PD.UploadAccount.keys.rsync[0].id -UploadAccountID $TestUploadAccountID @CommonParams 
        }
    }
    
    Context 'Enable-NetstorageUploadAccountRSyncKey' {
        It 'throws no errors' {
            Enable-NetstorageUploadAccountRSyncKey -Identity $PD.UploadAccount.keys.rsync[0].id -UploadAccountID $TestUploadAccountID @CommonParams 
        }
    }
    
    Context 'Remove-NetstorageUploadAccountRSyncKey, single' {
        It 'throws no errors' {
            Remove-NetstorageUploadAccountRSyncKey -UploadAccountID $TestUploadAccountID -Identity $PD.UploadAccount.keys.rsync[0].id @CommonParams 
        }
    }

    #------------------------------------------------
    #                 NetstorageUploadAccountSSHKey                  
    #------------------------------------------------

    Context 'Add-NetstorageUploadAccountSSHKey' {
        It 'returns the correct data' {
            Add-NetstorageUploadAccountSSHKey -Key $TestSSHKey -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.UploadAccount.keys.ssh[0].id | Should -Not -BeNullOrEmpty
        }

    }

    Context 'Disable-NetstorageUploadAccountSSHKey' {
        It 'throws no errors' {
            Disable-NetstorageUploadAccountSSHKey -Identity $PD.UploadAccount.keys.ssh[0].id -UploadAccountID $TestUploadAccountID @CommonParams 
        }
    }
    
    Context 'Enable-NetstorageUploadAccountSSHKey' {
        It 'throws no errors' {
            Enable-NetstorageUploadAccountSSHKey -Identity $PD.UploadAccount.keys.ssh[0].id -UploadAccountID $TestUploadAccountID @CommonParams  
        }
    }
    
    Context 'Remove-NetstorageUploadAccountSSHKey' {
        It 'throws no errors' {
            Remove-NetstorageUploadAccountSSHKey -Identity $PD.UploadAccount.keys.ssh[0].id -UploadAccountID $TestUploadAccountID @CommonParams 
        }
    }

    #------------------------------------------------
    #                 NetstorageCPCode                  
    #------------------------------------------------

    Context 'Get-NetstorageCPCode' {
        It 'returns the correct data' {
            $PD.GetNetstorageCPCode = Get-NetstorageCPCode @CommonParams
            $PD.GetNetstorageCPCode[0].cpcodeId | Should -Not -BeNullOrEmpty
        }
    }

    # #------------------------------------------------
    # #                 NetstorageCPCodePurgeRoutine                  
    # #------------------------------------------------

    Context 'Get-NetstorageCPCodePurgeRoutine' {
        It 'returns the correct data' {
            $PD.GetNetstorageCPCodePurgeRoutine = Get-NetstorageCPCodePurgeRoutine -CPCodeID $TestCPCodeID @CommonParams
            $PD.GetNetstorageCPCodePurgeRoutine[0].ageDeletionDirectory | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageCPCodePurgeRoutine by parameter' {
        It 'throws no errors' {
            Set-NetstorageCPCodePurgeRoutine -Body $PD.GetNetstorageCPCodePurgeRoutine -CPCodeID $TestCPCodeID @CommonParams 
        }
    }

    Context 'Set-NetstorageCPCodePurgeRoutine by pipeline' {
        It 'throws no errors' {
            $PD.GetNetstorageCPCodePurgeRoutine | Set-NetstorageCPCodePurgeRoutine -CPCodeID $TestCPCodeID @CommonParams 
        }
    }

    #------------------------------------------------
    #                 NetstorageSnapshot
    #------------------------------------------------

    Context 'New-NetstorageSnapshot by parameter' {
        It 'returns the correct data' {
            $PD.NewNetstorageSnapshotByParam = New-NetstorageSnapshot -Body $TestSnapshot @CommonParams
            $PD.NewNetstorageSnapshotByParam.snapshotId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-NetstorageSnapshot by pipeline' {
        It 'returns the correct data' {
            $PD.NewNetstorageSnapshotByPipeline = ($TestSnapshot | New-NetstorageSnapshot @CommonParams)
            $PD.NewNetstorageSnapshotByPipeline.snapshotId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageSnapshot, all' {
        It 'returns the correct data' {
            $PD.GetNetstorageSnapshotAll = Get-NetstorageSnapshot @CommonParams
            $PD.GetNetstorageSnapshotAll[0].snapshotId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-NetstorageSnapshot, single' {
        It 'returns the correct data' {
            $PD.GetNetstorageSnapshotSingle = Get-NetstorageSnapshot -SnapShotID $PD.NewNetstorageSnapshotByParam.snapshotId @CommonParams
            $PD.GetNetstorageSnapshotSingle.snapshotId | Should -Be $PD.NewNetstorageSnapshotByParam.snapshotId
        }
    }

    Context 'Set-NetstorageSnapshot by parameter' {
        It 'returns the correct data' {
            $PD.SetNetstorageSnapshotByParam = Set-NetstorageSnapshot -Body $PD.NewNetstorageSnapshotByParam -SnapShotID $PD.NewNetstorageSnapshotByParam.snapshotId @CommonParams
            $PD.SetNetstorageSnapshotByParam.snapshotId | Should -Be $PD.NewNetstorageSnapshotByParam.snapshotId
        }
    }

    Context 'Set-NetstorageSnapshot by pipeline' {
        It 'returns the correct data' {
            $PD.SetNetstorageSnapshotByPipeline = ($PD.NewNetstorageSnapshotByParam | Set-NetstorageSnapshot -SnapShotID $PD.NewNetstorageSnapshotByParam.snapshotId @CommonParams)
            $PD.SetNetstorageSnapshotByPipeline.snapshotId | Should -Be $PD.NewNetstorageSnapshotByParam.snapshotId
        }
    }

    Context 'Remove-NetstorageSnapshot' {
        It 'throws no errors' {
            Remove-NetstorageSnapshot -SnapShotID $PD.NewNetstorageSnapshotByParam.snapshotId @CommonParams 
            Remove-NetstorageSnapshot -SnapShotID $PD.NewNetstorageSnapshotByPipeline.snapshotId @CommonParams 
        }
    }

    #------------------------------------------------
    #                 NetstorageZones
    #------------------------------------------------

    Context 'Get-NetstorageZones' {
        It 'returns the correct data' {
            $PD.GetNetstorageZones = Get-NetstorageZones @CommonParams
            $PD.GetNetstorageZones[0] | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 NetstorageAuth
    #------------------------------------------------

    Context 'New-NetstorageAuth create new auth file' {
        It 'should create new file called .nsrc at root' {
            $PD.NewNetstorageAuth = New-NetstorageAuth -UploadAccountID $TestUploadAccountID -OutputDirectory $TestOutputDirectory -AuthSection $PD.Section @CommonParams
            $TestNewNSAuthKey = $($PD.GetNetstorageUploadAccountSingle.keys.g2o.key)
            $PD.File = "$TestOutputDirectory/.nsrc"
            $PD.File | Should -Exist
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "\[$Section\]"
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "key=$TestNewNSAuthKey" 
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "id=$TestUploadAccountID" 
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "group=$TestStorageGroupID" 
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "host=$TestDomainName"
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "cpcode=$TestCPCodeID"
        }
    }

    Context 'New-NetStorageAuth append auth file with existing default section' {
        It 'should fail because a default section already exists' {
            New-NetstorageAuth -UploadAccountID $TestUploadAccountID -OutputDirectory $TestOutputDirectory @CommonParams
        }
    }

    Context 'New-NetstorageAuth create new auth section on existing .nsrc' {
        It 'should create new section on existing .nsrc' {
            $PD.NewNetstorageAuth2 = New-NetstorageAuth -UploadAccountID $TestUploadAccountID -OutputDirectory $TestOutputDirectory @CommonParams -AuthSection $TestAuthSection
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatchMultiline "\n\[$TestAuthSection\]"
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "key=$TestNewNSAuthKey" 
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "id=$TestUploadAccountID" 
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "group=$TestStorageGroupID" 
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "host=$TestDomainName"
            "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "cpcode=$TestCPCodeID"
        }
    }

    AfterAll {
        Remove-Item -Path "$TestOutputDirectory" -Recurse -Force
    }
}

Describe 'Unsafe Akamai.Netstorage Config Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Netstorage/Akamai.Netstorage.psd1 -Force
        
        $TestGroupJSON = @"
{"contractId":"1-2AB34D","storageGroupId":123456,"storageGroupName":"akamaipowershell","storageGroupType":"OBJECTSTORE","storageGroupPurpose":"NETSTORAGE","domainPrefix":"akamaipowershell","asperaEnabled":false,"pciEnabled":false,"estimatedUsageGB":0.01,"allowEdit":true,"provisionStatus":"PROVISIONED","cpcodes":[{"cpcodeId":234567,"downloadSecurity":"ALL_EDGE_SERVERS","useSsl":false,"serveFromZip":false,"sendHash":false,"quickDelete":true,"numberOfFiles":2,"numberOfBytes":10,"lastChangesPropagated":true,"requestUriCaseConversion":"NO_CONVERSION","queryStringConversion":{"queryStringConversionMode":"STRIP_ALL_INCOMING_QUERY"},"pathCheckAndConversion":"DO_NOT_CHECK_PATHS","encodingConfig":{"enforceEncoding":false,"encoding":"ISO_8859_1"},"dirListing":{"maxListSize":0,"searchOn404":"DO_NOT_SEARCH"},"ageDeletions":[{"ageDeletionDirectory":"/234567/purge","ageDeletionDays":10.0,"ageDeletionSizeBytes":10000000000.0,"ageDeletionRecursivePurge":false}]}],"zones":[{"zoneName":"europe","noCapacityAction":"SPILL_OUTSIDE","allowUpload":"YES","allowDownload":"YES","lastModifiedBy":"okenobi","lastModifiedDate":"2022-07-15T10:43:33Z"},{"zoneName":"global","noCapacityAction":"SPILL_OUTSIDE","allowUpload":"YES","allowDownload":"YES","lastModifiedBy":"okenobi","lastModifiedDate":"2022-07-15T10:43:33Z"}]}
"@
        $TestGroup = ConvertFrom-Json -InputObject $TestGroupJSON
        $TestUploadAccountJSON = @"
{"uploadAccountId":"akamaipowershell","storageGroupId":123456,"storageGroupName":"akamaipowershell","storageGroupType":"OBJECTSTORE","uploadAccountStatus":"ACTIVE","isEditable":true,"isVisible":true,"ftpEnabled":false,"sshEnabled":true,"rsyncEnabled":false,"asperaEnabled":false,"eventSubEnabled":false,"hasFileManagerAccess":false,"hasHttpApiAccess":true,"hasPendingPropagation":true,"email":"akamaipowershell@example.com","keys":{"ssh":[],"g2o":[]},"accessConfig":{"hasReadOnlyAccess":false,"cpcodes":[{"cpcodeId":234567,"storageGroup":{"storageGroupId":123456,"storageGroupName":"akamaipowershell"}}]},"technicalContactInfo":{"newTechnicalContact":{"firstName":"Obi-Wan","lastName":"Kenobi","email":"okenobi@akamai.com","phone":{"countryCode":"+44","areaCode":"203","number":"7879408"}}},"enableZipFileAutoIndex":false}
"@
        $TestUploadAccount = ConvertFrom-Json -InputObject $TestUploadAccountJSON
        $TestRuleSet = @"
{
    "name": "akamaipowershell",
    "description": "Testing the powershell module",
    "contractId": "1-2AB34C",
    "allowRest": true,
    "uploadAccounts": []
}
"@
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Netstorage"
        $PD = @{}
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 NetstorageGroup                  
    #------------------------------------------------

    Context 'New-NetstorageGroup by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageGroup.json"
                return $Response | ConvertFrom-Json
            }
            $PD.NewNetstorageGroupByParam = New-NetstorageGroup -Body $TestGroupJSON
            $PD.NewNetstorageGroupByParam.storageGroupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-NetstorageGroup by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageGroup.json"
                return $Response | ConvertFrom-Json
            }
            $NewNetstorageGroupByPipeline = ($TestGroup | New-NetstorageGroup)
            $NewNetstorageGroupByPipeline.storageGroupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageGroup by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-NetstorageGroup.json"
                return $Response | ConvertFrom-Json
            }
            $SetNetstorageGroupByParam = Set-NetstorageGroup -Body $PD.NewNetstorageGroupByParam -StorageGroupID 123456
            $SetNetstorageGroupByParam.storageGroupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageGroup by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-NetstorageGroup.json"
                return $Response | ConvertFrom-Json
            }
            $SetNetstorageGroupByPipeline = ($PD.NewNetstorageGroupByParam | Set-NetstorageGroup -StorageGroupID 123456)
            $SetNetstorageGroupByPipeline.storageGroupId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 NetstorageUploadAccount                  
    #------------------------------------------------

    Context 'New-NetstorageUploadAccount by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageUploadAccount.json"
                return $Response | ConvertFrom-Json
            }
            $NewNetstorageUploadAccountByParam = New-NetstorageUploadAccount -Body $TestUploadAccountJSON
            $NewNetstorageUploadAccountByParam.uploadAccountId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-NetstorageUploadAccount by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageUploadAccount.json"
                return $Response | ConvertFrom-Json
            }
            $NewNetstorageUploadAccountByPipeline = ($TestUploadAccount | New-NetstorageUploadAccount)
            $NewNetstorageUploadAccountByPipeline.uploadAccountId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 NetstorageCPCode                  
    #------------------------------------------------

    Context 'New-NetstorageCPCode' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageCPCode.json"
                return $Response | ConvertFrom-Json
            }
            $NewNetstorageCPCode = New-NetstorageCPCode -CPCodeName testcpcode -ContractID 1-2AB34C
            $NewNetstorageCPCode.cpcodeName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 NetstorageSnapshot                  
    #------------------------------------------------

    Context 'Start-NetstorageSnapshot' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Start-NetstorageSnapshot.json"
                return $Response | ConvertFrom-Json
            }
            $StartNetstorageSnapshot = Start-NetstorageSnapshot -SnapShotID 123456 -SnapshotName testname
            $StartNetstorageSnapshot.snapshotId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 NetstorageRuleSet                  
    #------------------------------------------------

    Context 'New-NetstorageRuleSet by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
            $PD.NewNetstorageRuleSetByParam = New-NetstorageRuleSet -Body $TestRuleSet
            $PD.NewNetstorageRuleSetByParam.ruleSetId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-NetstorageRuleSet by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
            $NewNetstorageRuleSetByPipeline = ($TestRuleSet | New-NetstorageRuleSet)
            $NewNetstorageRuleSetByPipeline.ruleSetId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageRuleSet, all' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetstorageRuleSet_1.json"
                return $Response | ConvertFrom-Json
            }
            $GetNetstorageRuleSetAll = Get-NetstorageRuleSet
            $GetNetstorageRuleSetAll[0].ruleSetId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-NetstorageRuleSet, single' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
            $GetNetstorageRuleSet = Get-NetstorageRuleSet -RuleSetID 123456
            $GetNetstorageRuleSet.ruleSetId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageRuleSet by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
            $SetNetstorageRuleSetByParam = Set-NetstorageRuleSet -Body $PD.NewNetstorageRuleSetByParam -RuleSetID 123456
            $SetNetstorageRuleSetByParam.ruleSetId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageRuleSet by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
            $SetNetstorageRuleSetByPipeline = ($PD.NewNetstorageRuleSetByParam | Set-NetstorageRuleSet -RuleSetID 123456)
            $SetNetstorageRuleSetByPipeline.ruleSetId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-NetstorageRuleSet' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
            Remove-NetstorageRuleSet -RuleSetID 123456 
        }
    }

    #------------------------------------------------
    #                 NetstorageCPCodePurgeRoutine                  
    #------------------------------------------------
    
    Context 'Remove-NetstorageCPCodePurgeRoutine' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-NetstorageCPCodePurgeRoutine.json"
                return $Response | ConvertFrom-Json
            }
            Remove-NetstorageCPCodePurgeRoutine -CPCodeID 123456 
        }
    }
}

Describe 'Safe Akamai.Netstorage Usage Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Netstorage/Akamai.Netstorage.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            AuthFile = $env:PesterAuthFile
        }
        $TestDirectory = "ns-usage-temp"
        $TestNewDirName = "temp"
        $TestNewFileName = "temp.txt"
        $TestNewFileContent = "new"
        $TestSymlinkFileName = "symlink.txt"
        $TestRenamedFileName = "renamed.txt"
        $PD = @{}
    }

    AfterAll {
        if ((Test-Path $TestNewFileName)) {
            Remove-Item $TestNewFileName -Force
        }
    }

    Context 'New-NetstorageDirectory' {
        It 'creates successfully' {
            $PD.NewDir = New-NetstorageDirectory -Path "/$TestDirectory/$TestNewDirName" @CommonParams
            $PD.NewDir | Should -Match 'successful'
        }
    }

    Context 'Write-NetstorageObject' {
        It 'throws no errors' {
            $TestNewFileContent | Set-Content $TestNewFileName
            Write-NetstorageObject -LocalPath $TestNewFileName -RemotePath "/$TestDirectory/$TestNewDirName/$TestNewFileName" @CommonParams 
            Write-NetstorageObject -LocalPath $TestNewFileName -RemotePath "/$TestDirectory/$TestNewFileName" @CommonParams 
        }
    }

    Context 'Get-NetstorageDirectory' {
        It 'lists content' {
            $PD.Dir = Get-NetstorageDirectory -Path $TestDirectory @CommonParams
            $PD.Dir[0].type | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageDirectory with recursion (ls)' {
        It 'lists content' {
            $PD.Dir = Get-NetstorageDirectory -Path $TestDirectory -Recurse @CommonParams
            ($PD.Dir | Where-Object type -eq file | Select-Object -First 1).size | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageDirectoryUsage' {
        It 'returns stats' {
            $PD.Usage = Get-NetstorageDirectoryUsage -Path $TestDirectory @CommonParams
            $PD.Usage.files | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Symlink-NetstorageObject' {
        It 'creates a symlink' {
            $PD.Symlink = New-NetstorageSymlink -Path "/$TestDirectory/$TestNewDirName/$TestSymlinkFileName" -Target "/$TestDirectory/$TestNewDirName/$TestNewFileName" @CommonParams
            $PD.Symlink | Should -Match 'successful'
        }
    }

    Context 'Read-NetstorageObject' {
        It 'downloads successfully' {
            Read-NetstorageObject -RemotePath "/$TestDirectory/$TestNewDirName/$TestNewFileName" -LocalPath $TestNewFileName @CommonParams 
            $PD.DownloadedContent = Get-Content $TestNewFileName
            $PD.DownloadedContent | Should -Be $TestNewFileContent
        }
    }

    Context 'Set-NetstorageObjectMTime' {
        It 'sets mtime' {
            $PD.MTime = Set-NetstorageObjectMTime -Path "/$TestDirectory/$TestNewDirName/$TestNewFileName" -mtime 0 @CommonParams
            $PD.MTime | Should -Match 'successful'
        }
    }

    Context 'Measure-NetstorageObject' {
        It 'gets object stats' {
            $PD.Stat = Measure-NetstorageObject -Path "/$TestDirectory/$TestNewDirName/$TestNewFileName" @CommonParams
            $PD.Stat.name | Should -Be $TestNewFileName
        }
    }

    Context 'Rename-NetstorageObject' {
        It 'renames a file' {
            $PD.Rename = Rename-NetstorageObject -Path "/$TestDirectory/$TestNewDirName/$TestNewFileName" -NewFilename $TestRenamedFileName @CommonParams
            $PD.Rename | Should -Match 'renamed'
        }
    }

    Context 'Remove-NetstorageObject' {
        It 'removes a file' {
            $PD.RemoveFile = Remove-NetstorageObject -Path "/$TestDirectory/$TestNewDirName/$TestSymlinkFileName" @CommonParams
            $PD.RemoveFile | Should -Match 'deleted'
        }
    }

    Context 'Remove-NetstorageDirectory' {
        It 'removes a dir' {
            $PD.RemoveDir = Remove-NetstorageDirectory -Path "/$TestDirectory/$TestNewDirName" -Force @CommonParams
            $PD.RemoveDir | Should -Match "quick-delete scheduled"
        }
    }
}
