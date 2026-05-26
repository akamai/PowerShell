function Get-APIEndpointMultistepGroup {
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $MultistepGroupID,

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
        if ($MultistepGroupID) {
            $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/multistep-groups/$MultistepGroupID"
        }
        else {
            $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/multistep-groups"
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
        if ($MultistepGroupID) {
            return $Response.Body
        }
        else {
            return $Response.Body.multistepGroups
        }
    }
}
