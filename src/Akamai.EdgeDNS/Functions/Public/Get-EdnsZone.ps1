function Get-EDNSZone {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ContractIDs,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $SubzoneGrant,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Types,

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
        if ($Zone) {
            $Path = "/config-dns/v2/zones/$Zone"
        }
        else {
            $Path = "/config-dns/v2/zones"
        }

        $QueryParameters = @{
            'contractIds'  = $ContractIDs
            'sortBy'       = $SortBy
            'types'        = $Types
            'search'       = $Search
            'subzoneGrant' = $PSBoundParameters.SubzoneGrant
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
            return $Response.Body.zones
        }
    }
}
