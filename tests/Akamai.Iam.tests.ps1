Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.IAM/Akamai.IAM.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContract
$Script:TestGroupID = $env:PesterGroupID
$Script:TestUIIdentityID = $env:PesterIAMUIID
$Script:TestNewGroupName = 'powershell-temp'
$Script:TestNewRoleName = 'akamaipowershell-testing'
$Script:TestNewRoleBody = @{
    "grantedRoles"    = @()
    "roleDescription" = "Test role for PowerShell pester testing."
    "roleName"        = $TestNewRoleName
}
$Script:TestPropertyID = $env:PesterAssetID
$Script:TestUsername = $env:PesterIAMUsername
$Script:TestExpirationDate = Get-Date ((Get-Date).ToUniversalTime().AddMinutes(60)) -Format 'yyyy-MM-ddTHH:mm:ss.000Z'
$Script:TestCredentialBody = @{
    'expiresOn'   = $TestExpirationDate
    'status'      = 'ACTIVE'
    'description' = 'Testing Pester update'
}
$Script:TestNewUserBody = '{
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
$Script:TestNewUserObj = ConvertFrom-Json $TestNewUserBody
$Script:CurrentPassword = 'This is the current password' | ConvertTo-SecureString -AsPlainText -Force
$Script:NewPassword = 'This is the new password' | ConvertTo-SecureString -AsPlainText -Force
$Script:TestUserNotificationsJSON = '{
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
$Script:TestUserNotificationsObj = ConvertFrom-Json $Script:TestUserNotificationsJSON
$Script:TestAvailableCPCodesJSON = '{
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
$Script:TestAPIClientJSON = @"
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
$Script:TestAPIClientObj = ConvertFrom-Json $Script:TestAPIClientJSON
$Script:TestAPIClientName = 'akamaipowershell_testclient'


Describe 'Safe Akamai.IAM Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 IAMGrantableRole                  
    #------------------------------------------------

    ### Get-IAMGrantableRole
    $Script:GetIAMGrantableRole = Get-IAMGrantableRole -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMGrantableRole returns the correct data' {
        $GetIAMGrantableRole[0].grantedRoleId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUser                  
    #------------------------------------------------

    ### Get-IAMUser - Parameter Set 'all'
    $Script:GetIAMUserAll = Get-IAMUser -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUser (all) returns the correct data' {
        $GetIAMUserAll[0].uiIdentityId | Should -Not -BeNullOrEmpty
    }

    ### Get-IAMUser - Parameter Set 'single'
    $Script:GetIAMUser = Get-IAMUser -UIIdentityID $TestUIIdentityID -Actions -AuthGrants -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUser (single) returns the correct data' {
        $GetIAMUser.uiIdentityId | Should -Be $TestUIIdentityID
    }

    ### Set-IAMUser by parameter
    $Script:SetIAMUserByParam = Set-IAMUser -Body $GetIAMUser -UIIdentityID $TestUIIdentityID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMUser (single) by param returns the correct data' {
        $SetIAMUserByParam.uiIdentityId | Should -Be $TestUIIdentityID
    }

    ### Set-IAMUser by pipeline
    $Script:SetIAMUserByPipeline = $GetIAMUser | Set-IAMUser -UIIdentityID $TestUIIdentityID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMUser (single) by pipeline returns the correct data' {
        $SetIAMUserByPipeline.uiIdentityId | Should -Be $TestUIIdentityID
    }

    ### Lock-IAMUser
    it 'Lock-IAMUser returns the correct data' {
        { Lock-IAMUser -UIIdentityID $TestUIIdentityID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Unlock-IAMUser
    it 'Unlock-IAMUser returns the correct data' {
        { Unlock-IAMUser -UIIdentityID $TestUIIdentityID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Set-IAMUserGroupAndRole by parameter
    $Script:SetIAMUserGroupAndRoleByParam = Set-IAMUserGroupAndRole -Body $GetIAMUser.authGrants -UiIdentityID $TestUIIdentityID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMUserGroupAndRole (others) by param returns the correct data' {
        $SetIAMUserGroupAndRoleByParam[0].groupId | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMUserGroupAndRole by pipeline
    $Script:SetIAMUserGroupAndRoleByPipeline = $GetIAMUser.authGrants | Set-IAMUserGroupAndRole -UiIdentityID $TestUIIdentityID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMUserGroupAndRole (others) by pipeline returns the correct data' {
        $SetIAMUserGroupAndRoleByPipeline[0].groupId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMGroup                  
    #------------------------------------------------

    ### New-IAMGroup
    $Script:NewIAMGroup = New-IAMGroup -GroupName $TestNewGroupName -ParentGroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-IAMGroup returns the correct data' {
        $NewIAMGroup.groupName | Should -Be $TestNewGroupName
    }

    ### Get-IAMGroup - All
    $Script:GetIAMGroupAll = Get-IAMGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMGroup returns the correct data' {
        $GetIAMGroupAll[0].groupId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-IAMGroup - Single
    $Script:GetIAMGroupSingle = Get-IAMGroup -GroupID $NewIAMGroup.groupId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMGroup returns the correct data' {
        $GetIAMGroupSingle.groupId | Should -Be $NewIAMGroup.groupId
    }

    ### Set-IAMGroup
    $Script:SetIAMGroup = Set-IAMGroup -GroupID $NewIAMGroup.groupId -GroupName $TestNewGroupName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMGroup returns the correct data' {
        $SetIAMGroup.groupName | Should -Be $TestNewGroupName
    }

    ### Move-IAMGroup
    it 'Move-IAMGroup throws no errors' {
        { Move-IAMGroup -DestinationGroupID $TestGroupID -SourceGroupID $NewIAMGroup.groupId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Remove-IAMGroup
    it 'Remove-IAMGroup throws no errors' {
        { Remove-IAMGroup -GroupID $NewIAMGroup.groupId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 IAMRole                  
    #------------------------------------------------

    ### New-IAMRole by parameter
    $TestNewRoleBody.grantedRoles += $GetIAMGrantableRole[0] | Select-Object grantedRoleId
    $Script:NewIAMRoleByParam = New-IAMRole -Body $TestNewRoleBody -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-IAMRole (self) by param returns the correct data' {
        $NewIAMRoleByParam.roleName | Should -Be $TestNewRoleName
    }

    ### New-IAMRole by pipeline
    $TestNewRoleBody.roleName += '-Pipeline'
    $Script:NewIAMRoleByPipeline = $TestNewRoleBody | New-IAMRole -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-IAMRole (self) by pipeline returns the correct data' {
        $NewIAMRoleByPipeline.roleName | Should -Be "$TestNewRoleName-Pipeline"
    }

    ### Get-IAMRole - Parameter Set 'single'
    $Script:GetIAMRole = Get-IAMRole -RoleID $NewIAMRoleByParam.roleId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMRole (single) returns the correct data' {
        $GetIAMRole.roleName | Should -Be $TestNewRoleName
    }

    ### Get-IAMRole - Parameter Set 'all'
    $Script:GetIAMRoleAll = Get-IAMRole -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMRole (all) returns the correct data' {
        $GetIAMRoleAll[0].roleName | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMRole by parameter
    $Script:SetIAMRoleByParam = Set-IAMRole -Body $NewIAMRoleByParam -RoleID $NewIAMRoleByParam.roleId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMRole (all) by param returns the correct data' {
        $SetIAMRoleByParam.roleName | Should -Be $TestNewRoleName
    }

    ### Set-IAMRole by pipeline
    $Script:SetIAMRoleByPipeline = $NewIAMRoleByParam | Set-IAMRole -RoleID $NewIAMRoleByParam.roleId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMRole (all) by pipeline returns the correct data' {
        $SetIAMRoleByPipeline.roleName | Should -Be $TestNewRoleName
    }

    ### Remove-IAMRole
    it 'Remove-IAMRole returns the correct data' {
        { Remove-IAMRole -RoleID $NewIAMRoleByParam.roleId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
        { Remove-IAMRole -RoleID $NewIAMRoleByPipeline.roleId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 IAMProperty                  
    #------------------------------------------------

    ### Get-IAMProperty - All
    $Script:GetIAMPropertyAll = Get-IAMProperty -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMProperty returns the correct data' {
        $GetIAMPropertyAll[0].propertyId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-IAMProperty - Single
    $Script:GetIAMPropertySingle = Get-IAMProperty -GroupID $TestGroupID -PropertyID $TestPropertyID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMProperty returns the correct data' {
        $GetIAMPropertySingle.arlConfigFile | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMPropertyResources                  
    #------------------------------------------------

    ### Get-IAMPropertyResources
    $Script:GetIAMPropertyResources = Get-IAMPropertyResources -GroupID $TestGroupID -PropertyID $TestPropertyID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMPropertyResources returns the correct data' {
        $GetIAMPropertyResources[0].resourceId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMPropertyUsers                  
    #------------------------------------------------

    ### Get-IAMPropertyUsers
    $Script:GetIAMPropertyUsers = Get-IAMPropertyUsers -PropertyID $TestPropertyID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMPropertyUsers returns the correct data' {
        $GetIAMPropertyUsers[0].uiIdentityId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMAPIClient                  
    #------------------------------------------------

    ### New-IAMAPIClient by parameter
    $Script:NewIAMAPIClientByParam = New-IAMAPIClient -Body $Script:TestAPIClientJSON -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-IAMAPIClient (self) by param returns the correct data' {
        $NewIAMAPIClientByParam.clientName | Should -Be $TestAPIClientName
    }

    ### New-IAMAPIClient by pipeline
    $TestAPIClientObj.clientName += "-pipeline"
    $Script:NewIAMAPIClientByPipeline = ($TestAPIClientObj | New-IAMAPIClient -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-IAMAPIClient (self) by pipeline returns the correct data' {
        $NewIAMAPIClientByPipeline.clientName | Should -Be "$TestAPIClientName-pipeline"
    }

    ### Get-IAMAPIClient, all
    $Script:GetIAMAPIClientAll = Get-IAMAPIClient -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAPIClient, all returns the correct data' {
        $GetIAMAPIClientAll[0].clientId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-IAMAPIClient, single
    $Script:GetIAMAPIClientSingle = Get-IAMAPIClient -ClientID $NewIAMAPIClientByParam.clientId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAPIClient, single returns the correct data' {
        $GetIAMAPIClientSingle.clientId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-IAMAPIClient, self
    $Script:GetIAMAPIClientSelf = Get-IAMAPIClient -ClientID self -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAPIClient, self returns the correct data' {
        $GetIAMAPIClientSelf.clientId | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMAPIClient - Parameter Set 'single', by parameter
    $Script:SetIAMAPIClientSingleByParam = Set-IAMAPIClient -Body $NewIAMAPIClientByParam -ClientID $NewIAMAPIClientByParam.clientId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMAPIClient (single) by param returns the correct data' {
        $SetIAMAPIClientSingleByParam.clientId | Should -Be $NewIAMAPIClientByParam.clientId
    }

    ### Set-IAMAPIClient - Parameter Set 'single', by pipeline
    $Script:SetIAMAPIClientSingleByPipeline = ($NewIAMAPIClientByParam | Set-IAMAPIClient -ClientID $NewIAMAPIClientByParam.clientId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-IAMAPIClient (single) by pipeline returns the correct data' {
        $SetIAMAPIClientSingleByPipeline.clientId | Should -Be $NewIAMAPIClientByParam.clientId
    }

    ### Set-IAMAPIClient - Parameter Set 'self', by parameter
    $Script:SetIAMAPIClientSelfByParam = Set-IAMAPIClient -Body $GetIAMAPIClientSelf -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMAPIClient (self) by param returns the correct data' {
        $SetIAMAPIClientSelfByParam.clientId | Should -Be $GetIAMAPIClientSelf.clientId
    }

    ### Set-IAMAPIClient - Parameter Set 'self', by pipeline
    $Script:SetIAMAPIClientSelfByPipeline = $GetIAMAPIClientSelf | Set-IAMAPIClient -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMAPIClient (self) by pipeline returns the correct data' {
        $SetIAMAPIClientSelfByPipeline.clientId | Should -Be $GetIAMAPIClientSelf.clientId
    }

    ### Lock-IAMAPIClient - Parameter Set 'single'
    $Script:LockIAMAPIClient = Lock-IAMAPIClient -ClientID $NewIAMAPIClientByParam.clientId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Lock-IAMAPIClient (single) returns the correct data' {
        $LockIAMAPIClient.isLocked | Should -Be $true
    }

    ### Unlock-IAMAPIClient
    $Script:UnlockIAMAPIClient = Unlock-IAMAPIClient -ClientID $NewIAMAPIClientByParam.clientId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Unlock-IAMAPIClient returns the correct data' {
        $UnlockIAMAPIClient.isLocked | Should -Be $false
    }

    #------------------------------------------------
    #                 IAMAPICredential                  
    #------------------------------------------------

    ### New-IAMAPICredential - Parameter Set 'self'
    $Script:NewIAMAPICredentialSelf = New-IAMAPICredential -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-IAMAPICredential (self) returns the correct data' {
        $NewIAMAPICredentialSelf.credentialId | Should -Not -BeNullOrEmpty
    }

    ### Get-IAMAPICredential - Parameter Set 'self' by an ID
    $Script:GetIAMAPICredentialSelfSingle = Get-IAMAPICredential -CredentialID $NewIAMAPICredentialSelf.credentialId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAPICredential (self) returns the correct data' {
        $GetIAMAPICredentialSelfSingle.credentialId | Should -Be $NewIAMAPICredentialSelf.credentialId
    }

    ### Get-IAMAPICredential - Parameter Set 'self' gets all 
    $Script:GetIAMAPICredentialSelf = Get-IAMAPICredential -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAPICredential (self-gets-all) returns the correct data' {
        $GetIAMAPICredentialSelf[0].credentialId | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMAPICredential - Parameter Set 'self', by param
    $Script:SetIAMAPICredentialSelfByParam = Set-IAMAPICredential -CredentialID $NewIAMAPICredentialSelf.credentialId -Status ACTIVE -ExpiresOn $TestExpirationDate -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMAPICredential (self) by param returns the correct data' {
        $SetIAMAPICredentialSelfByParam.expiresOn | Should -Not -BeNullOrEmpty
    }
    
    ### Set-IAMAPICredential - Parameter Set 'self', by pipeline
    $Script:SetIAMAPICredentialSelfByPipeline = ($TestCredentialBody | Set-IAMAPICredential -CredentialID $NewIAMAPICredentialSelf.credentialId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-IAMAPICredential (self) by pipeline returns the correct data' {
        $SetIAMAPICredentialSelfByPipeline.expiresOn | Should -Not -BeNullOrEmpty
    }

    ### Disable-IAMAPICredential - Parameter Set 'self'
    it 'Disable-IAMAPICredential (self) does not throw any errors' {
        { Disable-IAMAPICredential -CredentialID $NewIAMAPICredentialSelf.credentialId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Remove-IAMAPICredential - Parameter Set 'self'
    it 'Remove-IAMAPICredential (self) throws no errors' {
        { Remove-IAMAPICredential -CredentialID $NewIAMAPICredentialSelf.credentialId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    

    #------------------------------------------------
    #                 IAMAccessibleGroups                  
    #------------------------------------------------

    ### Get-IAMAccessibleGroups
    $Script:GetIAMAccessibleGroups = Get-IAMAccessibleGroups -Username $TestUsername -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAccessibleGroups returns the correct data' {
        $GetIAMAccessibleGroups[0].groupId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMAdminContactTypes                  
    #------------------------------------------------

    ### Get-IAMAdminContactTypes
    $Script:GetIAMAdminContactTypes = Get-IAMAdminContactTypes -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAdminContactTypes returns the correct data' {
        $GetIAMAdminContactTypes.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMUserContactTypes                  
    #------------------------------------------------

    ### Get-IAMUserContactTypes
    $Script:GetIAMUserContactTypes = Get-IAMUserContactTypes -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUserContactTypes returns the correct data' {
        $GetIAMUserContactTypes.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMAdminCountries                  
    #------------------------------------------------

    ### Get-IAMAdminCountries
    $Script:GetIAMAdminCountries = Get-IAMAdminCountries -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAdminCountries returns the correct data' {
        $GetIAMAdminCountries.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMUserCountries                  
    #------------------------------------------------

    ### Get-IAMUserCountries
    $Script:GetIAMUserCountries = Get-IAMUserCountries -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUserCountries returns the correct data' {
        $GetIAMUserCountries.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMAdminLanguages                  
    #------------------------------------------------

    ### Get-IAMAdminLanguages
    $Script:GetIAMAdminLanguages = Get-IAMAdminLanguages -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAdminLanguages returns the correct data' {
        $GetIAMAdminLanguages.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMUserLanguages                  
    #------------------------------------------------

    ### Get-IAMUserLanguages
    $Script:GetIAMUserLanguages = Get-IAMUserLanguages -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUserLanguages returns the correct data' {
        $GetIAMUserLanguages.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMAdminPasswordPolicy                  
    #------------------------------------------------

    ### Get-IAMAdminPasswordPolicy
    $Script:GetIAMAdminPasswordPolicy = Get-IAMAdminPasswordPolicy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAdminPasswordPolicy returns the correct data' {
        $GetIAMAdminPasswordPolicy.minLength | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUserPasswordPolicy                  
    #------------------------------------------------

    ### Get-IAMUserPasswordPolicy
    $Script:GetIAMUserPasswordPolicy = Get-IAMUserPasswordPolicy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUserPasswordPolicy returns the correct data' {
        $GetIAMUserPasswordPolicy.minLength | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMAdminProducts                  
    #------------------------------------------------

    ### Get-IAMAdminProducts
    $Script:GetIAMAdminProducts = Get-IAMAdminProducts -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAdminProducts returns the correct data' {
        $GetIAMAdminProducts.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMUserProducts                  
    #------------------------------------------------

    ### Get-IAMUserProducts
    $Script:GetIAMUserProducts = Get-IAMUserProducts -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUserProducts returns the correct data' {
        $GetIAMUserProducts.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMAdminStates                  
    #------------------------------------------------

    ### Get-IAMAdminStates
    $Script:GetIAMAdminStates = Get-IAMAdminStates -Country USA -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAdminStates returns the correct data' {
        $GetIAMAdminStates.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMUserStates                  
    #------------------------------------------------

    ### Get-IAMUserStates
    $Script:GetIAMUserStates = Get-IAMUserStates -Country USA -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUserStates returns the correct data' {
        $GetIAMUserStates.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 IAMAdminTimeoutPolicy                  
    #------------------------------------------------

    ### Get-IAMAdminTimeoutPolicy
    $Script:GetIAMAdminTimeoutPolicy = Get-IAMAdminTimeoutPolicy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAdminTimeoutPolicy returns the correct data' {
        $GetIAMAdminTimeoutPolicy[0].value | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUserTimeoutPolicy                  
    #------------------------------------------------

    ### Get-IAMUserTimeoutPolicy
    $Script:GetIAMUserTimeoutPolicy = Get-IAMUserTimeoutPolicy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUserTimeoutPolicy returns the correct data' {
        $GetIAMUserTimeoutPolicy[0].value | Should -Not -BeNullOrEmpty
    }
    
    #------------------------------------------------
    #                 IAMAdminTimeZones                  
    #------------------------------------------------
    
    ### Get-IAMAdminTimeZones
    $Script:GetIAMAdminTimeZones = Get-IAMAdminTimeZones -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAdminTimeZones returns the correct data' {
        $GetIAMAdminTimeZones[0].timezone | Should -Not -BeNullOrEmpty
    }
    
    #------------------------------------------------
    #                 IAMUserTimeZones                  
    #------------------------------------------------

    ### Get-IAMUserTimeZones
    $Script:GetIAMUserTimeZones = Get-IAMUserTimeZones -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMUserTimeZones returns the correct data' {
        $GetIAMUserTimeZones[0].timezone | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMAllowedAPIs                  
    #------------------------------------------------

    ### Get-IAMAllowedAPIs
    $Script:GetIAMAllowedAPIs = Get-IAMAllowedAPIs -Username $TestUsername -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAllowedAPIs returns the correct data' {
        $GetIAMAllowedAPIs[0].apiId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMAuthorizedUsers                  
    #------------------------------------------------

    ### Get-IAMAuthorizedUsers
    $Script:GetIAMAuthorizedUsers = Get-IAMAuthorizedUsers -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-IAMAuthorizedUsers returns the correct data' {
        $GetIAMAuthorizedUsers[0].userName | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUserNotifications                  
    #------------------------------------------------

    ### Set-IAMUserNotifications, single by parameter
    $Script:SetIAMUserNotificationsSingleByParam = Set-IAMUserNotifications -Body $Script:TestUserNotificationsJSON -UIIdentityID $TestUIIdentityID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMUserNotifications (single) by param returns the correct data' {
        $SetIAMUserNotificationsSingleByParam.enableEmailNotifications | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMUserNotifications by pipeline
    $Script:SetIAMUserNotificationsSingleByPipeline = $Script:TestUserNotificationsObj | Set-IAMUserNotifications -UIIdentityID $TestUIIdentityID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-IAMUserNotifications (single) by pipeline returns the correct data' {
        $SetIAMUserNotificationsSingleByPipeline.enableEmailNotifications | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 Removals
    #------------------------------------------------

    ### Remove-IAMAPIClient - Parameter Set 'single'
    it 'Remove-IAMAPIClient (single) returns the correct data' {
        {
            Remove-IAMAPIClient -ClientID $NewIAMAPIClientByParam.clientId -EdgeRCFile $EdgeRCFile -Section $Section
            Remove-IAMAPIClient -ClientID $NewIAMAPIClientByPipeline.clientId -EdgeRCFile $EdgeRCFile -Section $Section
        } | Should -Not -Throw
    }


    AfterAll {
        
    }

}

Describe 'UnSafe Akamai.IAM Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 AccountSwitchKey                  
    #------------------------------------------------

    ### Get-AccountSwitchKey
    $Script:GetAccountSwitchKey = Get-AccountSwitchKey -Search 'Akamai' -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-AccountSwitchKey returns the correct data' {
        $GetAccountSwitchKey.accountSwitchKey | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUser                  
    #------------------------------------------------

    ### New-IAMUser by parameter
    $Script:NewIAMUserByParam = New-IAMUser -Body $TestNewUserBody -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-IAMUser (all) by param returns the correct data' {
        $NewIAMUserByParam.uiIdentityId | Should -Not -BeNullOrEmpty
    }

    ### New-IAMUser by pipeline
    $Script:NewIAMUserByPipeline = $TestNewUserObj | New-IAMUser -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-IAMUser (all) by pipeline returns the correct data' {
        $NewIAMUserByPipeline.uiIdentityId | Should -Not -BeNullOrEmpty
    }

    ### Remove-IAMUser
    it 'Remove-IAMUser does not throw' {
        { Remove-IAMUser -UIIdentityID $TestUIIdentityID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }


    ### Get-IAMGroupMoveAffectedUsers
    $Script:GetIAMGroupMoveAffectedUsers = Get-IAMGroupMoveAffectedUsers -DestinationGroupID 22222 -SourceGroupID 11111 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IAMGroupMoveAffectedUsers returns the correct data' {
        $GetIAMGroupMoveAffectedUsers[0].uiIdentityId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMIPAllowList                  
    #------------------------------------------------

    ### Disable-IAMIPAllowList
    it 'Disable-IAMIPAllowList throws no errors' {
        { Disable-IAMIPAllowList -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Enable-IAMIPAllowList
    it 'Enable-IAMIPAllowList throws no errors' {
        { Enable-IAMIPAllowList -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 IAMIPAllowListStatus                  
    #------------------------------------------------

    ### Get-IAMIPAllowListStatus
    $Script:GetIAMIPAllowListStatus = Get-IAMIPAllowListStatus -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IAMIPAllowListStatus returns the correct data' {
        $GetIAMIPAllowListStatus.enabled | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUserProfile                  
    #------------------------------------------------

    ### Get-IAMUserProfile
    $Script:GetIAMUserProfile = Get-IAMUserProfile -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IAMUserProfile returns the correct data' {
        $GetIAMUserProfile.firstName | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMUserProfile by parameter
    $Script:SetIAMUserProfileByParam = Set-IAMUserProfile -Body $GetIAMUserProfile -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-IAMUserProfile (single) by param returns the correct data' {
        $SetIAMUserProfileByParam.uiIdentityId | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMUserProfile by pipeline
    $Script:SetIAMUserProfileByPipeline = $GetIAMUserProfile | Set-IAMUserProfile -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-IAMUserProfile (single) by pipeline returns the correct data' {
        $SetIAMUserProfileByPipeline.uiIdentityId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUserPassword                  
    #------------------------------------------------

    ### Set-IAMUserPassword - Parameter Set 'my'
    it 'Set-IAMUserPassword (my) throws no errors' {
        { Set-IAMUserPassword -CurrentPassword $CurrentPassword -NewPassword $NewPassword -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Set-IAMUserPassword - Parameter Set 'others'
    it 'Set-IAMUserPassword (others) throws no errors' {
        { Set-IAMUserPassword -NewPassword $NewPassword -UIIdentityID $TestUIIdentityID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -BeNullOrEmpty
    }

    ### Reset-IAMUserPassword
    it 'Reset-IAMUserPassword throws no errors' {
        { Reset-IAMUserPassword -UIIdentityID $TestUIIdentityID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMPropertyUsers                  
    #------------------------------------------------

    ## Block-IAMPropertyUsers by parameter
    $Script:BlockIAMPropertyUsersByParam = Block-IAMPropertyUsers -PropertyID $TestPropertyID -UIIdentityID $TestUIIdentityID -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Block-IAMPropertyUsers by param returns the correct data' {
        $BlockIAMPropertyUsersByParam[0].uiIdentityId | Should -Not -BeNullOrEmpty
    }

    ### Block-IAMPropertyUsers by pipeline
    $Script:BlockIAMPropertyUsersByPipeline = $TestUIIdentityID | Block-IAMPropertyUsers -PropertyID $TestPropertyID -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Block-IAMPropertyUsers by pipeline returns the correct data' {
        $BlockIAMPropertyUsersByPipeline[0].uiIdentityId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUserBlockedProperties                  
    #------------------------------------------------

    ### Get-IAMUserBlockedProperties
    $Script:GetIAMUserBlockedProperties = Get-IAMUserBlockedProperties -GroupID $TestGroupID -UIIdentityID $TestUIIdentityID -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IAMUserBlockedProperties returns the correct data' {
        $GetIAMUserBlockedProperties[0] | Should -Match '^[\d]+$'
    }

    ### Set-IAMUserBlockedProperties
    $Script:SetIAMUserBlockedProperties = Set-IAMUserBlockedProperties -Body @(123456, 234567) -GroupID $TestGroupID -UIIdentityID $TestUIIdentityID -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-IAMUserBlockedProperties returns the correct data' {
        $SetIAMUserBlockedProperties[0] | Should -Match '^[\d]+$'
    }

    #------------------------------------------------
    #                 IAMUser                  
    #------------------------------------------------

    ### Set-IAMUserMFA - My
    it 'Set-IAMUserMFA returns the correct data' {
        { Set-IAMUserMFA -Value MFA -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Set-IAMUserMFA - Other
    it 'Set-IAMUserMFA returns the correct data' {
        { Set-IAMUserMFA -Value MFA -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Reset-IAMUserMFA - My
    it 'Reset-IAMUserMFA returns the correct data' {
        { Reset-IAMUserMFA -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Reset-IAMUserMFA - Other
    it 'Reset-IAMUserMFA returns the correct data' {
        { Reset-IAMUserMFA -UIIdentityID $TestUIIdentityID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 IAMProperty                  
    #------------------------------------------------

    ### Move-IAMProperty
    it 'Move-IAMProperty throws no errors' {
        { Move-IAMProperty -DestinationGroupID 11111 -PropertyID 12345678 -SourceGroupID 22222 -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 IAMCIDRBlock                  
    #------------------------------------------------

    ### New-IAMCIDRBlock
    $Script:NewIAMCIDRBlock = New-IAMCIDRBlock -CIDRBlock 1.0.0.0/24 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-IAMCIDRBlock returns the correct data' {
        $NewIAMCIDRBlock.cidrBlock | Should -Not -BeNullOrEmpty
    }

    ### Get-IAMCIDRBlock, single
    $Script:GetIAMCIDRBlockSingle = Get-IAMCIDRBlock -CIDRBlockID 1234 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IAMCIDRBlock returns the correct data' {
        $GetIAMCIDRBlockSingle.cidrBlock | Should -Not -BeNullOrEmpty
    }
    
    ### Get-IAMCIDRBlock, all
    $Script:GetIAMCIDRBlockAll = Get-IAMCIDRBlock -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IAMCIDRBlock returns the correct data' {
        $GetIAMCIDRBlockAll[0].cidrBlock | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMCIDRBlock
    $Script:SetIAMCIDRBlock = Set-IAMCIDRBlock -CIDRBlockID 1234 -CIDRBlock 1.0.0.0/24 -Comments 'Testing' -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-IAMCIDRBlock returns the correct data' {
        $SetIAMCIDRBlock.cidrBlock | Should -Not -BeNullOrEmpty
    }

    ### Test-IAMCIDRBlock
    it 'Test-IAMCIDRBlock throws no errors' {
        { Test-IAMCIDRBlock -CIDRBlock 1.0.0.0/24 -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -BeNullOrEmpty
    }

    ### Remove-IAMCIDRBlock
    it 'Remove-IAMCIDRBlock throws no errors' {
        { Remove-IAMCIDRBlock -CIDRBlockID 1234 -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMUserNotifications                  
    #------------------------------------------------

    ### Set-IAMUserNotifications, self by parameter
    $Script:SetIAMUserNotificationsSelfByParam = Set-IAMUserNotifications -Body $Script:TestUserNotificationsJSON -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-IAMUserNotifications (single) by param returns the correct data' {
        $SetIAMUserNotificationsSelfByParam.enableEmailNotifications | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMUserNotifications, self by pipeline
    $Script:SetIAMUserNotificationsSelfByPipeline = $Script:TestUserNotificationsObj | Set-IAMUserNotifications -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-IAMUserNotifications (single) by pipeline returns the correct data' {
        $SetIAMUserNotificationsSelfByPipeline.enableEmailNotifications | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMAllowedCPCodes                  
    #------------------------------------------------

    ### Get-IAMAllowedCPCodes
    $Script:GetIAMAllowedCPCodes = Get-IAMAllowedCPCodes -Body $Script:TestAvailableCPCodesJSON -Username $TestUsername -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IAMAllowedCPCodes returns the correct data' {
        $GetIAMAllowedCPCodes[0].name | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 IAMAPIClient                  
    #------------------------------------------------

    ### Remove-IAMAPICredential - Parameter Set 'self'
    it 'Remove-IAMAPICredential (self) does not throw any errors' {
        { Remove-IAMAPICredential -CredentialID 12345 -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Lock-IAMAPIClient - Parameter Set 'self'
    $Script:LockIAMAPIClient = Lock-IAMAPIClient -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Lock-IAMAPIClient (self) returns the correct data' {
        $LockIAMAPIClient.isLocked | Should -Be $true
    }

    ### Remove-IAMAPIClient - Parameter Set 'self'
    it 'Remove-IAMAPIClient (self) throws no errors' {
        { Remove-IAMAPIClient -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 IAMAPICredential                  
    #------------------------------------------------

    ### New-IAMAPICredential - Parameter Set 'single'
    $Script:NewIAMAPICredentialSingle = New-IAMAPICredential -ClientID $NewIAMAPIClientByParam.clientId -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-IAMAPICredential (single) returns the correct data' {
        $NewIAMAPICredentialSingle.credentialId | Should -Not -BeNullOrEmpty
    }

    ### Get-IAMAPICredential - Parameter Set 'single'
    $Script:GetIAMAPICredentialSingle = Get-IAMAPICredential -ClientID $NewIAMAPIClientByParam.clientId -CredentialID $NewIAMAPICredentialSingle.credentialId -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IAMAPICredential (single) returns the correct data' {
        $GetIAMAPICredentialSingle.credentialId | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMAPICredential - Parameter Set 'single', by parameter
    $Script:SetIAMAPICredentialSingleByParam = Set-IAMAPICredential -Body $GetIAMAPICredentialSingle -ClientID $NewIAMAPIClientByParam.clientId -CredentialID $NewIAMAPICredentialSingle.credentialId -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-IAMAPICredential (single) by param returns the correct data' {
        $SetIAMAPICredentialSingleByParam.expiresOn | Should -Not -BeNullOrEmpty
    }

    ### Set-IAMAPICredential - Parameter Set 'single', by pipeline
    $Script:SetIAMAPICredentialSingleByPipeline = ($GetIAMAPICredentialSingle | Set-IAMAPICredential -ClientID $NewIAMAPIClientByParam.clientId -CredentialID $NewIAMAPICredentialSingle.credentialId -EdgeRCFile $SafeEdgeRCFile -Section $Section)
    it 'Set-IAMAPICredential (single) by pipeline returns the correct data' {
        $SetIAMAPICredentialSingleByPipeline.expiresOn | Should -Not -BeNullOrEmpty
    }

    ### Disable-IAMAPICredential - Parameter Set 'single'
    it 'Disable-IAMAPICredential (single) throws no errors' {
        { Disable-IAMAPICredential -ClientID $NewIAMAPIClientByParam.clientId -CredentialID $NewIAMAPICredentialSingle.credentialId -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Remove-IAMAPICredential - Parameter Set 'single'
    it 'Remove-IAMAPICredential (single) throws no errors' {
        { Remove-IAMAPICredential -ClientID $NewIAMAPIClientByParam.clientId -CredentialID $NewIAMAPICredentialSingle.credentialId -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }


    AfterAll {
        
    }

}