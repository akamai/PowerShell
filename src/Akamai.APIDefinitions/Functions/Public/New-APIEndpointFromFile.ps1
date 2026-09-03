function New-APIEndpointFromFile {
    [CmdletBinding(DefaultParameterSetName = 'Attributes with filename')]
    Param(
        [Parameter(ParameterSetName = 'Attributes with URL', Mandatory)]
        [Parameter(ParameterSetName = 'Attributes with file content', Mandatory)]
        [Parameter(ParameterSetName = 'Attributes with filename', Mandatory)]
        [ValidateSet('swagger', 'raml')]
        [string]
        $ImportFileFormat,

        [Parameter(ParameterSetName = 'Attributes with URL', Mandatory)]
        [Parameter(ParameterSetName = 'Attributes with file content', Mandatory)]
        [Parameter(ParameterSetName = 'Attributes with filename', Mandatory)]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Attributes with URL', Mandatory)]
        [Parameter(ParameterSetName = 'Attributes with file content', Mandatory)]
        [Parameter(ParameterSetName = 'Attributes with filename', Mandatory)]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes with URL', Mandatory)]
        [string]
        $ImportURL,

        [Parameter(ParameterSetName = 'Attributes with URL')]
        [string]
        $Root,
        
        [Parameter(ParameterSetName = 'Attributes with file content', Mandatory)]
        [string]
        $ImportFileContent,
        
        [Parameter(ParameterSetName = 'Attributes with filename', Mandatory)]
        [string]
        $ImportFilename,

        [Parameter(Mandatory, ParameterSetName = 'Body', ValueFromPipeline)]
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
        $Path = "/api-definitions/v2/endpoints/files"

        if ($PSCmdlet.ParameterSetName.StartsWith('Attributes')) {
            $Body = @{
                'importFileFormat' = $ImportFileFormat
                'contractId'       = $ContractID
                'groupId'          = $GroupID
            }
            
            if ($ImportURL) {
                $Body['importFileSource'] = 'URL'
                $Body['importUrl'] = $ImportURL 
                if ($Root) { $Body['root'] = $Root }
            }
            elseif ($ImportFileContent) {
                $Body['importFileSource'] = 'BODY_BASE64'
                $Body['importFileContent'] = $ImportFileContent
            }
            elseif ($ImportFilename) {
                $Body['importFileSource'] = 'BODY_BASE64'
                $Body['importFileContent'] = ConvertTo-Base64 -UnencodedString (Get-Content -Path $ImportFilename -Raw)
            }
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

