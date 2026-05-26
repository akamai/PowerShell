function New-APIKey {
    [CmdletBinding(DefaultParameterSetName = 'Key count')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Key values', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Key count', ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

        [Parameter(ParameterSetName = 'Key values', Mandatory)]
        [string[]]
        $KeyValues,

        [Parameter(ParameterSetName = 'Key count', Mandatory)]
        [int]
        $Count,

        [Parameter(ParameterSetName = 'Key values')]
        [Parameter(ParameterSetName = 'Key count')]
        [string]
        $KeyDescription,

        [Parameter(ParameterSetName = 'Key values')]
        [Parameter(ParameterSetName = 'Key count')]
        [switch]
        $IncrementLabel,

        [Parameter(ParameterSetName = 'Key values')]
        [Parameter(ParameterSetName = 'Key count')]
        [string]
        $Label,

        [Parameter(ParameterSetName = 'Key values')]
        [Parameter(ParameterSetName = 'Key count')]
        [string[]]
        $Tags,

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
        if ($PSCmdlet.ParameterSetName.Contains('Key')) {
            $Body = @{
                'collectionId'   = $CollectionID
                'incrementLabel' = $IncrementLabel.IsPresent
            }

            # Select only one of the 2 options, which should be mutually exclusive anyway
            if ($KeyValues) {
                $Body['keyValues'] = $KeyValues
            }
            elseif ($Count) {
                $Body['count'] = $Count
            }

            if ($KeyDescription) {
                $Body['keyDescription'] = $KeyDescription
            }
            if ($Label) {
                $Body['label'] = $Label
            }
            if ($Tags) {
                $Body['tags'] = $Tags
            }
        }
        else {
            $Body = Get-BodyObject -Source $Body
        }

        if ($null -ne $Body.keyValues) {
            $Path = "/apikey-manager-api/v2/keys"
        }
        else {
            $Path = "/apikey-manager-api/v2/keys/generate"
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
        return $Response.Body.keys
    }
}

