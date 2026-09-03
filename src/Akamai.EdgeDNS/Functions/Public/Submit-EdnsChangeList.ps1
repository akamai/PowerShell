function Submit-EDNSChangeList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter()]
        [switch]
        $SkipSignAndServeSafetyCheck,

        [Parameter()]
        [string]
        $Comment,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/changelists/$Zone/submit"

        $QueryParameters = @{
            'skipSignAndServeSafetyCheck' = $SkipSignAndServeSafetyCheck
            'comment'                     = $Comment
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Zone) {
            return $Response.Body
        }
        else {
            return $Response.Body
        }
    }
}
