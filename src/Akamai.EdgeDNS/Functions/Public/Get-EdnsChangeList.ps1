function Get-EDNSChangeList {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
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
        $Method = 'GET'
        if ($Zone) {
            $Path = "/config-dns/v2/changelists/$Zone"
        }
        else {
            $Path = "/config-dns/v2/changelists"
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
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
            return $Response.Body.changelists
        }
    }
}
