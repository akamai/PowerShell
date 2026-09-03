function Get-ChinaCDNPropertyHostname {
    Param(
        [Parameter()]
        [string]
        $Hostname,

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

    if ($Hostname) {
        $Path = "/chinacdn/v1/property-hostnames/$Hostname"
        $AdditionalHeaders = @{
            Accept = 'application/vnd.akamai.chinacdn.property-hostname.v1+json'
        }
    }
    else {
        $Path = "/chinacdn/v1/property-hostnames"
        $AdditionalHeaders = @{
            Accept = 'application/vnd.akamai.chinacdn.property-hostnames.v1+json'
        }
    }
    $RequestParams = @{
        'Path'              = $Path
        'Method'            = 'GET'
        'AdditionalHeaders' = $AdditionalHeaders
        'EdgeRCFile'        = $EdgeRCFile
        'Section'           = $Section
        'AccountSwitchKey'  = $AccountSwitchKey
        'Debug'             = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    if ($Hostname) {
        return $Response.Body
    }
    else {
        $Response.Body.propertyHostnames
    }
}

