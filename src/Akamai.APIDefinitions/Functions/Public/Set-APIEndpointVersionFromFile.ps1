function Set-APIEndpointVersionFromFile {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Name & body')]
        [string]
        $APIEndpointName,

        [Parameter(Mandatory, ParameterSetName = 'ID & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'ID & body')]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory)]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('swagger', 'raml')]
        [string]
        $ImportFileFormat,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('URL', 'BODY_BASE64')]
        [string]
        $ImportFileSource,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ImportURL,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ImportFileContent,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Root,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory, ParameterSetName = 'Name & body', ValueFromPipeline)]
        [Parameter(Mandatory, ParameterSetName = 'ID & body', ValueFromPipeline)]
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
        $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/file"

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'importFileFormat' = $ImportFileFormat
                'importFileSource' = $ImportFileSource
            }
            if ($ImportFileContent) { $Body['importFileContent'] = $ImportFileContent }
            if ($ImportURL) { $Body['importUrl'] = $ImportURL }
            if ($Root) { $Body['root'] = $Root }
            if ($ContractID) { $Body['contractId'] = $ContractID }
            if ($PSBoundParameters.GroupID) { $Body['groupId'] = $GroupID }
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

