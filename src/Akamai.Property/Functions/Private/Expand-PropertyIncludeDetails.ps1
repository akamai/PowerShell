function Expand-PropertyIncludeDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Alias('CloneIncludeName')]
        [string]
        $IncludeName,

        [Parameter()]
        [Alias('CloneIncludeID')]
        [string]
        $IncludeID,

        [Parameter()]
        [Alias('CreateFromVersion')]
        [Alias('CloneIncludeVersion')]
        [string]
        $IncludeVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractID,

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
    
        if ($IncludeName -ne '') {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $IncludeID = $Global:AkamaiDataCache.Property.Includes.$IncludeName.IncludeID
                $ContractID = $Global:AkamaiDataCache.Property.Includes.$IncludeName.ContractID
                $GroupID = $Global:AkamaiDataCache.Property.Includes.$IncludeName.GroupID
            }
    
            if (-not $IncludeID) {
                Write-Debug "Expand-PropertyIncludeDetails: Finding include with name '$IncludeName'."
                try {
                    $Include = Find-Property -IncludeName $IncludeName -latest @CommonParams
                    $IncludeID = $Include.IncludeId
                    if ($IncludeID -eq '') {
                        throw "Include '$IncludeName' not found."
                    }
                    $ContractID = $Include.contractId
                    $GroupID = $Include.groupId
                }
                catch {
                    throw $_
                }
            }
    
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache) {
                $Global:AkamaiDataCache.Property.Includes.$IncludeName = [ordered] @{ 
                    'IncludeID'  = $IncludeID
                    'ContractID' = $ContractID
                    'GroupID'    = $GroupID
                }
            }
    
            Write-Debug "Expand-PropertyIncludeDetails: IncludeID = $IncludeID."
        }
        if ($IncludeVersion -and $IncludeVersion -notmatch "^[0-9]+$") {
            try {
                if ($null -ne $Local:Include) {
                    $LatestInclude = $Include | Sort-Object -Property IncludeVersion -Descending | Select-Object -First 1
                    $StagingVersion = $Include | Where-Object stagingVersion -eq 'ACTIVE'
                    if ($IncludeVersion -eq 'latest') {
                        $IncludeVersion = $LatestInclude.IncludeVersion
                    }
                    elseif ($IncludeVersion -eq 'production') {
                        $ProductionVersion = $Include | Where-Object productionStatus -eq 'ACTIVE'
                        if ($null -eq $ProductionVersion) {
                            throw "No production-active version of Include $($Include.IncludeName)."
                        }
                        else {
                            $IncludeVersion = $ProductionVersion.IncludeVersion
                        }
                    }
                    elseif ($IncludeVersion -eq 'staging') {
                        $StagingVersion = $Include | Where-Object stagingStatus -eq 'ACTIVE'
                        if ($null -eq $StagingVersion) {
                            throw "No staging-active version of Include $($Include.IncludeName)."
                        }
                        else {
                            $IncludeVersion = $StagingVersion.IncludeVersion
                        }
                    }
                }
                else {
                    Write-Debug "Expand-IncludeDetails: Retrieving versions of Include with ID '$IncludeID'."
                    if ($ContractID -and $GroupID) {
                        $Include = Get-PropertyInclude -IncludeID $IncludeID -GroupID $GroupID -ContractId $ContractId @CommonParams
                    }
                    else {
                        $Include = Get-PropertyInclude -IncludeID $IncludeID @CommonParams
                        $ContractID = $Include.contractId
                        $GroupID = $Include.groupId
                    }
    
                    if ($IncludeVersion -eq 'latest') {
                        $IncludeVersion = $Include.latestVersion
                    }
                    elseif ($IncludeVersion -eq 'production') {
                        if ($Include.productionVersion) {
                            $IncludeVersion = $Include.productionVersion
                        }
                        else {
                            throw "No production-active version of Include $($Include.IncludeName)."
                        }
                    }
                    elseif ($IncludeVersion -eq 'staging') {
                        if ($Include.stagingVersion) {
                            $IncludeVersion = $Include.stagingVersion
                        }
                        else {
                            throw "No staging-active version of Include $($Include.IncludeName)."
                        }
                    }
                }
            }
            catch {
                throw $_
            }
            Write-Debug "Expand-IncludeDetails: IncludeVersion = $IncludeVersion."
        }
    
        return $IncludeID, $IncludeVersion, $GroupID, $ContractID
    }
}