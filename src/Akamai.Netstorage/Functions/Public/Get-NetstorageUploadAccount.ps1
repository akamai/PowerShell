function Get-NetstorageUploadAccount {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UploadAccountID,

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
        if ($UploadAccountID) {
            $Path = "/storage/v1/upload-accounts/$UploadAccountID"
        }
        else {
            $Path = "/storage/v1/upload-accounts"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($UploadAccountID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}
