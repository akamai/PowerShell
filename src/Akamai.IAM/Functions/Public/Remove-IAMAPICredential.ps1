function Remove-IAMAPICredential {
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
            $Path = "/identity-management/v3/api-clients/self/credentials/$CredentialId"
        }
        else {
            $Path = "/identity-management/v3/api-clients/$ClientID/credentials/$CredentialId"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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
