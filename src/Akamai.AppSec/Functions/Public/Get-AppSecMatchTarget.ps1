function Get-AppSecMatchTarget {
    [CmdletBinding(DefaultParameterSetName = 'Config name')]
    Param(
        [Parameter(ParameterSetName = 'Config name', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter()]
        [int]
        $TargetID,

        [Parameter()]
        [alias('IncludeChildObjectName')]
        [switch]
        $OmitChildObjectName,

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
        if ($TargetID) {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/match-targets/$TargetID"
        }
        else {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/match-targets"
        }
        $QueryParameters = @{
            includeChildObjectName = (-not $OmitChildObjectName)
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
        if ($TargetID) {
            return $Response.Body
        }
        else {
            return $Response.Body.matchTargets
        }
    }
}
