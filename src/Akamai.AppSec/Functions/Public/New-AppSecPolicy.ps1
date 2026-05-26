function New-AppSecPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Config name')]
    Param(
        [Parameter(ParameterSetName = 'Config name', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config id', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('version')]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $VersionNumber,

        [Parameter(Mandatory)]
        [string]
        $PolicyName,

        [Parameter(Mandatory)]
        [string]
        $PolicyPrefix,

        [Parameter()]
        [string]
        $CreateFromPolicyName,

        [Parameter()]
        [string]
        $CreateFromPolicyID,

        [Parameter()]
        [string]
        $DefaultSettings,

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
        $ExpandParams = @{
            'ConfigName'       = $ConfigName
            'ConfigID'         = $ConfigID
            'VersionNumber'    = $VersionNumber
            'PolicyName'       = $CreateFromPolicyName
            'PolicyID'         = $CreateFromPolicyID
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        [string] $ConfigID, $VersionNumber, $CreateFromPolicyID = Expand-AppSecConfigDetails @ExpandParams
        if ($CreateFromPolicyName -and -not $CreateFromPolicyID) {
            throw "Unable to find policy to clone with name '$CreateFromPolicyName'."
        }

        $Body = @{
            policyName      = $PolicyName
            policyPrefix    = $PolicyPrefix
            defaultSettings = $DefaultSettings
        }

        if ($CreateFromPolicyID) {
            $Body['createFromSecurityPolicy'] = $CreateFromPolicyID
        }

        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache, but only if we have config name since it is the key
            if ($AkamaiOptions.EnableDataCache -and $ConfigName) {
                $CacheParams = @{
                    'AppSecConfigName' = $ConfigName
                    'AppSecConfigID'   = $ConfigID
                    'AppSecPolicyName' = $Response.Body.policyName
                    'AppSecPolicyID'   = $Response.Body.policyId
                }
                Set-AkamaiDataCache @CacheParams
            }

            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
