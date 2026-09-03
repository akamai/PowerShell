function Set-IAMUserPassword {
    [CmdletBinding(DefaultParameterSetName = 'Other users')]
    Param(
        [Parameter(ParameterSetName = 'Other users', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UIIdentityID,

        [Parameter(ParameterSetName = 'Self', Mandatory)]
        [securestring]
        $CurrentPassword,

        [Parameter(Mandatory)]
        [securestring]
        $NewPassword,

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
        if ($PSCmdlet.ParameterSetName -eq 'Self') {
            $Path = "/identity-management/v3/user-profile/change-password"
        }
        else {
            $Path = "/identity-management/v3/user-admin/ui-identities/$UIIdentityID/set-password"
        }
        $Body = @{
            'newPassword' = (New-Object PSCredential 0, $NewPassword).GetNetworkCredential().Password
        }
        if ($PSCmdlet.ParameterSetName -eq 'Self') {
            $Body['currentPassword'] = (New-Object PSCredential 0, $CurrentPassword).GetNetworkCredential().Password
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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
