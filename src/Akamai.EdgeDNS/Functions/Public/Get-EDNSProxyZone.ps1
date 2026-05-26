
function Get-EDNSProxyZone {
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
        [string]
        $Search,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $FilterMode,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize = 1000,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

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
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name"
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones"
        }
        $QueryParameters = @{
            'search'     = $Search
            'filterMode' = $FilterMode
            'page'       = $PSBoundParameters.Page
            'pageSize'   = $PSBoundParameters.PageSize
            'sortBy'     = $SortBy
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
