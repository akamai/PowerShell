function Get-EDNSZoneVersion {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Get one')]
        [Alias("UUID")]
        [string]
        $VersionID,

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
        $Method = 'GET'
        if ($VersionID) {
            $Path = "/config-dns/v2/zones/$Zone/versions/$VersionID"
        }
        else {
            $Path = "/config-dns/v2/zones/$Zone/versions"
        }

        $QueryParameters = @{}
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters['showAll'] = $true
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            return $Response.Body
        }
        else {
            return $Response.Body.versions
        }
    }
}
