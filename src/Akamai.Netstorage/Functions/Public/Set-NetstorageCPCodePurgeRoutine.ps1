function Set-NetstorageCPCodePurgeRoutine {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $CPCodeID,
        
        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,
        
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

        # Convert body to object in order to check it is an array of objects, rather than a single
        if ($Body -is 'String') {
            $Body = ConvertFrom-Json $Body
        }
        if ($Body -isnot 'Array') {
            $Body = @($Body)
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}
