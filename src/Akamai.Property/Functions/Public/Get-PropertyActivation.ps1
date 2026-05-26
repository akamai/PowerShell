function Get-PropertyActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter()]
        [string]
        $ActivationID,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        if ($ActivationID) {
            $Path = "/papi/v1/properties/$PropertyID/activations/$ActivationID"
        }
        else {
            $Path = "/papi/v1/properties/$PropertyID/activations"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.activations.items
    }
}
