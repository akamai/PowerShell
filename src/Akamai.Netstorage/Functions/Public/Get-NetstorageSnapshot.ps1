function Get-NetstorageSnapshot {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $SnapShotID,

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
        if ($SnapShotID) {
            $Path = "/storage/v1/site-snapshots/$SnapShotID"
        }
        else {
            $Path = "/storage/v1/site-snapshots"
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
        if ($SnapShotID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}
