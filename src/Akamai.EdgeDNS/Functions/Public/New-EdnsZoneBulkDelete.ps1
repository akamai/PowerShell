function New-EDNSZoneBulkDelete {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Zones')]
        [string[]]
        $Zone,

        [Parameter()]
        [switch] 
        $BypassSafetyChecks,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        foreach ($SingleZone in $Zone) {
            $CollatedZones.Add($SingleZone)
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/delete-requests"

        $QueryParameters = @{
            'bypassSafetyChecks' = $BypassSafetyChecks
        }

        $Body = @{
            'zones' = $CollatedZones
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
        return $Response.Body
    }
}
