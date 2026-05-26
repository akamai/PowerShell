function Get-BodyObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        $Source
    )

    if ($Source -is 'String') {
        # Trim whitespace
        $Source = $Source.Trim()
        # Handle JSON array
        if ($Source.StartsWith('[')) {
            $BodyObject = ConvertFrom-Json -InputObject $Source -AsArray -NoEnumerate
        }
        # Handle standard JSON object
        elseif ($Source.StartsWith('{') -and $Source.EndsWith('}')) {
            $BodyObject = ConvertFrom-Json -InputObject $Source
        }
        # If none of the above, just use string as-is
        else {
            $BodyObject = $Source
        }
    }
    elseif ($Source -is 'Hashtable') {
        $BodyObject = [PScustomObject] $Source
    }
    elseif ($Source -is 'PSCustomObject' -or $Source -is 'Object' -or $Source -is 'Object[]') {
        $BodyObject = $Source
    }
    else {
        throw "Source param is of an unhandled type '$($Source.GetType().Name)'"
    }

    return $BodyObject
}

function Add-APIKeyToCollection {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int64[]]
        $CollectionIDs,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int64[]]
        $KeyIDs,

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

    process {
        $Path = "/apikey-manager-api/v2/keys/assign"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'collectionIds' = $CollectionIDs
                'keyIds'        = $KeyIds
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
        return $Response.Body.keys
    }
}


function Export-APIKey {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

        [Parameter()]
        [string]
        $OutputFileName,

        [Parameter()]
        [switch]
        $PassThru,

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
        if ($OutputFileName) {
            if (-not $OutputFileName.EndsWith('.json') -and -not $OutputFileName.EndsWith('.xml') -and -not $OutputFileName.EndsWith('.csv')) {
                throw "OutputFileName must use either a json, xml or csv file extension"
            }
            if ($OutputFileName.EndsWith('.csv')) {
                $AdditionalHeaders = @{
                    'Accept' = 'text/csv'
                }
            }
            elseif ($OutputFileName.EndsWith('.xml')) {
                $AdditionalHeaders = @{
                    'Accept' = 'application/xml'
                }
            }
        }
    
        if ($CollectionID) {
            $Path = "/apikey-manager-api/v2/collections/$CollectionID/keys/export"
        }
        else {
            $Path = "/apikey-manager-api/v2/keys/export"
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($OutputFileName) {
            Write-Host 'Writing keys to: ' -NoNewline
            Write-Host $OutputFileName -ForegroundColor Green -NoNewline
            Write-Host '.'
            # JSON
            if ($OutputFileName.EndsWith('.json')) {
                ConvertTo-Json -InputObject @($Response.Body) -Depth 100 | Out-File -FilePath $OutputFileName -Encoding utf8
            }
            # XML
            elseif ($OutputFileName.EndsWith('.xml')) {
                $StringWriter = New-Object System.Io.Stringwriter
                $XMLWriter = New-Object System.Xml.XmlTextWriter($StringWriter)
                $XMLWriter.Formatting = "indented"
                $XMLWriter.IndentChar = " "
                $XMLWriter.Indentation = 4
                $Response.Body.WriteContentTo($XMLWriter)
                $StringWriter.ToString() | Out-File $OutputFileName -Encoding utf8 -NoNewline
            }
            # CSV
            else {
                $ExportParams = @{
                    Path              = $OutputFileName
                    NoTypeInformation = $true
                }
                if ($PSVersionTable.PSVersion -ge '7.0.0') {
                    $ExportParams.UseQuotes = 'AsNeeded'
                }
                $Response.Body | Export-CSV @ExportParams
            }
        }
        if (-not $OutputFileName -or $PassThru) {
            return $Response.Body
        }
    }
}


function Get-APIKey {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $KeyID,

        [Parameter(ParameterSetName = 'Get all')]
        [int64]
        $CollectionID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Filter,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('PENDING_DEPLOYMENT', 'DEPLOYED', 'PENDING_REVOCATION', 'REVOKED')]
        [string]
        $KeyStatus,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('asc', 'desc')]
        [string]
        $SortDirection,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('createdAt', 'id', 'label', 'description')]
        [string]
        $SortColumn,

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
        if ($null -ne $PSBoundParameters.KeyID) {
            $Path = "/apikey-manager-api/v2/keys/$KeyID"
        }
        else {
            $Path = "/apikey-manager-api/v2/keys"
        }

        $QueryParameters = @{
            'collectionId' = $PSBoundParameters.CollectionID
            'filter'       = $Filter
            'keyType'      = $KeyType
            'page'         = $PSBoundParameters.Page
            'pageSize'     = $PSBoundParameters.PageSize
            'sortDirect'   = $SortDirection
            'sortColumn'   = $SortColumn
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($null -ne $PSBoundParameters.KeyID) {
            return $Response.Body
        }
        else {
            return $Response.Body.keys
        }
    }
}


function Get-APIKeyCollection {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

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

    Process {
        if ($CollectionID) {
            $Path = "/apikey-manager-api/v2/collections/$CollectionID"
        }
        else {
            $Path = "/apikey-manager-api/v2/collections"
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
        if ($CollectionID) {
            return $Response.Body
        }
        else {
            return $Response.Body.collections
        }
    }
}


function Get-APIKeyCollectionACL {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

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
        $Path = "/apikey-manager-api/v2/collections/$CollectionID/acl-entries"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
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


function Get-APIKeyCollectionEndpoints {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

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

    Process {
        $Path = "/apikey-manager-api/v2/collections/$CollectionID/endpoints"
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
        return $Response.Body.endpoints
    }
}


function Get-APIKeyCollectionQuota {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

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

    Process {
        $Path = "/apikey-manager-api/v2/collections/$CollectionID/quota-config"
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
        return $Response.Body
    }
}


function Get-APITag {
    [CmdletBinding()]
    Param(
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

    $Path = "/apikey-manager-api/v2/tags"
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
    return $Response.Body.tags
}


function Get-APIThrottlingCounter {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CounterID,

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

    Process {
        if ($CounterID) {
            $Path = "/apikey-manager-api/v2/counters/$CounterID"
        }
        else {
            $Path = "/apikey-manager-api/v2/counters"
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
        if ($CounterID) {
            return $Response.Body
        }
        else {
            return $Response.Body.throttlingCounters
        }
    }
}


function Get-APIThrottlingCounterEndpoints {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CounterID,

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

    Process {
        $Path = "/apikey-manager-api/v2/counters/$CounterID/endpoints"
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
        return $Response.Body.endpoints
    }
}


function Get-APIThrottlingCounterKeyCollections {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CounterID,

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

    Process {
        $Path = "/apikey-manager-api/v2/counters/$CounterID/key-collections"
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
        return $Response.Body.collections
    }
}


function Get-APIThrottlingCounterKeys {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CounterID,

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

    Process {
        $Path = "/apikey-manager-api/v2/counters/$CounterID/keys"
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
        return $Response.Body.keys
    }
}


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


function Move-APIKey {
    [CmdletBinding(DefaultParameterSetName = 'Existing')]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64[]]
        $KeyIds,

        [Parameter(Mandatory, ParameterSetName = 'Existing')]
        [int]
        $DestinationCollectionID,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [string]
        $NewCollectionName,

        [Parameter(ParameterSetName = 'New')]
        [string]
        $NewCollectionDescription,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [string]
        $ContractID,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [int]
        $GroupID,

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
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['int']
    }

    process {
        foreach ($KeyID in $KeyIds) {
            $CollatedKeys.Add($KeyId)
        }
    }

    end {
        $Path = "/apikey-manager-api/v2/keys/move"
        $Body = @{
            'keyIds' = $KeyIDs
        }
        if ($PSCmdlet.ParameterSetName -eq 'Existing') {
            $Body['destinationCollectionId'] = $DestinationCollectionID
        }
        else {
            $Body['newCollectionName'] = $NewCollectionName
            $Body['newCollectionContractId'] = $ContractID
            $Body['newCollectionGroupId'] = $GroupID
            if ($NewCollectionDescription) {
                $Body['newCollectionDescription'] = $NewCollectionDescription
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


function New-APIKeyCollection {
    [CmdletBinding(DefaultParameterSetName = 'Body')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $CollectionName,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $CollectionDescription,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
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

    begin {}

    process {
        $Path = "/apikey-manager-api/v2/collections"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'collectionName'        = $CollectionName
                'collectionDescription' = $CollectionDescription
                'contractId'            = $ContractID
                'groupId'               = $GroupID
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

    end {}
}


function New-APIThrottlingCounter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
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

    begin {}

    process {
        $Path = "/apikey-manager-api/v2/counters"
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

    end {}

}


function Remove-APIKeyCollection {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

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
        $Path = "/apikey-manager-api/v2/collections/$CollectionID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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


function Remove-APIKeyFromCollection {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int64[]]
        $CollectionIDs,
        
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int64[]]
        $KeyIDs,

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

    process {
        $Path = "/apikey-manager-api/v2/keys/unassign"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'collectionIds' = $CollectionIDs
                'keyIds'        = $KeyIDs
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
        return $Response.Body.keys
    }
}


function Remove-APIThrottlingCounter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CounterID,

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
        $Path = "/apikey-manager-api/v2/counters/$CounterID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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


function Reset-APIKeyCollectionQuota {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int64]
        $CollectionID,
        
        [Parameter(Mandatory, ValueFromPipeline)]
        [int64[]]
        $KeyIDs,

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
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['int64']
    }

    process {
        foreach ($KeyID in $KeyIDs) {
            $CollatedKeys.Add($KeyID)
        }
    }
    
    end {
        $Path = "/apikey-manager-api/v2/collections/$CollectionID/quota-reset"
        $Body = @{
            'keyIds' = $CollatedKeys
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


function Reset-APIKeyQuota {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [int64[]]
        $KeyIDs,

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
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['int']
    }

    process {
        foreach ($KeyID in $KeyIDs) {
            $CollatedKeys.Add($KeyID)
        }
    }

    end {
        $Path = "/apikey-manager-api/v2/keys/quota-reset"
        $Body = @{
            'keyIds' = $CollatedKeys
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


function Restore-APIKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [int64[]]
        $KeyIDs,

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
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['int']
    }

    process {
        foreach ($KeyID in $KeyIDs) {
            $CollatedKeys.Add($KeyID)
        }
    }

    end {
        $Path = "/apikey-manager-api/v2/keys/restore"
        $Body = @{
            'keyIds' = $CollatedKeys
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


function Revoke-APIKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [int64[]]
        $KeyIDs,

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
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['int']
    }

    process {
        foreach ($KeyID in $KeyIDs) {
            $CollatedKeys.Add($KeyID)
        }
    }

    end {
        $Path = "/apikey-manager-api/v2/keys/revoke"
        $Body = @{
            'keyIds' = $CollatedKeys
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


function Set-APIKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int64]
        $KeyID,

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

    begin {}

    process {
        $Path = "/apikey-manager-api/v2/keys/$KeyID"
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

    end {}

}


function Set-APIKeyCollection {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

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

    begin {}
    
    process {
        $Path = "/apikey-manager-api/v2/collections/$CollectionID"
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

    end {}
}


function Set-APIKeyCollectionACL {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int64]
        $CollectionID,

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

    begin {}

    process {
        $Path = "/apikey-manager-api/v2/collections/$CollectionID/acl-entries"
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

    end {}
}


function Set-APIKeyCollectionQuota {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int64]
        $CollectionID,

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

    begin {}

    process {
        $Path = "/apikey-manager-api/v2/collections/$CollectionID/quota-config"
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

    end {}

}


function Set-APIThrottlingCounter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('ThrottlingCounterID')]
        [int64]
        $CounterID,

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

    begin {}

    process {
        $Path = "/apikey-manager-api/v2/counters/$CounterID"
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

    end {}

}



# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDmhcLHLv5jBgNS
# pHNAMDs6XTNlfQCCnLIKnIgEJzO6gKCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
# X6hjGl1wSSyYMA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBD
# b2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjYwMjI1MDAw
# MDAwWhcNMjcwMzEwMjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcG
# CysGAQQBgjc8AgECEwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6
# YXRpb24xEDAOBgNVBAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1N
# YXNzYWNodXNldHRzMRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1h
# aSBUZWNobm9sb2dpZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVz
# IEluYzCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAJeMKuhiUI5WSRdG
# IPhNWLpaVPlXbSazhGuvzZxTi623Ht46hiPejDtWB8F8dT2pd+nOWsx5NVgkv7x/
# Tz35cZcWVMDxq/K7wYe9R2GndGgfEL02/j5rslwHr8e6qFzy1axuL/xaGXuBTVrS
# Qw25019l1KalUHwInKLIP7Hw1HLPTacyJNNTsYmOpZNqKIiQe9ivzBd7SuPU0cGi
# 1YHUk4ZQh6Ig5tBx8XZYjTmzbiQr2WWwk/CufaoIPME5zAvmW99S05rAtOqvoUr7
# eoLUQ/TcMMA6eOliAbO5m0w/pv5YDgzhzt9hQez189zZNOkMO6AcHNitJzzsEvCg
# 7fhPHxoXvasRJ0EaCEze0nuVakLPf+mGCLoZYGRctayOn4HP6LEEOGmAnQBZkwFR
# 6zxk0hzAMOkK/p7MV9V6QwOuk9q7WKnIdzS/4RjRtXNxXb2fMNyBEwrwJhdmEhWF
# 0eS0Wd6Uz3IbSr0+XH8FHLflQXFCkPcZKiGPgSCp8rTP3KHr6wIDAQABo4ICAjCC
# Af4wHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFKT3
# RICOlmcsnPu7KwUf9HL4YegLMD0GA1UdIAQ2MDQwMgYFZ4EMAQMwKTAnBggrBgEF
# BQcCARYbaHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmlu
# Z1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hB
# Mzg0MjAyMUNBMS5jcmwwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNB
# NDA5NlNIQTM4NDIwMjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQAD
# ggIBAGSBrSnUReHUzGTy9VC6hy2oDSpu2QNu5j3o/uoaaAy2CgI0hVJRL/OfYinL
# R4hJofuNNKORp2MWXpy52L5PCGtD6/Hf92bMkDl1AP6nXuplt5HvkFPh5kVDbQ7o
# HfI1Pup2IOpKxb00UNwjtKy+38ZCX0dgkASP2vQFamBCG0eTaGUh/9ZH9rz11Nkr
# 9p83Snz/3eW3vOeKAFL3S5RDEMkTvv09540mnzA4J5lKGES2eje/FhwCCQUQBvqC
# voNFNZHyXvW9v8KqX/3CcN1LAtGCy4XnkFjQRPyn+o/OJv5M5yX2Rm5kq9dYpWnD
# U2xgxMR1BZaDf+uDoqGsLo4OqbPV4Dftp2FDs8DHMD8xP6i/k4htaWShkdyjdijr
# 9TBOi+pS9vNlcCKjwLq6aibcbkUk7ef3wxR5imhajsX22vy8Zd9ByAk07BJrccgg
# JGczCtiKcD6LZtP3VjnqhYPSQ4jk6wCruqcTCTwwO7FrIROVrWb2Ro+ph+/a5Llj
# 5ryLyp+6NAgtNwyrkp2WxZviLbh5AXnmg9Pnwrz64UE93LEjI23AWBJsLFdJTbis
# Z/tTgozdVdPZf2Dy2k8xfYZoIq6V1oWiAoQCzb5B9nETV5NGjiMPskJ4GwnlzOvz
# +4IgLQjl0V5I08Qw+3uvPQ8rHHMLbKgncTqSxqtZ73kItOztMYIClDCCApACAQEw
# fTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hB
# Mzg0IDIwMjEgQ0ExAhAGRzH371ShX6hjGl1wSSyYMA0GCWCGSAFlAwQCAQUAoGow
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOnAUBvKvJrME+536qgOidI038MTsPhf
# pPaLCJT5q1BOMA0GCSqGSIb3DQEBAQUABIIBgDIgBHE19o3Q3Nx93NBxpLBuAb34
# sU41NuDDQqR2Hzz1Bla1sTOzJwqii2FMWvcFzOHKzDpwFcz0BXPp1o7X4jWAmPdo
# 7cP6SsSvkqEWRhZu5hiOw1cMqYaeY0aejemrZ5v1C++Vcd9joYpDXrXfd24cdJbD
# GzrkVQ0fuG9N8itX+BpV2MMOmsvJDvQwREGQb6KRIcKNUnNtuIN1IBJKLeh7s57w
# xpi4c9A+RbqLPREMti8dhHg+rZhXquvr1c+bm606RN1p0ENSzidPFSXkUT8LKQZD
# f19zWbxv+Ft+Tyb0ZVl9AVGJggYXJ93ducFcI7YATalSM5zdakefIM/5fbB309XZ
# K//05sLvKYYnX7wv+I4uT5Z8fpGLHNlomav9Uto5IFSgOMPHzv9tLyTH9kjTX0mR
# mRjrWWMu3Pu2sX3RuTQI6kYpcPGSIpkxxbW4B40BU/RNZwEKrdOzsxG/9eVUHu2i
# xJi4rxMtnr4PlYzvWSqkxA5oLvwGE7W+kFBt6w==
# SIG # End signature block
