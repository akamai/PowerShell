function Get-AppSecDiscoveredAPIEndpoints {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $Hostname,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $BasePath,

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
        $Base64Match = '^[a-zA-Z0-9+\/]+=*$'
        if ($Hostname -notmatch $Base64Match) {
            $Hostname = ConvertTo-Base64 -UnencodedString $Hostname
        }
        if ($BasePath -notmatch $Base64Match -or $BasePath.StartsWith('/')) {
            $BasePath = ConvertTo-Base64 -UnencodedString $BasePath
        }
        $Path = "/appsec/v1/api-discovery/host/$Hostname/basepath/$BasePath/endpoints"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.apis
    }
}
