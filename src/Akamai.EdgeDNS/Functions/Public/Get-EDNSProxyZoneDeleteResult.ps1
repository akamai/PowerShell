
function Get-EDNSProxyZoneDeleteResult {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $RequestID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $ShowAll,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsComplete,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsExpired,

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
        if ($RequestID) {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/delete-requests/$RequestID/result"
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/delete-requests/results"
            $QueryParameters = @{
                'page'       = $PSBoundParameters.Page
                'pageSize'   = $PSBoundParameters.PageSize
                'showAll'    = $PSBoundParameters.ShowAll.IsPresent
                'isComplete' = $PSBoundParameters.IsComplete.IsPresent
                'isExpired'  = $PSBoundParameters.IsExpired.IsPresent
            }
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
            if ($RequestID) {
                return $Response.Body
            }
            else {
                return $Response.Body.requests
            }
        }
        catch {
            throw $_
        }
    }
}
