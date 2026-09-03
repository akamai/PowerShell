
function Get-EDNSProxyZoneTSIGKey {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(ParameterSetName = 'Get one')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

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

    process {
        if ($Name) {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/key"
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/keys"
        }
        $QueryParameters = @{
            'page'     = $PSBoundParameters.Page
            'pageSize' = $PSBoundParameters.PageSize
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($Name) {
                return $Response.Body
            }
            else {
                return $Response.Body.proxyZones
            }
        }
        catch {
            throw $_
        }
    }
}
