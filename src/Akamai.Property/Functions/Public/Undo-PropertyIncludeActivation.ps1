function Undo-PropertyIncludeActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Restore-PropertyInclude')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

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
        $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters

        $Path = "/papi/v1/includes/$IncludeID/activations/$ActivationId"
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
