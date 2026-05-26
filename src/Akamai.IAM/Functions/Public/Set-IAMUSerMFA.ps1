function Set-IAMUserMFA {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $UIIdentityID,

        [Parameter(Mandatory)]
        [ValidateSet('TFA', 'MFA', 'NONE')]
        $Value,

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
            $Path = "/identity-management/v3/user-admin/ui-identities/$UIIdentityID/additionalAuthentication"
        }
        else {
            $Path = '/identity-management/v3/user-profile/additionalAuthentication'
        }
        $Body = @{
            'value' = $Value
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'Body'             = $Body
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
