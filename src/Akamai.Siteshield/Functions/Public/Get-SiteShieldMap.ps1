function Get-SiteShieldMap {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ID,

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
        if ($PSBoundParameters.ID) {
            $Path = "/siteshield/v1/maps/$ID"
        }
        else {
            $Path = "/siteshield/v1/maps"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($ID) {
            return $Response.Body
        }
        else {
            return $Response.Body.siteShieldMaps
        }
    }
}
