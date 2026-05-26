function Set-APIEndpointVersionResource {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]
        $APIEndpointName,

        [Parameter(Mandatory, ParameterSetName = 'ID')]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory)]
        [string]
        $VersionNumber,

        [Parameter(Mandatory)]
        [int]
        $APIResourceID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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
        $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/resources/$APIResourceID"

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        $Body = Get-BodyObject -Source $Body
        $Body.PSObject.Members.Remove('createDate')
        $Body.PSObject.Members.Remove('updateDate')
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'Body'             = $Body
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

