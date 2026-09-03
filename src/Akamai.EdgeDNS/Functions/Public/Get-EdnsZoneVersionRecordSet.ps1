function Get-EDNSZoneVersionRecordSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory)]
        [Alias("UUID")]
        [string]
        $VersionID,

        [Parameter()]
        [string[]]
        $Types,

        [Parameter()]
        [string]
        $Search,

        [Parameter()]
        [ValidateSet('name', 'type')]
        [string[]]
        $SortBy,
        
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
        $Path = "/config-dns/v2/zones/$Zone/versions/$VersionID/recordsets"

        if ($SortBy) {
            $SortByString = $SortBy -join ","
        }

        if ($Types) {
            $TypesString = $Types -join ","
        }

        $QueryParameters = @{
            'sortBy'  = $SortByString
            'types'   = $TypesString
            'search'  = $Search
            'showAll' = $true
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.recordsets
    }
}
