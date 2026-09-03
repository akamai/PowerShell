function New-EdgeDiagnosticsMTR {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Destination,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('IP', 'HOST')]
        [string]
        $DestinationType,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('ICMP', 'TCP')]
        [string]
        $PacketType,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet(80, 443)]
        [int]
        $Port,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $ResolveDNS,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $ShowIPs,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $ShowLocations,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $SiteShieldHostname,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Source,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('EDGE_IP', 'LOCATION')]
        [string]
        $SourceType,

        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'body')]
        $Body,

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
        $Path = "/edge-diagnostics/v1/mtr"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'destination'     = $Destination
                'destinationType' = $DestinationType
                'packetType'      = $PacketType
                'resolveDns'      = $ResolveDNS.IsPresent
                'showIps'         = $ShowIPs.IsPresent
                'showLocations'   = $ShowLocations.IsPresent
            }

            if ($Port) { $Body['port'] = $Port }
            if ($SiteShieldHostname) { $Body['siteShieldHostname'] = $SiteShieldHostname }
            if ($Source) { $Body['source'] = $Source }
            if ($SourceType) { $Body['sourceType'] = $SourceType }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

