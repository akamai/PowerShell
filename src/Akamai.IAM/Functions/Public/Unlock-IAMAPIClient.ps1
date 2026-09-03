function Unlock-IAMAPIClient {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ClientID,

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
            $Path = "/identity-management/v3/api-clients/self/unlock"
        }
        else {
            $Path = "/identity-management/v3/api-clients/$ClientID/unlock"
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
