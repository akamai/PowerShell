
function Add-NetstorageUploadAccountHTTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/g2o"
        $RequestParams = @{
            Path             = $Path
            Method           = 'PUT'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}
