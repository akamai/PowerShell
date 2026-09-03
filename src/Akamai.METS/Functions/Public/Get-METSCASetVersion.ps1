function Get-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter()]
        [int]
        $Version,

        [Parameter()]
        [switch]
        $IncludeCertificates,

        [Parameter()]
        [switch]
        $ActiveVersionsOnly,

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
        $QueryParameters = @{
            'includeCertificates' = $PSBoundParameters.IncludeCertificates.IsPresent
            'activeVersionsOnly'  = $PSBoundParameters.ActiveVersionsOnly.IsPresent
        }
        if ($Version) {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version"
        }
        else {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions"
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
        if ($Version) {
            return $Response.Body
        }
        else {
            return $Response.Body.versions
        }
    }
}
