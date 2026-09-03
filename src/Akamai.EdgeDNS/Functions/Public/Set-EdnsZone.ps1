function Set-EDNSZone {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter()]
        [switch]
        $SkipSignAndServeSafetyCheck, 
        
        [Parameter(ValueFromPipeline)]
        $Body,     

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
        $Method = 'PUT'
        $Path = "/config-dns/v2/zones/$Zone"

        $QueryParameters = @{
            'skipSignAndServeSafetyCheck' = $SkipSignAndServeSafetyCheck.IsPresent
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Zone) {
            return $Response.Body
        }
        else {
            return $Response.Body.zones
        }
    }
}
