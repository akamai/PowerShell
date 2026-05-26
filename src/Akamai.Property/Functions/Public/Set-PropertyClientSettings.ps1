function Set-PropertyClientSettings {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $RuleFormat,

        [Parameter(Mandatory)]
        [bool]
        $UsePrefixes,
        
        [Parameter()]
        [bool]
        $UpgradeRules,

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

    $AcceptedRuleFormats = Get-RuleFormat -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
    if ($RuleFormat -notin $AcceptedRuleFormats) {
        throw "$RuleFormat is not an accepted rule format. Run Get-RuleFormat for a full list."
    }
    
    $Path = "/papi/v1/client-settings"
    $Body = @{ 
        'ruleFormat'  = $RuleFormat
        'usePrefixes' = $UsePrefixes
    }
    if ($null -ne $PSBoundParameters.UpgradeRules) {
        $Body['upgradeRules'] = $UpgradeRules
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
