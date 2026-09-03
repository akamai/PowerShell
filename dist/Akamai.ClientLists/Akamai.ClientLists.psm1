function Expand-ClientListDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        $ListID,

        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    $CommonParams = @{
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    if ($Name -ne '') {
        # Check cache if enabled
        if ($Global:AkamaiOptions.EnableDataCache) {
            $ListID = $Global:AkamaiDataCache.ClientLists.Lists.$Name.ListID
        }

        if (-not $ListID) {
            Write-Debug "Expand-ClientListDetails: '$Name' - Retrieving list details."
            $ClientList = Get-ClientList -Name $Name @CommonParams
            if ($ClientList.count -gt 1) {
                throw "There are multiple client lists with the name '$Name'. Please use -ListID instead."
            }
            elseif ($null -ne $ClientList.listId) {
                # Single item array has been enumerated
                $ListID = $ClientList.listId
            }
            else {
                throw "Client List '$Name' not found."
            }
        }

        # Add to data cache
        if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.ClientLists.Lists.$Name) {
            $Global:AkamaiDataCache.ClientLists.Lists.$Name = @{
                'ListID' = $ListID
            }
        }
        Write-Debug "Expand-ClientListDetails: ListID = $ListID."
    }

    if ($Version -and $Version -notmatch '^[0-9]+$') {
        Write-Debug "Expand-ClientListDetails: '$ListID' - Retrieving list versions."
        if ($null -eq $ClientList) {
            $ClientList = Get-ClientList -ListID $ListID @CommonParams
        }

        if ($Version -eq 'latest') {
            $Version = $ClientList.version
        }
        elseif ($Version -eq 'production') {
            if ($null -eq $ClientList.productionActiveVersion) {
                throw "No production-active version of client list '$($ClientList.name)'."
            }
            else {
                $Version = $ClientList.productionActiveVersion
            }
        }
        elseif ($Version -eq 'staging') {
            if ($null -eq $ClientList.stagingActiveVersion) {
                throw "No staging-active version of client list '$($ClientList.name)'."
            }
            else {
                $Version = $ClientList.stagingActiveVersion
            }
        }
        Write-Debug "Expand-ClientListDetails: Version = $Version."
    }

    return $ListID, $Version
}

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
        throw "Source param is of an unhandled type '$($Source.GetType().Name)'."
    }

    return $BodyObject
}

function Add-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Name & items')]
    param(
        [Parameter(ParameterSetName = 'Name & items', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & items', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & items', ValueFromPipeline, Mandatory)]
        [Parameter(ParameterSetName = 'ID & items', ValueFromPipeline, Mandatory)]
        [Object[]]
        $Items,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
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
        $CollatedItems = New-Object -TypeName System.Collections.Generic.List['object']
    }

    process {
        $Items | ForEach-Object {
            if ($_ -is 'String') {
                $CollatedItems.Add( @{ 'value' = $_ })
            }
            else {
                $CollatedItems.Add($_)
            }
        }
    }

    end {
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/items"
        if ($PSCmdlet.ParameterSetName.Contains('items')) {
            $Body = @{
                'append' = $CollatedItems
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
function Get-ClientList {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param(
        [Parameter(ParameterSetName = 'Get all', Position = 0)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, Mandatory)]
        [string]
        $ListID,

        [Parameter()]
        [switch]
        $IncludeItems,

        [Parameter()]
        [switch]
        $IncludeNetworkList,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IncludeDeprecated,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize = 1000,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Sort,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH', 'USER_ID', 'DOMAIN', 'REQUEST_HEADER_NAME_VALUE')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IncludeMetadata,

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
        if ($ListID) {
            $Path = "/client-list/v1/lists/$ListID"
        }
        else {
            $Path = "/client-list/v1/lists"
        }
        $QueryParameters = @{
            'includeItems'       = $PSBoundParameters.IncludeItems.IsPresent
            'includeDeprecated'  = $PSBoundParameters.IncludeDeprecated.IsPresent
            'search'             = $Search
            'page'               = $PSBoundParameters.Page
            'pageSize'           = $PageSize
            'sort'               = $Sort
            'type'               = $Type
            'includeNetworkList' = $PSBoundParameters.IncludeNetworkList.IsPresent
            'name'               = $Name
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                if ($ListID) {
                    Set-AkamaiDataCache -ClientListName $Response.Body.Name -ClientListID $Response.Body.listId
                }
                else {
                    foreach ($List in $Response.Body.content) {
                        Set-AkamaiDataCache -ClientListName $List.Name -ClientListID $List.listId
                    }
                }
            }

            # Return response
            if ($ListID -or $IncludeMetadata) {
                return $Response.Body
            }
            else {
                return $Response.Body.content
            }
        }
        catch {
            throw $_
        }
    }
}

function Get-ClientListActivation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $ActivationID,

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
        $Path = "/client-list/v1/activations/$ActivationID"
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

function Get-ClientListActivationStatus {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $ListID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Environment,

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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/environments/$Environment/status"
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

function Get-ClientListContractsGroups {
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

    process {
        $Path = "/client-list/v1/contracts-groups"
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

function Get-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $ListID,

        [Parameter()]
        [string]
        $Include,

        [Parameter()]
        [string]
        $Search,

        [Parameter()]
        [int]
        $Page,

        [Parameter()]
        [int]
        $PageSize = 1000,

        [Parameter()]
        [string]
        $Sort,

        [Parameter()]
        [switch]
        $IncludeMetadata,

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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/items"
        $QueryParameters = @{
            'include'  = $Include
            'search'   = $Search
            'page'     = $PSBoundParameters.Page
            'pageSize' = $PageSize
            'sort'     = $Sort
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
        if ($IncludeMetadata) {
            return $Response.Body
        }
        else {
            return $Response.Body.content
        }
    }
}

function Get-ClientListSnapshot {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ListID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $Version,

        [Parameter()]
        [string]
        $Search,

        [Parameter()]
        [int]
        $Page,

        [Parameter()]
        [int]
        $PageSize = 1000,

        [Parameter()]
        [string]
        $Sort,

        [Parameter()]
        [switch]
        $IncludeMetadata,

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
        $ListID, $Version = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/versions/$Version/snapshot"
        $QueryParameters = @{
            'search'   = $Search
            'page'     = $PSBoundParameters.Page
            'pageSize' = $PSBoundParameters.PageSize
            'sort'     = $Sort
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
        if ($IncludeMetadata) {
            return $Response.Body
        }
        else {
            return $Response.Body.content
        }
    }
}

function Get-ClientListTag {
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

    process {
        $Path = "/client-list/v1/lists/tags"
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
}

function Get-ClientListUsage {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $ListID,

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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/usage"
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

function Import-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Name & file')]
    Param(
        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'Name & items', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & items', Mandatory)]
        [string]
        $ListID,

        [Parameter(Mandatory)]
        [ValidatePattern('[\d]+|latest')]
        [string]
        $Version,

        [Parameter(Mandatory, ParameterSetName = 'Name & file')]
        [Parameter(Mandatory, ParameterSetName = 'ID & file')]
        [string]
        $File,

        [Parameter(Mandatory, ParameterSetName = 'Name & items')]
        [Parameter(Mandatory, ParameterSetName = 'ID & items')]
        [string[]]
        $Items,

        [Parameter(Mandatory)]
        [ValidateSet('MERGE', 'REPLACE')]
        [string]
        $Action,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [switch]
        $IncludeStatus,

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
        $CollatedItems = New-Object -TypeName System.Collections.Generic.List['string']
    }

    process {
        $Items | ForEach-Object {
            $CollatedItems.Add($_)
        }
    }

    end {
        $ListID, $Version = Expand-ClientListDetails @PSBoundParameters
        if ($PSCMDlet.ParameterSetName.Contains('items')) {
            $Path = "/client-list/v1/lists/$ListID/items/import"
            $Body = @{
                'items'   = $CollatedItems
                'action'  = $Action
                'version' = $Version
            }
        }
        else {
            $Path = "/client-list/v1/lists/$ListID/items/import-file"
            $FileContent = Get-Content -Raw $File
            $FileName = (Get-Item $File).Name
            $Boundary = "AKAMAIPOWERSHELL"
            $Body = @"
--$Boundary
Content-Disposition: form-data; name="file"; filename="$FileName"

$FileContent
--$Boundary
Content-Disposition: form-data; name="action"

$Action
--$Boundary
Content-Disposition: form-data; name="version"

$Version
--$Boundary--
"@

            $AdditionalHeaders = @{ 'Content-Type' = "multipart/form-data; boundary=$Boundary" }
        }
        $QueryParameters = @{
            'dryRun' = $PSBoundParameters.DryRun.IsPresent
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.result
        }
    }
}
function New-ClientList {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH', 'USER_ID', 'DOMAIN', 'REQUEST_HEADER_NAME_VALUE')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes')]
        [Object[]]
        $Items,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Notes,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Tags,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
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
        $Path = "/client-list/v1/lists"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'name'       = $Name
                'type'       = $Type
                'contractId' = $ContractID
                'groupId'    = $GroupID
            }
            if ($Notes) { $Body['notes'] = $Notes }
            if ($Tags) { $Body['tags'] = $Tags }
            if ($Items) {
                $Body.items = New-Object -TypeName System.Collections.Generic.List[Object]
                $Items | ForEach-Object {
                    if ($_ -is 'String') {
                        $Body.items.Add( @{ 'value' = $_ })
                    }
                    else {
                        $Body.items.Add($_)
                    }
                }
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                Set-AkamaiDataCache -ClientListName $Response.Body.name -ClientListID $Response.Body.listId
            }

            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function New-ClientListActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    [Alias('Deploy-ClientList')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Comments,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string[]]
        $NotificationRecipients,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $SiebelTicketID,

        [Parameter(ParameterSetName = 'Name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipeline)]
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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v2/lists/$ListID/activations"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'action'  = 'ACTIVATE'
                'network' = $Network
            }
            if ($Comments) { $Body['comments'] = $Comments }
            if ($NotificationRecipients) { $Body['notificationRecipients'] = $NotificationRecipients }
            if ($SiebelTicketID) { $Body['siebelTicketId'] = $SiebelTicketID }
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

function New-ClientListDeactivation {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    [Alias('Disable-ClientList')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Comments,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string[]]
        $NotificationRecipients,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $SiebelTicketID,

        [Parameter(ParameterSetName = 'Name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipeline)]
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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v2/lists/$ListID/activations"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'action' = 'DEACTIVATE'
            }
            if ($Comments) { $Body['comments'] = $Comments }
            if ($NotificationRecipients) { $Body['notificationRecipients'] = $NotificationRecipients }
            if ($SiebelTicketID) { $Body['siebelTicketId'] = $SiebelTicketID }
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

function New-ClientListSubscription {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string[]]
        $Recipients,

        [Parameter(Position = 1, Mandatory)]
        [string[]]
        $UniqueIDs,

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
        $Path = "/client-list/v1/notifications/subscribe"
        $Body = @{
            'recipients' = $Recipients
            'uniqueIds'  = $UniqueIDs
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

function Remove-ClientList {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID', ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [string]
        $ListID,

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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID"
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
        # Remove list from data cache
        Clear-AkamaiDataCache -ClientListID $ListID
        return $Response.Body
    }
}

function Remove-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Name & items')]
    param(
        [Parameter(ParameterSetName = 'Name & items', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & items', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & items', ValueFromPipeline, Mandatory)]
        [Parameter(ParameterSetName = 'ID & items', ValueFromPipeline, Mandatory)]
        [Object[]]
        $Items,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
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
        $CollatedItems = New-Object -TypeName System.Collections.Generic.List['object']
    }

    process {
        $Items | ForEach-Object {
            if ($_ -is 'String') {
                $CollatedItems.Add( @{ 'value' = $_ })
            }
            else {
                $CollatedItems.Add($_)
            }
        }
    }

    end {
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/items"
        if ($PSCmdlet.ParameterSetName.Contains('items')) {
            $Body = @{
                'delete' = $CollatedItems
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
function Remove-ClientListSubscription {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string[]]
        $Recipients,

        [Parameter(Position = 1, Mandatory)]
        [string[]]
        $UniqueIDs,

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
        $Path = "/client-list/v1/notifications/unsubscribe"
        $Body = @{
            'recipients' = $Recipients
            'uniqueIds'  = $UniqueIDs
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

function Set-ClientList {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & attributes', ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $NewName,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Notes,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string[]]
        $Tags,

        [Parameter(ParameterSetName = 'Name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipeline)]
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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'name' = $NewName
            }
            if ($Notes) { $Body['notes'] = $Notes }
            if ($Tags) { $Body['tags'] = $Tags }
        }
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
function Set-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Name & items')]
    param(
        [Parameter(ParameterSetName = 'Name & items', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & items', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & items', ValueFromPipeline, Mandatory)]
        [Parameter(ParameterSetName = 'ID & items', ValueFromPipeline, Mandatory)]
        [Object[]]
        $Items,

        [Parameter(ParameterSetName = 'Name & items')]
        [Parameter(ParameterSetName = 'ID & items')]
        [ValidateSet('update', 'append', 'delete')]
        [String]
        $Operation = 'update',

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
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
        $CollatedItems = New-Object -TypeName System.Collections.Generic.List['object']
    }

    process {
        $Items | ForEach-Object {
            if ($_ -is 'String') {
                $CollatedItems.Add( @{ 'value' = $_ })
            }
            else {
                $CollatedItems.Add($_)
            }
        }
    }

    end {
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/items"
        if ($PSCmdlet.ParameterSetName.Contains('items')) {
            $Body = @{
                $Operation = $CollatedItems
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

function Test-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Items')]
    Param(
        [Parameter(ParameterSetName = 'Items', Mandatory)]
        [string[]]
        $Items,

        [Parameter(ParameterSetName = 'File', Mandatory)]
        [string]
        $File,

        [Parameter(Mandatory)]
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH', 'USER_ID', 'DOMAIN', 'REQUEST_HEADER_NAME_VALUE')]
        [string]
        $ListType,

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
        if ($PSCmdlet.ParameterSetName -eq 'Items') {
            $Path = "/client-list/v1/lists/items/import/validation"
            $Body = @{
                'items'    = $Items
                'listType' = $ListType
            }
        }
        else {
            $Path = "/client-list/v1/lists/items/import-file/validation"
            $FileContent = Get-Content -Raw $File
            $FileName = (Get-Item $File).Name
            $Boundary = "AKAMAIPOWERSHELL"
            $Body = @"
--$Boundary
Content-Disposition: form-data; name="file"; filename="$FileName"

$FileContent
--$Boundary
Content-Disposition: form-data; name="action"

$Action
--$Boundary
Content-Disposition: form-data; name="listType"

$listType
--$Boundary--
"@
            $AdditionalHeaders = @{ 'Content-Type' = "multipart/form-data; boundary=$Boundary" }
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
        return $Response.Body
    }
}


# SIG # Begin signature block
# MIIo2AYJKoZIhvcNAQcCoIIoyTCCKMUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCajOM4yX5P9eGC
# XPAkRAH4sGXQWgq8fBtnmoEdTrXHiKCCDg4wggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggdWMIIFPqADAgECAhAGRzH371ShX6hjGl1wSSyYMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjYwMjI1MDAwMDAwWhcNMjcwMzEw
# MjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEDAOBgNV
# BAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRz
# MRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1haSBUZWNobm9sb2dp
# ZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVzIEluYzCCAaIwDQYJ
# KoZIhvcNAQEBBQADggGPADCCAYoCggGBAJeMKuhiUI5WSRdGIPhNWLpaVPlXbSaz
# hGuvzZxTi623Ht46hiPejDtWB8F8dT2pd+nOWsx5NVgkv7x/Tz35cZcWVMDxq/K7
# wYe9R2GndGgfEL02/j5rslwHr8e6qFzy1axuL/xaGXuBTVrSQw25019l1KalUHwI
# nKLIP7Hw1HLPTacyJNNTsYmOpZNqKIiQe9ivzBd7SuPU0cGi1YHUk4ZQh6Ig5tBx
# 8XZYjTmzbiQr2WWwk/CufaoIPME5zAvmW99S05rAtOqvoUr7eoLUQ/TcMMA6eOli
# AbO5m0w/pv5YDgzhzt9hQez189zZNOkMO6AcHNitJzzsEvCg7fhPHxoXvasRJ0Ea
# CEze0nuVakLPf+mGCLoZYGRctayOn4HP6LEEOGmAnQBZkwFR6zxk0hzAMOkK/p7M
# V9V6QwOuk9q7WKnIdzS/4RjRtXNxXb2fMNyBEwrwJhdmEhWF0eS0Wd6Uz3IbSr0+
# XH8FHLflQXFCkPcZKiGPgSCp8rTP3KHr6wIDAQABo4ICAjCCAf4wHwYDVR0jBBgw
# FoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFKT3RICOlmcsnPu7KwUf
# 9HL4YegLMD0GA1UdIAQ2MDQwMgYFZ4EMAQMwKTAnBggrBgEFBQcCARYbaHR0cDov
# L3d3dy5kaWdpY2VydC5jb20vQ1BTMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAK
# BggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEz
# ODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5j
# cmwwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIw
# MjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQADggIBAGSBrSnUReHU
# zGTy9VC6hy2oDSpu2QNu5j3o/uoaaAy2CgI0hVJRL/OfYinLR4hJofuNNKORp2MW
# Xpy52L5PCGtD6/Hf92bMkDl1AP6nXuplt5HvkFPh5kVDbQ7oHfI1Pup2IOpKxb00
# UNwjtKy+38ZCX0dgkASP2vQFamBCG0eTaGUh/9ZH9rz11Nkr9p83Snz/3eW3vOeK
# AFL3S5RDEMkTvv09540mnzA4J5lKGES2eje/FhwCCQUQBvqCvoNFNZHyXvW9v8Kq
# X/3CcN1LAtGCy4XnkFjQRPyn+o/OJv5M5yX2Rm5kq9dYpWnDU2xgxMR1BZaDf+uD
# oqGsLo4OqbPV4Dftp2FDs8DHMD8xP6i/k4htaWShkdyjdijr9TBOi+pS9vNlcCKj
# wLq6aibcbkUk7ef3wxR5imhajsX22vy8Zd9ByAk07BJrccggJGczCtiKcD6LZtP3
# VjnqhYPSQ4jk6wCruqcTCTwwO7FrIROVrWb2Ro+ph+/a5Llj5ryLyp+6NAgtNwyr
# kp2WxZviLbh5AXnmg9Pnwrz64UE93LEjI23AWBJsLFdJTbisZ/tTgozdVdPZf2Dy
# 2k8xfYZoIq6V1oWiAoQCzb5B9nETV5NGjiMPskJ4GwnlzOvz+4IgLQjl0V5I08Qw
# +3uvPQ8rHHMLbKgncTqSxqtZ73kItOztMYIaIDCCGhwCAQEwfTBpMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0
# IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0Ex
# AhAGRzH371ShX6hjGl1wSSyYMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILndsywIx7nDK/WU0tJ0+R8+
# FqUA/cjZumQh0rzSODHWMA0GCSqGSIb3DQEBAQUABIIBgJIMvqtXem/he6oPAYx8
# ZJCwFZpmg0sA8w9ZxWtP/1BAp+GbWemE5PsH0fnSuDHHoey83rS7U2UxtC+ZXEhZ
# 9lymMZpEN2uMst+qEZNHGIxDsNNlyLZIzN+BDN05HbUCKM0nyaJ/Lq8W845jfYm7
# qA5D79WSrNhm5J/91AMoFpAfglJDvQORC3zt/sKToqdbqW6s7lXE+aCCMpqHGap+
# 7FwkfjaNH9swXl4s8yUJGRyyMMlmHDHk3LeWBk1tqDqPy4vA5AM/vzSRGIsFGEUf
# 6hSoB6tpfH+vJyiMY/W5FBghYH0YJoo1hvCjXPb92iWczo4nrKo4kZ0Niq6wNSTz
# gRKBu1rXoXzG1TWgk03crVq0D8rNCfHkeKbFIEjJBzqvbFynNuJLdKpgF0ZN7Qp+
# /LtYtticnw2wV8bSmledRsJOgNKdSSQW+mdb+XcvQN0/g2jUtoM7NmwQCiaGXqUr
# w+sFKlDXHeRry1HuRHa6V1o3wWfafnDIYUoKBYcdBMEWX6GCF3YwghdyBgorBgEE
# AYI3AwMBMYIXYjCCF14GCSqGSIb3DQEHAqCCF08wghdLAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCDnn7VNPUdOQ93O4iQ9aS0bokGaDbRw40qHYlufcn6XagIQHNxp
# RPkz9FioBecT+h8pBxgPMjAyNjA4MjUyMjQxMjRaoIITOjCCBu0wggTVoAMCAQIC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMx
# FzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVz
# dGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTAeFw0y
# NTA2MDQwMDAwMDBaFw0zNjA5MDMyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgU0hBMjU2IFJT
# QTQwOTYgVGltZXN0YW1wIFJlc3BvbmRlciAyMDI1IDEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDQRqwtEsae0OquYFazK1e6b1H/hnAKAd/KN8wZQjBj
# MqiZ3xTWcfsLwOvRxUwXcGx8AUjni6bz52fGTfr6PHRNv6T7zsf1Y/E3IU8kgNke
# ECqVQ+3bzWYesFtkepErvUSbf+EIYLkrLKd6qJnuzK8Vcn0DvbDMemQFoxQ2Dsw4
# vEjoT1FpS54dNApZfKY61HAldytxNM89PZXUP/5wWWURK+IfxiOg8W9lKMqzdIo7
# VA1R0V3Zp3DjjANwqAf4lEkTlCDQ0/fKJLKLkzGBTpx6EYevvOi7XOc4zyh1uSqg
# r6UnbksIcFJqLbkIXIPbcNmA98Oskkkrvt6lPAw/p4oDSRZreiwB7x9ykrjS6GS3
# NR39iTTFS+ENTqW8m6THuOmHHjQNC3zbJ6nJ6SXiLSvw4Smz8U07hqF+8CTXaETk
# VWz0dVVZw7knh1WZXOLHgDvundrAtuvz0D3T+dYaNcwafsVCGZKUhQPL1naFKBy1
# p6llN3QgshRta6Eq4B40h5avMcpi54wm0i2ePZD5pPIssoszQyF4//3DoK2O65Uc
# k5Wggn8O2klETsJ7u8xEehGifgJYi+6I03UuT1j7FnrqVrOzaQoVJOeeStPeldYR
# NMmSF3voIgMFtNGh86w3ISHNm0IaadCKCkUe2LnwJKa8TIlwCUNVwppwn4D3/Pt5
# pwIDAQABo4IBlTCCAZEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU5Dv88jHt/f3X
# 85FxYxlQQ89hjOgwHwYDVR0jBBgwFoAU729TSunkBnx6yuKQVvYv1Ensy04wDgYD
# VR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMIGVBggrBgEFBQcB
# AQSBiDCBhTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMF0G
# CCsGAQUFBzAChlFodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcnQwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3JsMCAG
# A1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOC
# AgEAZSqt8RwnBLmuYEHs0QhEnmNAciH45PYiT9s1i6UKtW+FERp8FgXRGQ/YAavX
# zWjZhY+hIfP2JkQ38U+wtJPBVBajYfrbIYG+Dui4I4PCvHpQuPqFgqp1PzC/ZRX4
# pvP/ciZmUnthfAEP1HShTrY+2DE5qjzvZs7JIIgt0GCFD9ktx0LxxtRQ7vllKluH
# WiKk6FxRPyUPxAAYH2Vy1lNM4kzekd8oEARzFAWgeW3az2xejEWLNN4eKGxDJ8WD
# l/FQUSntbjZ80FU3i54tpx5F/0Kr15zW/mJAxZMVBrTE2oi0fcI8VMbtoRAmaasl
# NXdCG1+lqvP4FbrQ6IwSBXkZagHLhFU9HCrG/syTRLLhAezu/3Lr00GrJzPQFnCE
# H1Y58678IgmfORBPC1JKkYaEt2OdDh4GmO0/5cHelAK2/gTlQJINqDr6JfwyYHXS
# d+V08X1JUPvB4ILfJdmL+66Gp3CSBXG6IwXMZUXBhtCyIaehr0XkBoDIGMUG1dUt
# wq1qmcwbdUfcSYCn+OwncVUXf53VJUNOaMWMts0VlRYxe5nK+At+DI96HAlXHAL5
# SlfYxJ7La54i71McVWRP66bW+yERNpbJCjyCYG2j+bdpxo/1Cy4uPcU3AWVPGrbn
# 5PhDBf3Froguzzhk++ami+r3Qrx5bIbY3TVzgiFI7Gq3zWcwgga0MIIEnKADAgEC
# AhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yNTA1MDcw
# MDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1l
# U3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51NrY0NlLWZ
# loMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5bap+0lgloM
# 2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf77S2uPoCj
# 7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF2hfQz3zQ
# Sku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80FiocSk1VYLZ
# lDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzVyhYn4p0+
# 8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl92QOMeRx
# ykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGPRdtBx3yG
# OP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//Wx+5kMqI
# MRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4OLu9BMIFm
# 1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM7Bu2ayBj
# UwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU729T
# SunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUF
# BwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEG
# CCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAX
# MAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBABfO+xaA
# HP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM0lBryPTQ
# M2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqWGd3rLAUt
# 6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr0UdqirZ7
# bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35k5zOCPmS
# Nq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKqMVuqte69
# M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiyfTPjLbnF
# RsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDUphPvSRmM
# Thi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTjd6xpR6oa
# Qf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2ZyJ/+xhCx
# 9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWCnb5WqxL3
# /BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIFjTCCBHWgAwIBAgIQDpsYjvnQ
# Lefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYD
# VQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAw
# WhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QN
# xDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DC
# srp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTr
# BcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463JT17l
# Necxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WC
# QTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1
# EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KS
# Op493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAs
# QWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUO
# UlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtv
# sauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCC
# ATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQD
# AgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaG
# NGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9D
# XFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6
# Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuW
# cqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLih
# Vo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBj
# xZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02f
# c7cBqZ9Xql4o4rmUMYIDfDCCA3gCAQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQg
# VGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExAhAKgO8YS43xBYLR
# xHanlXRoMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAcBgkqhkiG9w0BCQUxDxcNMjYwODI1MjI0MTI0WjArBgsqhkiG9w0BCRAC
# DDEcMBowGDAWBBTdYjCshgotMGvaOLFoeVIwB/tBfjAvBgkqhkiG9w0BCQQxIgQg
# SXUWv6UY84QCUMkcAB4eEtGmY1XiKccfhfJaa/RzMk8wNwYLKoZIhvcNAQkQAi8x
# KDAmMCQwIgQgSqA/oizXXITFXJOPgo5na5yuyrM/420mmqM08UYRCjMwDQYJKoZI
# hvcNAQEBBQAEggIAhM9s4IiBHnKC/3f+vCWPNrvVIcARLXxD0MAhWpXlywIuLC3e
# XXGFynoS1L5jeGseIJ+VqiBf6lqOEcjj6q4Hv3Cqa+eEU447grIHnxlBzJB+z1/J
# P08BxVxga/+2rVnR0CZwXZfDOD/cfFmsTRVAmbuf8DEeNtAaPxcCXS5pvdaYLqeq
# VQfzb8vILqdmTeuQlej3wD2W7FrWG1kpV/oDMAG5mdOGSGf2Y0SzIiyjcTVta9Xv
# HlV25vSt5zVri3qxmAquoFVYEndO9cR+UFaBtRZnjQqCdJaTvtM3CeUG1fwZqpB8
# N5IwYbmc3idOCs+UCLBGqYThA+4qvNnQto2AxafspdNG9Dt7FZ4xRxCS1FnfG7gK
# XsDeN6LnBqxvIRe3Nk1Ng1lR/fcAZk37KMNKOPMLbNha3VO6/aTj/+VRbzApAqB4
# pKSHVbQLfKDdGZBltbRdeijxCldTeT7f/J6v4KfCiEQmQpLWcpVPWaurP/AYgQ8t
# Jn8yJsWLp9cL6ARCHqLg/bfh6LZFXciIuVdg2DXOyp7yE3Uvo88Qm2O29YNwjgMZ
# jVl47umTU7Nh7vwG9kYxC7iH8LcME8KzPZiKUoaehDZil4hAMbb+YS/v8Ks8Mn9J
# +BzccqIEb4gnpY/IWd+WZa9V5B8WAB1LANzQJFAzCOx7RbX5yGomZqgSzek=
# SIG # End signature block
