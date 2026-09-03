function Set-EDNSChangeListMasterFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ValueFromPipeline)]
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
        $Path = "/config-dns/v2/changelists/$Zone/recordsets"

        $AdditionalHeaders = @{
            "content-type" = 'text/dns'
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
