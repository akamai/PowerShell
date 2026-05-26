function Get-AppSecPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Get all by config name')]
    Param(
        [Parameter(ParameterSetName = 'Get one by config & policy name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by config name & policy ID', Mandatory)]
        [Parameter(ParameterSetName = 'Get all by config name', Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Get one by config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get one by config & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all by config ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Get one by config & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Get one by config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Get one by config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get one by config & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

        [Parameter(ParameterSetName = 'Get all by config name')]
        [Parameter(ParameterSetName = 'Get all by config ID')]
        [switch]
        $NotMatched,

        [Parameter(ParameterSetName = 'Get all by config name')]
        [Parameter(ParameterSetName = 'Get all by config ID')]
        [switch]
        $Detail,

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
        if ($PolicyID) {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID"
        }
        else {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies"
        }
        $QueryParameters = @{
            notMatched = $PSBoundParameters.NotMatched
            detail     = $PSBoundParameters.Detail
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache -and $ConfigName) {
                # Only adding if we have config name, since it is the key
                $CacheParams = @{
                    'AppSecConfigName' = $ConfigName
                }
                if ($PSCmdlet.ParameterSetName.contains('all')) {
                    foreach ($Policy in $Response.Body.policies) {
                        $CacheParams.AppSecPolicyName = $Policy.policyName
                        $CacheParams.AppSecPolicyID = $Policy.policyId
                        Set-AkamaiDataCache @CacheParams
                    }
                }
                else {
                    $CacheParams.AppSecPolicyName = $Response.Body.policyName
                    $CacheParams.AppSecPolicyID = $Response.Body.policyId
                    Set-AkamaiDataCache @CacheParams
                }
            }

            if ($PSCmdlet.ParameterSetName.contains('all')) {
                return $Response.Body.policies
            }
            else {
                return $Response.Body
            }
        }
        catch {
            throw $_
        }
    }
}
