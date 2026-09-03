function Set-IAMUserProfile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Path = "/identity-management/v3/user-profile/basic-info"
        $RequestParams = @{
            'Path'       = $Path
            'Method'     = 'PUT'
            'Body'       = $Body
            'EdgeRCFile' = $EdgeRCFile
            'Section'    = $Section
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


