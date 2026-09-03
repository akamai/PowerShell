function New-GTMDefaultDatacenter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

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

    $Path = "/config-gtm/v1/domains/$DomainName/datacenters/default-datacenter-for-maps"
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

