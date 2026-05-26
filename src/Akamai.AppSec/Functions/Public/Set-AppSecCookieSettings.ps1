function Set-AppSecCookieSettings {
    [CmdletBinding(DefaultParameterSetName = 'Config name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & body', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & body', Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & attributes')]
        [Parameter(ParameterSetName = 'Config ID & attributes')]
        [ValidateSet('automatic', 'fqdn', 'legacy', 'psl')]
        [string]
        $CookieDomain,

        [Parameter()]
        [switch]
        $UseAllSecureTraffic,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Config name & body')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Config ID & body')]
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
        [string] $ConfigID, $VersionNumber, $null = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/advanced-settings/cookie-settings"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'cookieDomain'        = $CookieDomain
                'useAllSecureTraffic' = $UseAllSecureTraffic.IsPresent
            }
        }
        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
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
