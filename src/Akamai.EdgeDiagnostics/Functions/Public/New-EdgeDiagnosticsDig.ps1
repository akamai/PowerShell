function New-EdgeDiagnosticsDig {
    [CmdletBinding(DefaultParameterSetName = 'IP & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [ValidateSet('A', 'AAAA', 'SOA', 'CNAME', 'PTR', 'MX', 'NS', 'TXT', 'SRV', 'CAA', 'ANY')]
        [string]
        $QueryType = 'ANY',

        [Parameter(ParameterSetName = 'IP & attributes')]
        [string]
        $EdgeIP,

        [Parameter(ParameterSetName = 'Location & attributes')]
        [string]
        $EdgeLocationID,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [switch]
        $IsGTMHostname,

        [Parameter(Mandatory, ParameterSetName = 'Body')]
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
        $Path = "/edge-diagnostics/v1/dig"

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'hostname'      = $Hostname
                'queryType'     = $QueryType
                'isGtmHostname' = $IsGTMHostname.IsPresent
            }

            if ($EdgeIP) {
                $Body['edgeIp'] = $EdgeIP
            }

            if ($EdgeLocationID) {
                $Body['edgeLocationId'] = $EdgeLocationID
            }
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

