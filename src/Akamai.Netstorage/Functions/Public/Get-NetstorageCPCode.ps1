function Get-NetstorageCPCode {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [switch]
        $Unused,
        
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
        if ($Unused) {
            $Path = "/storage/v1/cpcodes/unused"
        }
        else {
            $Path = "/storage/v1/cpcodes/used"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.items
    }

}
