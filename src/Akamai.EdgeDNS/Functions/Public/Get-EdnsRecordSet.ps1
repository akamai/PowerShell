function Get-EDNSRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Get one', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Get one', Mandatory)]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Types,

        [Parameter(ParameterSetName = 'Get all')]
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
        $Path = "/config-dns/v2/zones/$Zone/recordsets"

        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
        }

        $QueryParameters = @{
            'sortBy' = $SortBy
            'types'  = $Types
            'search' = $Search
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters['showAll'] = $true
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
