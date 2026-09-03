function Restore-EDNSZoneVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("UUID")]
        [string]
        $VersionID,

        [Parameter(ValueFromPipelineByPropertyName)]
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
        $Path = "/config-dns/v2/zones/$Zone/versions/$VersionID/recordsets/activate"

        $QueryParameters = @{
            'comment' = $Comment
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
        return $Response.Body
    }
}
