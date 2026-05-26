function Get-EdgeDiagnosticsGTMPropertyIPs {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Domain,
        
        [Parameter(Mandatory)]
        [string]
        $Property,
        
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

    $Path = "/edge-diagnostics/v1/gtm/$Property/$Domain/gtm-property-ips"
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
    return $Response.Body.gtmPropertyIps
}

