
function Set-EDNSProxyZoneManualFilterNames {
    [CmdletBinding(DefaultParameterSetName = 'Manage manual filters')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Manage manual filters')]
        [switch]
        $AddSkipExisting,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Manage manual filters')]
        $Body,

        [Parameter(ParameterSetName = 'Zone file')]
        [string]
        $ZoneFile,

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
        if ($PSCmdlet.ParameterSetName -eq 'Manage manual filters') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names/manage"
            $QueryParameters = @{
                'addSkipExisting' = $PSBoundParameters.AddSkipExisting.IsPresent
            }
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names/zone-file"
            $Body = Get-Content -Path $ZoneFile -Raw
            $AdditionalHeaders = @{
                'content-type' = 'text/dns'
            }
        }

        $RequestParameters = @{
            Path              = $Path
            Method            = 'POST'
            Body              = $Body
            AdditionalHeaders = $AdditionalHeaders
            QueryParameters   = $QueryParameters
            EdgeRCFile        = $EdgeRCFile
            Section           = $Section
            AccountSwitchKey  = $AccountSwitchKey
            Debug             = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
