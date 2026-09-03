function Protect-AppSecEvaluationHostnames {
    [CmdletBinding(DefaultParameterSetName = 'Config name by pipeline')]
    Param(
        [Parameter(ParameterSetName = 'Config name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name by pipeline', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Config ID by pipeline', Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $VersionNumber,

        [Parameter(Mandatory, ParameterSetName = 'Config name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Config ID & attributes')]
        [string[]]
        $Hostnames,

        [Parameter(Mandatory, ParameterSetName = 'Config name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Config ID & attributes')]
        [ValidateSet('append', 'remove', 'replace')]
        [string]
        $Mode,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Config name by pipeline')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Config ID by pipeline')]
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

        [string] $ConfigID, $VersionNumber, $null = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/protect-eval-hostnames"
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
