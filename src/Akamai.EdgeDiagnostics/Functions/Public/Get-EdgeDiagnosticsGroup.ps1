function Get-EdgeDiagnosticsGroup {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter()]
        [switch]
        $IncludeCurl,

        [Parameter()]
        [switch]
        $IncludeDig,

        [Parameter()]
        [switch]
        $IncludeMTR,

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

    if ($GroupID) {
        $Path = "/edge-diagnostics/v1/user-diagnostic-data/groups/$GroupID/records"
        $QueryParameters = @{
            'includeCurl' = $PSBoundParameters.IncludeCurl.IsPresent
            'includeDig'  = $PSBoundParameters.IncludeDig.IsPresent
            'includeMtr'  = $PSBoundParameters.IncludeMTR.IsPresent
        }
    }
    else {
        $Path = "/edge-diagnostics/v1/user-diagnostic-data/groups"
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
    if ($GroupID) {
        return $Response.Body
    }
    else {
        return $Response.Body.groups
    }
}

