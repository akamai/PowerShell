function Get-EdgeDiagnosticsURLHealthCheck {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RequestID,
        
        [Parameter()]
        [switch]
        $IncludeContentResponseBody,
        
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

    $Path = "/edge-diagnostics/v1/url-health-check/requests/$RequestID"
    $QueryParameters = @{
        'includeContentResponseBody' = $PSBoundParameters.IncludeContentResponseBody.IsPresent
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
    return $Response.Body
}

