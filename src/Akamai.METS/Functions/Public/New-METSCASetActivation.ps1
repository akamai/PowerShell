function New-METSCASetActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Deploy-METSCASet')]
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

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

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
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/activate"
        $Body = @{
            'network' = $Network
        }

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
