function Enable-AppSecPolicyRapidRules {
    [CmdletBinding(DefaultParameterSetName = 'Config & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
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
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/rapid-rules/status"
        $Body = @{ 'enabled' = $true }
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
