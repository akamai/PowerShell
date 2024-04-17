Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Netstorage/Akamai.Netstorage.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:TestStorageGroupID = $env:PesterStorageGroupID
$Script:TestUploadAccountID = 'akamaipowershell'
$Script:TestFTPKey = 'abcdefg1234'
$Script:TestRSyncKey = 'abcdefg1234'
$Script:TestSSHKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQaxsF1OBwZbN/6G2D3P/QritNfPYizc4gJyry3SBQT6lfHojQbjOTG2+3j5/Gx5ve5o05h3+TzECihXHUj2jbc19HzdBs+jPafcJj+w9LAupcKi/WkDG/3GQDrp1zXMnPg/n+QrxeaqZpAawN6bDLpnAnfrmseb1GxL9cKwzNYR9A4uVm5JQaHD0iNGni09SNPdpmJrYLw9aw/AQaMtA35w7eIK+5h15wobW7+A00jVpqBfAfUJByzFueI+uj9ZVJKWN+MOUg6QqppVOjqYKRoWl3rcXOGPBmAvrk5YwseRX3f231ItIY7NsCaWLYpVVcISFICQjTZIUr3GfNf5D9 pester@akamai.com'
$Script:TestCPCodeID = $env:PesterNSCpCode
$Script:TestRuleSetID = $env:PesterRuleSetID
$Script:TestRuleSet = @"
{
    "name": "akamaipowershell",
    "description": "Testing the powershell module",
    "contractId": "$env:PesterContractID",
    "allowRest": true,
    "uploadAccounts": []
}
"@
$Script:TestSnapshot = @"
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
$Script:TestGroupJSON = @"
{"contractId":"$env:PesterContractID","storageGroupId":$env:PesterStorageGroupID,"storageGroupName":"akamaipowershell","storageGroupType":"OBJECTSTORE","storageGroupPurpose":"NETSTORAGE","domainPrefix":"akamaipowershell","asperaEnabled":false,"pciEnabled":false,"estimatedUsageGB":0.01,"allowEdit":true,"provisionStatus":"PROVISIONED","cpcodes":[{"cpcodeId":$env:PesterNSCpCode,"downloadSecurity":"ALL_EDGE_SERVERS","useSsl":false,"serveFromZip":false,"sendHash":false,"quickDelete":true,"numberOfFiles":2,"numberOfBytes":10,"lastChangesPropagated":true,"requestUriCaseConversion":"NO_CONVERSION","queryStringConversion":{"queryStringConversionMode":"STRIP_ALL_INCOMING_QUERY"},"pathCheckAndConversion":"DO_NOT_CHECK_PATHS","encodingConfig":{"enforceEncoding":false,"encoding":"ISO_8859_1"},"dirListing":{"maxListSize":0,"searchOn404":"DO_NOT_SEARCH"},"ageDeletions":[{"ageDeletionDirectory":"/$env:PesterNSCpCode/purge","ageDeletionDays":10.0,"ageDeletionSizeBytes":10000000000.0,"ageDeletionRecursivePurge":false}]}],"zones":[{"zoneName":"europe","noCapacityAction":"SPILL_OUTSIDE","allowUpload":"YES","allowDownload":"YES","lastModifiedBy":"okenobi","lastModifiedDate":"2022-07-15T10:43:33Z"},{"zoneName":"global","noCapacityAction":"SPILL_OUTSIDE","allowUpload":"YES","allowDownload":"YES","lastModifiedBy":"okenobi","lastModifiedDate":"2022-07-15T10:43:33Z"}]}
"@
$Script:TestGroup = ConvertFrom-Json -InputObject $TestGroupJSON
$Script:TestUploadAccountJSON = @"
{"uploadAccountId":"akamaipowershell","storageGroupId":$env:PesterStorageGroupID,"storageGroupName":"akamaipowershell","storageGroupType":"OBJECTSTORE","uploadAccountStatus":"ACTIVE","isEditable":true,"isVisible":true,"ftpEnabled":false,"sshEnabled":true,"rsyncEnabled":false,"asperaEnabled":false,"eventSubEnabled":false,"hasFileManagerAccess":false,"hasHttpApiAccess":true,"hasPendingPropagation":true,"email":"akamaipowershell@example.com","keys":{"ssh":[],"g2o":[]},"accessConfig":{"hasReadOnlyAccess":false,"cpcodes":[{"cpcodeId":$env:PesterNSCpCode,"storageGroup":{"storageGroupId":$env:PesterStorageGroupID,"storageGroupName":"akamaipowershell"}}]},"technicalContactInfo":{"newTechnicalContact":{"firstName":"Obi-Wan","lastName":"Kenobi","email":"okenobi@akamai.com","phone":{"countryCode":"+44","areaCode":"203","number":"7879408"}}},"enableZipFileAutoIndex":false}
"@
$Script:TestUploadAccount = ConvertFrom-Json -InputObject $TestUploadAccountJSON
$Script:TestOutputDirectory = './tests'
$Script:TestDomainName = 'akamaipowershell-nsu.akamaihd.net'
$Script:TestAuthSection = 'new-section'

Describe 'Safe Akamai.Netstorage Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 NetstorageGroup                  
    #------------------------------------------------

    ### Get-NetstorageGroup - Parameter Set 'all'
    $Script:GetNetstorageGroupAll = Get-NetstorageGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageGroup (all) returns the correct data' {
        $GetNetstorageGroupAll[0].storageGroupId | Should -Not -BeNullOrEmpty
    }

    ### Get-NetstorageGroup - Parameter Set 'single'
    $Script:GetNetstorageGroupSingle = Get-NetstorageGroup -StorageGroupID $TestStorageGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageGroup (single) returns the correct data' {
        $GetNetstorageGroupSingle.storageGroupId | Should -Be $TestStorageGroupID
    }

    #------------------------------------------------
    #                 NetstorageUploadAccount                  
    #------------------------------------------------

    ### Get-NetstorageUploadAccount (all)
    $Script:GetNetstorageUploadAccountAll = Get-NetstorageUploadAccount -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageUploadAccount (all) returns the correct data' {
        $GetNetstorageUploadAccountAll[0].uploadAccountId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-NetstorageUploadAccount (single)
    $Script:GetNetstorageUploadAccountSingle = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageUploadAccount (single) returns the correct data' {
        $GetNetstorageUploadAccountSingle.uploadAccountId | Should -Be $TestUploadAccountID
    }

    ### Set-NetstorageUploadAccount by parameter
    $Script:SetNetstorageUploadAccountByParam = Set-NetstorageUploadAccount -Body $GetNetstorageUploadAccountSingle -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-NetstorageUploadAccount by param returns the correct data' {
        $SetNetstorageUploadAccountByParam.uploadAccountId | Should -Be $TestUploadAccountID
    }

    ### Set-NetstorageUploadAccount by pipeline
    $Script:SetNetstorageUploadAccountByPipeline = ($GetNetstorageUploadAccountSingle | Set-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-NetstorageUploadAccount by pipeline returns the correct data' {
        $SetNetstorageUploadAccountByPipeline.uploadAccountId | Should -Be $TestUploadAccountID
    }

    ### Disable-NetstorageUploadAccount
    it 'Disable-NetstorageUploadAccount throws no errors' {
        { Disable-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Enable-NetstorageUploadAccount
    it 'Enable-NetstorageUploadAccount throws no errors' {
        { Enable-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #          NetstorageUploadAccountFTPKey
    #------------------------------------------------
    
    ### Add-NetstorageUploadAccountFTPKey
    Add-NetstorageUploadAccountFTPKey -Key $TestFTPKey -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    $Script:UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Add-NetstorageUploadAccountFTPKey returns the correct data' {
        $UploadAccount.keys.ftp[0].id | Should -Not -BeNullOrEmpty
    }

    ## Disable-NetstorageUploadAccountFTPKey
    it 'Disable-NetstorageUploadAccountFTPKey throws no errors' {
        { Disable-NetstorageUploadAccountFTPKey -Identity $UploadAccount.keys.ftp[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Enable-NetstorageUploadAccountFTPKey
    it 'Enable-NetstorageUploadAccountFTPKey throws no errors' {
        { Enable-NetstorageUploadAccountFTPKey -Identity $UploadAccount.keys.ftp[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Update-NetstorageUploadAccountFTPKey
    $Script:UpdateNetstorageUploadAccountFTPKey = Update-NetstorageUploadAccountFTPKey -Identity $UploadAccount.keys.ftp[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Update-NetstorageUploadAccountFTPKey returns the correct data' {
        $UpdateNetstorageUploadAccountFTPKey.message | Should -Not -BeNullOrEmpty
    }
    
    ### Set-NetstorageUploadAccountFTPKey
    it 'Set-NetstorageUploadAccountFTPKey throws no errors' {
        { Set-NetstorageUploadAccountFTPKey -Identity $UploadAccount.keys.ftp[0].id -UploadAccountID $TestUploadAccountID -Key $TestFTPKey -Comments 'Updating' -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Remove-NetstorageUploadAccountFTPKey
    it 'Remove-NetstorageUploadAccountFTPKey throws no errors' {
        # Re-retrieve upload account as key ID changes when updated. Obviously...
        $UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
        { 
            $UploadAccount.Keys.FTP | ForEach-Object {
                Remove-NetstorageUploadAccountFTPKey -Identity $_.id -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
            }
        } | Should -Not -Throw
    }

    #------------------------------------------------
    #        NetstorageUploadAccountRSyncKey
    #------------------------------------------------

    ## Add-NetstorageUploadAccountRSyncKey
    Add-NetstorageUploadAccountRSyncKey -Key $TestRsyncKey -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    $Script:UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Add-NetstorageUploadAccountRSyncKey returns the correct data' {
        $UploadAccount.keys.rsync[0].id | Should -Not -BeNullOrEmpty
    }
    
    ### Disable-NetstorageUploadAccountRSyncKey
    it 'Disable-NetstorageUploadAccountRSyncKey throws no errors' {
        { Disable-NetstorageUploadAccountRSyncKey -Identity $UploadAccount.keys.rsync[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Enable-NetstorageUploadAccountRSyncKey
    it 'Enable-NetstorageUploadAccountRSyncKey throws no errors' {
        { Enable-NetstorageUploadAccountRSyncKey -Identity $UploadAccount.keys.rsync[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Remove-NetstorageUploadAccountRSyncKey, single
    it 'Remove-NetstorageUploadAccountRSyncKey, single throws no errors' {
        { Remove-NetstorageUploadAccountRSyncKey -UploadAccountID $TestUploadAccountID -Identity $UploadAccount.keys.rsync[0].id -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Remove-NetstorageUploadAccountRSyncKey, all
    it 'Remove-NetstorageUploadAccountRSyncKey, all throws no errors' {
        { Remove-NetstorageUploadAccountRSyncKey -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 NetstorageUploadAccountSSHKey                  
    #------------------------------------------------

    ## Add-NetstorageUploadAccountSSHKey
    Add-NetstorageUploadAccountSSHKey -Key $TestSSHKey -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    $Script:UploadAccount = Get-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Add-NetstorageUploadAccountSSHKey returns the correct data' {
        $UploadAccount.keys.ssh[0].id | Should -Not -BeNullOrEmpty
    }

    ### Disable-NetstorageUploadAccountSSHKey
    it 'Disable-NetstorageUploadAccountSSHKey throws no errors' {
        { Disable-NetstorageUploadAccountSSHKey -Identity $UploadAccount.keys.ssh[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Enable-NetstorageUploadAccountSSHKey
    it 'Enable-NetstorageUploadAccountSSHKey throws no errors' {
        { Enable-NetstorageUploadAccountSSHKey -Identity $UploadAccount.keys.ssh[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw 
    }
    
    ### Enable-NetstorageUploadAccountSSHKey
    it 'Enable-NetstorageUploadAccountSSHKey throws no errors' {
        { Enable-NetstorageUploadAccountSSHKey -Identity $UploadAccount.keys.ssh[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }
    
    ### Remove-NetstorageUploadAccountSSHKey
    it 'Remove-NetstorageUploadAccountSSHKey throws no errors' {
        { Remove-NetstorageUploadAccountSSHKey -Identity $UploadAccount.keys.ssh[0].id -UploadAccountID $TestUploadAccountID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 NetstorageCPCode                  
    #------------------------------------------------

    ### Get-NetstorageCPCode
    $Script:GetNetstorageCPCode = Get-NetstorageCPCode -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageCPCode returns the correct data' {
        $GetNetstorageCPCode[0].cpcodeId | Should -Not -BeNullOrEmpty
    }

    # #------------------------------------------------
    # #                 NetstorageCPCodePurgeRoutine                  
    # #------------------------------------------------

    ### Get-NetstorageCPCodePurgeRoutine
    $Script:GetNetstorageCPCodePurgeRoutine = Get-NetstorageCPCodePurgeRoutine -CPCodeID $TestCPCodeID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageCPCodePurgeRoutine returns the correct data' {
        $GetNetstorageCPCodePurgeRoutine[0].ageDeletionDirectory | Should -Not -BeNullOrEmpty
    }

    ### Set-NetstorageCPCodePurgeRoutine by parameter
    it 'Set-NetstorageCPCodePurgeRoutine by param throws no errors' {
        { Set-NetstorageCPCodePurgeRoutine -Body $GetNetstorageCPCodePurgeRoutine -CPCodeID $TestCPCodeID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Set-NetstorageCPCodePurgeRoutine by pipeline
    it 'Set-NetstorageCPCodePurgeRoutine by pipeline throws no errors' {
        { $GetNetstorageCPCodePurgeRoutine | Set-NetstorageCPCodePurgeRoutine -CPCodeID $TestCPCodeID -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    # #------------------------------------------------
    # #                 NetstorageSnapshot                  
    # #------------------------------------------------

    ### New-NetstorageSnapshot by parameter
    $Script:NewNetstorageSnapshotByParam = New-NetstorageSnapshot -Body $TestSnapshot -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-NetstorageSnapshot by param returns the correct data' {
        $NewNetstorageSnapshotByParam.snapshotId | Should -Not -BeNullOrEmpty
    }

    ### New-NetstorageSnapshot by pipeline
    $Script:NewNetstorageSnapshotByPipeline = ($TestSnapshot | New-NetstorageSnapshot -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-NetstorageSnapshot by pipeline returns the correct data' {
        $NewNetstorageSnapshotByPipeline.snapshotId | Should -Not -BeNullOrEmpty
    }

    ### Get-NetstorageSnapshot, all
    $Script:GetNetstorageSnapshotAll = Get-NetstorageSnapshot -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageSnapshot, all returns the correct data' {
        $GetNetstorageSnapshotAll[0].snapshotId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-NetstorageSnapshot, single
    $Script:GetNetstorageSnapshotSingle = Get-NetstorageSnapshot -SnapShotID $NewNetstorageSnapshotByParam.snapshotId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageSnapshot, single returns the correct data' {
        $GetNetstorageSnapshotSingle.snapshotId | Should -Be $NewNetstorageSnapshotByParam.snapshotId
    }

    ### Set-NetstorageSnapshot by parameter
    $Script:SetNetstorageSnapshotByParam = Set-NetstorageSnapshot -Body $NewNetstorageSnapshotByParam -SnapShotID $NewNetstorageSnapshotByParam.snapshotId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-NetstorageSnapshot by param returns the correct data' {
        $SetNetstorageSnapshotByParam.snapshotId | Should -Be $NewNetstorageSnapshotByParam.snapshotId
    }

    ### Set-NetstorageSnapshot by pipeline
    $Script:SetNetstorageSnapshotByPipeline = ($NewNetstorageSnapshotByParam | Set-NetstorageSnapshot -SnapShotID $NewNetstorageSnapshotByParam.snapshotId -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-NetstorageSnapshot by pipeline returns the correct data' {
        $SetNetstorageSnapshotByPipeline.snapshotId | Should -Be $NewNetstorageSnapshotByParam.snapshotId
    }

    ### Remove-NetstorageSnapshot
    it 'Remove-NetstorageSnapshot throws no errors' {
        { Remove-NetstorageSnapshot -SnapShotID $NewNetstorageSnapshotByParam.snapshotId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
        { Remove-NetstorageSnapshot -SnapShotID $NewNetstorageSnapshotByPipeline.snapshotId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    # #------------------------------------------------
    # #                 NetstorageZones                  
    # #------------------------------------------------

    ### Get-NetstorageZones
    $Script:GetNetstorageZones = Get-NetstorageZones -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetstorageZones returns the correct data' {
        $GetNetstorageZones[0] | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 NetstorageAuth
    #------------------------------------------------

    ### New-NetstorageAuth create new auth file
    $Script:NewNetstorageAuth = New-NetstorageAuth -UploadAccountID $TestUploadAccountID -OutputDirectory $TestOutputDirectory -AuthSection $Section -EdgeRCFile $EdgeRCFile -Section $Section
    $Script:TestNewNSAuthKey = $($GetNetstorageUploadAccountSingle.keys.g2o.key)
    it 'New-NetStorageAuth should create new file called .nsrc at root' {
        $File = "$TestOutputDirectory/.nsrc"
        $File | Should -Exist
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "\[$Section\]"
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "key=$TestNewNSAuthKey" 
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "id=$TestUploadAccountID" 
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "group=$TestStorageGroupID" 
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "host=$TestDomainName"
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "cpcode=$TestCPCodeID"
    }

    ### New-NetStorageAuth append auth file with existing default section
    it 'New-NetStorageAuth should fail because a default section already exists' {
        { New-NetstorageAuth -UploadAccountID $TestUploadAccountID -OutputDirectory $TestOutputDirectory -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Throw
    }

    ### New-NetstorageAuth create new auth section on existing .nsrc
    $Script:NewNetstorageAuth2 = New-NetstorageAuth -UploadAccountID $TestUploadAccountID -OutputDirectory $TestOutputDirectory -EdgeRCFile $EdgeRCFile -Section $Section -AuthSection $TestAuthSection
    it 'New-NetStorageAuth2 should create new section on existing .nsrc' {
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatchMultiline "\n\[$TestAuthSection\]"
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "key=$TestNewNSAuthKey" 
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "id=$TestUploadAccountID" 
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "group=$TestStorageGroupID" 
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "host=$TestDomainName"
        "$TestOutputDirectory/.nsrc" | Should -FileContentMatch "cpcode=$TestCPCodeID"
    }

    AfterAll {
        Remove-Item -Path "$TestOutputDirectory" -Recurse -Force
    }
}

Describe 'Unsafe Akamai.Netstorage Tests' {
    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 NetstorageGroup                  
    #------------------------------------------------

    ### New-NetstorageGroup by parameter
    $Script:NewNetstorageGroupByParam = New-NetstorageGroup -Body $TestGroupJSON -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-NetstorageGroup by param returns the correct data' {
        $NewNetstorageGroupByParam.storageGroupId | Should -Not -BeNullOrEmpty
    }

    ### New-NetstorageGroup by pipeline
    $Script:NewNetstorageGroupByPipeline = ($TestGroup | New-NetstorageGroup -EdgeRCFile $SafeEdgeRCFile -Section $Section)
    it 'New-NetstorageGroup by pipeline returns the correct data' {
        $NewNetstorageGroupByPipeline.storageGroupId | Should -Not -BeNullOrEmpty
    }

    ### Set-NetstorageGroup by parameter
    $Script:SetNetstorageGroupByParam = Set-NetstorageGroup -Body $NewNetstorageGroupByParam -StorageGroupID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-NetstorageGroup by param returns the correct data' {
        $SetNetstorageGroupByParam.storageGroupId | Should -Not -BeNullOrEmpty
    }

    ### Set-NetstorageGroup by pipeline
    $Script:SetNetstorageGroupByPipeline = ($NewNetstorageGroupByParam | Set-NetstorageGroup -StorageGroupID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section)
    it 'Set-NetstorageGroup by pipeline returns the correct data' {
        $SetNetstorageGroupByPipeline.storageGroupId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 NetstorageUploadAccount                  
    #------------------------------------------------

    ### New-NetstorageUploadAccount by parameter
    $Script:NewNetstorageUploadAccountByParam = New-NetstorageUploadAccount -Body $TestUploadAccountJSON -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-NetstorageUploadAccount by param returns the correct data' {
        $NewNetstorageUploadAccountByParam.uploadAccountId | Should -Not -BeNullOrEmpty
    }

    ### New-NetstorageUploadAccount by pipeline
    $Script:NewNetstorageUploadAccountByPipeline = ($TestUploadAccount | New-NetstorageUploadAccount -EdgeRCFile $SafeEdgeRCFile -Section $Section)
    it 'New-NetstorageUploadAccount by pipeline returns the correct data' {
        $NewNetstorageUploadAccountByPipeline.uploadAccountId | Should -Not -BeNullOrEmpty
    }

    ### Remove-NetstorageUploadAccount
    it 'Remove-NetstorageUploadAccount throws no errors' {
        { Remove-NetstorageUploadAccount -UploadAccountID $TestUploadAccountID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 NetstorageCPCode                  
    #------------------------------------------------

    ### New-NetstorageCPCode
    $Script:NewNetstorageCPCode = New-NetstorageCPCode -CPCodeName testcpcode -ContractID $TestContract -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-NetstorageCPCode returns the correct data' {
        $NewNetstorageCPCode.cpcodeName | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 NetstorageSnapshot                  
    #------------------------------------------------

    ### Start-NetstorageSnapshot
    $Script:StartNetstorageSnapshot = Start-NetstorageSnapshot -SnapShotID 123456 -SnapshotName testname -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Start-NetstorageSnapshot returns the correct data' {
        $StartNetstorageSnapshot.snapshotId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 NetstorageRuleSet                  
    #------------------------------------------------

    ### New-NetstorageRuleSet by parameter
    $Script:NewNetstorageRuleSetByParam = New-NetstorageRuleSet -Body $TestRuleSet -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-NetstorageRuleSet by param returns the correct data' {
        $NewNetstorageRuleSetByParam.ruleSetId | Should -Not -BeNullOrEmpty
    }

    ### New-NetstorageRuleSet by pipeline
    $Script:NewNetstorageRuleSetByPipeline = ($TestRuleSet | New-NetstorageRuleSet -EdgeRCFile $SafeEdgeRCFile -Section $Section)
    it 'New-NetstorageRuleSet by pipeline returns the correct data' {
        $NewNetstorageRuleSetByPipeline.ruleSetId | Should -Not -BeNullOrEmpty
    }

    ### Get-NetstorageRuleSet, all
    $Script:GetNetstorageRuleSetAll = Get-NetstorageRuleSet -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-NetstorageRuleSet, all returns the correct data' {
        $GetNetstorageRuleSetAll[0].ruleSetId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-NetstorageRuleSet, single
    $Script:GetNetstorageRuleSet = Get-NetstorageRuleSet -RuleSetID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-NetstorageRuleSet returns the correct data' {
        $GetNetstorageRuleSet.ruleSetId | Should -Not -BeNullOrEmpty
    }

    ### Set-NetstorageRuleSet by parameter
    $Script:SetNetstorageRuleSetByParam = Set-NetstorageRuleSet -Body $NewNetstorageRuleSetByParam -RuleSetID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-NetstorageRuleSet by param returns the correct data' {
        $SetNetstorageRuleSetByParam.ruleSetId | Should -Not -BeNullOrEmpty
    }

    ### Set-NetstorageRuleSet by pipeline
    $Script:SetNetstorageRuleSetByPipeline = ($NewNetstorageRuleSetByParam | Set-NetstorageRuleSet -RuleSetID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section)
    it 'Set-NetstorageRuleSet by pipeline returns the correct data' {
        $SetNetstorageRuleSetByPipeline.ruleSetId | Should -Not -BeNullOrEmpty
    }

    ### Remove-NetstorageRuleSet
    it 'Remove-NetstorageRuleSet throws no errors' {
        { Remove-NetstorageRuleSet -RuleSetID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 NetstorageCPCodePurgeRoutine                  
    #------------------------------------------------
    
    ### Remove-NetstorageCPCodePurgeRoutine
    it 'Remove-NetstorageCPCodePurgeRoutine throws no errors' {
        { Remove-NetstorageCPCodePurgeRoutine -CPCodeID $TestCPCodeID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    AfterAll {
        
    }
}
