BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.Netstorage Config Tests' {

    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'

        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.Netstorage'
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
        $TestStorageGroupID = $env:PesterStorageGroupID
        $TestUploadAccountID = 'pester'
        $TestUploadAccountIDNoHTTP = 'pester-ftp'
        $TestFTPKey = 'abcdefg1234'
        $TestFTPKey2 = 'abcdefg4321'
        $TestRSyncKey = 'abcdefg1234'
        $TestRSyncKey2 = 'abcdefg4321'
        $TestSSHKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQaxsF1OBwZbN/6G2D3P/QritNfPYizc4gJyry3SBQT6lfHojQbjOTG2+3j5/Gx5ve5o05h3+TzECihXHUj2jbc19HzdBs+jPafcJj+w9LAupcKi/WkDG/3GQDrp1zXMnPg/n+QrxeaqZpAawN6bDLpnAnfrmseb1GxL9cKwzNYR9A4uVm5JQaHD0iNGni09SNPdpmJrYLw9aw/AQaMtA35w7eIK+5h15wobW7+A00jVpqBfAfUJByzFueI+uj9ZVJKWN+MOUg6QqppVOjqYKRoWl3rcXOGPBmAvrk5YwseRX3f231ItIY7NsCaWLYpVVcISFICQjTZIUr3GfNf5D9$Timestamp pester@akamai.com"
        $TestSSHKey2 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGgKXj705ecYc1EGtm+PmqwshkAbSTuWFVgpiSzoog9w1bEF1BKxOtDfdnLlIZuPR9L28rEk2GFULQRSbes9tq88XjQp+4yky8kWqVdMOyUzqB3F7zZU6c+ENinlvK3qyeYlGJ2oDYKT831BiCJU2Dk1xgXey/g+XzbfUNpV+J0QaI56985eSWKuABp30re57jX5EWk0Vvbb0nK7m0PWupA/+Q/yST9HTmCWM/3zBkI+uhevJeQKOEhZpm5N9mKbIFShlpL/qKHd9pLnso/jgcy4zpV2rqhbH+4xh87k0lw6dlSwpM9lastPVoMeAJ0QLvd5GVolJE/LlA7GOldUmF powershell@akamai.com'
        $TestCPCodeID = $env:PesterNSCpCode
        $TestRuleSetID = $env:PesterRuleSetID
        $TestSnapshot = @"
{
    "snapshotName": "pester-$Timestamp",
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
        $TestDomainName = 'pester-nsu.akamaihd.net'
        $TestAuthSection = 'new-section'
        $TestGroupJSON = @"
{"contractId":"1-2AB34D","storageGroupId":123456,"storageGroupName":"pester","storageGroupType":"OBJECTSTORE","storageGroupPurpose":"NETSTORAGE","domainPrefix":"pester","asperaEnabled":false,"pciEnabled":false,"estimatedUsageGB":0.01,"allowEdit":true,"provisionStatus":"PROVISIONED","cpcodes":[{"cpcodeId":234567,"downloadSecurity":"ALL_EDGE_SERVERS","useSsl":false,"serveFromZip":false,"sendHash":false,"quickDelete":true,"numberOfFiles":2,"numberOfBytes":10,"lastChangesPropagated":true,"requestUriCaseConversion":"NO_CONVERSION","queryStringConversion":{"queryStringConversionMode":"STRIP_ALL_INCOMING_QUERY"},"pathCheckAndConversion":"DO_NOT_CHECK_PATHS","encodingConfig":{"enforceEncoding":false,"encoding":"ISO_8859_1"},"dirListing":{"maxListSize":0,"searchOn404":"DO_NOT_SEARCH"},"ageDeletions":[{"ageDeletionDirectory":"/234567/purge","ageDeletionDays":10.0,"ageDeletionSizeBytes":10000000000.0,"ageDeletionRecursivePurge":false}]}],"zones":[{"zoneName":"europe","noCapacityAction":"SPILL_OUTSIDE","allowUpload":"YES","allowDownload":"YES","lastModifiedBy":"okenobi","lastModifiedDate":"2022-07-15T10:43:33Z"},{"zoneName":"global","noCapacityAction":"SPILL_OUTSIDE","allowUpload":"YES","allowDownload":"YES","lastModifiedBy":"okenobi","lastModifiedDate":"2022-07-15T10:43:33Z"}]}
"@
        $TestGroup = ConvertFrom-Json -InputObject $TestGroupJSON
        $TestUploadAccountJSON = @"
{"uploadAccountId":"pester","storageGroupId":123456,"storageGroupName":"pester","storageGroupType":"OBJECTSTORE","uploadAccountStatus":"ACTIVE","isEditable":true,"isVisible":true,"ftpEnabled":false,"sshEnabled":true,"rsyncEnabled":false,"asperaEnabled":false,"eventSubEnabled":false,"hasFileManagerAccess":false,"hasHttpApiAccess":true,"hasPendingPropagation":true,"email":"pester@example.com","keys":{"ssh":[],"g2o":[]},"accessConfig":{"hasReadOnlyAccess":false,"cpcodes":[{"cpcodeId":234567,"storageGroup":{"storageGroupId":123456,"storageGroupName":"pester"}}]},"technicalContactInfo":{"newTechnicalContact":{"firstName":"Obi-Wan","lastName":"Kenobi","email":"okenobi@akamai.com","phone":{"countryCode":"+44","areaCode":"203","number":"7879408"}}},"enableZipFileAutoIndex":false}
"@
        $TestUploadAccount = ConvertFrom-Json -InputObject $TestUploadAccountJSON
        $TestRuleSet = @"
{
    "name": "pester",
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
        # We keep the first http and ssh keys, remove the rest. Last SSH key cannot be removed, and we need the HTTP key for the usage tests
        $TestParams = @{
            'UploadAccountID' = $TestUploadAccountID
        }
        $UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
        $UploadAccount.keys | Where-Object ftp | Remove-NetstorageUploadAccountFTPKey -UploadAccountID $TestUploadAccountID @CommonParams
        $UploadAccount.keys | Where-Object rsync | Remove-NetstorageUploadAccountRSyncKey -UploadAccountID $TestUploadAccountID @CommonParams
        $UploadAccount.keys.g2o | Select-Object -Skip 1 | Remove-NetstorageUploadAccountHTTPKey -UploadAccountID $TestUploadAccountID @CommonParams
        $UploadAccount.keys.ssh | Select-Object -Skip 1 | Remove-NetstorageUploadAccountSSHKey -UploadAccountID $TestUploadAccountID @CommonParams

        Get-NetstorageSnapshot @CommonParams | Where-Object snapshotName -Like "pester-*" | Remove-NetstorageSnapshot @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 NetstorageGroup
    #------------------------------------------------

    Context 'Get-NetstorageGroup' {
        It 'gets a list' {
            $PD.StorageGroups = Get-NetstorageGroup @CommonParams
            $PD.StorageGroups[0].storageGroupId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific group by its ID' {
            $TestParams = @{
                'StorageGroupID' = $TestStorageGroupID
            }
            $PD.StorageGroup = Get-NetstorageGroup @TestParams @CommonParams
            $PD.StorageGroup.storageGroupId | Should -Be $TestStorageGroupID
        }
    }

    Context 'New-NetstorageGroup' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageGroup.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'creates by param' {
            $TestParams = @{
                'Body' = $TestGroupJSON
            }
            $PD.NewNetstorageGroupByParam = New-NetstorageGroup @TestParams
            $PD.NewNetstorageGroupByParam.storageGroupId | Should -Not -BeNullOrEmpty
        }
        It 'creates by pipeline' {
            $NewNetstorageGroupByPipeline = $TestGroup | New-NetstorageGroup
            $NewNetstorageGroupByPipeline.storageGroupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageGroup' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-NetstorageGroup.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'updates by param' {
            $TestParams = @{
                'Body'           = $PD.StorageGroup
                'StorageGroupID' = 123456
            }
            $SetNetstorageGroupByParam = Set-NetstorageGroup @TestParams
            $SetNetstorageGroupByParam.storageGroupId | Should -Not -BeNullOrEmpty
        }
        It 'updates by pipeline' {
            $SetNetstorageGroupByPipeline = $PD.StorageGroup | Set-NetstorageGroup
            $SetNetstorageGroupByPipeline.storageGroupId | Should -Not -BeNullOrEmpty
        }
    }

    # Context 'Remove-NetstorageGroup' {
    #     BeforeAll {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
    #             $Response = Get-Content -Raw "$ResponseLibrary/Remove-NetstorageGroup.json"
    #             return $Response | ConvertFrom-Json
    #         }
    #     }
    #     It 'throws no errors' {
    #         $RemoveGroup = $PD.StorageGroup | Remove-NetstorageGroup
    #         $RemoveGroup.description | Should -Be "Request OK.`n"
    #     }
    #     It 'handles empty input correctly' {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
    #         $Result = & {} | Remove-NetstorageGroup
    #         $Result | Should -Not -Be 'IAR executed'
    #     }
    # }

    # Context 'Restore-NetstorageGroup' {
    #     BeforeAll {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
    #             $Response = Get-Content -Raw "$ResponseLibrary/Restore-NetstorageGroup.json"
    #             return $Response | ConvertFrom-Json
    #         }
    #     }
    #     It 'throws no errors' {
    #         $RestoreGroup = $PD.StorageGroup | Restore-NetstorageGroup
    #         $RestoreGroup.description | Should -Be "Request OK.`n"
    #     }
    #     It 'handles empty input correctly' {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
    #         $Result = & {} | Restore-NetstorageGroup
    #         $Result | Should -Not -Be 'IAR executed'
    #     }
    # }

    #------------------------------------------------
    #             NetstorageUploadAccount
    #------------------------------------------------

    Context 'New-NetstorageUploadAccount' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageUploadAccount.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'creates by param' {
            $TestParams = @{
                'Body' = $TestUploadAccountJSON
            }
            $NewNetstorageUploadAccountByParam = New-NetstorageUploadAccount @TestParams
            $NewNetstorageUploadAccountByParam.uploadAccountId | Should -Not -BeNullOrEmpty
        }
        It 'creates by pipeline' {
            $NewNetstorageUploadAccountByPipeline = $TestUploadAccount | New-NetstorageUploadAccount
            $NewNetstorageUploadAccountByPipeline.uploadAccountId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageUploadAccount' {
        It 'gets a list' {
            $PD.UploadAccounts = Get-NetstorageUploadAccount @CommonParams
            $PD.UploadAccounts[0].uploadAccountId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific account by its ID' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
            $PD.UploadAccount.uploadAccountId | Should -Be $TestUploadAccountID
        }
    }

    Context 'Set-NetstorageUploadAccount' {
        It 'updates by param' {
            $TestParams = @{
                'Body'            = $PD.UploadAccount
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.SetUploadAccountByParam = Set-NetstorageUploadAccount @TestParams @CommonParams
            $PD.SetUploadAccountByParam.uploadAccountId | Should -Be $TestUploadAccountID
        }
        It 'updates by pipeline' {
            $PD.SetUploadAccountByPipeline = $PD.UploadAccount | Set-NetstorageUploadAccount @CommonParams
            $PD.SetUploadAccountByPipeline.uploadAccountId | Should -Be $TestUploadAccountID
        }
    }

    Context 'Disable-NetstorageUploadAccount' {
        It 'throws no errors' {
            $PD.UploadAccount | Disable-NetstorageUploadAccount @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Disable-NetstorageUploadAccount
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Enable-NetstorageUploadAccount' {
        It 'throws no errors' {
            $PD.UploadAccount | Enable-NetstorageUploadAccount @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Enable-NetstorageUploadAccount
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    # Context 'Remove-NetstorageUploadAccount' {
    #     BeforeAll {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
    #             $Response = Get-Content -Raw "$ResponseLibrary/Remove-NetstorageUploadAccount.json"
    #             return $Response | ConvertFrom-Json
    #         }
    #     }
    #     It 'throws no errors' {
    #         $PD.UploadAccount | Remove-NetstorageUploadAccount @CommonParams
    #     }
    #     It 'handles empty input correctly' {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
    #         $Result = & {} | Remove-NetstorageUploadAccount
    #         $Result | Should -Not -Be 'IAR executed'
    #     }
    # }

    #------------------------------------------------
    #          NetstorageUploadAccountFTPKey
    #------------------------------------------------

    Context 'Add-NetstorageUploadAccountFTPKey' {
        It 'adds a key by param' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
                'Key'             = $TestFTPKey
            }
            Add-NetstorageUploadAccountFTPKey @TestParams @CommonParams
        }
        It 'adds a key by pipeline' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $TestFTPKey2 | Add-NetstorageUploadAccountFTPKey @TestParams @CommonParams
        }
        AfterAll {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
            $PD.UploadAccount.keys.ftp[0].id | Should -Not -BeNullOrEmpty
            $PD.UploadAccount.keys.ftp[1].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Disable/Enable by param' {
        Context 'Disable-NetstorageUploadAccountFTPKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                    'Identity'        = $PD.UploadAccount.keys.ftp[0].id
                }
                Disable-NetstorageUploadAccountFTPKey @TestParams @CommonParams
            }
            It 'handles empty input correctly' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
                $Result = & {} | Disable-NetstorageUploadAccountFTPKey -UploadAccountID $TestUploadAccountID
                $Result | Should -Not -Be 'IAR executed'
            }
        }

        Context 'Enable-NetstorageUploadAccountFTPKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                    'Identity'        = $PD.UploadAccount.keys.ftp[0].id
                }
                Enable-NetstorageUploadAccountFTPKey @TestParams @CommonParams
            }
            It 'handles empty input correctly' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
                $Result = & {} | Enable-NetstorageUploadAccountFTPKey -UploadAccountID $TestUploadAccountID
                $Result | Should -Not -Be 'IAR executed'
            }
        }
    }

    Context 'Disable/Enable by pipeline' {
        Context 'Disable-NetstorageUploadAccountFTPKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount.keys.ftp[0] | Disable-NetstorageUploadAccountFTPKey @TestParams @CommonParams
            }
        }

        Context 'Enable-NetstorageUploadAccountFTPKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount.keys.ftp[0] | Enable-NetstorageUploadAccountFTPKey @TestParams @CommonParams
            }
        }
    }

    Context 'Update-NetstorageUploadAccountFTPKey' {
        It 'returns the correct data' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UpdateNetstorageUploadAccountFTPKey = $PD.UploadAccount.keys.ftp[0] | Update-NetstorageUploadAccountFTPKey @TestParams @CommonParams
            $PD.UpdateNetstorageUploadAccountFTPKey.message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageUploadAccountFTPKey' {
        It 'throws no errors' {
            $TestParams = @{
                'Identity'        = $PD.UploadAccount.keys.ftp[0].id
                'UploadAccountID' = $TestUploadAccountID
                'Key'             = $TestFTPKey
                'Comments'        = 'Updating'
            }
            Set-NetstorageUploadAccountFTPKey @TestParams @CommonParams
        }
    }

    Context 'Remove-NetstorageUploadAccountFTPKey' {
        BeforeAll {
            # Re-retrieve upload account as key ID changes when updated. Obviously...
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
        }
        It 'deletes by param' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
                'Identity'        = $PD.UploadAccount.keys.ftp[0].id
            }
            Remove-NetstorageUploadAccountFTPKey @TestParams @CommonParams
        }
        It 'deletes by pipeline' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UploadAccount.keys.ftp[1] | Remove-NetstorageUploadAccountFTPKey @TestParams @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetstorageUploadAccountFTPKey -UploadAccountID $TestUploadAccountID
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #        NetstorageUploadAccountRSyncKey
    #------------------------------------------------

    Context 'Add-NetstorageUploadAccountRSyncKey' {
        It 'adds a key by param' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
                'Key'             = $TestRSyncKey
            }
            Add-NetstorageUploadAccountRSyncKey @TestParams @CommonParams
        }
        It 'adds a key by pipeline' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $TestRsyncKey2 | Add-NetstorageUploadAccountRSyncKey @TestParams @CommonParams
        }
        AfterAll {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
            $PD.UploadAccount.keys.rsync[0].id | Should -Not -BeNullOrEmpty
            $PD.UploadAccount.keys.rsync[1].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Disable/Enable by param' {
        Context 'Disable-NetstorageUploadAccountRSyncKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                    'Identity'        = $PD.UploadAccount.keys.rsync[0].id
                }
                Disable-NetstorageUploadAccountRSyncKey @TestParams @CommonParams
            }
            It 'handles empty input correctly' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
                $Result = & {} | Disable-NetstorageUploadAccountRSyncKey -UploadAccountID $TestUploadAccountID
                $Result | Should -Not -Be 'IAR executed'
            }
        }

        Context 'Enable-NetstorageUploadAccountRSyncKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                    'Identity'        = $PD.UploadAccount.keys.rsync[0].id
                }
                Enable-NetstorageUploadAccountRSyncKey @TestParams @CommonParams
            }
            It 'handles empty input correctly' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
                $Result = & {} | Enable-NetstorageUploadAccountRSyncKey -UploadAccountID $TestUploadAccountID
                $Result | Should -Not -Be 'IAR executed'
            }
        }
    }

    Context 'Disable/Enable by pipeline' {
        Context 'Disable-NetstorageUploadAccountRSyncKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount.keys.rsync[0] | Disable-NetstorageUploadAccountRSyncKey @TestParams @CommonParams
            }
        }

        Context 'Enable-NetstorageUploadAccountRSyncKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount.keys.rsync[0] | Enable-NetstorageUploadAccountRSyncKey @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-NetstorageUploadAccountRSyncKey' {
        BeforeAll {
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
        }
        It 'deletes by param' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
                'Identity'        = $PD.UploadAccount.keys.rsync[0].id
            }
            Remove-NetstorageUploadAccountRSyncKey @TestParams @CommonParams
        }
        It 'deletes by pipeline' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UploadAccount.keys.rsync[1] | Remove-NetstorageUploadAccountRSyncKey @TestParams @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetstorageUploadAccountRSyncKey -UploadAccountID $TestUploadAccountID
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #          NetstorageUploadAccountSSHKey
    #------------------------------------------------

    Context 'Add-NetstorageUploadAccountSSHKey' {
        It 'adds a key by param' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
                'Key'             = $TestSSHKey
            }
            Add-NetstorageUploadAccountSSHKey @TestParams @CommonParams
        }
        It 'adds a key by pipeline' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $TestSSHKey2 | Add-NetstorageUploadAccountSSHKey @TestParams @CommonParams
        }
        AfterAll {
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
            $PD.EditableSSHKeys = $PD.UploadAccount.keys.ssh | Where-Object { $_.key -notlike "*keepme*" }
            $PD.UploadAccount.keys.ssh.count | Should -Be 3
            $PD.UploadAccount.keys.ssh | ForEach-Object {
                $_.id | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Disable/Enable by param' {
        Context 'Disable-NetstorageUploadAccountSSHKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                    'Identity'        = $PD.EditableSSHKeys[0].id
                }
                Disable-NetstorageUploadAccountSSHKey @TestParams @CommonParams
            }
            It 'handles empty input correctly' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
                $Result = & {} | Disable-NetstorageUploadAccountSSHKey -UploadAccountID $TestUploadAccountID
                $Result | Should -Not -Be 'IAR executed'
            }
        }

        Context 'Enable-NetstorageUploadAccountSSHKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                    'Identity'        = $PD.EditableSSHKeys[0].id
                }
                Enable-NetstorageUploadAccountSSHKey @TestParams @CommonParams
            }
            It 'handles empty input correctly' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
                $Result = & {} | Enable-NetstorageUploadAccountSSHKey -UploadAccountID $TestUploadAccountID
                $Result | Should -Not -Be 'IAR executed'
            }
        }
    }

    Context 'Disable/Enable by pipeline' {
        Context 'Disable-NetstorageUploadAccountSSHKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.EditableSSHKeys[0] | Disable-NetstorageUploadAccountSSHKey @TestParams @CommonParams
            }
        }

        Context 'Enable-NetstorageUploadAccountSSHKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.EditableSSHKeys[0] | Enable-NetstorageUploadAccountSSHKey @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-NetstorageUploadAccountSSHKey' {
        BeforeAll {
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
        }
        It 'deletes by param' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
                'Identity'        = $PD.EditableSSHKeys[0].id
            }
            Remove-NetstorageUploadAccountSSHKey @TestParams @CommonParams
        }
        It 'deletes by pipeline' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.EditableSSHKeys[1] | Remove-NetstorageUploadAccountSSHKey @TestParams @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetstorageUploadAccountSSHKey -UploadAccountID $TestUploadAccountID
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #          NetstorageUploadAccountHTTPKey
    #------------------------------------------------

    Context 'Add-NetstorageUploadAccountHTTPKey' {
        It 'creates successfully' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.HTTPKey = Add-NetstorageUploadAccountHTTPKey @TestParams @CommonParams
            # Add a 2nd key also
            $PD.HTTPKey2 = Add-NetstorageUploadAccountHTTPKey @TestParams @CommonParams
        }
        AfterAll {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
            $PD.UploadAccount.keys.g2o[1].id | Should -Not -BeNullOrEmpty
            $PD.UploadAccount.keys.g2o[1].key | Should -Be $PD.HTTPKey.key
            $PD.UploadAccount.keys.g2o[2].id | Should -Not -BeNullOrEmpty
            $PD.UploadAccount.keys.g2o[2].key | Should -Be $PD.HTTPKey2.key
        }
    }

    Context 'Disable/Enable by param' {
        Context 'Disable-NetstorageUploadAccountHTTPKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                    'Identity'        = $PD.UploadAccount.keys.g2o[1].id
                }
                Disable-NetstorageUploadAccountHTTPKey @TestParams @CommonParams
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
                $PD.UploadAccount.keys.g2o[1].isActive | Should -Be $false
            }
            It 'handles empty input correctly' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
                $Result = & {} | Disable-NetstorageUploadAccountHTTPKey -UploadAccountID $TestUploadAccountID
                $Result | Should -Not -Be 'IAR executed'
            }
        }

        Context 'Enable-NetstorageUploadAccountHTTPKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                    'Identity'        = $PD.UploadAccount.keys.g2o[1].id
                }
                Enable-NetstorageUploadAccountHTTPKey @TestParams @CommonParams
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
                $PD.UploadAccount.keys.g2o[1].isActive | Should -Be $true
            }
            It 'handles empty input correctly' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
                $Result = & {} | Enable-NetstorageUploadAccountHTTPKey -UploadAccountID $TestUploadAccountID
                $Result | Should -Not -Be 'IAR executed'
            }
        }
    }

    Context 'Disable/Enable by pipeline' {
        Context 'Disable-NetstorageUploadAccountHTTPKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount.keys.g2o[1] | Disable-NetstorageUploadAccountHTTPKey @TestParams @CommonParams
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
                $PD.UploadAccount.keys.g2o[1].isActive | Should -Be $false
            }
        }

        Context 'Enable-NetstorageUploadAccountHTTPKey' {
            It 'throws no errors' {
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount.keys.g2o[1] | Enable-NetstorageUploadAccountHTTPKey @TestParams @CommonParams
                $TestParams = @{
                    'UploadAccountID' = $TestUploadAccountID
                }
                $PD.UploadAccount = Get-NetstorageUploadAccount @TestParams @CommonParams
                $PD.UploadAccount.keys.g2o[1].isActive | Should -Be $true
            }
        }
    }

    Context 'Remove-NetstorageUploadAccountHTTPKey' {
        BeforeAll {
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
        }
        It 'deletes by param' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
                'Identity'        = $PD.UploadAccount.keys.g2o[1].id
            }
            Remove-NetstorageUploadAccountHTTPKey @TestParams @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetstorageUploadAccountHTTPKey -UploadAccountID $TestUploadAccountID
            $Result | Should -Not -Be 'IAR executed'
        }
        # Pipeline deletion happens later, after the credentials creation function is tested.
    }

    #------------------------------------------------
    #              NetstorageCPCode
    #------------------------------------------------

    Context 'New-NetstorageCPCode' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageCPCode.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CPCodeName' = 'testcpcode'
                'ContractID' = '1-2AB34C'
            }
            $NewNetstorageCPCode = New-NetstorageCPCode @TestParams
            $NewNetstorageCPCode.cpcodeName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageCPCode' {
        It 'returns the correct data' {
            $PD.CPCodes = Get-NetstorageCPCode @CommonParams
            $PD.CPCodes[0].cpcodeId | Should -Not -BeNullOrEmpty
        }
    }

    # Context 'Remove-NetstorageCPCode' {
    #     It 'deletes correctly' {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
    #             $Response = Get-Content -Raw "$ResponseLibrary/Remove-NetstorageCPCode.json"
    #             return $Response | ConvertFrom-Json
    #         }
    #         $TestParams = @{
    #             'ForceDelete' = $true
    #         }
    #         $PD.RemoveCPCode = $PD.CPCodes[0] | Remove-NetstorageCPCode @TestParams
    #         $PD.RemoveCPCode.description | Should -Be "Request OK.`n"
    #     }
    # }

    # Context 'Restore-NetstorageCPCode' {
    #     It 'restores correctly' {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
    #             $Response = Get-Content -Raw "$ResponseLibrary/Restore-NetstorageCPCode.json"
    #             return $Response | ConvertFrom-Json
    #         }

    #         $PD.RestoreCPCode = $PD.CPCodes[0] | Restore-NetstorageCPCode
    #         $PD.RestoreCPCode.description | Should -Be "Request OK.`n"
    #     }
    # }

    #------------------------------------------------
    #           NetstorageCPCodePurgeRoutine
    #------------------------------------------------

    Context 'Get-NetstorageCPCodePurgeRoutine' {
        It 'returns the correct data' {
            $TestParams = @{
                'CPCodeID' = $TestCPCodeID
            }
            $PD.PurgeRoutine = Get-NetstorageCPCodePurgeRoutine @TestParams @CommonParams
            $PD.PurgeRoutine[0].ageDeletionDirectory | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageCPCodePurgeRoutine' {
        It 'updates by param' {
            $TestParams = @{
                'Body'     = $PD.PurgeRoutine
                'CPCodeID' = $TestCPCodeID
            }
            Set-NetstorageCPCodePurgeRoutine @TestParams @CommonParams
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'CPCodeID' = $TestCPCodeID
            }
            $PD.PurgeRoutine[0] | Set-NetstorageCPCodePurgeRoutine @TestParams @CommonParams
        }
    }

    #------------------------------------------------
    #                 NetstorageSnapshot
    #------------------------------------------------

    Context 'New-NetstorageSnapshot' {
        It 'creates by param' {
            $TestParams = @{
                'Body' = $TestSnapshot
            }
            $PD.NewSnapshot = New-NetstorageSnapshot @TestParams @CommonParams
            $PD.NewSnapshot.snapshotId | Should -Not -BeNullOrEmpty
        }
        It 'creates by pipeline' {
            $PD.SnapshotByPipeline = $TestSnapshot | New-NetstorageSnapshot @CommonParams
            $PD.SnapshotByPipeline.snapshotId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageSnapshot' {
        It 'gets a list' {
            $PD.Snapshots = Get-NetstorageSnapshot @CommonParams
            $PD.Snapshots[0].snapshotId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific snapshot by its ID' {
            $TestParams = @{
                'SnapShotID' = $PD.NewSnapshot.snapshotId
            }
            $PD.Snapshot = Get-NetstorageSnapshot @TestParams @CommonParams
            $PD.Snapshot.snapshotId | Should -Be $PD.Snapshot.snapshotId
        }
    }

    Context 'Set-NetstorageSnapshot' {
        It 'updates by param' {
            $TestParams = @{
                'Body'       = $PD.Snapshot
                'SnapShotID' = $PD.NewSnapshot.snapshotId
            }
            $PD.SetNetstorageSnapshotByParam = Set-NetstorageSnapshot @TestParams @CommonParams
            $PD.SetNetstorageSnapshotByParam.snapshotId | Should -Be $PD.Snapshot.snapshotId
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'SnapShotID' = $PD.Snapshot.snapshotId
            }
            $PD.SetNetstorageSnapshotByPipeline = $PD.Snapshot | Set-NetstorageSnapshot @TestParams @CommonParams
            $PD.SetNetstorageSnapshotByPipeline.snapshotId | Should -Be $PD.Snapshot.snapshotId
        }
    }

    Context 'Start-NetstorageSnapshot' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Start-NetstorageSnapshot.json"
                return $Response | ConvertFrom-Json
            }
            $StartNetstorageSnapshot = $PD.Snapshot | Start-NetstorageSnapshot
            $StartNetstorageSnapshot.snapshotId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-NetstorageSnapshot' {
        It 'throws no errors' {
            $PD.Snapshot | Remove-NetstorageSnapshot @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetstorageSnapshot
            $Result | Should -Not -Be 'IAR executed'
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
    #         New-NetstorageCredentials
    #------------------------------------------------

    Context 'New-NetstorageCredentials' {
        BeforeAll {
            # Refresh upload account
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
        }
        It 'should create new credentials object with default NS API key' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.Credentials = New-NetstorageCredentials @TestParams @CommonParams
            $PD.Credentials.key | Should -Be $PD.UploadAccount.keys.g2o[0].key
            $PD.Credentials.id | Should -Be $TestUploadAccountID
            $PD.Credentials.group | Should -Be $TestStorageGroupID
            $PD.Credentials.host | Should -Be $TestDomainName
            $PD.Credentials.cpcode | Should -Be $TestCPCodeID
        }
        It 'should create new credentials object with provided API key' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
                'APIKey'          = "123456789"
            }
            $PD.Credentials = New-NetstorageCredentials @TestParams @CommonParams
            $PD.Credentials.key | Should -Be "123456789"
            $PD.Credentials.id | Should -Be $TestUploadAccountID
            $PD.Credentials.group | Should -Be $TestStorageGroupID
            $PD.Credentials.host | Should -Be $TestDomainName
            $PD.Credentials.cpcode | Should -Be $TestCPCodeID
        }
    }

    #------------------------------------------------
    #           NetstorageUploadAccountHTTPKey
    #            Last Key can now be removed
    #------------------------------------------------

    Context 'Remove-NetstorageUploadAccountHTTPKey' {
        BeforeAll {
            $PD.UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID @CommonParams
        }
        It 'deletes by pipeline' {
            $TestParams = @{
                'UploadAccountID' = $TestUploadAccountID
            }
            $PD.UploadAccount.keys.g2o[1] | Remove-NetstorageUploadAccountHTTPKey @TestParams @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetstorageUploadAccountHTTPKey -UploadAccountID $TestUploadAccountID
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #               NetstorageRuleSet
    #------------------------------------------------

    Context 'New-NetstorageRuleSet' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'creates by param' {
            $TestParams = @{
                'Body' = $TestRuleSet
            }
            $PD.NewNetstorageRuleSetByParam = New-NetstorageRuleSet @TestParams
            $PD.NewNetstorageRuleSetByParam.ruleSetId | Should -Not -BeNullOrEmpty
        }
        It 'creates by pipeline' {
            $NewNetstorageRuleSetByPipeline = $TestRuleSet | New-NetstorageRuleSet
            $NewNetstorageRuleSetByPipeline.ruleSetId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageRuleSet' {
        It 'gets a list' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetstorageRuleSet_1.json"
                return $Response | ConvertFrom-Json
            }
            $GetNetstorageRuleSetAll = Get-NetstorageRuleSet
            $GetNetstorageRuleSetAll[0].ruleSetId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific snapshot by its ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'RuleSetID' = 123456
            }
            $GetNetstorageRuleSet = Get-NetstorageRuleSet @TestParams
            $GetNetstorageRuleSet.ruleSetId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-NetstorageRuleSet' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'updates by param' {
            $TestParams = @{
                'Body'      = $PD.NewNetstorageRuleSetByParam
                'RuleSetID' = 123456
            }
            $SetNetstorageRuleSetByParam = Set-NetstorageRuleSet @TestParams
            $SetNetstorageRuleSetByParam.ruleSetId | Should -Not -BeNullOrEmpty
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'RuleSetID' = 123456
            }
            $SetNetstorageRuleSetByPipeline = $PD.NewNetstorageRuleSetByParam | Set-NetstorageRuleSet @TestParams
            $SetNetstorageRuleSetByPipeline.ruleSetId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-NetstorageRuleSet' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-NetstorageRuleSet.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'RuleSetID' = 123456
            }
            Remove-NetstorageRuleSet @TestParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetstorageRuleSet
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #           NetstorageCPCodePurgeRoutine
    #------------------------------------------------

    Context 'Remove-NetstorageCPCodePurgeRoutine' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-NetstorageCPCodePurgeRoutine.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CPCodeID' = 123456
            }
            Remove-NetstorageCPCodePurgeRoutine @TestParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Netstorage -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-NetstorageCPCodePurgeRoutine
            $Result | Should -Not -Be 'IAR executed'
        }
    }
}