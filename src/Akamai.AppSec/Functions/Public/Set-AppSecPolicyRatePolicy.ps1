function Set-AppSecPolicyRatePolicy {
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

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory)]
        [Parameter(ParameterSetName = 'Config & policy ID', Mandatory)]
        [string]
        $PolicyID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $RatePolicyID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^alert$|^deny$|^deny_custom_|^none$|^tarpit$|^monitor$|^delay$|^slow$|^serve_alt$|^cond_action$|^challenge$')]
        [string]
        $IPv4Action,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^alert$|^deny$|^deny_custom_|^none$|^tarpit$|^monitor$|^delay$|^slow$|^serve_alt$|^cond_action$|^challenge$')]
        [string]
        $IPv6Action,

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
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/rate-policies/$($PSBoundParameters.RatePolicyID)"
        $Body = @{
            ipv4Action = $IPv4Action
            ipv6Action = $IPv6Action
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
