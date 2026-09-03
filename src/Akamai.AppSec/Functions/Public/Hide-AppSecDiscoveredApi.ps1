function Hide-AppSecDiscoveredAPI {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $Hostname,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $BasePath,
        
        [Parameter(Mandatory)]
        [ValidateSet('FALSE_POSITIVE', 'NOT_ELIGIBLE')]
        [string]
        $Reason,

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
        $Path = "/appsec/v1/api-discovery/host/$Hostname/basepath/$BasePath"
        $Body = @{
            'hidden' = $true
            'reason' = $Reason
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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
