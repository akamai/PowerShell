BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.IAM Tests' {

    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.IAM'
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
        $TestContractID = $env:PesterContract
        $TestGroupID = $env:PesterGroupID
        $TestUIIdentityID = $env:PesterIAMUIID
        $TestNewGroupName = "powershell-temp-$Timestamp"
        $TestNewRoleName = "pester-testing-$Timestamp"
        $TestNewRoleBody = @{
            "grantedRoles"    = @()
            "roleDescription" = "Test role for PowerShell pester testing."
            "roleName"        = $TestNewRoleName
        }
        $TestAssetID = $env:PesterAssetID
        $TestUsername = $env:PesterIAMUsername
        $TestExpirationDate = Get-Date ((Get-Date).ToUniversalTime().AddMinutes(60)) -Format 'yyyy-MM-ddTHH:mm:ss.000Z'
        $TestCredentialBody = @{
            'expiresOn'   = $TestExpirationDate
            'status'      = 'ACTIVE'
            'description' = 'Testing Pester update'
        }
        $TestUserNotificationsJSON = '{
            "options": {
              "newUserNotification": true,
              "passwordExpiry": true,
              "proactive": [],
              "upgrade": [
                "NetStorage"
              ]
            },
            "enableEmailNotifications": true
        }'
        $TestUserNotificationsObj = ConvertFrom-Json $TestUserNotificationsJSON
        $TestAPIClientName = "pester_testclient_$Timestamp"
        $TestAPIClientJSON = @"
{
    "clientName": "$TestAPIClientName",
    "clientDescription": "Temporary account for testing. Will be deleted shortly",
    "clientType": "CLIENT",
    "authorizedUsers": ["$env:PesterIAMAuthorizedUsers"],
    "allowAccountSwitch": false,
    "isLocked": false,
    "groupAccess": {
        "cloneAuthorizedUserGroups": true,
        "groups": []
    },
    "apiAccess": {
        "allAccessibleApis": true,
        "apis": []
    }
}
"@
        $TestAPIClientObj = ConvertFrom-Json $TestAPIClientJSON
        $TestNewUserBody = '{
            "firstName": "Test",
            "lastName": "User",
            "email": "test@example.com",
            "phone": "(111) 111-1111",
            "timeZone": "GMT",
            "additionalAuthentication": "NONE",
            "passwordExpiryDate": "2023-11-09T18:05:00Z",
            "address": "TBD",
            "city": "TBD",
            "state": "TBD",
            "country": "USA"
        }'
        $TestNewUserObj = ConvertFrom-Json $TestNewUserBody
        $CurrentPassword = 'This is the current password' | ConvertTo-SecureString -AsPlainText -Force
        $NewPassword = 'This is the new password' | ConvertTo-SecureString -AsPlainText -Force
        $TestAvailableCPCodesJSON = '{
            "clientType": "CLIENT",
            "groups": [
                {
                    "groupId": 12345,
                    "groupName": "Fala Internal-2-2EZBD",
                    "roleDescription": "CPCodeTest RolePermissions Automation",
                    "roleId": 654321,
                    "roleName": "CP Code Automation role"
                }
            ]
        }'
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.IAM"
        $PD = @{}
    }

    AfterAll {
        Get-IAMRole @CommonParams | Where-Object roleName -like "$TestNewRoleName*" | ForEach-Object { Remove-IAMRole -RoleID $_.roleId @CommonParams }
        Get-IAMGroup @CommonParams | Where-Object groupName -eq $TestNewGroupName | ForEach-Object { Remove-IAMGroup -GroupID $_.groupId @CommonParams }
        Get-IAMAPIClient @CommonParams | Where-Object clientName -like "$TestAPIClientName*" | ForEach-Object { Remove-IAMAPIClient -ClientID $_.clientId @CommonParams }
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 IAMGrantableRole
    #------------------------------------------------

    Context 'Get-IAMGrantableRole' {
        It 'gets all IAM grantable roles' {
            $PD.GetIAMGrantableRole = Get-IAMGrantableRole @CommonParams
            $PD.GetIAMGrantableRole[0].grantedRoleId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUser
    #------------------------------------------------

    Context 'Get-IAMUser' {
        It 'gets a list of users' {
            $PD.GetIAMUserAll = Get-IAMUser @CommonParams
            $PD.GetIAMUserAll[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
        It 'gets a single user by ID' {
            $TestParams = @{
                'UIIdentityID' = $TestUIIdentityID
                'Actions'      = $true
                'AuthGrants'   = $true
            }
            $PD.GetIAMUser = Get-IAMUser @TestParams @CommonParams
            $PD.GetIAMUser.uiIdentityId | Should -Be $TestUIIdentityID
        }
    }


    Context 'Set-IAMUser' {
        It 'updates IAM user by parameter' {
            $TestParams = @{
                'Body'         = $PD.GetIAMUser
                'UIIdentityID' = $TestUIIdentityID
            }
            $PD.SetIAMUserByParam = Set-IAMUser @TestParams @CommonParams
            $PD.SetIAMUserByParam.uiIdentityId | Should -Be $TestUIIdentityID
        }
        It 'updates IAM user by pipeline' {
            $PD.SetIAMUserByPipeline = $PD.GetIAMUser | Set-IAMUser @CommonParams
            $PD.SetIAMUserByPipeline.uiIdentityId | Should -Be $TestUIIdentityID
        }
    }


    Context 'Lock-IAMUser' {
        It 'locks an IAM user account' {
            $TestUIIdentityID | Lock-IAMUser @CommonParams
        }
    }

    Context 'Unlock-IAMUser' {
        It 'unlocks an IAM user account' {
            $TestUIIdentityID | Unlock-IAMUser @CommonParams
        }
    }

    Context 'Set-IAMUserGroupAndRole' {
        It 'updates IAM user group and role assignments by parameter' {
            $TestParams = @{
                'Body'         = $PD.GetIAMUser.authGrants
                'UiIdentityID' = $TestUIIdentityID
            }
            $PD.SetIAMUserGroupAndRoleByParam = Set-IAMUserGroupAndRole @TestParams @CommonParams
            $PD.SetIAMUserGroupAndRoleByParam[0].groupId | Should -Not -BeNullOrEmpty
        }
        It 'updates IAM user group and role assignments by pipeline' {
            $TestParams = @{
                'UiIdentityID' = $TestUIIdentityID
            }
            $PD.SetIAMUserGroupAndRoleByPipeline = $PD.GetIAMUser.authGrants | Set-IAMUserGroupAndRole @TestParams @CommonParams
            $PD.SetIAMUserGroupAndRoleByPipeline[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMGroup
    #------------------------------------------------

    Context 'New-IAMGroup' {
        It 'creates a new IAM group' {
            $TestParams = @{
                'GroupName'     = $TestNewGroupName
                'ParentGroupID' = $TestGroupID
            }
            $PD.NewIAMGroup = New-IAMGroup @TestParams @CommonParams
            $PD.NewIAMGroup.groupName | Should -Be $TestNewGroupName
        }
    }

    Context 'Get-IAMGroup' {
        It 'gets all IAM groups' {
            $PD.GetIAMGroupAll = Get-IAMGroup @CommonParams
            $PD.GetIAMGroupAll[0].groupId | Should -Not -BeNullOrEmpty
        }
        It 'gets all IAM groups in a flattened structure' {
            $TestParams = @{
                'Flatten' = $true
            }
            $PD.GetIAMGroupFlatten = Get-IAMGroup @TestParams @CommonParams
            $PD.GetIAMGroupFlatten[0].groupId | Should -Not -BeNullOrEmpty
            $PD.GetIAMGroupFlatten.count | Should -BeGreaterThan $PD.GetIAMGroupAll.count
        }
        It 'gets a single IAM group by ID' {
            $TestParams = @{
                'GroupID' = $PD.NewIAMGroup.groupId
            }
            $PD.GetIAMGroupSingle = Get-IAMGroup @TestParams @CommonParams
            $PD.GetIAMGroupSingle.groupId | Should -Be $PD.NewIAMGroup.groupId
        }
    }

    Context 'Set-IAMGroup' {
        It 'updates IAM group settings' {
            $TestParams = @{
                'GroupName' = $TestNewGroupName
            }
            $PD.SetIAMGroup = $PD.NewIAMGroup | Set-IAMGroup @TestParams @CommonParams
            $PD.SetIAMGroup.groupName | Should -Be $TestNewGroupName
        }
    }

    Context 'Move-IAMGroup' {
        It 'moves an IAM group to a different parent group' {
            $TestParams = @{
                'DestinationGroupID' = $TestGroupID
                'SourceGroupID'      = $PD.NewIAMGroup.groupId
            }
            Move-IAMGroup @TestParams @CommonParams
        }
    }

    Context 'Remove-IAMGroup' {
        It 'removes an IAM group' {
            $PD.NewIAMGroup | Remove-IAMGroup @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-IAMGroup @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 IAMRole
    #------------------------------------------------

    Context 'New-IAMRole' {
        It 'creates a new IAM role by parameter' {
            $TestNewRoleBody.grantedRoles += $PD.GetIAMGrantableRole[0] | Select-Object grantedRoleId
            $TestParams = @{
                'Body' = $TestNewRoleBody
            }
            $PD.NewIAMRoleByParam = New-IAMRole @TestParams @CommonParams
            $PD.NewIAMRoleByParam.roleName | Should -Be $TestNewRoleName
        }
        It 'creates a new IAM role by pipeline' {
            $TestNewRoleBody.roleName += '-Pipeline'
            $PD.NewIAMRoleByPipeline = $TestNewRoleBody | New-IAMRole @CommonParams
            $PD.NewIAMRoleByPipeline.roleName | Should -Be "$TestNewRoleName-Pipeline"
        }
    }

    Context 'Get-IAMRole' {
        It 'gets a list of roles' {
            $PD.GetIAMRoleAll = Get-IAMRole @CommonParams
            $PD.GetIAMRoleAll[0].roleName | Should -Not -BeNullOrEmpty
        }
        It 'gets a single role by ID' {
            $PD.GetIAMRole = $PD.NewIAMRoleByParam | Get-IAMRole @CommonParams
            $PD.GetIAMRole.roleName | Should -Be $TestNewRoleName
        }
    }

    Context 'Set-IAMRole' {
        It 'updates IAM role by parameter' {
            $TestParams = @{
                'Body'   = $PD.NewIAMRoleByParam
                'RoleID' = $PD.NewIAMRoleByParam.roleId
            }
            $PD.SetIAMRoleByParam = Set-IAMRole @TestParams @CommonParams
            $PD.SetIAMRoleByParam.roleName | Should -Be $TestNewRoleName
        }
        It 'updates IAM role by pipeline' {
            $PD.SetIAMRoleByPipeline = $PD.NewIAMRoleByParam | Set-IAMRole @CommonParams
            $PD.SetIAMRoleByPipeline.roleName | Should -Be $TestNewRoleName
        }
    }


    Context 'Remove-IAMRole' {
        It 'removes an IAM role' {
            $TestParams = @{
                'RoleID' = $PD.NewIAMRoleByParam.roleId
            }
            Remove-IAMRole @TestParams @CommonParams
            $PD.NewIAMRoleByPipeline | Remove-IAMRole @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-IAMRole @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 IAMProperty
    #------------------------------------------------

    Context 'Get-IAMProperty' {
        It 'gets a list of properties' {
            $PD.GetIAMPropertyAll = Get-IAMProperty @CommonParams
            $PD.GetIAMPropertyAll[0].propertyId | Should -Not -BeNullOrEmpty
        }
        It 'gets a single property by Asset ID and group' {
            $TestParams = @{
                'GroupID' = $TestGroupID
                'AssetID' = $TestAssetID
            }
            $PD.GetIAMPropertySingle = Get-IAMProperty @TestParams @CommonParams
            $PD.GetIAMPropertySingle.arlConfigFile | Should -Not -BeNullOrEmpty
        }

        It 'gets a single property by Property ID and group' {
            $TestParams = @{
                'GroupID'    = $TestGroupID
                'PropertyID' = $TestAssetID
            }
            $PD.GetIAMPropertySingle = Get-IAMProperty @TestParams @CommonParams
            $PD.GetIAMPropertySingle.arlConfigFile | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMPropertyResources
    #------------------------------------------------

    Context 'Get-IAMPropertyResources' {
        It 'gets property resources by Asset ID' {
            $TestParams = @{
                'GroupID' = $TestGroupID
            }
            $PD.GetIAMPropertyResources = $TestAssetID | Get-IAMPropertyResources @TestParams @CommonParams
            $PD.GetIAMPropertyResources[0].resourceId | Should -Not -BeNullOrEmpty
        }

        It 'gets property resources by Property ID' {
            $TestParams = @{
                'GroupID'    = $TestGroupID
                'PropertyID' = $TestAssetID
            }
            $PD.GetIAMPropertyResources = Get-IAMPropertyResources @TestParams @CommonParams
            $PD.GetIAMPropertyResources[0].resourceId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMPropertyUsers
    #------------------------------------------------

    Context 'Get-IAMPropertyUsers' {
        It 'gets property users by Asset ID' {
            $TestParams = @{
                'AssetID' = $TestAssetID
            }
            $PD.GetIAMPropertyUsers = Get-IAMPropertyUsers @TestParams @CommonParams
            $PD.GetIAMPropertyUsers[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }

        It 'gets property users by Property ID' {
            $TestParams = @{
                'PropertyID' = $TestAssetID
            }
            $PD.GetIAMPropertyUsers = Get-IAMPropertyUsers @TestParams @CommonParams
            $PD.GetIAMPropertyUsers[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAPIClient
    #------------------------------------------------

    Context 'New-IAMAPIClient' {
        It 'creates a new API client by parameter' {
            $TestParams = @{
                'Body' = $TestAPIClientJSON
            }
            $PD.NewIAMAPIClientByParam = New-IAMAPIClient @TestParams @CommonParams
            $PD.NewIAMAPIClientByParam.clientName | Should -Be $TestAPIClientName
        }
        It 'creates a new API client by pipeline' {
            $TestAPIClientObj.clientName += "-pipeline"
            $PD.NewIAMAPIClientByPipeline = $TestAPIClientObj | New-IAMAPIClient @CommonParams
            $PD.NewIAMAPIClientByPipeline.clientName | Should -Be "$TestAPIClientName-pipeline"
        }
    }

    Context 'Get-IAMAPIClient' {
        It 'gets a list of clients' {
            $PD.GetIAMAPIClientAll = Get-IAMAPIClient @CommonParams
            $PD.GetIAMAPIClientAll[0].clientId | Should -Not -BeNullOrEmpty
        }
        It 'gets a single client by ID' {
            $PD.GetIAMAPIClientSingle = $PD.NewIAMAPIClientByParam | Get-IAMAPIClient @CommonParams
            $PD.GetIAMAPIClientSingle.clientId | Should -Not -BeNullOrEmpty
        }
        It 'gets own API client with access details' {
            $TestParams = @{
                'ClientID'    = 'self'
                'GroupAccess' = $true
                'APIAccess'   = $true
            }
            $PD.GetIAMAPIClientSelf = Get-IAMAPIClient @TestParams @CommonParams
            $PD.GetIAMAPIClientSelf.clientId | Should -Not -BeNullOrEmpty
        }
    }


    Context 'Set-IAMAPIClient' {
        It 'updates API client by parameter' {
            $TestParams = @{
                'Body'     = $PD.NewIAMAPIClientByParam
                'ClientID' = $PD.NewIAMAPIClientByParam.clientId
            }
            $PD.SetIAMAPIClientSingleByParam = Set-IAMAPIClient @TestParams @CommonParams
            $PD.SetIAMAPIClientSingleByParam.clientId | Should -Be $PD.NewIAMAPIClientByParam.clientId
        }
        It 'updates API client by pipeline' {
            $PD.SetIAMAPIClientSingleByPipeline = $PD.NewIAMAPIClientByParam | Set-IAMAPIClient @CommonParams
            $PD.SetIAMAPIClientSingleByPipeline.clientId | Should -Be $PD.NewIAMAPIClientByParam.clientId
        }
        It 'updates own API client by parameter' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMAPIClient.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $PD.GetIAMAPIClientSelf
            }
            $SetIAMAPIClientSelfByParam = Set-IAMAPIClient @TestParams @CommonParams
            $SetIAMAPIClientSelfByParam.clientId | Should -Not -BeNullOrEmpty
        }
        It 'updates own API client by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMAPIClient.json"
                return $Response | ConvertFrom-Json
            }
            $SetIAMAPIClientSelfByPipeline = $PD.GetIAMAPIClientSelf | Set-IAMAPIClient @CommonParams
            $SetIAMAPIClientSelfByPipeline.clientId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Lock-IAMAPIClient' {
        It 'locks an API client' {
            $PD.LockIAMAPIClient = $PD.NewIAMAPIClientByParam | Lock-IAMAPIClient @CommonParams
            $PD.LockIAMAPIClient.isLocked | Should -Be $true
        }
    }

    Context 'Unlock-IAMAPIClient' {
        It 'unlocks an API client' {
            $PD.UnlockIAMAPIClient = $PD.NewIAMAPIClientByParam | Unlock-IAMAPIClient @CommonParams
            $PD.UnlockIAMAPIClient.isLocked | Should -Be $false
        }
    }

    #------------------------------------------------
    #                 IAMAPICredential
    #------------------------------------------------

    Context 'New-IAMAPICredential' {
        It 'creates API credential for self with client secret and token' {
            $PD.NewIAMAPICredentialSelf = New-IAMAPICredential @CommonParams
            $PD.NewIAMAPICredentialSelf.credentialId | Should -Not -BeNullOrEmpty
            $PD.NewIAMAPICredentialSelf.accessToken | Should -Not -BeNullOrEmpty
            $PD.NewIAMAPICredentialSelf.ClientSecret | Should -Not -BeNullOrEmpty
            $PD.NewIAMAPICredentialSelf.ClientToken | Should -Not -BeNullOrEmpty
            $PD.NewIAMAPICredentialSelf.Host | Should -Not -BeNullOrEmpty
        }
        It 'creates API credential for self with API response only' {
            $TestParams = @{
                'APIResponseOnly' = $true
            }
            $PD.NewIAMAPICredentialSelf = New-IAMAPICredential @TestParams @CommonParams
            $PD.NewIAMAPICredentialSelf.credentialId | Should -Not -BeNullOrEmpty
            $PD.NewIAMAPICredentialSelf.ClientToken | Should -Not -BeNullOrEmpty
            $PD.NewIAMAPICredentialSelf.ClientSecret | Should -Not -BeNullOrEmpty
            $PD.NewIAMAPICredentialSelf.accessToken | Should -BeNullOrEmpty
            $PD.NewIAMAPICredentialSelf.Host | Should -BeNullOrEmpty
        }
    }

    Context 'Get-IAMAPICredential' {
        It 'gets all API credentials for self' {
            $PD.GetIAMAPICredentialSelf = Get-IAMAPICredential @CommonParams
            $PD.GetIAMAPICredentialSelf[0].credentialId | Should -Not -BeNullOrEmpty
        }
        It 'gets a credential by ID' {
            $TestParams = @{
                'CredentialID' = $PD.NewIAMAPICredentialSelf.credentialId
            }
            $PD.GetIAMAPICredentialSelfSingle = Get-IAMAPICredential @TestParams @CommonParams
            $PD.GetIAMAPICredentialSelfSingle.credentialId | Should -Be $PD.NewIAMAPICredentialSelf.credentialId
        }
    }

    Context 'Set-IAMAPICredential' {
        It 'updates API credential by parameter' {
            $TestParams = @{
                'CredentialID' = $PD.NewIAMAPICredentialSelf.credentialId
                'Status'       = 'ACTIVE'
                'ExpiresOn'    = $TestExpirationDate
            }
            $PD.SetIAMAPICredentialSelfByParam = Set-IAMAPICredential @TestParams @CommonParams
            $PD.SetIAMAPICredentialSelfByParam.expiresOn | Should -Not -BeNullOrEmpty
        }
        It 'updates API credential by pipeline' {
            $PD.GetIAMAPICredentialSelfSingle.expiresOn = $TestExpirationDate
            $PD.SetIAMAPICredentialSelfByPipeline = $PD.GetIAMAPICredentialSelfSingle | Set-IAMAPICredential @CommonParams
            $PD.SetIAMAPICredentialSelfByPipeline.expiresOn | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Disable-IAMAPICredential' {
        It 'disables API credential for self' {
            $PD.GetIAMAPICredentialSelfSingle | Disable-IAMAPICredential @CommonParams
        }
    }

    Context 'Remove-IAMAPICredential' {
        It 'removes API credential for self' {
            $PD.GetIAMAPICredentialSelfSingle | Remove-IAMAPICredential @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-IAMAPICredential @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }


    #------------------------------------------------
    #                 IAMAccessibleGroups
    #------------------------------------------------

    Context 'Get-IAMAccessibleGroups' {
        It 'gets accessible groups for a user' {
            $TestParams = @{
                'Username' = $TestUsername
            }
            $PD.GetIAMAccessibleGroups = Get-IAMAccessibleGroups @TestParams @CommonParams
            $PD.GetIAMAccessibleGroups[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAdminContactTypes
    #------------------------------------------------

    Context 'Get-IAMAdminContactTypes' {
        It 'gets all admin contact types' {
            $PD.GetIAMAdminContactTypes = Get-IAMAdminContactTypes @CommonParams
            $PD.GetIAMAdminContactTypes.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserContactTypes
    #------------------------------------------------

    Context 'Get-IAMUserContactTypes' {
        It 'gets all user contact types' {
            $PD.GetIAMUserContactTypes = Get-IAMUserContactTypes @CommonParams
            $PD.GetIAMUserContactTypes.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminCountries
    #------------------------------------------------

    Context 'Get-IAMAdminCountries' {
        It 'gets all admin countries' {
            $PD.GetIAMAdminCountries = Get-IAMAdminCountries @CommonParams
            $PD.GetIAMAdminCountries.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserCountries
    #------------------------------------------------

    Context 'Get-IAMUserCountries' {
        It 'gets all user countries' {
            $PD.GetIAMUserCountries = Get-IAMUserCountries @CommonParams
            $PD.GetIAMUserCountries.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminLanguages
    #------------------------------------------------

    Context 'Get-IAMAdminLanguages' {
        It 'gets all admin languages' {
            $PD.GetIAMAdminLanguages = Get-IAMAdminLanguages @CommonParams
            $PD.GetIAMAdminLanguages.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserLanguages
    #------------------------------------------------

    Context 'Get-IAMUserLanguages' {
        It 'gets all user languages' {
            $PD.GetIAMUserLanguages = Get-IAMUserLanguages @CommonParams
            $PD.GetIAMUserLanguages.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminPasswordPolicy
    #------------------------------------------------

    Context 'Get-IAMAdminPasswordPolicy' {
        It 'gets admin password policy' {
            $PD.GetIAMAdminPasswordPolicy = Get-IAMAdminPasswordPolicy @CommonParams
            $PD.GetIAMAdminPasswordPolicy.minLength | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserPasswordPolicy
    #------------------------------------------------

    Context 'Get-IAMUserPasswordPolicy' {
        It 'gets user password policy' {
            $PD.GetIAMUserPasswordPolicy = Get-IAMUserPasswordPolicy @CommonParams
            $PD.GetIAMUserPasswordPolicy.minLength | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAdminProducts
    #------------------------------------------------

    Context 'Get-IAMAdminProducts' {
        It 'gets all admin products' {
            $PD.GetIAMAdminProducts = Get-IAMAdminProducts @CommonParams
            $PD.GetIAMAdminProducts.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserProducts
    #------------------------------------------------

    Context 'Get-IAMUserProducts' {
        It 'gets all user products' {
            $PD.GetIAMUserProducts = Get-IAMUserProducts @CommonParams
            $PD.GetIAMUserProducts.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminStates
    #------------------------------------------------

    Context 'Get-IAMAdminStates' {
        It 'gets all admin states for a country' {
            $TestParams = @{
                'Country' = 'USA'
            }
            $PD.GetIAMAdminStates = Get-IAMAdminStates @TestParams @CommonParams
            $PD.GetIAMAdminStates.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserStates
    #------------------------------------------------

    Context 'Get-IAMUserStates' {
        It 'gets all user states for a country' {
            $TestParams = @{
                'Country' = 'USA'
            }
            $PD.GetIAMUserStates = Get-IAMUserStates @TestParams @CommonParams
            $PD.GetIAMUserStates.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminTimeoutPolicy
    #------------------------------------------------

    Context 'Get-IAMAdminTimeoutPolicy' {
        It 'gets admin timeout policy' {
            $PD.GetIAMAdminTimeoutPolicy = Get-IAMAdminTimeoutPolicy @CommonParams
            $PD.GetIAMAdminTimeoutPolicy[0].value | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserTimeoutPolicy
    #------------------------------------------------

    Context 'Get-IAMUserTimeoutPolicy' {
        It 'gets user timeout policy' {
            $PD.GetIAMUserTimeoutPolicy = Get-IAMUserTimeoutPolicy @CommonParams
            $PD.GetIAMUserTimeoutPolicy[0].value | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAdminTimeZones
    #------------------------------------------------

    Context 'Get-IAMAdminTimeZones' {
        It 'gets all admin time zones' {
            $PD.GetIAMAdminTimeZones = Get-IAMAdminTimeZones @CommonParams
            $PD.GetIAMAdminTimeZones[0].timezone | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserTimeZones
    #------------------------------------------------

    Context 'Get-IAMUserTimeZones' {
        It 'gets all user time zones' {
            $PD.GetIAMUserTimeZones = Get-IAMUserTimeZones @CommonParams
            $PD.GetIAMUserTimeZones[0].timezone | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAllowedAPIs
    #------------------------------------------------

    Context 'Get-IAMAllowedAPIs' {
        It 'gets allowed APIs for a user' {
            $TestParams = @{
                'Username' = $TestUsername
            }
            $PD.GetIAMAllowedAPIs = Get-IAMAllowedAPIs @TestParams @CommonParams
            $PD.GetIAMAllowedAPIs[0].apiId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAuthorizedUsers
    #------------------------------------------------

    Context 'Get-IAMAuthorizedUsers' {
        It 'gets all authorized users' {
            $PD.GetIAMAuthorizedUsers = Get-IAMAuthorizedUsers @CommonParams
            $PD.GetIAMAuthorizedUsers[0].userName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserNotifications
    #------------------------------------------------

    Context 'Set-IAMUserNotifications' {
        It 'updates user notification settings by parameter' {
            $TestParams = @{
                'Body'         = $TestUserNotificationsJSON
                'UIIdentityID' = $TestUIIdentityID
            }
            $PD.SetIAMUserNotificationsSingleByParam = Set-IAMUserNotifications @TestParams @CommonParams
            $PD.SetIAMUserNotificationsSingleByParam.enableEmailNotifications | Should -Not -BeNullOrEmpty
        }
        It 'updates user notification settings by pipeline' {
            $TestParams = @{
                'UIIdentityID' = $TestUIIdentityID
            }
            $PD.SetIAMUserNotificationsSingleByPipeline = $TestUserNotificationsObj | Set-IAMUserNotifications @TestParams @CommonParams
            $PD.SetIAMUserNotificationsSingleByPipeline.enableEmailNotifications | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Removals
    #------------------------------------------------

    Context 'Remove-IAMAPIClient' {
        It 'removes an API client' {
            $TestParams = @{
                'ClientID' = $PD.NewIAMAPIClientByParam.clientId
            }
            Remove-IAMAPIClient @TestParams @CommonParams
            $PD.NewIAMAPIClientByPipeline | Remove-IAMAPIClient @CommonParams
        }
    }

    #------------------------------------------------
    #                 AccountSwitchKey
    #------------------------------------------------

    # Commented out to fix GH Issue 30.
    # Test should not be mocked.
    # Context 'Get-AccountSwitchKey' {
    #     It 'gets account switch key by search term' {
    #         Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
    #             $Response = Get-Content -Raw "$ResponseLibrary/Get-AccountSwitchKey.json"
    #             return $Response | ConvertFrom-Json
    #         }
    #         $TestParams = @{
    #             'Search' = 'Akamai'
    #         }
    #         $GetAccountSwitchKey = Get-AccountSwitchKey @TestParams
    #         $GetAccountSwitchKey.accountSwitchKey | Should -Not -BeNullOrEmpty
    #     }
    # }

    #------------------------------------------------
    #                 IAMUser
    #------------------------------------------------

    Context 'New-IAMUser' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-IAMUser.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'creates a new IAM user by parameter' {
            $TestParams = @{
                'Body' = $TestNewUserBody
            }
            $NewIAMUserByParam = New-IAMUser @TestParams
            $NewIAMUserByParam.uiIdentityId | Should -Not -BeNullOrEmpty
        }
        It 'creates a new IAM user by pipeline' {
            $NewIAMUserByPipeline = $TestNewUserObj | New-IAMUser
            $NewIAMUserByPipeline.uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-IAMUser' {
        It 'removes an IAM user' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMUser.json"
                return $Response | ConvertFrom-Json
            }
            'A-1-23CDEF' | Remove-IAMUser
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-IAMUser @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }


    Context 'Get-IAMGroupMoveAffectedUsers' {
        It 'gets users affected by group move' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMGroupMoveAffectedUsers.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'DestinationGroupID' = 22222
                'SourceGroupID'      = 11111
            }
            $GetIAMGroupMoveAffectedUsers = Get-IAMGroupMoveAffectedUsers @TestParams
            $GetIAMGroupMoveAffectedUsers[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMIPAllowList
    #------------------------------------------------

    Context 'Disable-IAMIPAllowList' {
        It 'disables IP allow list' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Disable-IAMIPAllowList.json"
                return $Response | ConvertFrom-Json
            }
            Disable-IAMIPAllowList
        }
    }

    Context 'Enable-IAMIPAllowList' {
        It 'enables IP allow list' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Enable-IAMIPAllowList.json"
                return $Response | ConvertFrom-Json
            }
            Enable-IAMIPAllowList
        }
    }

    #------------------------------------------------
    #                 IAMIPAllowListStatus
    #------------------------------------------------

    Context 'Get-IAMIPAllowListStatus' {
        It 'gets IP allow list status' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMIPAllowListStatus.json"
                return $Response | ConvertFrom-Json
            }
            $GetIAMIPAllowListStatus = Get-IAMIPAllowListStatus
            $GetIAMIPAllowListStatus.enabled | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserProfile
    #------------------------------------------------

    Context 'Get-IAMUserProfile' {
        It 'gets current user profile' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMUserProfile.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetIAMUserProfile = Get-IAMUserProfile
            $PD.GetIAMUserProfile.firstName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMUserProfile' {
        It 'updates user profile by parameter' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserProfile.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $PD.GetIAMUserProfile
            }
            $SetIAMUserProfileByParam = Set-IAMUserProfile @TestParams
            $SetIAMUserProfileByParam.uiIdentityId | Should -Not -BeNullOrEmpty
        }
        It 'updates user profile by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserProfile.json"
                return $Response | ConvertFrom-Json
            }
            $SetIAMUserProfileByPipeline = $PD.GetIAMUserProfile | Set-IAMUserProfile
            $SetIAMUserProfileByPipeline.uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserPassword
    #------------------------------------------------

    Context 'Set-IAMUserPassword' {
        It 'updates own password with current password verification' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserPassword.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CurrentPassword' = $CurrentPassword
                'NewPassword'     = $NewPassword
            }
            Set-IAMUserPassword @TestParams
        }
        It 'updates another user password' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserPassword.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'NewPassword' = $NewPassword
            }
            'A-1-23CDEF' | Set-IAMUserPassword @TestParams
        }
    }

    Context 'Reset-IAMUserPassword' {
        It 'resets user password' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Reset-IAMUserPassword.json"
                return $Response | ConvertFrom-Json
            }
            'A-1-23CDEF' | Reset-IAMUserPassword
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-IAMUser @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #               IAMPropertyUsers
    #------------------------------------------------

    Context 'Block-IAMPropertyUsers' {
        It 'blocks property users by Asset ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Block-IAMPropertyUsers.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'AssetID'      = 123456789
                'UIIdentityID' = 'A-1-23CDEF'
            }
            $BlockIAMPropertyUsersByParam = Block-IAMPropertyUsers @TestParams
            $BlockIAMPropertyUsersByParam[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }

        It 'blocks property users by Property ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Block-IAMPropertyUsers.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'PropertyID'   = 123456789
                'UIIdentityID' = 'A-1-23CDEF'
            }
            $BlockIAMPropertyUsersByParam = Block-IAMPropertyUsers @TestParams
            $BlockIAMPropertyUsersByParam[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
        It 'blocks property users by Asset ID via pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Block-IAMPropertyUsers.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'AssetID' = 123456789
            }
            $BlockIAMPropertyUsersByPipeline = 'A-1-23CDEF' | Block-IAMPropertyUsers @TestParams
            $BlockIAMPropertyUsersByPipeline[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }

        It 'blocks property users by Property ID via pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Block-IAMPropertyUsers.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'PropertyID' = 123456789
            }
            $BlockIAMPropertyUsersByPipeline = 'A-1-23CDEF' | Block-IAMPropertyUsers @TestParams
            $BlockIAMPropertyUsersByPipeline[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #           IAMUserBlockedProperties
    #------------------------------------------------

    Context 'Get-IAMUserBlockedProperties' {
        It 'gets blocked properties for a user' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMUserBlockedProperties.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'GroupID'      = 123456
                'UIIdentityID' = 'A-1-23CDEF'
            }
            $GetIAMUserBlockedProperties = Get-IAMUserBlockedProperties @TestParams
            $GetIAMUserBlockedProperties[0] | Should -Match '^[\d]+$'
        }
    }

    Context 'Set-IAMUserBlockedProperties' {
        It 'updates blocked properties for a user' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserBlockedProperties.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'GroupID'      = 123456
                'UIIdentityID' = 'A-1-23CDEF'
            }
            $SetIAMUserBlockedProperties = 123456, 234567 | Set-IAMUserBlockedProperties @TestParams
            $SetIAMUserBlockedProperties[0] | Should -Match '^[\d]+$'
        }
    }

    #------------------------------------------------
    #                 IAMUser
    #------------------------------------------------

    Context 'Set-IAMUserMFA' {
        It 'enables MFA for current user' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserMFA.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Value' = 'MFA'
            }
            Set-IAMUserMFA @TestParams
        }
        It 'enables MFA for another user' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserMFA.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Value'        = 'MFA'
                'UIIdentityID' = 'A-1-23CDEF'
            }
            Set-IAMUserMFA @TestParams
        }
    }

    Context 'Reset-IAMUserMFA' {
        It 'resets MFA for current user' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Reset-IAMUserMFA.json"
                return $Response | ConvertFrom-Json
            }
            Reset-IAMUserMFA
        }
        It 'resets MFA for another user' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Reset-IAMUserMFA.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'UIIdentityID' = 'A-1-23CDEF'
            }
            Reset-IAMUserMFA @TestParams
        }
    }

    #------------------------------------------------
    #                 IAMProperty
    #------------------------------------------------

    Context 'Move-IAMProperty' {
        It 'moves property by Asset ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Move-IAMProperty.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'DestinationGroupID' = 11111
                'AssetID'            = 12345678
                'SourceGroupID'      = 22222
            }
            Move-IAMProperty @TestParams
        }

        It 'moves property by Property ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Move-IAMProperty.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'DestinationGroupID' = 11111
                'PropertyID'         = 12345678
                'SourceGroupID'      = 22222
            }
            Move-IAMProperty @TestParams
        }
    }

    #------------------------------------------------
    #                 IAMCIDRBlock
    #------------------------------------------------

    Context 'New-IAMCIDRBlock' {
        It 'creates a new CIDR block' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CIDRBlock' = '1.0.0.0/24'
            }
            $NewIAMCIDRBlock = New-IAMCIDRBlock @TestParams
            $NewIAMCIDRBlock.cidrBlock | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IAMCIDRBlock' {
        It 'gets a single CIDR block by ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetIAMCIDRBlockSingle = 1234 | Get-IAMCIDRBlock
            $PD.GetIAMCIDRBlockSingle.cidrBlock | Should -Not -BeNullOrEmpty
        }
        It 'gets all CIDR blocks' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            $GetIAMCIDRBlockAll = Get-IAMCIDRBlock
            $GetIAMCIDRBlockAll[0].cidrBlock | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMCIDRBlock' {
        It 'updates CIDR block settings' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CIDRBlock' = '1.0.0.0/24'
                'Comments'  = 'Testing'
            }
            $SetIAMCIDRBlock = $PD.GetIAMCIDRBlockSingle | Set-IAMCIDRBlock @TestParams
            $SetIAMCIDRBlock.cidrBlock | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-IAMCIDRBlock' {
        It 'validates CIDR block format' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Test-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            '1.0.0.0/24' | Test-IAMCIDRBlock
        }
    }

    Context 'Remove-IAMCIDRBlock' {
        It 'removes a CIDR block' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            1234 | Remove-IAMCIDRBlock
        }
    }

    #------------------------------------------------
    #                 IAMAllowedCPCodes
    #------------------------------------------------

    Context 'Get-IAMAllowedCPCodes' {
        It 'gets allowed CP codes for a user' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMAllowedCPCodes.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body'     = $TestAvailableCPCodesJSON
                'Username' = 'dvader'
            }
            $GetIAMAllowedCPCodes = Get-IAMAllowedCPCodes @TestParams
            $GetIAMAllowedCPCodes[0].name | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAPIClient
    #------------------------------------------------

    Context 'Remove-IAMAPICredential' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            12345 | Remove-IAMAPICredential
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-IAMAPICredential @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Lock-IAMAPIClient' {
        It 'locks own API client' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Lock-IAMAPIClient.json"
                return $Response | ConvertFrom-Json
            }
            $LockIAMAPIClient = Lock-IAMAPIClient
            $LockIAMAPIClient.isLocked | Should -Be $true
        }
    }

    Context 'Remove-IAMAPIClient' {
        It 'removes an API client by ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMAPIClient.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ClientID' = 12345
            }
            Remove-IAMAPIClient @TestParams
        }
    }

    #------------------------------------------------
    #                 IAMAPICredential
    #------------------------------------------------

    Context 'New-IAMAPICredential' -Tag 'New-IAMAPICredential' {
        It 'creates API credential for a client' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ClientID'        = 'xfz2n5d43mogkdim'
                'APIResponseOnly' = $true
            }
            $NewIAMAPICredentialSingle = New-IAMAPICredential @TestParams
            $NewIAMAPICredentialSingle.credentialId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IAMAPICredential' {
        It 'gets API credential by client and credential ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ClientID'     = 'xfz2n5d43mogkdim'
                'CredentialID' = 14111
            }
            $PD.GetIAMAPICredentialSingle = Get-IAMAPICredential @TestParams
            $PD.GetIAMAPICredentialSingle.credentialId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMAPICredential' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'updates API credential by parameter' {
            $TestParams = @{
                'Body'         = $PD.GetIAMAPICredentialSingle
                'ClientID'     = 'xfz2n5d43mogkdim'
                'CredentialID' = 14111
            }
            $SetIAMAPICredentialSingleByParam = Set-IAMAPICredential @TestParams
            $SetIAMAPICredentialSingleByParam.expiresOn | Should -Not -BeNullOrEmpty
        }
        It 'updates API credential by pipeline' {
            $TestParams = @{
                'ClientID' = 'xfz2n5d43mogkdim'
            }
            $SetIAMAPICredentialSingleByPipeline = $PD.GetIAMAPICredentialSingle | Set-IAMAPICredential @TestParams
            $SetIAMAPICredentialSingleByPipeline.expiresOn | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Disable-IAMAPICredential' {
        It 'disables API credential for a client' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Disable-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ClientID' = 'xfz2n5d43mogkdim'
            }
            $PD.GetIAMAPICredentialSingle | Disable-IAMAPICredential @TestParams
        }
    }

    Context 'Remove-IAMAPICredential' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ClientID' = 'xfz2n5d43mogkdim'
            }
            $PD.GetIAMAPICredentialSingle | Remove-IAMAPICredential @TestParams
        }
    }
}

