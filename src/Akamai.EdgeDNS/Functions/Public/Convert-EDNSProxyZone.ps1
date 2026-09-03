
function Convert-EDNSProxyZone {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [ValidateSet('all', 'automatic', 'manual', 'none')]
        [string]
        $Mode,

        [Parameter(Mandatory)]
        [string[]]
        $Name,

        [Parameter(ParameterSetName = 'Manual')]
        [string[]]
        $ManualFilterNames,

        [Parameter(ParameterSetName = 'Automatic', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Automatic', Mandatory)]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Automatic', Mandatory)]
        [string]
        $TSIGKeySecret,

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

    begin {
        $CollatedProxyZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        $Name | ForEach-Object {
            $CollatedProxyZones.Add($_)
        }
    }

    end {
        if ($Mode -eq 'all') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/filter-mode-convert/to-all"
        }
        if ($Mode -eq 'automatic') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/filter-mode-convert/to-automatic"
        }
        if ($Mode -eq 'manual') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/filter-mode-convert/to-manual"
        }
        if ($Mode -eq 'none') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/filter-mode-convert/to-none"
        }

        $Body = @{
            'proxyZones' = $CollatedProxyZones
        }
        if ($TSIGKeyName) {
            $Body.tsigKey = @{
                'algorithm' = $TSIGKeyAlgorithm
                'name'      = $TSIGKeyName
                'secret'    = $TSIGKeySecret
            }
        }
        if ($ManualFilterNames) {
            $Body.manualFilterNames = @($ManualFilterNames)
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
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
