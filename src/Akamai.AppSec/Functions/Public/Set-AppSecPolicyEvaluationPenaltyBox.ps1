function Set-AppSecPolicyEvaluationPenaltyBox {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name-body')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name-attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy name-body', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID & body', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name & body', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID & body', Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name-attributes', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy name-body', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name & body', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID & body', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID & body', Mandatory)]
        [string]
        $PolicyID,

        [Parameter(ParameterSetName = 'Config name & policy name-attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory)]
        [string]
        $Action,

        [Parameter(ParameterSetName = 'Config name & policy name-attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory)]
        [bool]
        $PenaltyBoxProtection,

        [Parameter(ParameterSetName = 'Config name & policy name-body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'Config name & policy ID & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'Config ID & policy name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'Config & policy ID & body', Mandatory, ValueFromPipeline)]
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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/eval-penalty-box"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'action'               = $Action
                'penaltyBoxProtection' = $PenaltyBoxProtection
            }
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

