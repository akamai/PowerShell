function Set-AppSecEvaluationRatePolicy {
    [CmdletBinding(DefaultParameterSetName = 'Config name')]
    Param(
        [Parameter(ParameterSetName = 'Config name', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID', Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $VersionNumber,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $RatePolicyID,

        [Parameter(Mandatory)]
        [ValidateSet('APPLY', 'DISCARD')]
        [string]
        $Action,

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
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/rate-policies/$RatePolicyID/evaluation"
        $Body = @{
            action = $Action
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
