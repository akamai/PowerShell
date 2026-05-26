function Get-BucketActivation {
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
        $HostnameActivationID,

        [Parameter()]
        [switch]
        $IncludeHostnames,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
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

        if ($HostnameActivationID) {
            $Path = "/papi/v1/properties/$PropertyID/hostname-activations/$HostnameActivationID"
        }
        else {
            $Path = "/papi/v1/properties/$PropertyID/hostname-activations"
        }
        $QueryParameters = @{
            includeHostnames = $PSBoundParameters.IncludeHostnames
            contractId       = $ContractId
            groupId          = $GroupID
            offset           = $OffSet
            limit            = $Limit
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
        if ($HostnameActivationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.hostnameActivations.items
        }
    }
}
