function Expand-EdgeWorkerDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $EdgeWorkerName,

        [Parameter()]
        $EdgeWorkerID,

        [Parameter()]
        [string]
        $Version,
        
        [Parameter()]
        [string]
        $ActivationID,
        
        [Parameter()]
        [string]
        $DeactivationID,

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
    
        $ProductionActivationRetrieved = $false
        $StagingActivationRetrieved = $false
    
        if ($EdgeWorkerName) {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $EdgeWorkerID = $Global:AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName.EdgeWorkerID
            }
    
            try {
                $EdgeWorker = (Get-EdgeWorker @CommonParams) | Where-Object name -eq $EdgeWorkerName
                if ($EdgeWorker.count -gt 1) {
                    throw "Multiple EdgeWorkers found with name '$EdgeWorkerName'. Use -EdgeWorkerID instead to specify which one you wish to use."
                }
                $EdgeWorkerID = $EdgeWorker.edgeWorkerId
                if (-not $EdgeWorkerID) {
                    throw "EdgeWorker $EdgeWorkerName not found."
                }
            }
            catch {
                throw $_
            }
    
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName) {
                $Global:AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName = @{'EdgeWorkerID' = $EdgeWorkerID }
            }
            Write-Debug "Expand-EdgeWorkerDetails: EdgeWorkerID = $EdgeWorkerID."
        }
    
        # ---- Expand version
        if ($Version.ToLower() -in "latest", "production", "staging") {
            if ($Version.ToLower() -eq 'latest') {
                try {
                    $Versions = Get-EdgeWorkerVersion -EdgeWorkerID $EdgeWorkerID @CommonParams | Sort-Object -Property sequenceNumber -Descending
                }
                catch {
                    throw $_
                }
                $Version = $Versions[0].version
            }
            elseif ($Version.ToLower() -eq 'production') {
                try {
                    Write-Debug "Expand-EdgeWorkerDetails: retrieving active production activation."
                    $ProductionActivation = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID -ActiveOnNetwork -Network PRODUCTION @CommonParams
                    $ProductionActivationRetrieved = $true
                }
                catch {
                    throw "Failed to retrieve production activation: $_."
                }
                if ($ProductionActivation) {
                    $Version = $ProductionActivation.version
                }
                else {
                    throw "No production-active version of EdgeWorker $EdgeWorkerID."
                }
            }
            elseif ($Version.ToLower() -eq 'staging') {
                try {
                    Write-Debug "Expand-EdgeWorkerDetails: retrieving active staging activation."
                    $StagingActivation = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID -ActiveOnNetwork -Network STAGING @CommonParams
                    $StagingActivationRetrieved = $true
                }
                catch {
                    throw "Failed to retrieve staging activation: $_."
                }
                if ($StagingActivation) {
                    $Version = $StagingActivation.version
                }
                else {
                    throw "No staging-active version of EdgeWorker $EdgeWorkerID."
                }
            }
        }
    
        # ---- Expand ActivationID
        if ($ActivationID.ToLower() -in 'latest', 'production', 'staging') {
            if ($ActivationID.ToLower() -eq 'latest') {
                try {
                    $Activations = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID @CommonParams
                    $ActivationID = $Activations[0].activationId
                }
                catch {
                    throw $_
                }
            }
            elseif ($ActivationID.ToLower() -eq 'production') {
                if ($ProductionActivationRetrieved -eq $false) {
                    try {
                        Write-Debug "Expand-EdgeWorkerDetails: retrieving active production activation."
                        $ProductionActivation = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID -ActiveOnNetwork -Network PRODUCTION @CommonParams
                    }
                    catch {
                        throw "Failed to retrieve production activation: $_."
                    }
                }
                if ($ProductionActivation) {
                    $ActivationID = $ProductionActivation.activationId
                }
                else {
                    throw "No production-active version of EdgeWorker $EdgeWorkerID."
                }
            }
            elseif ($ActivationID.ToLower() -eq 'staging') {
                if ($StagingActivationRetrieved -eq $false) {
                    try {
                        Write-Debug "Expand-EdgeWorkerDetails: retrieving active staging activation."
                        $StagingActivation = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID -ActiveOnNetwork -Network STAGING @CommonParams
                    }
                    catch {
                        throw "Failed to retrieve staging activation: $_."
                    }
                }
                if ($StagingActivation) {
                    $ActivationID = $StagingActivation.activationId
                }
                else {
                    throw "No staging-active version of EdgeWorker $EdgeWorkerID."
                }
            }
        }
        
        # ---- Expand DeactivationID
        if ($DeactivationID.ToLower() -eq 'latest') {
            try {
                $Deactivations = Get-EdgeWorkerDeactivation -EdgeWorkerID $EdgeWorkerID @CommonParams
                $DeactivationID = $Deactivations[0].deactivationId
            }
            catch {
                throw $_
            }
        }
    
        return $EdgeWorkerID, $Version, $ActivationID, $DeactivationID
    }
}