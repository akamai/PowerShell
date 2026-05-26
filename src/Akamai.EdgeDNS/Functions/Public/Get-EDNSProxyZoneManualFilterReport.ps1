
function Get-EDNSProxyZoneManualFilterReport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

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
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.manualFilterNames
        }
        catch {
            throw $_
        }
    }
}
