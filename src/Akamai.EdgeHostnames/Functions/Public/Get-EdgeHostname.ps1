function Get-EdgeHostname {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Position = 0, ParameterSetName = 'Get one by ID', ValueFromPipeline)]
        [int]
        $EdgeHostnameID,

        [Parameter(ParameterSetName = 'Get one by components', Mandatory)]
        [string]
        $RecordName,

        [Parameter(ParameterSetName = 'Get all')]
        [Parameter(ParameterSetName = 'Get one by components', Mandatory)]
        [string]
        $DNSZone,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $ChinaCDNEnabled,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Comments,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CustomTarget,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsEdgeIPBindingEnabled,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Map,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $MapAlias,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $RecordNameSubstring,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SecurityType,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $SlotNumber,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $TTL,

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
        if ($EdgeHostnameID) {
            $Path = "/hapi/v1/edge-hostnames/$EdgeHostnameID"
        }
        else {
            $Path = "/hapi/v1/edge-hostnames"
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters = @{
                'chinaCdnEnabled'        = $PSBoundParameters.ChinaCDNEnabled
                'comments'               = $Comments
                'customTarget'           = $CustomTarget
                'dnsZone'                = $DNSZone
                'isEdgeIPBindingEnabled' = $PSBoundParameters.IsEdgeIPBindingEnabled
                'map'                    = $Map
                'mapAlias'               = $MapAlias
                'recordNameSubstring'    = $RecordNameSubstring
                'securityType'           = $SecurityType
                'slotNumber'             = $PSBoundParameters.SlotNumber
                'ttl'                    = $PSBoundParameters.TTL
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Get one by components') {
            $Path = "/hapi/v1/dns-zones/$DNSZone/edge-hostnames/$RecordName"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            return $Response.Body.edgeHostnames
        }
        else {
            return $Response.Body
        }
    }
}
