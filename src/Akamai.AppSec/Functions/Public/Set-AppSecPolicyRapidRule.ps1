function Set-AppSecPolicyRapidRule {
    [CmdletBinding(DefaultParameterSetName = 'Config & policy name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Config & policy name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy name & body', Position = 0, Mandatory)]
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

        [Parameter(ParameterSetName = 'Config & policy name & attributes', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy name & body', Position = 2, Mandatory)]
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

        [Parameter(ParameterSetName = 'Config & policy name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $RuleID,

        [Parameter(ParameterSetName = 'Config & policy name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('version')]
        [int]
        $RuleVersion,

        [Parameter(ParameterSetName = 'Config & policy name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^alert$|^deny$|^deny_custom_|^none$|^akamai_managed$')]
        [string]
        $Action,

        [Parameter(ParameterSetName = 'Config & policy name & body', Mandatory, ValueFromPipeline)]
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
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/rapid-rules/$RuleID/versions/$RuleVersion/action"

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'action' = $Action
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
