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
    Param(
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
        [String]
        $Operation,

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
    Param(
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
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH', 'USER_ID')]
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
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH', 'USER_ID')]
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
    Param(
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
    Param(
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
        [String]
        $Operation,

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
    Param(
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
    Param(
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

        [Parameter(ParameterSetName = 'Name & items', Mandatory)]
        [Parameter(ParameterSetName = 'ID & items', Mandatory)]
        [ValidateSet('update', 'append', 'delete')]
        [String]
        $Operation,

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
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH')]
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
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCClO2h4u1E+okZG
# XH++S4M1GFzxWC1Egi+oqhtDYdfHSKCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPM4j41bLTpL7PlwTRySaijUq33hIq/R
# +c4Ie4vsvIfqMA0GCSqGSIb3DQEBAQUABIIBgI8MIthz9V3E4W+zyHQ5cQQuV/Qh
# /1GQePiSIyklufXksVJWTJyXvGjQvR2STulexlKdM8v9WYb1Zt5b2kZAjXQm0UWE
# Pwy3UzmD9EjwWJ1Iq7hqVse6BRJnWmP8P2IkjCi0t1lIfrzXB48vECzbCwXksGYO
# gtkB8Adsmn7XIIOLE+rdH3KIw9SAtnuHc6XSR8HRvjM0nFJIdmLpEXmfEXcUx1DS
# cHVuTWod2UDKB5d8SA5OIwzRsoobP8kBE05cY/DnGvAiX3Agt6B/p8R6IKMJiDcV
# TyG0k/W/kHRkqNKixl2q0/Q/2lKZ/07If9F+SUJ97/UFj+xDwdPis1YlztStq1XQ
# G93aKCztTNQfG7TqH7v1IGFhfd/JAyg+hPSiDXRlIcG9ZllVBqeMP02OezhiVcFS
# X6/yBGxdNF7Pyvoxy1ar4Ig1YehA7dE8EcadHqxitrPvRGhbEIz1d/NYjgDr2W7q
# Tz0RkpHPstRSRVVSpiC/LxvKypBBcmK0Iuho3A==
# SIG # End signature block
