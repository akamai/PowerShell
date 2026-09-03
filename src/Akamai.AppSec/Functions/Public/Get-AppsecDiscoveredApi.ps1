function Get-AppSecDiscoveredAPI {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'Get one', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $BasePath,

        [Parameter(ParameterSetName = 'Get one')]
        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IncludeHidden,

        [Parameter(ParameterSetName = 'Get one')]
        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

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
        if ($Hostname -and $BasePath) {
            $Base64Match = '^[a-zA-Z0-9+\/]+=*$'
            if ($Hostname -notmatch $Base64Match) {
                $Hostname = ConvertTo-Base64 -UnencodedString $Hostname
            }
            if ($BasePath -notmatch $Base64Match -or $BasePath.StartsWith('/')) {
                $BasePath = ConvertTo-Base64 -UnencodedString $BasePath
            }
            $Path = "/appsec/v1/api-discovery/host/$Hostname/basepath/$BasePath"
        }
        else {
            $Path = "/appsec/v1/api-discovery"
        }
        $QueryParameters = @{
            'includeHidden' = $PSBoundParameters.IncludeHidden.IsPresent
            'search'        = $Search
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
        if ($Hostname -and $BasePath) {
            return $Response.Body
        }
        else {
            return $Response.Body.apis
        }
    }
}
