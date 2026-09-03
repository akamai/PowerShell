function Set-APIEndpointVersionPIIStatus {
    [CmdletBinding(DefaultParameterSetName = 'Name & Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Name & Attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Name & Request Body')]
        [string]
        $APIEndpointName,

        [Parameter(Mandatory, ParameterSetName = 'ID & Attributes')]
        [Parameter(Mandatory, ParameterSetName = 'ID & Request Body')]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory)]
        [string]
        $VersionNumber,

        [Parameter(Mandatory, ParameterSetName = 'Name & Attributes')]
        [Parameter(Mandatory, ParameterSetName = 'ID & Attributes')]
        [Alias('id')]
        [Int64]
        $ParamID,

        [Parameter(Mandatory, ParameterSetName = 'Name & Attributes')]
        [Parameter(Mandatory, ParameterSetName = 'ID & Attributes')]
        [ValidateSet('DECLINED', 'DEFERRED', 'CONFIRMED')]
        [string]
        $Status,

        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'Name & Request Body')]
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'ID & Request Body')]
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
        $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/piis/status"
        if ($PSCmdlet.ParameterSetName.EndsWith('Attributes')) {
            $Body = @(
                @{
                    'id'     = $ParamID
                    'status' = $Status
                }
            )
        }
        # Wrap body in array if not already
        $Body = Get-BodyObject -Source $Body
        if ($Body -IsNot 'Array') {
            $Body = @($Body)
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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

