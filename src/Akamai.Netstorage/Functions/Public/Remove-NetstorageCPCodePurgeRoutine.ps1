function Remove-NetstorageCPCodePurgeRoutine {
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
        $Body = "ageDeletionDirectoryPrefix=$AgeDeletionDirectoryPrefix"
        $AdditionalHeaders = @{
            'content-type' = 'application/x-www-form-urlencoded'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'DELETE'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}
