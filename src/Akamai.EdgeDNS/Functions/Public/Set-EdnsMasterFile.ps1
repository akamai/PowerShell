function Set-EDNSMasterFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ValueFromPipeline, Mandatory)]
        [string]
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
    
    begin {
        $MasterFile = ""
    }

    process {
        foreach ($Line in $Body) {
            $MasterFile += $Line 
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/$Zone/zone-file"

        $AdditionalHeaders = @{
            'content-type' = 'text/dns'
        }

        $RequestParams = @{
            'Method'            = $Method
            'Path'              = $Path
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $MasterFile
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
