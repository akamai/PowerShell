function Get-APIEndpointVersionResourceOperation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]
        $APIEndpointName,

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName)]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $VersionNumber,

        [Parameter(Mandatory)]
        [int]
        $APIResourceID,

        [Parameter()]
        [string]
        $OperationID,

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
        $APIEndpointID, $VersionNumber = Expand-APIEndpointDetails @PSBoundParameters
        if ($OperationID) {
            $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/resources/$APIResourceID/operations/$OperationID"
        }
        else {
            $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/resources/$APIResourceID/operations"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($OperationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.operations
        }
    }
}

