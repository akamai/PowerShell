function Get-METSCASet {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(ParameterSetName = 'Get one by name')]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CASetNamePrefix,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ActivatedOn,

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
        $QueryParameters = @{
            'caSetNamePrefix' = $CASetNamePrefix
            'activatedOn'     = $ActivatedOn
        }

        if ($CASetID) {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID"
        }
        else {
            $Path = "/mtls-edge-truststore/v2/ca-sets"
        }

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            $Response = Invoke-AkamaiRequest @RequestParams
            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                if ($CASetID) {
                    Set-AkamaiDataCache -METSCaSetName $Response.Body.caSetName -METSCaSetID $Response.Body.caSetId
                }
                else {
                    # Process is delete first, such that any live sets with the same name win
                    $DeletedCASets = @($Response.Body.caSets | Where-Object caSetStatus -eq 'DELETED')
                    $LiveCASets = @($Response.Body.caSets | Where-Object caSetStatus -ne 'DELETED')
                    foreach ($CASet in @($DeletedCASets + $LiveCASets)) {
                        Set-AkamaiDataCache -METSCaSetName $CASet.caSetName -METSCaSetID $CASet.caSetId
                    }
                }
            }

            if ($CASetID) {
                return $Response.Body
            }
            elseif ($CASetName) {
                return $Response.Body.caSets | Where-Object caSetName -eq $CASetName
            }
            else {
                return $Response.body.caSets
            }
        }
        catch {
            throw $_
        }
    }
}
