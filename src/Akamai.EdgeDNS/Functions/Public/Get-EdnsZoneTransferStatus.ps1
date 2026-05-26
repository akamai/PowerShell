function Get-EDNSZoneTransferStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
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
    
    begin {
        $CollatedZones = New-Object System.Collections.Generic.List[string]
    }

    process {
        foreach ($SingleZone in $Zone) {
            $CollatedZones.Add($SingleZone)
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/zone-transfer-status"

        $Body = @{
            'zones' = $CollatedZones
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.zones
    }
}
