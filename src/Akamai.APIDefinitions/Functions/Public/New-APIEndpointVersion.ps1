function New-APIEndpointVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]
        $APIEndpointName,

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName)]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('versionNumber')]
        $CloneVersionNumber,

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
        $APIEndpointID, $CloneVersionNumber = Expand-APIEndpointDetails @PSBoundParameters
        $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$CloneVersionNumber/cloneVersion"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

