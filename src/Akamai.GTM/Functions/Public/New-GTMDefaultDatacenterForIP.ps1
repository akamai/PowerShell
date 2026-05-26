function New-GTMDefaultDatacenterForIP {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [ValidateSet('ipv4', 'ipv6')]
        [string]
        $IPVersion,

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

    if ($IPVersion -eq 'ipv4') {
        $Path = "/config-gtm/v1/domains/$DomainName/datacenters/datacenter-for-ip-version-selector-ipv4"
    }
    elseif ($IPVersion -eq 'ipv6') {
        $Path = "/config-gtm/v1/domains/$DomainName/datacenters/datacenter-for-ip-version-selector-ipv6"
    }
    $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
    $RequestParams = @{
        'Path'              = $Path
        'Method'            = 'POST'
        'AdditionalHeaders' = $AdditionalHeaders
        'EdgeRCFile'        = $EdgeRCFile
        'Section'           = $Section
        'AccountSwitchKey'  = $AccountSwitchKey
        'Debug'             = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body.resource
}

