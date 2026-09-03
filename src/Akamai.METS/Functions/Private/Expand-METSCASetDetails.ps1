function Expand-METSCASetDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $CASetName,
        
        [Parameter()]
        $CASetID,

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

    $CommonParams = @{
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    if ($CASetName -ne '') {
        # Check cache if enabled
        if ($Global:AkamaiOptions.EnableDataCache) {
            $CASetID = $Global:AkamaiDataCache.METS.CASets.$CASetName.CASetID
        }

        if (-not $CASetID) {
            Write-Debug "Expand-METSCASetDetails: '$CASetName' - Retrieving CASet details."
            $CASet = Get-METSCASet -CASetName $CASetName @CommonParams | Where-Object caSetName -eq $CASetName
            if ($null -eq $CASet) {
                throw "CA Set '$CASetName' not found"
            }
            elseif ($CASet.count -gt 1) {
                # Name match is not exact, so filter for exact name
                $CASet = $CASet | Where-Object { $_.caSetName -eq $CASetName -and $_.caSetStatus -ne 'DELETED' }
                # If you still have more than 1, throw an error as we can't know which one the user wants
                if ($CASet.count -gt 1) {
                    throw "Multiple CA Sets with name '$CASetName' found. Please use -CASetID instead"
                } 
            }
            $CASetID = $CASet.caSetId
        }

        # Add to data cache
        if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.METS.CASets.$CASetName) {
            $Global:AkamaiDataCache.METS.CASets.$CASetName = @{
                'CASetID' = $CASetID
            }
        }
        Write-Debug "Expand-METSCASetDetails: CASetID = $CASetID"
    }

    return $CASetID
}
