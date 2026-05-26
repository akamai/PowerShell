function Get-IAMAPICredential {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ClientID = 'self',

        [Parameter(ValueFromPipelineByPropertyName)]
        [int]
        $CredentialID,

        [Parameter()]
        [switch]
        $Actions,

        [Parameter()]
        [switch]
        $ActiveOnly,

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
        if ($null -ne $PSBoundParameters.CredentialId) {
            if ($ClientID -eq 'self') {
                $Path = "/identity-management/v3/api-clients/self/credentials/$CredentialId"
            }
            else {
                $Path = "/identity-management/v3/api-clients/$ClientID/credentials/$CredentialId"
            }
        }
        else {
            if ($ClientID -eq 'self') {
                $Path = "/identity-management/v3/api-clients/self/credentials"
            }
            else {
                $Path = "/identity-management/v3/api-clients/$ClientID/credentials"
            }
        }
        $QueryParameters = @{
            'actions' = $Actions.IsPresent
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        if ($ActiveOnly) {
            return $Response.Body | Where-Object { $_.status -eq 'ACTIVE' }
        }
        else {
            return $Response.Body
        }
    }
}
