function Reset-IAMUserMFA {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UIIdentityID,

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
        if ($UIIdentityID) {
            $Path = "/identity-management/v3/user-admin/ui-identities/$UIIdentityID/additionalAuthentication/reset"
        }
        else {
            $Path = '/identity-management/v3/user-profile/additionalAuthentication/reset'
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
