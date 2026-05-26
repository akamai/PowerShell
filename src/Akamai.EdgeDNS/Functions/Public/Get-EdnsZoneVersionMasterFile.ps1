function Get-EDNSZoneVersionMasterFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("UUID")]
        [string]
        $VersionID,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/versions/$VersionID/zone-file"

        $AdditionalHeaders = @{
            'accept' = 'text/dns'
        }

        $RequestParams = @{
            'Method'          = $Method
            'Path'            = $Path
            EdgeRCFile        = $EdgeRCFile
            Section           = $Section
            AccountSwitchKey  = $AccountSwitchKey
            AdditionalHeaders = $AdditionalHeaders
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
