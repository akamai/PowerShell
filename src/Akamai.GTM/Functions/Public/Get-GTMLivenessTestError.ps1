function Get-GTMLivenessTestError {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $ErrorCode,

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

    Process {
        if ($ErrorCode) {
            $Path = "/gtm-api/v1/reports/liveness-tests/error-code-descriptions/$ErrorCode"
        }
        else {
            $Path = "/gtm-api/v1/reports/liveness-tests/error-code-descriptions"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.items
    }
}

