function Import-APIKey {
    [CmdletBinding(DefaultParameterSetName = 'Body')]
    Param(
        [Parameter(Mandatory)]
        [int64]
        $CollectionID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $KeyValue,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $KeyDescription,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Label,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Tags,

        [Parameter(ParameterSetName = 'File')]
        [string]
        $InputFile,

        [Parameter(ParameterSetName = 'Body', ValueFromPipeline, Mandatory)]
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

    begin {
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['object']
    }

    process {
        if ($Body -isnot 'String') {
            $CollatedKeys.Add($Body)
        }
    }

    end {
        $Path = "/apikey-manager-api/v2/collections/$CollectionID/import-keys"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @(
                @{ 'keyValue' = $KeyValue }
            )

            if ($KeyDescription) {
                $Body[0]['keyDescription'] = $KeyDescription
            }
            if ($Label) {
                $Body[0]['label'] = $Label
            }
            if ($Tags) {
                $Body[0]['tags'] = $Tags
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'File') {
            $Body = Get-Content $InputFile -Raw
            if ($InputFile.EndsWith('.json')) {
                # Handle single item file by wrapping in array
                if (-not ($Body -match '^[\s]*\[[\s\S]*\][\s]*$')) {
                    $Body = "[$Body]"
                }
            }
            elseif ($InputFile.EndsWith('.csv')) {
                $AdditionalHeaders = @{
                    'Content-Type' = 'text/csv'
                }
            }
            elseif ($InputFile.EndsWith('.xml')) {
                $AdditionalHeaders = @{
                    'Content-Type' = 'application/xml'
                }
            }
            elseif (-not $InputFile.EndsWith('.json')) {
                throw "Only csv, xml and json files are supported."
            }
        }
        elseif ($CollatedKeys.Count -gt 0) {
            $Body = $CollatedKeys
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.Keys
    }

}

