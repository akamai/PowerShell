function Get-EDNSChangeListRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Get all')]
        [string[]]
        $Types,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

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
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/config-dns/v2/changelists/$Zone/names/$Name/types/$Type"
        }
        else {
            $Path = "/config-dns/v2/changelists/$Zone/recordsets"
        }

        $QueryParameters = @{
            'sortBy'  = $SortBy
            'types'   = $Types -join ','
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
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            return $Response.Body
        }
        else {
            return $Response.Body.recordsets
        }
    }
}
