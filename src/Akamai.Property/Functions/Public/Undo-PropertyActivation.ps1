function Undo-PropertyActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Restore-Property')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Mandatory)]
        [string]
        $ActivationId,

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

        $Path = "/papi/v1/properties/$PropertyID/activations/$ActivationID"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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
