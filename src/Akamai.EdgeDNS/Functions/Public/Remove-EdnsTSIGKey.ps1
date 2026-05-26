function Remove-EDNSTSIGKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,
        
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
        $Method = 'DELETE'
        $Path = "/config-dns/v2/zones/$Zone/key"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
