function Get-IVMImage {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [string]
        $PolicySetID,

        [Parameter()]
        [ValidateSet('Staging', 'Production')]
        [string]
        $Network = 'Production',

        [Parameter(ParameterSetName = 'Get one')]
        [string]
        $ImageID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $PolicyID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Limit,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $URL,

        [Parameter()]
        [string]
        $ContractID,

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

    Process {
        $Network = $Network.ToLower()
        if ($ImageID) {
            $Path = "/imaging/v2/network/$Network/images$ImageId"
        }
        else {
            $Path = "/imaging/v2/network/$Network/images"
        }
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }

        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }

        $QueryParameters = @{
            'limit'    = $PSBoundParameters.Limit
            'url'      = $URL
            'policyId' = $PolicyID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($ImageID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}
