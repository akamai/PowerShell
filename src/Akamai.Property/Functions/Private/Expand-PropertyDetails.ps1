function Expand-PropertyDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Alias('ClonePropertyName')]
        [string]
        $PropertyName,

        [Parameter()]
        [Alias('ClonePropertyID')]
        [string]
        $PropertyID,

        [Parameter()]
        [Alias('CreateFromVersion')]
        [Alias('ClonePropertyVersion')]
        [string]
        $PropertyVersion,

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
        if ($PropertyName -ne '') {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $PropertyID = $Global:AkamaiDataCache.Property.Properties.$PropertyName.PropertyID
                $ContractID = $Global:AkamaiDataCache.Property.Properties.$PropertyName.ContractID
                $GroupID = $Global:AkamaiDataCache.Property.Properties.$PropertyName.GroupID
            }
            
            if (-not $PropertyID) {
                Write-Debug "Expand-PropertyDetails: Finding property with name '$PropertyName'."
                try {
                    $Property = Find-Property -PropertyName $PropertyName @CommonParams
                    if ($null -eq $Property) {
                        throw "Property '$PropertyName' not found."
                    }
                    $PropertyID = $Property[0].propertyId
                    $ContractID = $Property[0].contractId
                    $GroupID = $Property[0].groupId
                }
                catch {
                    throw $_
                }
            }
    
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache) {
                $Global:AkamaiDataCache.Property.Properties.$PropertyName = [ordered] @{ 
                    'PropertyID' = $PropertyID
                    'ContractID' = $ContractID
                    'GroupID'    = $GroupID
                }
            }
    
            Write-Debug "Expand-PropertyDetails: PropertyID = $PropertyID."
        }
        if ($PropertyVersion -and $PropertyVersion -notmatch "^[0-9]+$") {
            try {
                if ($null -ne $Local:Property) {
                    $LatestProperty = $Property | Sort-Object -Property propertyVersion -Descending | Select-Object -First 1
                    $StagingVersion = $Property | Where-Object stagingVersion -eq 'ACTIVE'
                    if ($PropertyVersion -eq 'latest') {
                        $PropertyVersion = $LatestProperty.propertyVersion
                    }
                    elseif ($PropertyVersion -eq 'production') {
                        $ProductionVersion = $Property | Where-Object productionStatus -eq 'ACTIVE'
                        if ($null -eq $ProductionVersion) {
                            throw "No production-active version of property $($Property.propertyName)."
                        }
                        else {
                            $PropertyVersion = $ProductionVersion.propertyVersion
                        }
                    }
                    elseif ($PropertyVersion -eq 'staging') {
                        $StagingVersion = $Property | Where-Object stagingStatus -eq 'ACTIVE'
                        if ($null -eq $StagingVersion) {
                            throw "No staging-active version of property $($Property.propertyName)."
                        }
                        else {
                            $PropertyVersion = $StagingVersion.propertyVersion
                        }
                    }
                }
                else {
                    Write-Debug "Expand-PropertyDetails: Retrieving versions of property with ID '$PropertyID'."
                    if ($ContractID -and $GroupID) {
                        $Property = Get-Property -PropertyID $PropertyID -GroupID $GroupID -ContractId $ContractId @CommonParams
                    }
                    else {
                        $Property = Get-Property -PropertyID $PropertyID @CommonParams
                        $ContractID = $Property.contractId
                        $GroupID = $Property.groupId
                    }
    
                    if ($PropertyVersion -eq 'latest') {
                        $PropertyVersion = $Property.latestVersion
                    }
                    elseif ($PropertyVersion -eq 'production') {
                        if ($Property.productionVersion) {
                            $PropertyVersion = $Property.productionVersion
                        }
                        else {
                            throw "No production-active version of property $($Property.propertyName)."
                        }
                    }
                    elseif ($PropertyVersion -eq 'staging') {
                        if ($Property.stagingVersion) {
                            $PropertyVersion = $Property.stagingVersion
                        }
                        else {
                            throw "No staging-active version of property $($Property.propertyName)."
                        }
                    }
                }
            }
            catch {
                throw $_
            }
            Write-Debug "Expand-PropertyDetails: PropertyVersion = $PropertyVersion."
        }
    
        return $PropertyID, $PropertyVersion, $GroupID, $ContractID
    }
}