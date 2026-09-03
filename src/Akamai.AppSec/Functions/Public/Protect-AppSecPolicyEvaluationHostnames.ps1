function Protect-AppSecPolicyEvaluationHostnames {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name-pipeline')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name-attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy name-pipeline', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID by pipeline', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name by pipeline', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID by pipeline', Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name-attributes', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy name-pipeline', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name & attributes', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name by pipeline', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID by pipeline', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID by pipeline', Mandatory)]
        [string]
        $PolicyID,

        [Parameter(Mandatory, ParameterSetName = 'Config name & policy name-attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Config name & policy ID & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Config ID & policy name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Config & policy ID & attributes')]
        [string[]]
        $Hostnames,

        [Parameter(Mandatory, ParameterSetName = 'Config name & policy name-attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Config name & policy ID & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Config ID & policy name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Config & policy ID & attributes')]
        [ValidateSet('append', 'remove', 'replace')]
        [string]
        $Mode,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Config name & policy name-pipeline')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Config name & policy ID by pipeline')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Config ID & policy name by pipeline')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Config & policy ID by pipeline')]
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
        if ($null -ne $Hostnames -and $Hostnames.GetType() -notin [string], [array]) {
            throw "Parameter '-Hostnames' must be either a String or an Array."
        }

        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/protect-eval-hostnames"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'hostnames' = $Hostnames
                'mode'      = $Mode
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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
