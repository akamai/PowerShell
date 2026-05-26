function Get-EdgeDiagnosticsErrorStatistics {
    [CmdletBinding(DefaultParameterSetName = 'CP code')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'CP code')]
        [int]
        $CPCode,

        [Parameter(Mandatory, ParameterSetName = 'URL')]
        [string]
        $URL,

        [Parameter()]
        [ValidateSet('EDGE_ERRORS', 'ORIGIN_ERRORS')]
        [string]
        $ErrorType,

        [Parameter()]
        [ValidateSet('STANDARD_TLS', 'ENHANCED_TLS')]
        [string]
        $Delivery,

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

    $Path = "/edge-diagnostics/v1/estats"
    $Body = @{}
    if ($CPCode) { $Body['cpCode'] = $CPCode }
    if ($URL) { $Body['url'] = $URL }
    if ($ErrorType) { $Body['errorType'] = $ErrorType }
    if ($Delivery) { $Body['delivery'] = $Delivery }
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

