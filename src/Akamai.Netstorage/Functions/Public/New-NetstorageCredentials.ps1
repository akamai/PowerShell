function New-NetstorageCredentials {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UploadAccountID,

        [Parameter()]
        [string]
        $APIKey,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        # ----------------- Get credentials
    
        # Gets the given upload account's details. 
        #
        # The response contains two values needed for the auth file, the HTTP API key and the storage group ID.
    
        $UploadAccountParams = @{
            'UploadAccountID'  = $UploadAccountID
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        $UploadAccount = Get-NetstorageUploadAccount @UploadAccountParams
    
        # Check if upload account has http api access
        if (-not $UploadAccount.hasHttpApiAccess) {
            throw "Upload account ID $UploadAccountID does not have HTTP API access enabled. Please enable and try again."
        }

        # Select the API key from the upload user, unless provided
        if (-not $APIKey) {
            # Warn the user if account has multiple g2o keys
            if ($UploadAccount.keys.g2o.Count -gt 1) {
                Write-Warning "Upload account ID $UploadAccountID has multiple g2o keys, we will use the first one returned by the API. If you want to specify a different key, please provide it with the -APIKey parameter."
            }
            $APIKey = $UploadAccount.keys.g2o[0].key
        }
    
        # Gets the given storage group's details.
        #
        # The response contains two additional values needed for the auth file, the HTTP domain name and upload directory's CP code.  
    
        $GroupParams = @{
            'StorageGroupID'   = $UploadAccount.storageGroupId
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        $StorageGroup = Get-NetstorageGroup @GroupParams
    
        # The content of the NS auth resource file.
    
        return [PSCustomObject] @{
            'key'    = $APIKey
            'id'     = $UploadAccountID
            'group'  = $UploadAccount.storageGroupId
            'host'   = "$($StorageGroup.domainprefix)-nsu.akamaihd.net"
            'cpcode' = $StorageGroup.cpcodes[0].cpcodeId
        }
    }
}
