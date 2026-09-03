function Add-NetstorageUploadAccountFTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,
        
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Key,
        
        [Parameter()]
        [string]
        $Comments,

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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ftp"
        $Body = @{
            key = $Key
        }
        if ($null -ne $Comments) {
            $Body.comments = $Comments
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

