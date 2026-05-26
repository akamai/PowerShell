function Test-EdgeDiagnosticsIP {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $IPAddress,
        
        [Parameter()]
        [switch]
        $IncludeLocation,

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

    if ($IncludeLocation) {
        $Path = "/edge-diagnostics/v1/verify-locate-ip"
        if ($IPAddress.Count -gt 1) {
            throw "Only one IP address can be included when using the -IncludeLocation switch."
        }
        $Body = @{
            'ipAddress' = $IPAddress[0]
        }
    }
    else {
        $Path = "/edge-diagnostics/v1/verify-edge-ip"
        $Body = @{
            'ipAddresses' = $IPAddress
        }
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

