function Get-EDNSTSIGKey {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param (
        [Parameter(ParameterSetName = 'Get one', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Get all')]
        $ContractIDs,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
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

        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/config-dns/v2/zones/$Zone/key"
        }
        else {
            $Path = "/config-dns/v2/keys"
        }

        $QueryParameters = @{
            'contractIds' = $ContractIDs -join ','
            'search'      = $Search
            'sortBy'      = $SortBy -join ','
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
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            return $Response.Body.keys
        }
        else {
            return $Response.Body
        }
    }
}
