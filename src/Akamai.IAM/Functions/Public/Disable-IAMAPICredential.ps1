function Disable-IAMAPICredential {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $ClientID = 'self',

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CredentialID,

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
        if ($ClientID -eq 'self') {
            $Path = "/identity-management/v3/api-clients/self/credentials/deactivate"
        }
        else {
            $Path = "/identity-management/v3/api-clients/$ClientID/credentials/deactivate"
        }
        if ($CredentialID) {
            if ($ClientID -eq 'self') {
                $Path = "/identity-management/v3/api-clients/self/credentials/$CredentialId/deactivate"
            }
            else {
                $Path = "/identity-management/v3/api-clients/$ClientID/credentials/$CredentialId/deactivate"
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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
