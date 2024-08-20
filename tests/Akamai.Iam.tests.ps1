Describe 'Safe Akamai.IAM Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.IAM/Akamai.IAM.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContract
        $TestGroupID = $env:PesterGroupID
        $TestUIIdentityID = $env:PesterIAMUIID
        $TestNewGroupName = 'powershell-temp'
        $TestNewRoleName = 'akamaipowershell-testing'
        $TestNewRoleBody = @{
            "grantedRoles"    = @()
            "roleDescription" = "Test role for PowerShell pester testing."
            "roleName"        = $TestNewRoleName
        }
        $TestPropertyID = $env:PesterAssetID
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
              "proactive": [
                "EdgeScape",
                "EdgeSuite (HTTP Content Delivery)"
              ],
              "upgrade": [
                "NetStorage"
              ]
            },
            "enableEmailNotifications": true
        }'
        $TestUserNotificationsObj = ConvertFrom-Json $TestUserNotificationsJSON
        $TestAPIClientJSON = @"
{
    "clientName": "akamaipowershell_testclient",
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
        $TestAPIClientName = 'akamaipowershell_testclient'
        $PD = @{}
    }

    #------------------------------------------------
    #                 IAMGrantableRole                  
    #------------------------------------------------

    Context 'Get-IAMGrantableRole' {
        It 'returns the correct data' {
            $PD.GetIAMGrantableRole = Get-IAMGrantableRole @CommonParams
            $PD.GetIAMGrantableRole[0].grantedRoleId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUser                  
    #------------------------------------------------

    Context 'Get-IAMUser - Parameter Set all' {
        It 'Get-IAMUser (all) returns the correct data' {
            $PD.GetIAMUserAll = Get-IAMUser @CommonParams
            $PD.GetIAMUserAll[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IAMUser - Parameter Set single' {
        It 'Get-IAMUser (single) returns the correct data' {
            $PD.GetIAMUser = Get-IAMUser -UIIdentityID $TestUIIdentityID -Actions -AuthGrants @CommonParams
            $PD.GetIAMUser.uiIdentityId | Should -Be $TestUIIdentityID
        }
    }

    Context 'Set-IAMUser by parameter' {
        It 'Set-IAMUser (single) by param returns the correct data' {
            $PD.SetIAMUserByParam = Set-IAMUser -Body $PD.GetIAMUser -UIIdentityID $TestUIIdentityID @CommonParams
            $PD.SetIAMUserByParam.uiIdentityId | Should -Be $TestUIIdentityID
        }
    }

    Context 'Set-IAMUser by pipeline' {
        It 'Set-IAMUser (single) by pipeline returns the correct data' {
            $PD.SetIAMUserByPipeline = $PD.GetIAMUser | Set-IAMUser -UIIdentityID $TestUIIdentityID @CommonParams
            $PD.SetIAMUserByPipeline.uiIdentityId | Should -Be $TestUIIdentityID
        }
    }

    Context 'Lock-IAMUser' {
        It 'throws no errors' {
            Lock-IAMUser -UIIdentityID $TestUIIdentityID @CommonParams 
        }
    }

    Context 'Unlock-IAMUser' {
        It 'throws no errors' {
            Unlock-IAMUser -UIIdentityID $TestUIIdentityID @CommonParams 
        }
    }

    Context 'Set-IAMUserGroupAndRole by parameter' {
        It 'Set-IAMUserGroupAndRole (others) by param returns the correct data' {
            $PD.SetIAMUserGroupAndRoleByParam = Set-IAMUserGroupAndRole -Body $PD.GetIAMUser.authGrants -UiIdentityID $TestUIIdentityID @CommonParams
            $PD.SetIAMUserGroupAndRoleByParam[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMUserGroupAndRole by pipeline' {
        It 'Set-IAMUserGroupAndRole (others) by pipeline returns the correct data' {
            $PD.SetIAMUserGroupAndRoleByPipeline = $PD.GetIAMUser.authGrants | Set-IAMUserGroupAndRole -UiIdentityID $TestUIIdentityID @CommonParams
            $PD.SetIAMUserGroupAndRoleByPipeline[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMGroup                  
    #------------------------------------------------

    Context 'New-IAMGroup' {
        It 'returns the correct data' {
            $PD.NewIAMGroup = New-IAMGroup -GroupName $TestNewGroupName -ParentGroupID $TestGroupID @CommonParams
            $PD.NewIAMGroup.groupName | Should -Be $TestNewGroupName
        }
    }

    Context 'Get-IAMGroup - All' {
        It 'returns the correct data' {
            $PD.GetIAMGroupAll = Get-IAMGroup @CommonParams
            $PD.GetIAMGroupAll[0].groupId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-IAMGroup - Single' {
        It 'returns the correct data' {
            $PD.GetIAMGroupSingle = Get-IAMGroup -GroupID $PD.NewIAMGroup.groupId @CommonParams
            $PD.GetIAMGroupSingle.groupId | Should -Be $PD.NewIAMGroup.groupId
        }
    }

    Context 'Set-IAMGroup' {
        It 'returns the correct data' {
            $PD.SetIAMGroup = Set-IAMGroup -GroupID $PD.NewIAMGroup.groupId -GroupName $TestNewGroupName @CommonParams
            $PD.SetIAMGroup.groupName | Should -Be $TestNewGroupName
        }
    }

    Context 'Move-IAMGroup' {
        It 'throws no errors' {
            Move-IAMGroup -DestinationGroupID $TestGroupID -SourceGroupID $PD.NewIAMGroup.groupId @CommonParams 
        }
    }
    
    Context 'Remove-IAMGroup' {
        It 'throws no errors' {
            Remove-IAMGroup -GroupID $PD.NewIAMGroup.groupId @CommonParams 
        }
    }

    #------------------------------------------------
    #                 IAMRole                  
    #------------------------------------------------

    Context 'New-IAMRole by parameter' {
        It 'returns the correct data' {
            $TestNewRoleBody.grantedRoles += $PD.GetIAMGrantableRole[0] | Select-Object grantedRoleId
            $PD.NewIAMRoleByParam = New-IAMRole -Body $TestNewRoleBody @CommonParams
            $PD.NewIAMRoleByParam.roleName | Should -Be $TestNewRoleName
        }
    }

    Context 'New-IAMRole by pipeline' {
        It 'returns the correct data' {
            $TestNewRoleBody.roleName += '-Pipeline'
            $PD.NewIAMRoleByPipeline = $TestNewRoleBody | New-IAMRole @CommonParams
            $PD.NewIAMRoleByPipeline.roleName | Should -Be "$TestNewRoleName-Pipeline"
        }
    }

    Context 'Get-IAMRole - Parameter Set single' {
        It 'returns the correct data' {
            $PD.GetIAMRole = Get-IAMRole -RoleID $PD.NewIAMRoleByParam.roleId @CommonParams
            $PD.GetIAMRole.roleName | Should -Be $TestNewRoleName
        }
    }

    Context 'Get-IAMRole - Parameter Set all' {
        It 'returns the correct data' {
            $PD.GetIAMRoleAll = Get-IAMRole @CommonParams
            $PD.GetIAMRoleAll[0].roleName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMRole by parameter' {
        It 'by param returns the correct data' {
            $PD.SetIAMRoleByParam = Set-IAMRole -Body $PD.NewIAMRoleByParam -RoleID $PD.NewIAMRoleByParam.roleId @CommonParams
            $PD.SetIAMRoleByParam.roleName | Should -Be $TestNewRoleName
        }
    }

    Context 'Set-IAMRole by pipeline' {
        It 'by pipeline returns the correct data' {
            $PD.SetIAMRoleByPipeline = $PD.NewIAMRoleByParam | Set-IAMRole -RoleID $PD.NewIAMRoleByParam.roleId @CommonParams
            $PD.SetIAMRoleByPipeline.roleName | Should -Be $TestNewRoleName
        }
    }

    Context 'Remove-IAMRole' {
        It 'returns the correct data' {
            Remove-IAMRole -RoleID $PD.NewIAMRoleByParam.roleId @CommonParams 
            Remove-IAMRole -RoleID $PD.NewIAMRoleByPipeline.roleId @CommonParams 
        }
    }

    #------------------------------------------------
    #                 IAMProperty                  
    #------------------------------------------------

    Context 'Get-IAMProperty - All' {
        It 'returns the correct data' {
            $PD.GetIAMPropertyAll = Get-IAMProperty @CommonParams
            $PD.GetIAMPropertyAll[0].propertyId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-IAMProperty - Single' {
        It 'returns the correct data' {
            $PD.GetIAMPropertySingle = Get-IAMProperty -GroupID $TestGroupID -PropertyID $TestPropertyID @CommonParams
            $PD.GetIAMPropertySingle.arlConfigFile | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMPropertyResources                  
    #------------------------------------------------

    Context 'Get-IAMPropertyResources' {
        It 'returns the correct data' {
            $PD.GetIAMPropertyResources = Get-IAMPropertyResources -GroupID $TestGroupID -PropertyID $TestPropertyID @CommonParams
            $PD.GetIAMPropertyResources[0].resourceId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMPropertyUsers                  
    #------------------------------------------------

    Context 'Get-IAMPropertyUsers' {
        It 'returns the correct data' {
            $PD.GetIAMPropertyUsers = Get-IAMPropertyUsers -PropertyID $TestPropertyID @CommonParams
            $PD.GetIAMPropertyUsers[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAPIClient                  
    #------------------------------------------------

    Context 'New-IAMAPIClient by parameter' {
        It 'returns the correct data' {
            $PD.NewIAMAPIClientByParam = New-IAMAPIClient -Body $TestAPIClientJSON @CommonParams
            $PD.NewIAMAPIClientByParam.clientName | Should -Be $TestAPIClientName
        }
    }

    Context 'New-IAMAPIClient by pipeline' {
        It 'returns the correct data' {
            $TestAPIClientObj.clientName += "-pipeline"
            $PD.NewIAMAPIClientByPipeline = ($TestAPIClientObj | New-IAMAPIClient @CommonParams)
            $PD.NewIAMAPIClientByPipeline.clientName | Should -Be "$TestAPIClientName-pipeline"
        }
    }

    Context 'Get-IAMAPIClient, all' {
        It 'returns the correct data' {
            $PD.GetIAMAPIClientAll = Get-IAMAPIClient @CommonParams
            $PD.GetIAMAPIClientAll[0].clientId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-IAMAPIClient, single' {
        It 'returns the correct data' {
            $PD.GetIAMAPIClientSingle = Get-IAMAPIClient -ClientID $PD.NewIAMAPIClientByParam.clientId @CommonParams
            $PD.GetIAMAPIClientSingle.clientId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-IAMAPIClient, self' {
        It 'returns the correct data' {
            $PD.GetIAMAPIClientSelf = Get-IAMAPIClient -ClientID self @CommonParams
            $PD.GetIAMAPIClientSelf.clientId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMAPIClient - Parameter Set single, by parameter' {
        It 'returns the correct data' {
            $PD.SetIAMAPIClientSingleByParam = Set-IAMAPIClient -Body $PD.NewIAMAPIClientByParam -ClientID $PD.NewIAMAPIClientByParam.clientId @CommonParams
            $PD.SetIAMAPIClientSingleByParam.clientId | Should -Be $PD.NewIAMAPIClientByParam.clientId
        }
    }

    Context 'Set-IAMAPIClient - Parameter Set single, by pipeline' {
        It 'returns the correct data' {
            $PD.SetIAMAPIClientSingleByPipeline = ($PD.NewIAMAPIClientByParam | Set-IAMAPIClient -ClientID $PD.NewIAMAPIClientByParam.clientId @CommonParams)
            $PD.SetIAMAPIClientSingleByPipeline.clientId | Should -Be $PD.NewIAMAPIClientByParam.clientId
        }
    }

    Context 'Set-IAMAPIClient - Parameter Set self, by parameter' {
        It 'returns the correct data' {
            $PD.SetIAMAPIClientSelfByParam = Set-IAMAPIClient -Body $PD.GetIAMAPIClientSelf @CommonParams
            $PD.SetIAMAPIClientSelfByParam.clientId | Should -Be $PD.GetIAMAPIClientSelf.clientId
        }
    }

    Context 'Set-IAMAPIClient - Parameter Set self, by pipeline' {
        It 'returns the correct data' {
            $PD.SetIAMAPIClientSelfByPipeline = $PD.GetIAMAPIClientSelf | Set-IAMAPIClient @CommonParams
            $PD.SetIAMAPIClientSelfByPipeline.clientId | Should -Be $PD.GetIAMAPIClientSelf.clientId
        }
    }

    Context 'Lock-IAMAPIClient - Parameter Set single' {
        It 'returns the correct data' {
            $PD.LockIAMAPIClient = Lock-IAMAPIClient -ClientID $PD.NewIAMAPIClientByParam.clientId @CommonParams
            $PD.LockIAMAPIClient.isLocked | Should -Be $true
        }
    }

    Context 'Unlock-IAMAPIClient' {
        It 'returns the correct data' {
            $PD.UnlockIAMAPIClient = Unlock-IAMAPIClient -ClientID $PD.NewIAMAPIClientByParam.clientId @CommonParams
            $PD.UnlockIAMAPIClient.isLocked | Should -Be $false
        }
    }

    #------------------------------------------------
    #                 IAMAPICredential                  
    #------------------------------------------------

    Context 'New-IAMAPICredential - Parameter Set self' {
        It 'returns the correct data' {
            $PD.NewIAMAPICredentialSelf = New-IAMAPICredential @CommonParams
            $PD.NewIAMAPICredentialSelf.credentialId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IAMAPICredential - Parameter Set self by an ID' {
        It 'returns the correct data' {
            $PD.GetIAMAPICredentialSelfSingle = Get-IAMAPICredential -CredentialID $PD.NewIAMAPICredentialSelf.credentialId @CommonParams
            $PD.GetIAMAPICredentialSelfSingle.credentialId | Should -Be $PD.NewIAMAPICredentialSelf.credentialId
        }
    }

    Context 'Get-IAMAPICredential - Parameter Set self gets all' {
        It 'returns the correct data' {
            $PD.GetIAMAPICredentialSelf = Get-IAMAPICredential @CommonParams
            $PD.GetIAMAPICredentialSelf[0].credentialId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMAPICredential - Parameter Set self, by param' {
        It 'returns the correct data' {
            $PD.SetIAMAPICredentialSelfByParam = Set-IAMAPICredential -CredentialID $PD.NewIAMAPICredentialSelf.credentialId -Status ACTIVE -ExpiresOn $TestExpirationDate @CommonParams
            $PD.SetIAMAPICredentialSelfByParam.expiresOn | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-IAMAPICredential - Parameter Set self, by pipeline' {
        It 'returns the correct data' {
            $PD.SetIAMAPICredentialSelfByPipeline = ($TestCredentialBody | Set-IAMAPICredential -CredentialID $PD.NewIAMAPICredentialSelf.credentialId @CommonParams)
            $PD.SetIAMAPICredentialSelfByPipeline.expiresOn | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Disable-IAMAPICredential - Parameter Set self' {
        It 'does not throw any errors' {
            Disable-IAMAPICredential -CredentialID $PD.NewIAMAPICredentialSelf.credentialId @CommonParams 
        }
    }
    
    Context 'Remove-IAMAPICredential - Parameter Set self' {
        It 'throws no errors' {
            Remove-IAMAPICredential -CredentialID $PD.NewIAMAPICredentialSelf.credentialId @CommonParams 
        }
    }
    

    #------------------------------------------------
    #                 IAMAccessibleGroups                  
    #------------------------------------------------

    Context 'Get-IAMAccessibleGroups' {
        It 'returns the correct data' {
            $PD.GetIAMAccessibleGroups = Get-IAMAccessibleGroups -Username $TestUsername @CommonParams
            $PD.GetIAMAccessibleGroups[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAdminContactTypes                  
    #------------------------------------------------

    Context 'Get-IAMAdminContactTypes' {
        It 'returns the correct data' {
            $PD.GetIAMAdminContactTypes = Get-IAMAdminContactTypes @CommonParams
            $PD.GetIAMAdminContactTypes.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserContactTypes                  
    #------------------------------------------------

    Context 'Get-IAMUserContactTypes' {
        It 'returns the correct data' {
            $PD.GetIAMUserContactTypes = Get-IAMUserContactTypes @CommonParams
            $PD.GetIAMUserContactTypes.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminCountries                  
    #------------------------------------------------

    Context 'Get-IAMAdminCountries' {
        It 'returns the correct data' {
            $PD.GetIAMAdminCountries = Get-IAMAdminCountries @CommonParams
            $PD.GetIAMAdminCountries.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserCountries                  
    #------------------------------------------------

    Context 'Get-IAMUserCountries' {
        It 'returns the correct data' {
            $PD.GetIAMUserCountries = Get-IAMUserCountries @CommonParams
            $PD.GetIAMUserCountries.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminLanguages                  
    #------------------------------------------------

    Context 'Get-IAMAdminLanguages' {
        It 'returns the correct data' {
            $PD.GetIAMAdminLanguages = Get-IAMAdminLanguages @CommonParams
            $PD.GetIAMAdminLanguages.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserLanguages                  
    #------------------------------------------------

    Context 'Get-IAMUserLanguages' {
        It 'returns the correct data' {
            $PD.GetIAMUserLanguages = Get-IAMUserLanguages @CommonParams
            $PD.GetIAMUserLanguages.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminPasswordPolicy                  
    #------------------------------------------------

    Context 'Get-IAMAdminPasswordPolicy' {
        It 'returns the correct data' {
            $PD.GetIAMAdminPasswordPolicy = Get-IAMAdminPasswordPolicy @CommonParams
            $PD.GetIAMAdminPasswordPolicy.minLength | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserPasswordPolicy                  
    #------------------------------------------------

    Context 'Get-IAMUserPasswordPolicy' {
        It 'returns the correct data' {
            $PD.GetIAMUserPasswordPolicy = Get-IAMUserPasswordPolicy @CommonParams
            $PD.GetIAMUserPasswordPolicy.minLength | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAdminProducts                  
    #------------------------------------------------

    Context 'Get-IAMAdminProducts' {
        It 'returns the correct data' {
            $PD.GetIAMAdminProducts = Get-IAMAdminProducts @CommonParams
            $PD.GetIAMAdminProducts.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserProducts                  
    #------------------------------------------------

    Context 'Get-IAMUserProducts' {
        It 'returns the correct data' {
            $PD.GetIAMUserProducts = Get-IAMUserProducts @CommonParams
            $PD.GetIAMUserProducts.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminStates                  
    #------------------------------------------------

    Context 'Get-IAMAdminStates' {
        It 'returns the correct data' {
            $PD.GetIAMAdminStates = Get-IAMAdminStates -Country USA @CommonParams
            $PD.GetIAMAdminStates.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMUserStates                  
    #------------------------------------------------

    Context 'Get-IAMUserStates' {
        It 'returns the correct data' {
            $PD.GetIAMUserStates = Get-IAMUserStates -Country USA @CommonParams
            $PD.GetIAMUserStates.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 IAMAdminTimeoutPolicy                  
    #------------------------------------------------

    Context 'Get-IAMAdminTimeoutPolicy' {
        It 'returns the correct data' {
            $PD.GetIAMAdminTimeoutPolicy = Get-IAMAdminTimeoutPolicy @CommonParams
            $PD.GetIAMAdminTimeoutPolicy[0].value | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserTimeoutPolicy                  
    #------------------------------------------------

    Context 'Get-IAMUserTimeoutPolicy' {
        It 'returns the correct data' {
            $PD.GetIAMUserTimeoutPolicy = Get-IAMUserTimeoutPolicy @CommonParams
            $PD.GetIAMUserTimeoutPolicy[0].value | Should -Not -BeNullOrEmpty
        }
    }
    
    #------------------------------------------------
    #                 IAMAdminTimeZones                  
    #------------------------------------------------
    
    Context 'Get-IAMAdminTimeZones' {
        It 'returns the correct data' {
            $PD.GetIAMAdminTimeZones = Get-IAMAdminTimeZones @CommonParams
            $PD.GetIAMAdminTimeZones[0].timezone | Should -Not -BeNullOrEmpty
        }
    }
    
    #------------------------------------------------
    #                 IAMUserTimeZones                  
    #------------------------------------------------

    Context 'Get-IAMUserTimeZones' {
        It 'returns the correct data' {
            $PD.GetIAMUserTimeZones = Get-IAMUserTimeZones @CommonParams
            $PD.GetIAMUserTimeZones[0].timezone | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAllowedAPIs                  
    #------------------------------------------------

    Context 'Get-IAMAllowedAPIs' {
        It 'returns the correct data' {
            $PD.GetIAMAllowedAPIs = Get-IAMAllowedAPIs -Username $TestUsername @CommonParams
            $PD.GetIAMAllowedAPIs[0].apiId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAuthorizedUsers                  
    #------------------------------------------------

    Context 'Get-IAMAuthorizedUsers' {
        It 'returns the correct data' {
            $PD.GetIAMAuthorizedUsers = Get-IAMAuthorizedUsers @CommonParams
            $PD.GetIAMAuthorizedUsers[0].userName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserNotifications                  
    #------------------------------------------------

    Context 'Set-IAMUserNotifications, single by parameter' {
        It 'returns the correct data' {
            $PD.SetIAMUserNotificationsSingleByParam = Set-IAMUserNotifications -Body $TestUserNotificationsJSON -UIIdentityID $TestUIIdentityID @CommonParams
            $PD.SetIAMUserNotificationsSingleByParam.enableEmailNotifications | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMUserNotifications by pipeline' {
        It 'returns the correct data' {
            $PD.SetIAMUserNotificationsSingleByPipeline = $TestUserNotificationsObj | Set-IAMUserNotifications -UIIdentityID $TestUIIdentityID @CommonParams
            $PD.SetIAMUserNotificationsSingleByPipeline.enableEmailNotifications | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Removals
    #------------------------------------------------

    Context 'Remove-IAMAPIClient - Parameter Set single' {
        It 'throws no errors' {
            Remove-IAMAPIClient -ClientID $PD.NewIAMAPIClientByParam.clientId @CommonParams
            Remove-IAMAPIClient -ClientID $PD.NewIAMAPIClientByPipeline.clientId @CommonParams
        }
    }


    AfterAll {
        
    }

}

Describe 'UnSafe Akamai.IAM Tests' {

    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.IAM/Akamai.IAM.psd1 -Force
        
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

    #------------------------------------------------
    #                 AccountSwitchKey                  
    #------------------------------------------------

    Context 'Get-AccountSwitchKey' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AccountSwitchKey.json"
                return $Response | ConvertFrom-Json
            }
            $GetAccountSwitchKey = Get-AccountSwitchKey -Search 'Akamai'
            $GetAccountSwitchKey.accountSwitchKey | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUser                  
    #------------------------------------------------

    Context 'New-IAMUser by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-IAMUser.json"
                return $Response | ConvertFrom-Json
            }
            $NewIAMUserByParam = New-IAMUser -Body $TestNewUserBody
            $NewIAMUserByParam.uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-IAMUser by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-IAMUser.json"
                return $Response | ConvertFrom-Json
            }
            $NewIAMUserByPipeline = $TestNewUserObj | New-IAMUser
            $NewIAMUserByPipeline.uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-IAMUser' {
        It 'does not throw' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMUser.json"
                return $Response | ConvertFrom-Json
            }
            Remove-IAMUser -UIIdentityID A-1-23CDEF 
        }
    }


    Context 'Get-IAMGroupMoveAffectedUsers' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMGroupMoveAffectedUsers.json"
                return $Response | ConvertFrom-Json
            }
            $GetIAMGroupMoveAffectedUsers = Get-IAMGroupMoveAffectedUsers -DestinationGroupID 22222 -SourceGroupID 11111
            $GetIAMGroupMoveAffectedUsers[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMIPAllowList                  
    #------------------------------------------------

    Context 'Disable-IAMIPAllowList' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Disable-IAMIPAllowList.json"
                return $Response | ConvertFrom-Json
            }
            Disable-IAMIPAllowList 
        }
    }

    Context 'Enable-IAMIPAllowList' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
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
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
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
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMUserProfile.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetIAMUserProfile = Get-IAMUserProfile
            $PD.GetIAMUserProfile.firstName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMUserProfile by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserProfile.json"
                return $Response | ConvertFrom-Json
            }
            $SetIAMUserProfileByParam = Set-IAMUserProfile -Body $PD.GetIAMUserProfile
            $SetIAMUserProfileByParam.uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMUserProfile by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
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

    Context 'Set-IAMUserPassword - Parameter Set my' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserPassword.json"
                return $Response | ConvertFrom-Json
            }
            Set-IAMUserPassword -CurrentPassword $CurrentPassword -NewPassword $NewPassword 
        }
    }

    Context 'Set-IAMUserPassword - Parameter Set others' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserPassword.json"
                return $Response | ConvertFrom-Json
            }
            Set-IAMUserPassword -NewPassword $NewPassword -UIIdentityID 'A-1-23CDEF'
        }
    }

    Context 'Reset-IAMUserPassword' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Reset-IAMUserPassword.json"
                return $Response | ConvertFrom-Json
            }
            Reset-IAMUserPassword -UIIdentityID A-1-23CDEF
        }
    }

    #------------------------------------------------
    #                 IAMPropertyUsers                  
    #------------------------------------------------

    Context 'Block-IAMPropertyUsers by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Block-IAMPropertyUsers.json"
                return $Response | ConvertFrom-Json
            }
            $BlockIAMPropertyUsersByParam = Block-IAMPropertyUsers -PropertyID 123456789 -UIIdentityID 'A-1-23CDEF'
            $BlockIAMPropertyUsersByParam[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Block-IAMPropertyUsers by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Block-IAMPropertyUsers.json"
                return $Response | ConvertFrom-Json
            }
            $BlockIAMPropertyUsersByPipeline = 'A-1-23CDEF' | Block-IAMPropertyUsers -PropertyID 123456789
            $BlockIAMPropertyUsersByPipeline[0].uiIdentityId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMUserBlockedProperties                  
    #------------------------------------------------

    Context 'Get-IAMUserBlockedProperties' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMUserBlockedProperties.json"
                return $Response | ConvertFrom-Json
            }
            $GetIAMUserBlockedProperties = Get-IAMUserBlockedProperties -GroupID 123456 -UIIdentityID 'A-1-23CDEF'
            $GetIAMUserBlockedProperties[0] | Should -Match '^[\d]+$'
        }
    }

    Context 'Set-IAMUserBlockedProperties' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserBlockedProperties.json"
                return $Response | ConvertFrom-Json
            }
            $SetIAMUserBlockedProperties = Set-IAMUserBlockedProperties -Body @(123456, 234567) -GroupID 123456 -UIIdentityID 'A-1-23CDEF'
            $SetIAMUserBlockedProperties[0] | Should -Match '^[\d]+$'
        }
    }

    #------------------------------------------------
    #                 IAMUser                  
    #------------------------------------------------

    Context 'Set-IAMUserMFA - My' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserMFA.json"
                return $Response | ConvertFrom-Json
            }
            Set-IAMUserMFA -Value MFA 
        }
    }
    
    Context 'Set-IAMUserMFA - Other' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMUserMFA.json"
                return $Response | ConvertFrom-Json
            }
            Set-IAMUserMFA -Value MFA 
        }
    }

    Context 'Reset-IAMUserMFA - My' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Reset-IAMUserMFA.json"
                return $Response | ConvertFrom-Json
            }
            Reset-IAMUserMFA 
        }
    }
    
    Context 'Reset-IAMUserMFA - Other' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Reset-IAMUserMFA.json"
                return $Response | ConvertFrom-Json
            }
            Reset-IAMUserMFA -UIIdentityID 'A-1-23CDEF' 
        }
    }

    #------------------------------------------------
    #                 IAMProperty                  
    #------------------------------------------------

    Context 'Move-IAMProperty' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Move-IAMProperty.json"
                return $Response | ConvertFrom-Json
            }
            Move-IAMProperty -DestinationGroupID 11111 -PropertyID 12345678 -SourceGroupID 22222 
        }
    }

    #------------------------------------------------
    #                 IAMCIDRBlock                  
    #------------------------------------------------

    Context 'New-IAMCIDRBlock' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            $NewIAMCIDRBlock = New-IAMCIDRBlock -CIDRBlock 1.0.0.0/24
            $NewIAMCIDRBlock.cidrBlock | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IAMCIDRBlock, single' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            $GetIAMCIDRBlockSingle = Get-IAMCIDRBlock -CIDRBlockID 1234
            $GetIAMCIDRBlockSingle.cidrBlock | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-IAMCIDRBlock, all' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            $GetIAMCIDRBlockAll = Get-IAMCIDRBlock
            $GetIAMCIDRBlockAll[0].cidrBlock | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMCIDRBlock' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            $SetIAMCIDRBlock = Set-IAMCIDRBlock -CIDRBlockID 1234 -CIDRBlock 1.0.0.0/24 -Comments 'Testing'
            $SetIAMCIDRBlock.cidrBlock | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-IAMCIDRBlock' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Test-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            Test-IAMCIDRBlock -CIDRBlock 1.0.0.0/24
        }
    }

    Context 'Remove-IAMCIDRBlock' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMCIDRBlock.json"
                return $Response | ConvertFrom-Json
            }
            Remove-IAMCIDRBlock -CIDRBlockID 1234
        }
    }

    #------------------------------------------------
    #                 IAMAllowedCPCodes                  
    #------------------------------------------------

    Context 'Get-IAMAllowedCPCodes' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMAllowedCPCodes.json"
                return $Response | ConvertFrom-Json
            }
            $GetIAMAllowedCPCodes = Get-IAMAllowedCPCodes -Body $TestAvailableCPCodesJSON -Username dvader
            $GetIAMAllowedCPCodes[0].name | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 IAMAPIClient                  
    #------------------------------------------------

    Context 'Remove-IAMAPICredential - Parameter Set self' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            Remove-IAMAPICredential -CredentialID 12345 
        }
    }

    Context 'Lock-IAMAPIClient - Parameter Set self' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Lock-IAMAPIClient.json"
                return $Response | ConvertFrom-Json
            }
            $LockIAMAPIClient = Lock-IAMAPIClient
            $LockIAMAPIClient.isLocked | Should -Be $true
        }
    }

    Context 'Remove-IAMAPIClient - Parameter Set self' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMAPIClient.json"
                return $Response | ConvertFrom-Json
            }
            Remove-IAMAPIClient 
        }
    }

    #------------------------------------------------
    #                 IAMAPICredential                  
    #------------------------------------------------

    Context 'New-IAMAPICredential - Parameter Set single' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            $NewIAMAPICredentialSingle = New-IAMAPICredential -ClientID xfz2n5d43mogkdim
            $NewIAMAPICredentialSingle.credentialId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IAMAPICredential - Parameter Set single' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetIAMAPICredentialSingle = Get-IAMAPICredential -ClientID xfz2n5d43mogkdim -CredentialID 14111
            $PD.GetIAMAPICredentialSingle.credentialId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMAPICredential - Parameter Set single, by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            $SetIAMAPICredentialSingleByParam = Set-IAMAPICredential -Body $PD.GetIAMAPICredentialSingle -ClientID xfz2n5d43mogkdim -CredentialID 14111
            $SetIAMAPICredentialSingleByParam.expiresOn | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-IAMAPICredential - Parameter Set single, by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            $SetIAMAPICredentialSingleByPipeline = ($PD.GetIAMAPICredentialSingle | Set-IAMAPICredential -ClientID xfz2n5d43mogkdim -CredentialID 14111)
            $SetIAMAPICredentialSingleByPipeline.expiresOn | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Disable-IAMAPICredential - Parameter Set single' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Disable-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            Disable-IAMAPICredential -ClientID xfz2n5d43mogkdim -CredentialID 14111 
        }
    }

    Context 'Remove-IAMAPICredential - Parameter Set single' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IAM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-IAMAPICredential.json"
                return $Response | ConvertFrom-Json
            }
            Remove-IAMAPICredential -ClientID xfz2n5d43mogkdim -CredentialID 14111 
        }
    }
}

