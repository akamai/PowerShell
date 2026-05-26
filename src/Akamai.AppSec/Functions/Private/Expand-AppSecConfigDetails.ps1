function Expand-AppSecConfigDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $ConfigName,

        [Parameter()]
        $ConfigID,

        [Parameter()]
        [Alias('CreateFromVersion')]
        [string]
        $VersionNumber,

        [Parameter()]
        [string]
        $PolicyName,

        [Parameter()]
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
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    process {
        $CommonParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        if ($ConfigName -ne '') {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $ConfigID = $Global:AkamaiDataCache.AppSec.Configs.$ConfigName.ConfigID
            }
    
            if (-not $ConfigID) {
                Write-Debug "Expand-AppSecConfigDetails: '$ConfigName' - Retrieving Config details."
                $Config = Get-AppSecConfiguration @CommonParams | Where-Object { $_.name -eq $ConfigName }
                if ($Config) {
                    $ConfigID = $Config.id
                }
                else {
                    throw "Security config '$ConfigName' not found."
                }
            }
            
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.AppSec.Configs.$ConfigName) {
                $Global:AkamaiDataCache.AppSec.Configs.$ConfigName = @{
                    'ConfigID' = $ConfigID
                    'Policies' = @{}
                }
            }
            Write-Debug "Expand-AppSecConfigDetails: ConfigID = $ConfigID."
        }
        if ($VersionNumber -and $VersionNumber -notmatch '^[0-9]+$') {
            if (-not $Config) {
                Write-Debug "Expand-AppSecConfigDetails: '$ConfigID' - Retrieving Config."
                $Config = Get-AppSecConfiguration -ConfigID $ConfigID @CommonParams
            }
    
            if ($VersionNumber -eq 'latest') {
                $VersionNumber = $Config.latestVersion
            }
            if ($VersionNumber -eq 'production') {
                if ($null -eq $Config.productionVersion) {
                    throw "No production-active version of config '$($Config.name)'."
                }
                else {
                    $VersionNumber = $Config.productionVersion
                }
            }
            if ($VersionNumber -eq 'staging') {
                if ($null -eq $Config.stagingVersion) {
                    throw "No staging-active version of config '$($Config.name)'."
                }
                else {
                    $VersionNumber = $Config.stagingVersion
                }
            }
            Write-Debug "Expand-AppSecConfigDetails: VersionNumber = $VersionNumber."
        }
        if ($PolicyName -ne '') {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $PolicyID = $Global:AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName.PolicyID
            }
    
            if (-not $PolicyID) {
                Write-Debug "Expand-AppSecConfigDetails: '$PolicyName' - Retrieving policy details."
                $Policy = Get-AppSecPolicy -ConfigID $ConfigID -VersionNumber $VersionNumber @CommonParams | Where-Object { $_.policyName -eq $PolicyName }
                if ($Policy) {
                    $PolicyID = $Policy.policyId
                }
                else {
                    throw "Security policy '$PolicyName' not found."
                }
            }
            
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache) {
                # Check for cache entry. It may not exist
                if ($Global:AkamaiDataCache.AppSec.Configs.$ConfigName) {
                    $Global:AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName = @{
                        'PolicyID' = $PolicyID
                    }
                }
                else {
                    Write-Debug "Expand-AppSecConfigDetails: Cannot create data cache entry without ConfigName."
                }
            } 
            Write-Debug "Expand-AppSecConfigDetails: PolicyID = $PolicyID."
        }
    
        return $ConfigID, $VersionNumber, $PolicyID
    }
}