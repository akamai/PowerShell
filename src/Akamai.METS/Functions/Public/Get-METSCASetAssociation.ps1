function Get-METSCASetAssociation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter()]
        [ValidateSet('enrollments', 'properties')]
        [string]
        $AssociationType,

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
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/associations"
        $QueryParameters = @{
            'associationType' = $AssociationType
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
        return $Response.Body.associations
    }
}