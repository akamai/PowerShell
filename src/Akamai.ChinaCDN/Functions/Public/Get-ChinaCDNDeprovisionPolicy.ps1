function Get-ChinaCDNDeprovisionPolicy {
    Param(
        [Parameter(Mandatory)]
        [string]
        $EdgeHostname,

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

    $Path = "/chinacdn/v1/edge-hostnames/$EdgeHostname/deprovision-policy"
    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.deprovision-policy.v1+json'
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
    return $Response.Body
}

