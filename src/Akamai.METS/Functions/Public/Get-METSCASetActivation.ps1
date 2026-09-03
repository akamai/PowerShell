function Get-METSCASetActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $Version,

        [Parameter()]
        [int]
        $ActivationID,

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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        if ($ActivationID) {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/activations/$ActivationID"
        }
        else {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/activations"
        }

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($ActivationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.activations
        }
    }
}
