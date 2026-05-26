function Set-AppSecPolicyTuningRecommendations {
    [CmdletBinding(DefaultParameterSetName = 'Config & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID', Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

        [Parameter(Mandatory)]
        [ValidateSet('ACCEPT', 'DECLINE', 'RESET')]
        [string]
        $Action,

        [Parameter(Mandatory)]
        [int]
        $SelectorID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Body = @{
            action     = $Action
            selectorId = $SelectorID
        }

        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/recommendations"
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
