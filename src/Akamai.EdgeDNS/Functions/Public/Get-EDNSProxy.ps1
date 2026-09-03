
function Get-EDNSProxy {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Nameserver,

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
        if ($ProxyID) {
            $Path = "/config-dns/v2/proxies/$ProxyID"
        }
        else {
            $Path = "/config-dns/v2/proxies"
            $QueryParameters = @{
                'nameserver' = $Nameserver
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
            if ($ProxyID) {
                return $Response.Body
            }
            else {
                return $Response.Body.items
            }
        }
        catch {
            throw $_
        }
    }
}
