function New-EdgeDiagnosticsLink {
    [CmdletBinding(DefaultParameterSetName = 'URL & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'URL & attributes')]
        [string]
        $URL,

        [Parameter(Mandatory, ParameterSetName = 'IPA & attributes')]
        [string]
        $IPAHostname,

        [Parameter(ParameterSetName = 'URL & attributes')]
        [Parameter(ParameterSetName = 'IPA & attributes')]
        [string]
        $Note,

        [Parameter(ParameterSetName = 'Body', ValueFromPipeline, Mandatory)]
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
        $Path = "/edge-diagnostics/v1/user-diagnostic-data/groups"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{}
            if ($URL) {
                $Body['url'] = $URL
            }
            if ($IPAHostname) {
                $Body['ipaHostname'] = $IPAHostname
            }
            if ($Note) {
                $Body['note'] = $Note
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

