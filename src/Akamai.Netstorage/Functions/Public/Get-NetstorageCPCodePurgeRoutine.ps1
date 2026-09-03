function Get-NetstorageCPCodePurgeRoutine {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CPCodeID,
        
        [Parameter()]
        [string]
        $AgeDeletionDirectoryPrefix,
        
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
        $Path = "/storage/v1/cpcodes/$CPCodeID/age-deletions"
        $QueryParameters = @{
            'ageDeletionDirectoryPrefix' = $AgeDeletionDirectoryPrefix
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return @($Response.Body)
    }

}
