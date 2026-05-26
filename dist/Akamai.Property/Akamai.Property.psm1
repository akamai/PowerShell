function Expand-ChildRuleSnippet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Include,

        [Parameter(Mandatory)]
        [string]
        $Path,
        
        [Parameter(Mandatory)]
        [string]
        $DefaultRuleDirectory
    )

    process {
        $IncludePath = $Path + '/' + $Include.Replace("#include:", "")
        $IncludeDir = [System.IO.Path]::GetDirectoryName($IncludePath)
        $IncludePathFromMain = $DefaultRuleDirectory + '/' + $Include.Replace("#include:", "")
        if ((Test-Path $IncludePath)) {
            Write-Debug "Expanding include $IncludePath."
            $Child = Get-Content $IncludePath -Raw | ConvertFrom-Json
        }
        elseif ((Test-Path $IncludePathFromMain)) {
            Write-Debug "Expanding include from main path $IncludePathFromMain."
            $Child = Get-Content $IncludePathFromMain -Raw | ConvertFrom-Json
        }
        else {
            throw "Could not find include path in the following locations: $IncludePath, $IncludePathFromMain."
        }
    
        for ($i = 0; $i -lt $Child.children.count; $i++) {
            if ($Child.children[$i].GetType().Name -eq 'String' -and $Child.children[$i].StartsWith('#include:')) {
                $Child.children[$i] = Expand-ChildRuleSnippet -Include $Child.children[$i] -Path $IncludeDir -DefaultRuleDirectory $DefaultRuleDirectory
            }
        }
    
        return $Child
    }
}

function Expand-PropertyDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Alias('ClonePropertyName')]
        [string]
        $PropertyName,

        [Parameter()]
        [Alias('ClonePropertyID')]
        [string]
        $PropertyID,

        [Parameter()]
        [Alias('CreateFromVersion')]
        [Alias('ClonePropertyVersion')]
        [string]
        $PropertyVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractID,

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

    process {
        $CommonParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        if ($PropertyName -ne '') {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $PropertyID = $Global:AkamaiDataCache.Property.Properties.$PropertyName.PropertyID
                $ContractID = $Global:AkamaiDataCache.Property.Properties.$PropertyName.ContractID
                $GroupID = $Global:AkamaiDataCache.Property.Properties.$PropertyName.GroupID
            }
            
            if (-not $PropertyID) {
                Write-Debug "Expand-PropertyDetails: Finding property with name '$PropertyName'."
                try {
                    $Property = Find-Property -PropertyName $PropertyName @CommonParams
                    if ($null -eq $Property) {
                        throw "Property '$PropertyName' not found."
                    }
                    $PropertyID = $Property[0].propertyId
                    $ContractID = $Property[0].contractId
                    $GroupID = $Property[0].groupId
                }
                catch {
                    throw $_
                }
            }
    
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache) {
                $Global:AkamaiDataCache.Property.Properties.$PropertyName = [ordered] @{ 
                    'PropertyID' = $PropertyID
                    'ContractID' = $ContractID
                    'GroupID'    = $GroupID
                }
            }
    
            Write-Debug "Expand-PropertyDetails: PropertyID = $PropertyID."
        }
        if ($PropertyVersion -and $PropertyVersion -notmatch "^[0-9]+$") {
            try {
                if ($null -ne $Local:Property) {
                    $LatestProperty = $Property | Sort-Object -Property propertyVersion -Descending | Select-Object -First 1
                    $StagingVersion = $Property | Where-Object stagingVersion -eq 'ACTIVE'
                    if ($PropertyVersion -eq 'latest') {
                        $PropertyVersion = $LatestProperty.propertyVersion
                    }
                    elseif ($PropertyVersion -eq 'production') {
                        $ProductionVersion = $Property | Where-Object productionStatus -eq 'ACTIVE'
                        if ($null -eq $ProductionVersion) {
                            throw "No production-active version of property $($Property.propertyName)."
                        }
                        else {
                            $PropertyVersion = $ProductionVersion.propertyVersion
                        }
                    }
                    elseif ($PropertyVersion -eq 'staging') {
                        $StagingVersion = $Property | Where-Object stagingStatus -eq 'ACTIVE'
                        if ($null -eq $StagingVersion) {
                            throw "No staging-active version of property $($Property.propertyName)."
                        }
                        else {
                            $PropertyVersion = $StagingVersion.propertyVersion
                        }
                    }
                }
                else {
                    Write-Debug "Expand-PropertyDetails: Retrieving versions of property with ID '$PropertyID'."
                    if ($ContractID -and $GroupID) {
                        $Property = Get-Property -PropertyID $PropertyID -GroupID $GroupID -ContractId $ContractId @CommonParams
                    }
                    else {
                        $Property = Get-Property -PropertyID $PropertyID @CommonParams
                        $ContractID = $Property.contractId
                        $GroupID = $Property.groupId
                    }
    
                    if ($PropertyVersion -eq 'latest') {
                        $PropertyVersion = $Property.latestVersion
                    }
                    elseif ($PropertyVersion -eq 'production') {
                        if ($Property.productionVersion) {
                            $PropertyVersion = $Property.productionVersion
                        }
                        else {
                            throw "No production-active version of property $($Property.propertyName)."
                        }
                    }
                    elseif ($PropertyVersion -eq 'staging') {
                        if ($Property.stagingVersion) {
                            $PropertyVersion = $Property.stagingVersion
                        }
                        else {
                            throw "No staging-active version of property $($Property.propertyName)."
                        }
                    }
                }
            }
            catch {
                throw $_
            }
            Write-Debug "Expand-PropertyDetails: PropertyVersion = $PropertyVersion."
        }
    
        return $PropertyID, $PropertyVersion, $GroupID, $ContractID
    }
}
function Expand-PropertyIncludeDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Alias('CloneIncludeName')]
        [string]
        $IncludeName,

        [Parameter()]
        [Alias('CloneIncludeID')]
        [string]
        $IncludeID,

        [Parameter()]
        [Alias('CreateFromVersion')]
        [Alias('CloneIncludeVersion')]
        [string]
        $IncludeVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractID,

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

    process {
        $CommonParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
    
        if ($IncludeName -ne '') {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $IncludeID = $Global:AkamaiDataCache.Property.Includes.$IncludeName.IncludeID
                $ContractID = $Global:AkamaiDataCache.Property.Includes.$IncludeName.ContractID
                $GroupID = $Global:AkamaiDataCache.Property.Includes.$IncludeName.GroupID
            }
    
            if (-not $IncludeID) {
                Write-Debug "Expand-PropertyIncludeDetails: Finding include with name '$IncludeName'."
                try {
                    $Include = Find-Property -IncludeName $IncludeName -latest @CommonParams
                    $IncludeID = $Include.IncludeId
                    if ($IncludeID -eq '') {
                        throw "Include '$IncludeName' not found."
                    }
                    $ContractID = $Include.contractId
                    $GroupID = $Include.groupId
                }
                catch {
                    throw $_
                }
            }
    
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache) {
                $Global:AkamaiDataCache.Property.Includes.$IncludeName = [ordered] @{ 
                    'IncludeID'  = $IncludeID
                    'ContractID' = $ContractID
                    'GroupID'    = $GroupID
                }
            }
    
            Write-Debug "Expand-PropertyIncludeDetails: IncludeID = $IncludeID."
        }
        if ($IncludeVersion -and $IncludeVersion -notmatch "^[0-9]+$") {
            try {
                if ($null -ne $Local:Include) {
                    $LatestInclude = $Include | Sort-Object -Property IncludeVersion -Descending | Select-Object -First 1
                    $StagingVersion = $Include | Where-Object stagingVersion -eq 'ACTIVE'
                    if ($IncludeVersion -eq 'latest') {
                        $IncludeVersion = $LatestInclude.IncludeVersion
                    }
                    elseif ($IncludeVersion -eq 'production') {
                        $ProductionVersion = $Include | Where-Object productionStatus -eq 'ACTIVE'
                        if ($null -eq $ProductionVersion) {
                            throw "No production-active version of Include $($Include.IncludeName)."
                        }
                        else {
                            $IncludeVersion = $ProductionVersion.IncludeVersion
                        }
                    }
                    elseif ($IncludeVersion -eq 'staging') {
                        $StagingVersion = $Include | Where-Object stagingStatus -eq 'ACTIVE'
                        if ($null -eq $StagingVersion) {
                            throw "No staging-active version of Include $($Include.IncludeName)."
                        }
                        else {
                            $IncludeVersion = $StagingVersion.IncludeVersion
                        }
                    }
                }
                else {
                    Write-Debug "Expand-IncludeDetails: Retrieving versions of Include with ID '$IncludeID'."
                    if ($ContractID -and $GroupID) {
                        $Include = Get-PropertyInclude -IncludeID $IncludeID -GroupID $GroupID -ContractId $ContractId @CommonParams
                    }
                    else {
                        $Include = Get-PropertyInclude -IncludeID $IncludeID @CommonParams
                        $ContractID = $Include.contractId
                        $GroupID = $Include.groupId
                    }
    
                    if ($IncludeVersion -eq 'latest') {
                        $IncludeVersion = $Include.latestVersion
                    }
                    elseif ($IncludeVersion -eq 'production') {
                        if ($Include.productionVersion) {
                            $IncludeVersion = $Include.productionVersion
                        }
                        else {
                            throw "No production-active version of Include $($Include.IncludeName)."
                        }
                    }
                    elseif ($IncludeVersion -eq 'staging') {
                        if ($Include.stagingVersion) {
                            $IncludeVersion = $Include.stagingVersion
                        }
                        else {
                            throw "No staging-active version of Include $($Include.IncludeName)."
                        }
                    }
                }
            }
            catch {
                throw $_
            }
            Write-Debug "Expand-IncludeDetails: IncludeVersion = $IncludeVersion."
        }
    
        return $IncludeID, $IncludeVersion, $GroupID, $ContractID
    }
}
function Format-FileName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Filename
    )
    
    $BadCharacters = @(
        '\',
        '/',
        ':',
        '*',
        '?',
        '"',
        '<',
        '>',
        '|'
    )

    $SanitizedFilename = $Filename
    foreach ($BadCharacter in $BadCharacters) {
        $SanitizedFilename = $SanitizedFilename.Replace($BadCharacter, [System.Web.HttpUtility]::UrlEncode($BadCharacter))
    }

    # Special Handling for asterisk, which the HttpUtility doesn't encode
    $SanitizedFilename = $SanitizedFilename.Replace('*', '%2A')

    # Trim whitespace
    $SanitizedFilename = $SanitizedFilename.Trim()
    
    return $SanitizedFilename
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

function Get-ChildRuleSnippet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [object]
        $Rules,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [int]
        $CurrentDepth,

        [Parameter(Mandatory)]
        [int]
        $MaxDepth,
        
        [Parameter()]
        [switch]
        $PathFromMainJson
    )
    
    process {
        $SafeName = Format-Filename -FileName $Rules.Name
        $ChildPath = "$Path/$SafeName"
        $NewDepth = $CurrentDepth + 1
    
        if ($NewDepth -lt $MaxDepth) {
            if ($Rules.children.count -gt 0) {
                if (!(Test-Path $ChildPath)) {
                    New-Item -Path $ChildPath -ItemType Directory | Out-Null
                }
            }
            for ($i = 0; $i -lt $Rules.children.count; $i++) {
                $ChildRuleSnippetParams = @{
                    Rules        = $Rules.children[$i]
                    Path         = $ChildPath
                    CurrentDepth = $NewDepth
                    MaxDepth     = $MaxDepth
                }
                if ($ForceSlashStyle) { $ChildRuleSnippetParams['ForceSlashStype'] = $ForceSlashStyle }
                if ($PathFromMainJson) { $ChildRuleSnippetParams['PathFromMainJson'] = $PathFromMainJson }
                Get-ChildRuleSnippet @ChildRuleSnippetParams
                $SafeChildName = Format-Filename -FileName $Rules.children[$i].Name
                if ($PathFromMainJson) {
                    # Remove the first element from the path (the parent folder) in order to base from main json path
                    $Rules.children[$i] = "#include:$($ChildPath.SubString($ChildPath.IndexOf('/') + 1))/$SafeChildName.json"
                }
                else {
                    $Rules.children[$i] = "#include:$SafeName/$SafeChildName.json"
                }
            }
        }
    
        $Rules | ConvertTo-Json -Depth 100 | Set-Content "$Path/$SafeName.json"
    }
}

function Add-BucketHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [object[]]
        $NewHostnames,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [switch]
        $IncludeCertStatus,

        [Parameter()]
        [switch]
        $ValidateHostnames,

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
        # Capitalise $Network, API seems to care
        $Network = $Network.ToUpper()

        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/hostnames"
        $QueryParameters = @{
            contractId        = $ContractID
            groupId           = $GroupID
            network           = $Network
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }
        $CombinedHostnameArray = New-Object -TypeName System.Collections.Generic.List[Object]
    }

    process {
        foreach ($Hostname in $NewHostnames) {
            $CombinedHostnameArray.Add($Hostname) | Out-Null
        }
    }

    end {
        $Body = @{
            network = $Network
            add     = $CombinedHostnameArray
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.hostnames
    }
}

function Add-PropertyHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [object[]]
        $NewHostnames,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [switch]
        $IncludeCertStatus,

        [Parameter()]
        [switch]
        $ValidateHostnames,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/hostnames"
        $QueryParameters = @{
            contractId        = $ContractID
            groupId           = $GroupID
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }
        $CombinedHostnameArray = New-Object -TypeName System.Collections.Generic.List[Object]
    }

    process {
        foreach ($Hostname in $NewHostnames) {
            $CombinedHostnameArray.Add($Hostname) | Out-Null
        }
    }

    end {
        $Body = @{ add = $CombinedHostnameArray }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.hostnames.items
    }


}


function Add-PropertyIncludeRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory)]
        [string]
        $IncludeVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $RequestPath = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'add'
                'path'  = $Path
                'value' = (Get-BodyObject -Source $Value)
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
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

function Add-PropertyRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $RequestPath = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'add'
                'path'  = $Path
                'value' = (Get-BodyObject -Source $Value)
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
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

function Compare-BucketHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $OffSet,

        [Parameter()]
        [string]
        $Limit,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/hostnames/diff"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
            offset     = $OffSet
            limit      = $Limit
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
        return $Response.Body.hostnames.items
    }
}

function Copy-Property {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $RuleFormat,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [string]
        $ClonePropertyName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PropertyID')]
        [string]
        $ClonePropertyID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PropertyVersion')]
        [string]
        $ClonePropertyVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ClonePropertyVersionEtag,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $CopyHostnames,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UseHostnameBucket,

        [Parameter(ParameterSetName = 'Body', Mandatory)]
        $Body,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContractID,

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
        $ClonePropertyID, $ClonePropertyVersion, $null, $null = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties"
        $QueryParameters = @{
            'contractId' = $ContractId
            'groupId'    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'propertyName' = $Name
                'productId'    = $ProductID
                'cloneFrom'    = @{
                    'propertyId' = $ClonePropertyID
                    'version'    = $ClonePropertyVersion
                }
            }
            if ($RuleFormat) { $Body['ruleFormat'] = $RuleFormat }
            if ($UseHostnameBucket) { $Body['useHostnameBucket'] = $true }
            if ($CopyHostnames) { $Body.CloneFrom['copyHostnames'] = $CopyHostnames.ToBool() }
            if ($ClonePropertyVersionEtag) { $Body.CloneFrom['cloneFromVersionEtag'] = $ClonePropertyVersionEtag }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
    
            if ($Response.Body.propertyLink -Match '\/properties\/([^\?]+)') {
                $PropertyID = $matches[1]
                $Response.Body | Add-Member -NotePropertyName 'propertyId' -NotePropertyValue $PropertyID
    
                # Add to data cache
                if ($AkamaiOptions.EnableDataCache) {
                    Set-AkamaiDataCache -PropertyName $Name -PropertyID $PropertyID
                }
            }
    
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function Copy-PropertyInclude {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $RuleFormat,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('MICROSERVICES', 'COMMON_SETTINGS')]
        [string]
        $IncludeType,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [string]
        $CloneIncludeName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('IncludeID')]
        [string]
        $CloneIncludeID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('IncludeVersion')]
        [string]
        $CloneIncludeVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CloneIncludeVersionEtag,

        [Parameter(ParameterSetName = 'Body', Mandatory)]
        $Body,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContractID,

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
        $CloneIncludeID, $CloneIncludeVersion, $null, $null = Expand-PropertyIncludeDetails @PSBoundParameters

        $Path = "/papi/v1/includes"
        $QueryParameters = @{
            'contractId' = $ContractId
            'groupId'    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'productId'   = $ProductID
                'includeName' = $Name
                'includeType' = $IncludeType
                'cloneFrom'   = @{
                    'includeId' = $CloneIncludeID
                    'version'   = $CloneIncludeVersion
                }
            }
            if ($RuleFormat) { $Body['ruleFormat'] = $RuleFormat }
            if ($CloneIncludeVersionEtag) { $Body.cloneFrom['cloneFromVersionEtag'] = $CloneIncludeVersionEtag }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
            if ($Response.Body.includeLink -Match '\/includes\/([^\?]+)') {
                $IncludeID = $Matches[1]
                $Response.Body | Add-Member -NotePropertyName 'includeId' -NotePropertyValue $IncludeID
    
                # Add to data cache
                if ($AkamaiOptions.EnableDataCache) {
                    Set-AkamaiDataCache -IncludeName $Name -IncludeID $IncludeID
                }
            }
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function Find-Property {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,
    
        [Parameter(ParameterSetName = 'Host', Mandatory)]
        [string]
        $PropertyHostname,
    
        [Parameter(ParameterSetName = 'Edge', Mandatory)]
        [string]
        $EdgeHostname,
    
        [Parameter(ParameterSetName = 'Include', Mandatory)]
        [string]
        $IncludeName,
    
        [Parameter()]
        [switch]
        $Latest,
    
        [Parameter()]
        [switch]
        $JustProductionActive,
    
        [Parameter()]
        [switch]
        $JustStagingActive,
    
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

    $Path = "/papi/v1/search/find-by-value"
    
    $Body = @{}
    if ($PropertyName) {
        $Body["propertyName"] = $PropertyName
    }
    elseif ($PropertyHostname) {
        $Body["hostname"] = $PropertyHostName
    }
    elseif ($EdgeHostname) {
        $Body["edgeHostname"] = $EdgeHostname
    }
    elseif ($IncludeName) {
        $Body["includeName"] = $IncludeName
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
    if ($Latest) {
        if ($IncludeName) {
            $SortedResult = $Response.Body.versions.items | Sort-Object -Property includeVersion -Descending
        }
        else {
            $SortedResult = $Response.Body.versions.items | Sort-Object -Property propertyVersion -Descending
        }
        if ($null -ne $SortedResult -and $SortedResult.GetType().Name -eq "Object[]") {
            return $SortedResult[0]
        }
        else {
            return $SortedResult
        }
    }
    elseif ($JustProductionActive) {
        return $Response.Body.versions.items | Where-Object { $_.productionStatus -eq "ACTIVE" }
    }
    elseif ($JustStagingActive) {
        return $Response.Body.versions.items | Where-Object { $_.stagingStatus -eq "ACTIVE" }
    }
    else {
        return $Response.Body.versions.items
    }
}

function Get-AccountID {
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

    $Path = "/papi/v1/groups"
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
    return $Response.Body.accountId

}

function Get-BucketActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter()]
        [string]
        $HostnameActivationID,

        [Parameter()]
        [switch]
        $IncludeHostnames,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        if ($HostnameActivationID) {
            $Path = "/papi/v1/properties/$PropertyID/hostname-activations/$HostnameActivationID"
        }
        else {
            $Path = "/papi/v1/properties/$PropertyID/hostname-activations"
        }
        $QueryParameters = @{
            includeHostnames = $PSBoundParameters.IncludeHostnames
            contractId       = $ContractId
            groupId          = $GroupID
            offset           = $OffSet
            limit            = $Limit
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
        if ($HostnameActivationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.hostnameActivations.items
        }
    }
}

function Get-BucketHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $OffSet,

        [Parameter()]
        [string]
        $Limit,

        [Parameter()]
        [string]
        $Sort,

        [Parameter()]
        [string]
        $HostnameFilter,

        [Parameter()]
        [string]
        $CNAMEToFilter,

        [Parameter()]
        [switch]
        $IncludeCertStatus,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        # Capitalise $Network, API seems to care
        $Network = $Network.ToUpper()

        $Path = "/papi/v1/properties/$PropertyID/hostnames"
        $QueryParameters = @{
            contractId        = $ContractId
            groupId           = $GroupID
            network           = $Network
            offset            = $OffSet
            limit             = $Limit
            sort              = $Sort
            hostname          = $HostnameFilter
            cnameTo           = $CNAMEToFilter
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
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
        return $Response.Body.hostnames.items
    }
}

function Get-BulkActivatedProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]
        $BulkActivationID,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
        [string]
        $ContractId,

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
        $Path = "/papi/v1/bulk/activations/$BulkActivationID"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
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
        return $Response.Body           
    }
}

function Get-BulkPatchedProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]
        $BulkPatchID,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
        [string]
        $ContractId,

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
        $Path = "/papi/v1/bulk/rules-patch-requests/$BulkPatchID"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
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
        return $Response.Body           
    }
}

function Get-BulkSearchResult {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]
        $BulkSearchID,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
        [string]
        $ContractId,

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
        $Path = "/papi/v1/bulk/rules-search-requests/$BulkSearchID"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
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

function Get-BulkVersionedProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]
        $BulkCreateID,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
        [string]
        $ContractId,

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
        $Path = "/papi/v1/bulk/property-version-creations/$BulkCreateID"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
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
        return $Response.Body           
    }
}

function Get-CustomBehavior {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $BehaviorID,

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
        if ($BehaviorID) {
            $Path = "/papi/v1/custom-behaviors/$BehaviorID"
        }
        else {
            $Path = "/papi/v1/custom-behaviors"
        }
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
        return $Response.Body.customBehaviors.items
    }
}

function Get-CustomOverride {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $OverrideID,

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
        if ($OverrideID) {
            $Path = "/papi/v1/custom-overrides/$OverrideID"
        }
        else {
            $Path = "/papi/v1/custom-overrides"
        }
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
        return $Response.Body.customOverrides.items
    }
}

function Get-Group {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0)]
        [string]
        $GroupName,

        [Parameter(ParameterSetName = 'ID', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
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

    process {
        $Path = "/papi/v1/groups"
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
        if ($GroupName) {
            return $Response.Body.groups.items | Where-Object { $_.groupName -eq $GroupName }

        }
        elseif ($GroupID) {
            return $Response.Body.groups.items | Where-Object { $_.groupId -eq $GroupID }

        }
        else {
            return $Response.Body.groups.items
        }
    }
}

function Get-HostnameAuditHistory {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Hostname,

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
        $Path = "/papi/v1/hostnames/$Hostname/audit-history"
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
        return $Response.Body.history.items
    }
}

function Get-Product {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ContractID,

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
        $Path = "/papi/v1/products"
        $QueryParameters = @{
            contractId = $ContractID
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
        return $Response.Body.products.items
    }
}

function Get-ProductUseCases {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [string]
        $ContractID,
        
        [Parameter(Position = 1, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ProductID,

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
        $Path = "/papi/v1/products/$ProductID/mapping-use-cases"
        $QueryParameters = @{
            'contractId' = $ContractID
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
        return $Response.Body.useCases
    }
}

function Get-Property {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [Parameter(ParameterSetName = 'Get all', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [Parameter(ParameterSetName = 'Get all', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('contractIds')]
        [object]
        $ContractId,

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
        if ($ContractId -is [Array]) {
            $ContractId = $ContractId[0]  # Only one is expected, even though it is an array, so take the first one
        }

        if ($PSCmdlet.ParameterSetName.Contains('one')) {
            $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        }

        if ($PropertyID) {
            $Path = "/papi/v1/properties/$PropertyID"
        }
        else {
            $Path = "/papi/v1/properties"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
            if ($Response.Body.properties.items -and $AkamaiOptions.EnableDataCache) {
                foreach ($Property in $Response.Body.properties.items) {
                    Set-AkamaiDataCache -PropertyName $Property.propertyName -PropertyID $Property.propertyId
                }
            }
    
            return $Response.Body.properties.items
        }
        catch {
            throw $_
        }
    }
}

function Get-PropertyActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter()]
        [string]
        $ActivationID,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        if ($ActivationID) {
            $Path = "/papi/v1/properties/$PropertyID/activations/$ActivationID"
        }
        else {
            $Path = "/papi/v1/properties/$PropertyID/activations"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
        return $Response.Body.activations.items
    }
}

function Get-PropertyBehaviors {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/available-behaviors"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
        return $Response.Body.behaviors.items
    }
}

function Get-PropertyBuild {
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

    $Path = "/papi/v1/build"
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

function Get-PropertyCertificateChallenge {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]]
        $CnamesFrom,

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
        $CollatedCNAMEs = New-Object System.Collections.Generic.List[string]
    }

    process {
        $CnamesFrom | ForEach-Object {
            $CollatedCNAMEs.Add($_)
        }
    }

    end {
        $Path = "/papi/v1/hostnames/certificate-challenges"
        $Body = @{
            cnamesFrom = $CollatedCNAMEs
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
        return $Response.Body.hostnames.items
    }
}

function Get-PropertyClientSettings {
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

    $Path = "/papi/v1/client-settings"
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

function Get-PropertyContract {
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

    $Path = "/papi/v1/contracts"
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
    return $Response.Body.contracts.items  
}

function Get-PropertyCPCode {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $CPCodeID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

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
        if ($CPCodeID) {
            $Path = "/papi/v1/cpcodes/$CPCodeID"
        }
        else {
            $Path = "/papi/v1/cpcodes"
        }
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
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
        return $Response.Body.cpcodes.items
    }
}

function Get-PropertyCriteria {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/available-criteria"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
        return $Response.Body.criteria.items
    }
}

function Get-PropertyDomainOwnershipChallenge {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [string[]]
        $Hostname,

        [Parameter()]
        [switch]
        $RefreshToken,

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
        $CollatedHostnames = New-Object System.Collections.Generic.List[string]
    }

    process {
        $Hostname | ForEach-Object {
            $CollatedHostnames.Add($_)
        }
    }

    end {
        $Path = "/papi/v1/domain-challenges"
        $QueryParameters = @{
            'refreshToken' = $RefreshToken.IsPresent
        }
        $Body = @{
            'hostnames' = $CollatedHostnames
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.hostnames
    }
}
function Get-PropertyEdgeHostname {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $EdgeHostnameID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $Options,

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
        if ($EdgeHostnameID) {
            $Path = "/papi/v1/edgehostnames/$EdgeHostnameID"
        }
        else {
            $Path = "/papi/v1/edgehostnames"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
            options    = $Options
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
        return $Response.Body.edgehostnames.items
    }
}

function Get-PropertyHostname {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Get one by name', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get one by ID', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [switch]
        $ValidateHostnames,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [switch]
        $IncludeCertStatus,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Offset,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Limit,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('hostname:a', 'hostname:d')]
        [string]
        $Sort,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CnameTo,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('PRODUCTION', 'STAGING')]
        [string]
        $Network,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        if ($PSCmdlet.ParameterSetName.Contains('one')) {
            $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

            $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/hostnames"
            $QueryParameters = @{
                contractId        = $ContractId
                groupId           = $GroupID
                validateHostnames = $PSBoundParameters.ValidateHostnames
                includeCertStatus = $PSBoundParameters.IncludeCertStatus
            }
        }
        else {
            $Path = '/papi/v1/hostnames'
            $QueryParameters = @{
                contractId = $ContractId
                groupId    = $GroupID
                offset     = $PSBoundParameters.offset
                limit      = $PSBoundParameters.limit
                sort       = $Sort
                hostname   = $Hostname
                cnameTo    = $CnameTo
                network    = $Network
            }
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
        $Hostnames = $Response.Body.hostnames.items
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            if ($null -eq $PSBoundParameters.Limit -and $null -eq $PSBoundParameters.Offset) {
                $Offset = $Limit = $Response.Body.hostnames.items.count
                while ($Hostnames.count -lt $Response.Body.hostnames.totalItems) {
                    $PSBoundParameters.Limit = $Limit
                    $PSBoundParameters.Offset = $Offset
                    $Hostnames += Get-PropertyHostname @PSBoundParameters
                    # Increase offset for potential next iteration
                    $Offset += $Limit
                }
            }
        }
        return $Hostnames
    }
}

function Get-PropertyInclude {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(ParameterSetName = 'Get one by name', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'Get one by name', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('contractIds')]
        [string]
        $ContractId,

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
        $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        if ($IncludeID) {
            $Path = "/papi/v1/includes/$IncludeID"
        }
        else {
            $Path = "/papi/v1/includes"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
                foreach ($Include in $Response.Body.includes.items) {
                    Set-AkamaiDataCache -IncludeName $Include.includeName -IncludeID $Include.includeId
                }
            }
    
            return $Response.Body.includes.items
        }
        catch {
            throw $_
        }
    }
}

function Get-PropertyIncludeActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter()]
        [string]
        $IncludeActivationID,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        if ($IncludeActivationID) {
            $Path = "/papi/v1/includes/$IncludeID/activations/$IncludeActivationID"
        }
        else {
            $Path = "/papi/v1/includes/$IncludeID/activations"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
        return $Response.Body.activations.items
    }
}

function Get-PropertyIncludeBehaviors {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $IncludeVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $Path = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/available-behaviors"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
        return $Response.Body.behaviors.items
    }
}

function Get-PropertyIncludeCriteria {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $IncludeVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $Path = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/available-criteria"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
        return $Response.Body.criteria.items
    }
}


function Get-PropertyIncludeParent {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter()]
        [int]
        $Offset,

        [Parameter()]
        [int]
        $Limit,

        [Parameter()]
        [string]
        $ContractID,

        [Parameter()]
        [string]
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

    process {
        $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $Path = "/papi/v1/includes/$IncludeID/parents"
        $QueryParameters = @{
            'offset'     = $PSBoundParameters.Offset
            'limit'      = $PSBoundParameters.Limit
            'contractId' = $ContractID
            'groupId'    = $GroupID
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.properties.items
        }
        catch {
            throw $_
        }
    }
}

function Get-PropertyIncludeRules {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $IncludeVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $OutputToFile,

        [Parameter()]
        [string]
        $OutputFileName,

        [Parameter()]
        [switch]
        $OutputSnippets,

        [Parameter()]
        [string]
        $OutputDirectory,

        [Parameter()]
        [int]
        $MaxDepth = 100,

        [Parameter()]
        [ValidateSet('Windows', 'Unix', IgnoreCase)]
        [string]
        $ForceSlashStyle,

        [Parameter()]
        [switch]
        $PathFromMainJson,

        [Parameter()]
        [switch]
        $Force,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $Path = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'originalInput' = $PSBoundParameters.OriginalInput
        }

        if ($RuleFormat) {
            $AdditionalHeaders = @{
                Accept = "application/vnd.akamai.papirules.$RuleFormat+json"
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        if ($OutputToFile -or $OutputFileName) {
            if (!$OutputFileName) {
                $OutputFileName = $Response.Body.includeName + "_" + $Response.Body.includeVersion + ".json"
            }
            elseif (!($OutputFileName.EndsWith(".json"))) {
                $OutputFileName += ".json"
            }

            if ( (Test-Path $OutputFileName) -and !$Force) {
                Write-Host -ForegroundColor Yellow "Failed to write file. $OutputFileName exists and -Force not specified."
            }
            else {
                $Response.Body | ConvertTo-Json -Depth 100 | Set-Content $OutputFileName -Force
                Write-Host 'Wrote version ' -NoNewline
                Write-Host -ForegroundColor Green $Response.Body.includeVersion -NoNewline
                Write-Host ' of include ' -NoNewline
                Write-Host -ForegroundColor Green $Response.Body.includeName -NoNewline
                Write-Host ' to ' -NoNewline
                Write-Host -ForegroundColor Green $OutputFileName -NoNewline
                Write-Host '.'
            }
        }
        if ($OutputSnippets -or $OutputDirectory) {
            if ($OutputDirectory -eq '') {
                $OutputDirectory = $Response.Body.includeName
            }

            # Make Include Directory if required
            if (!(Test-Path $OutputDirectory)) {
                Write-Host "Creating new property include directory " -NoNewLine
                Write-Host -ForegroundColor Cyan $OutputDirectory -NoNewline
                Write-Host "."
                New-Item -Path $OutputDirectory -ItemType Directory | Out-Null
            }
            else {
                $ExistingFiles = Get-ChildItem $OutputDirectory
                if ($ExistingFiles.count -gt 0) {
                    if ($Force) {
                        Write-Debug "Get-PropertyRules: Deleting contents of $OutputDirectory."
                        Remove-Item -Path $OutputDirectory/* -Force -Recurse
                    }
                    else {
                        throw "Output directory $OutputDirectory already exists. To use this directory and overwrite its contents, use -Force."
                    }
                }
            }

            for ($i = 0; $i -lt $Response.Body.rules.children.count; $i++) {
                $ChildRuleSnippetParams = @{
                    Rules        = $Response.Body.rules.children[$i]
                    Path         = $OutputDirectory
                    CurrentDepth = 0
                    MaxDepth     = $MaxDepth
                }
                if ($ForceSlashStyle) { $ChildRuleSnippetParams['ForceSlashStyle'] = $ForceSlashStyle }
                if ($PathFromMainJson) { $ChildRuleSnippetParams['PathFromMainJson'] = $PathFromMainJson }
                Get-ChildRuleSnippet @ChildRuleSnippetParams
                $SafeName = Format-Filename -FileName $Response.Body.rules.children[$i].Name
                $Response.Body.rules.children[$i] = "#include:$SafeName.json"
            }

            ### Split variables out to its own file
            if ($null -ne $Response.Body.rules.variables) {
                ConvertTo-Json -depth 100 $Response.Body.rules.variables | Set-Content "$OutputDirectory\pmVariables.json" -Force
                $Response.Body.rules.variables = "#include:pmVariables.json"
            }

            ### Write default rule to main file
            $Response.Body.rules | ConvertTo-Json -depth 100 | Set-Content "$OutputDirectory\main.json" -Force

            Write-Host 'Wrote version ' -NoNewLine
            Write-Host -ForegroundColor Cyan $Response.Body.includeVersion -NoNewline
            Write-Host ' of include ' -NoNewline
            Write-Host  -ForegroundColor Cyan $Response.Body.includeName -NoNewline
            Write-Host ' to ' -NoNewline
            Write-Host  -ForegroundColor Cyan $OutputDirectory -NoNewline
            Write-Host '.'
        }
        # Return object if other options not specified, or user has supplied -PassThru
        if ( (-not $OutputToFile -and -not $OutputFileName -and -not $OutputSnippets -and -not $OutputDirectory) -or $PassThru) {
            return $Response.Body
        }
    }
}

function Get-PropertyIncludeRulesDigest {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $IncludeVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $Path = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'HEAD'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.status -eq 204) {
            $ETag = $Response.Headers['ETag']
            if ($ETag.Count -gt 1) {
                $ETag = $ETag[0]
            }
            return $ETag
        }
    }
}

function Get-PropertyIncludeVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $IncludeVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        if ($IncludeVersion) {
            $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
            $Path = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion"
        }
        else {
            $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
            $Path = "/papi/v1/includes/$IncludeID/versions"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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

        # Add elements to output for better pipelining
        foreach ($Item in $Response.Body.versions.items) {
            $Item | Add-Member -NotePropertyName IncludeID -NotePropertyValue $Response.Body.IncludeID -Force
            $Item | Add-Member -NotePropertyName ContractID -NotePropertyValue $Response.Body.ContractID -Force
            $Item | Add-Member -NotePropertyName GroupID -NotePropertyValue $Response.Body.GroupID -Force
        }

        return $Response.Body.versions.items
    }
}

function Get-PropertyRequestSchema {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string]
        $Filename,

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
        $Path = "/papi/v1/schemas/request/$Filename"
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

function Get-PropertyRules {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $OutputToFile,

        [Parameter()]
        [string]
        $OutputFileName,

        [Parameter()]
        [switch]
        $OutputSnippets,

        [Parameter()]
        [string]
        $OutputDirectory,

        [Parameter()]
        [int]
        $MaxDepth = 100,

        [Parameter()]
        [ValidateSet('Windows', 'Unix', IgnoreCase)]
        [string]
        $ForceSlashStyle,

        [Parameter()]
        [switch]
        $PathFromMainJson,

        [Parameter()]
        [switch]
        $Force,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
        $QueryParameters = @{
            contractId    = $ContractId
            groupId       = $GroupID
            originalInput = $PSBoundParameters.OriginalInput.IsPresent
        }

        if ($RuleFormat) {
            $AdditionalHeaders = @{
                Accept = "application/vnd.akamai.papirules.$RuleFormat+json"
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        if ($OutputToFile -or $OutputFileName) {
            if (!$OutputFileName) {
                $OutputFileName = $Response.Body.propertyName + "_" + $Response.Body.propertyVersion + ".json"
            }
            elseif (!($OutputFileName.EndsWith(".json"))) {
                $OutputFileName += ".json"
            }

            if ( (Test-Path $OutputFileName) -and !$Force) {
                throw "Failed to write file. $OutputFileName exists and -Force not specified."
            }
            else {
                $Response.Body | ConvertTo-Json -Depth 100 | Set-Content $OutputFileName -Force
                Write-Host 'Wrote version ' -NoNewline
                Write-Host -ForegroundColor Green $Response.Body.propertyVersion -NoNewline
                Write-Host ' of property ' -NoNewline
                Write-Host -ForegroundColor Green $Response.Body.propertyName -NoNewline
                Write-Host ' to ' -NoNewline
                Write-Host -ForegroundColor Green $OutputFileName -NoNewline
                Write-Host '.'
            }
        }
        if ($OutputSnippets -or $OutputDirectory) {
            # Duplicate response body to avoid clash with passthru output
            $SnippetsResponse = $Response.Body | ConvertTo-Json -Depth 100 | ConvertFrom-Json
            if (!$OutputDirectory) {
                $OutputDirectory = $SnippetsResponse.propertyName
            }

            # Make Property Directory if required
            if (!(Test-Path $OutputDirectory)) {
                Write-Host "Creating new property directory " -NoNewLine
                Write-Host -ForegroundColor Cyan $OutputDirectory -NoNewline
                Write-Host "."
                New-Item -Path $OutputDirectory -ItemType Directory | Out-Null
            }
            else {
                $ExistingFiles = Get-ChildItem $OutputDirectory
                if ($ExistingFiles.count -gt 0) {
                    if ($Force) {
                        Write-Debug "Get-PropertyRules: Deleting contents of $OutputDirectory."
                        Remove-Item -Path $OutputDirectory/* -Force -Recurse
                    }
                    else {
                        throw "Output directory $OutputDirectory already exists. To use this directory and overwrite its contents, use -Force."
                    }
                }
            }

            for ($i = 0; $i -lt $SnippetsResponse.rules.children.count; $i++) {
                $ChildRuleSnippetParams = @{
                    Rules        = $SnippetsResponse.rules.children[$i]
                    Path         = $OutputDirectory
                    CurrentDepth = 0
                    MaxDepth     = $MaxDepth
                }
                if ($ForceSlashStyle) { $ChildRuleSnippetParams['ForceSlashStyle'] = $ForceSlashStyle }
                if ($PathFromMainJson) { $ChildRuleSnippetParams['PathFromMainJson'] = $PathFromMainJson }
                Get-ChildRuleSnippet @ChildRuleSnippetParams
                $SafeName = Format-Filename -FileName $SnippetsResponse.rules.children[$i].Name
                $SnippetsResponse.rules.children[$i] = "#include:$SafeName.json"
            }

            ### Split variables out to its own file
            if ($SnippetsResponse.rules.variables.count -gt 0) {
                $SnippetsResponse.rules.variables | ConvertTo-Json -depth 100 | Set-Content "$OutputDirectory\pmVariables.json" -Force
            }
            else {
                '[]' | Set-Content "$OutputDirectory\pmVariables.json" -Force -NoNewline
            }
            $SnippetsResponse.rules | Add-Member -NotePropertyName 'variables' -NotePropertyValue "#include:pmVariables.json" -Force

            ### Write default rule to main file
            $SnippetsResponse.rules | ConvertTo-Json -depth 100 | Set-Content "$OutputDirectory\main.json" -Force

            Write-Host 'Wrote version ' -NoNewLine
            Write-Host -ForegroundColor Cyan $SnippetsResponse.propertyVersion -NoNewline
            Write-Host ' of property ' -NoNewline
            Write-Host  -ForegroundColor Cyan $SnippetsResponse.propertyName -NoNewline
            Write-Host ' to ' -NoNewline
            Write-Host  -ForegroundColor Cyan $OutputDirectory -NoNewline
            Write-Host '.'
        }
        # Return object if other options not specified, or user has supplied -PassThru
        if ( (-not $OutputToFile -and -not $OutputFileName -and -not $OutputSnippets -and -not $OutputDirectory) -or $PassThru) {
            return $Response.Body
        }
    }
}

function Get-PropertyRulesDigest {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'HEAD'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.status -eq 204) {
            $ETag = $Response.Headers['ETag']
            if ($ETag.Count -gt 1) {
                $ETag = $ETag[0]
            }
            return $ETag
        }
    }
}

function Get-PropertyVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        if ($PropertyVersion) {
            $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
            $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion"
        }
        else {
            $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
            $Path = "/papi/v1/properties/$PropertyID/versions"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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

        # Add elements to output for better pipelining
        foreach ($Item in $Response.Body.versions.items) {
            $Item | Add-Member -NotePropertyName PropertyID -NotePropertyValue $Response.Body.PropertyID -Force
            $Item | Add-Member -NotePropertyName ContractID -NotePropertyValue $Response.Body.ContractID -Force
            $Item | Add-Member -NotePropertyName GroupID -NotePropertyValue $Response.Body.GroupID -Force
        }

        return $Response.Body.versions.items
    }
}

function Get-PropertyVersionInclude {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/includes"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
        return $Response.Body.includes.items
    }
}

function Get-RuleFormat {
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

    $Path = "/papi/v1/rule-formats"
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
    return $Response.Body.ruleFormats.items
}

function Get-RuleFormatSchema {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [string]
        $ProductID,

        [Parameter(Position = 1, Mandatory, ValueFromPipeline)]
        [string]
        $RuleFormat,

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
        $Path = "/papi/v1/schemas/products/$ProductID/$RuleFormat"
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

function Get-TopLevelGroup {
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

    try {
        $Groups = Get-Group -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey | Where-Object { $null -eq $_.parentGroupId }
        return $Groups 
    }
    catch {
        throw $_
    }
}

function Merge-PropertyRules {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [string]
        $SourceDirectory,

        [Parameter()]
        [string]
        $DefaultRuleFilename = 'main.json',

        [Parameter()]
        [switch]
        $OutputToFile,

        [Parameter()]
        [string]
        $OutputFileName
    )

    process {
        if (!(Test-Path "$SourceDirectory/$DefaultRuleFilename")) {
            throw "Default rule file '$SourceDirectory/$DefaultRuleFilename' not found."
        }
        else {
            $Source = Get-Item $SourceDirectory
        }
    
        $DefaultRulePath = "$($Source.FullName)/$DefaultRuleFilename"
        $Rules = Get-Content -Raw $DefaultRulePath | ConvertFrom-Json
    
        ## Get Variables
        if ($null -ne $Rules.variables) {
            $VariablesFileName = $Rules.variables.Replace("#include:", "")
            $Rules.variables = @()
            $Variables = Get-Content -Raw "$($Source.FullName)/$VariablesFileName" | ConvertFrom-Json
            $Rules.variables += $Variables
        }
        
    
        for ($i = 0; $i -lt $Rules.children.count; $i++) {
            if ($Rules.children[$i].GetType().Name -eq 'String' -and $Rules.children[$i].StartsWith('#include:')) {
                $Rules.children[$i] = Expand-ChildRuleSnippet -Include $Rules.children[$i] -Path $Source.FullName -DefaultRuleDirectory $Source.FullName
            }
        }
    
        $Output = New-Object -TypeName PSCustomObject
        $Output | Add-Member -MemberType NoteProperty -Name rules -Value $Rules
    
        if ($OutputToFile) {
            if ($OutputFileName -eq '') {
                $OutputFileName = $Source.Name + '.json'
            }
            Write-Host 'Combined contents of ' -NoNewline
            Write-Host -ForegroundColor Green $SourceDirectory -NoNewline
            Write-Host ' into ' -NoNewline
            Write-Host -ForegroundColor Green $OutputFileName -NoNewline
            Write-Host '.'
            $Output | ConvertTo-Json -Depth 100 | Set-Content $OutputFileName
        }
        else {
            return $Output
        }
    }
}

function New-BulkActivation {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
        [string]
        $ContractId,

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
        $Path = "/papi/v1/bulk/activations"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Extract bulk activation ID
        $BulkActivationID = $Response.Body.bulkActivationLink -split '\?' | Select-Object -First 1
        $BulkActivationID = $BulkActivationID -split '/' | Select-Object -Last 1
        $Response.Body | Add-Member -NotePropertyName BulkActivationID -NotePropertyValue $BulkActivationID -Force
        
        return $Response.Body
    }
}
function New-BulkPatch {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
        [string]
        $ContractId,

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
        $Path = "/papi/v1/bulk/rules-patch-requests"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Extract bulk patch ID
        $BulkPatchID = $Response.Body.bulkPatchLink -split '\?' | Select-Object -First 1
        $BulkPatchID = $BulkPatchID -split '/' | Select-Object -Last 1
        $Response.Body | Add-Member -NotePropertyName BulkPatchID -NotePropertyValue $BulkPatchID -Force

        return $Response.Body
    }
}

function New-BulkSearch {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Position = 0, Mandatory)]
        [string]
        $Match,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $BulkSearchQualifier,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $Synchronous,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
        [string]
        $ContractId,

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
        if ($Synchronous) {
            $Path = "/papi/v1/bulk/rules-search-requests-synch"
        }
        else {
            $Path = "/papi/v1/bulk/rules-search-requests"
        }
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $BulkSearchQuery = @{
                'syntax' = 'JSONPATH'
                'match'  = $Match
            }
            if ($BulkSearchQualifier) {
                $BulkSearchQuery['bulkSearchQualifiers'] = @($BulkSearchQualifier)
            }
            $Body = @{'bulkSearchQuery' = $BulkSearchQuery }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Extract bulk search ID for async requests
        if (-not $Synchronous) {
            $BulkSearchID = $Response.Body.bulkSearchLink -split '\?' | Select-Object -First 1
            $BulkSearchID = $BulkSearchID -split '/' | Select-Object -Last 1
            $Response.Body | Add-Member -NotePropertyName BulkSearchID -NotePropertyValue $BulkSearchID -Force
        }

        return $Response.Body
    }
}


function New-BulkVersion {
    [CmdletBinding(DefaultParameterSetName = 'pipeline')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
        [string]
        $ContractId,

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
        $Path = "/papi/v1/bulk/property-version-creations"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Extract bulk version ID
        $BulkCreateID = $Response.Body.bulkCreateVersionLink -split '\?' | Select-Object -First 1
        $BulkCreateID = $BulkCreateID -split '/' | Select-Object -Last 1
        $Response.Body | Add-Member -NotePropertyName BulkCreateID -NotePropertyValue $BulkCreateID -Force

        return $Response.Body
    }
}
function New-CPCode {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory) ]
        [string]
        $CPCodeName,

        [Parameter(ParameterSetName = 'Attributes', Mandatory) ]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter(Mandatory)]
        [string]
        $ContractId,

        [Parameter(Mandatory)]
        [string]
        $GroupId,

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
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'productId'  = $ProductID
                'cpcodeName' = $CPCodeName
            }
        }

        $Path = "/papi/v1/cpcodes"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Body.cpcodeLink -Match '\/cpcodes\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'cpcodeId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}

function New-EdgeHostname {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $DomainPrefix,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('akamaized.net', 'edgesuite.net', 'edgekey.net')]
        [string]
        $DomainSuffix,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('IPV4', 'IPV6_COMPLIANCE', 'IPV6_PERFORMANCE')]
        [string]
        $IPVersionBehavior,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('ENHANCED_TLS', 'STANDARD_TLS', 'SHARED_CERT')]
        [string]
        $SecureNetwork,

        [Parameter(ParameterSetName = 'Attributes')]
        [int]
        $SlotNumber,

        [Parameter(ParameterSetName = 'Attributes')]
        [int]
        $CertEnrollmentID,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $Options,

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
        $Path = "/papi/v1/edgehostnames"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
            options    = $Options
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'productId'         = $ProductID
                'domainPrefix'      = $DomainPrefix
                'domainSuffix'      = $DomainSuffix
                'ipVersionBehavior' = $IPVersionBehavior
            }

            if ($SecureNetwork -ne '') { $Body['secureNetwork'] = $SecureNetwork }
            if ($SlotNumber) { $Body['slotNumber'] = $SlotNumber }
            if ($CertEnrollmentID) { $Body['certEnrollmentId'] = $CertEnrollmentID }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Body.edgeHostnameLink -Match '\/edgehostnames\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'edgeHostnameId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}

function New-Property {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $RuleFormat,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [string]
        $ClonePropertyName,

        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ClonePropertyID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ClonePropertyVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ClonePropertyVersionEtag,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $CopyHostnames,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UseHostnameBucket,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
        [string]
        $ContractID,

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
        $ClonePropertyID, $ClonePropertyVersion, $null, $null = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties"
        $QueryParameters = @{
            'contractId' = $ContractId
            'groupId'    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'propertyName' = $Name
                'productId'    = $ProductID
            }
            $CloneFrom = @{}
            if ($RuleFormat) { $Body['ruleFormat'] = $RuleFormat }
            if ($CopyHostnames) { $CloneFrom['copyHostnames'] = $CopyHostnames.ToBool() }
            if ($ClonePropertyID) { $CloneFrom['propertyId'] = $ClonePropertyID }
            if ($ClonePropertyVersion) { $CloneFrom['version'] = $ClonePropertyVersion }
            if ($ClonePropertyVersionEtag) { $CloneFrom['cloneFromVersionEtag'] = $ClonePropertyVersionEtag }
            if ($CloneFromVersionEtag -or $CopyHostnames -or $ClonePropertyID -or $ClonePropertyVersion) { $Body['cloneFrom'] = $CloneFrom }
            if ($UseHostnameBucket) { $Body['useHostnameBucket'] = $true }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
    
            if ($Response.Body.propertyLink -Match '\/properties\/([^\?]+)') {
                $PropertyID = $matches[1]
                $Response.Body | Add-Member -NotePropertyName 'propertyId' -NotePropertyValue $PropertyID
    
                # Add to data cache
                if ($AkamaiOptions.EnableDataCache) {
                    Set-AkamaiDataCache -PropertyName $Name -PropertyID $PropertyID
                }
            }
    
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function New-PropertyActivation {
    [CmdletBinding(DefaultParameterSetName = 'ID & attributes')]
    [Alias('Deploy-Property')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('Staging', 'Production')]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Note,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UseFastFallback,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string[]]
        $NotifyEmails,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [ValidateSet('NONE', 'OTHER', 'NO_PRODUCTION_TRAFFIC', 'EMERGENCY')]
        [string]
        $NoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $OtherNoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CustomerEmail,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $PeerReviewedBy,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UnitTested,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $TicketID,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            if ($NoncomplianceReason -eq 'NONE' -and $Network -eq 'Production') {
                if ($CustomerEmail -eq '' -or $PeerReviewedBy -eq '' -or $UnitTested -eq $false) {
                    throw "You must supply the following when NonComplianceReason is 'NONE': CustomerEmail, PeerReviewedBy & UnitTested."
                }
            }

            $Body = @{
                'propertyVersion'        = [int] $PropertyVersion
                'network'                = $Network.ToUpper()
                'note'                   = $Note
                'useFastFallback'        = $useFastFallback.ToBool()
                'notifyEmails'           = $NotifyEmails
                'acknowledgeAllWarnings' = $true
            }

            # Only add optional fields if they are present
            $ComplianceRecord = @{}
            if ($NoncomplianceReason) {
                $ComplianceRecord['noncomplianceReason'] = $NoncomplianceReason
            }
            if ($CustomerEmail) {
                $ComplianceRecord['customerEmail'] = $CustomerEmail
            }
            if ($PeerReviewedBy) {
                $ComplianceRecord['peerReviewedBy'] = $PeerReviewedBy
            }
            if ($UnitTested) {
                $ComplianceRecord['unitTested'] = $UnitTested.ToBool()
            }
            if ($TicketID) {
                $ComplianceRecord['ticketId'] = $TicketID
            }
            if ($OtherNoncomplianceReason) {
                $ComplianceRecord['otherNoncomplianceReason'] = $OtherNoncomplianceReason
            }

            # Only add compliance record to body if not empty
            if ($ComplianceRecord.count -gt 0) {
                $Body['complianceRecord'] = $ComplianceRecord
            }
        }

        $Path = "/papi/v1/properties/$PropertyID/activations"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Body.activationLink -Match '\/activations\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'activationId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}

function New-PropertyDeactivation {
    [CmdletBinding(DefaultParameterSetName = 'ID & attributes')]
    [Alias('Disable-Property')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('Staging', 'Production')]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Note,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UseFastFallback,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string[]]
        $NotifyEmails,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [ValidateSet('NONE', 'OTHER', 'NO_PRODUCTION_TRAFFIC', 'EMERGENCY')]
        [string]
        $NoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $OtherNoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CustomerEmail,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $PeerReviewedBy,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UnitTested,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $TicketID,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            if ($NoncomplianceReason -eq 'NONE' -and $Network -eq 'Production') {
                if ($CustomerEmail -eq '' -or $PeerReviewedBy -eq '' -or $UnitTested -eq $false) {
                    throw "You must supply the following when NonComplianceReason is 'NONE': CustomerEmail, PeerReviewedBy & UnitTested."
                }
            }

            $Body = @{
                activationType         = 'DEACTIVATE'
                propertyVersion        = [int] $PropertyVersion
                network                = $Network.ToUpper()
                note                   = $Note
                notifyEmails           = $NotifyEmails
                acknowledgeAllWarnings = $true
            }

            # Only add optional fields if they are present

            $ComplianceRecord = @{}
            if ($NoncomplianceReason) {
                $ComplianceRecord['noncomplianceReason'] = $NoncomplianceReason
            }
            if ($CustomerEmail) {
                $ComplianceRecord['customerEmail'] = $CustomerEmail
            }
            if ($PeerReviewedBy) {
                $ComplianceRecord['peerReviewedBy'] = $PeerReviewedBy
            }
            if ($UnitTested) {
                $ComplianceRecord['unitTested'] = $UnitTested.ToBool()
            }
            if ($TicketID) {
                $ComplianceRecord['ticketId'] = $TicketID
            }
            if ($OtherNoncomplianceReason) {
                $ComplianceRecord['otherNoncomplianceReason'] = $OtherNoncomplianceReason
            }

            # Only add compliance record to body if not empty
            if ($ComplianceRecord.count -gt 0) {
                $Body['complianceRecord'] = $ComplianceRecord
            }
        }

        $Path = "/papi/v1/properties/$PropertyID/activations"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Body.activationLink -Match '\/activations\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'activationId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}

function New-PropertyInclude {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $RuleFormat,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('MICROSERVICES', 'COMMON_SETTINGS')]
        [string]
        $IncludeType,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [string]
        $CloneIncludeName,

        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CloneIncludeID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CloneIncludeVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CloneIncludeVersionEtag,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
        [string]
        $ContractID,

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
        $CloneIncludeID, $CloneIncludeVersion, $null, $null = Expand-PropertyIncludeDetails @PSBoundParameters

        $Path = "/papi/v1/includes"
        $QueryParameters = @{
            'contractId' = $ContractId
            'groupId'    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'productId'   = $ProductID
                'includeName' = $Name
                'includeType' = $IncludeType
            }
            $CloneFrom = @{}
            if ($RuleFormat) { $Body['ruleFormat'] = $RuleFormat }
            if ($CloneIncludeID) { $CloneFrom['includeId'] = $CloneIncludeID }
            if ($CloneIncludeVersion) { $CloneFrom['version'] = $CloneIncludeVersion }
            if ($CloneIncludeVersionEtag) { $CloneFrom['cloneFromVersionEtag'] = $CloneIncludeVersionEtag }
            if ($CloneFromVersionEtag -or $CopyHostnames -or $CloneIncludeID -or $CloneIncludeVersion) { $Body['cloneFrom'] = $CloneFrom }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
            if ($Response.Body.includeLink -Match '\/includes\/([^\?]+)') {
                $IncludeID = $Matches[1]
                $Response.Body | Add-Member -NotePropertyName 'includeId' -NotePropertyValue $IncludeID
    
                # Add to data cache
                if ($AkamaiOptions.EnableDataCache) {
                    Set-AkamaiDataCache -IncludeName $Name -IncludeID $IncludeID
                }
            }
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function New-PropertyIncludeActivation {
    [CmdletBinding(DefaultParameterSetName = 'ID & attributes')]
    [Alias('Deploy-PropertyInclude')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeVersion,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('Staging', 'Production')]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Note,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UseFastFallback,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string[]]
        $NotifyEmails,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [ValidateSet('NONE', 'OTHER', 'NO_PRODUCTION_TRAFFIC', 'EMERGENCY')]
        [string]
        $NoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $OtherNoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CustomerEmail,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $PeerReviewedBy,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UnitTested,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $TicketID,

        [Parameter()]
        [string]
        $EdgeRCFile = '~\.edgerc',

        [Parameter()]
        [string]
        $Section = 'default',

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            if ($NoncomplianceReason -eq 'NONE' -and $Network -eq 'Production') {
                if ($CustomerEmail -eq '' -or $PeerReviewedBy -eq '' -or $UnitTested -eq $false) {
                    throw "You must supply the following when NonComplianceReason is 'NONE': CustomerEmail, PeerReviewedBy & UnitTested."
                }
            }

            $Body = @{
                includeVersion         = [int] $IncludeVersion
                network                = $Network.ToUpper()
                note                   = $Note
                useFastFallback        = $useFastFallback.ToBool()
                acknowledgeAllWarnings = $true
                notifyEmails           = $NotifyEmails
            }

            # Only add optional fields if they are present
            $ComplianceRecord = @{}
            if ($NoncomplianceReason) {
                $ComplianceRecord['noncomplianceReason'] = $NoncomplianceReason
            }
            if ($CustomerEmail) {
                $ComplianceRecord['customerEmail'] = $CustomerEmail
            }
            if ($PeerReviewedBy) {
                $ComplianceRecord['peerReviewedBy'] = $PeerReviewedBy
            }
            if ($UnitTested) {
                $ComplianceRecord['unitTested'] = $UnitTested.ToBool()
            }
            if ($TicketID) {
                $ComplianceRecord['ticketId'] = $TicketID
            }
            if ($OtherNoncomplianceReason) {
                $ComplianceRecord['otherNoncomplianceReason'] = $OtherNoncomplianceReason
            }

            # Only add compliance record to body if not empty
            if ($ComplianceRecord.count -gt 0) {
                $Body['complianceRecord'] = $ComplianceRecord
            }
        }

        $Path = "/papi/v1/includes/$IncludeID/activations"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Body.activationLink -Match '\/activations\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'activationId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}

function New-PropertyIncludeDeactivation {
    [CmdletBinding(DefaultParameterSetName = 'ID & attributes')]
    [Alias('Disable-PropertyInclude')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeVersion,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('Staging', 'Production')]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Note,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UseFastFallback,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string[]]
        $NotifyEmails,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [ValidateSet('NONE', 'OTHER', 'NO_PRODUCTION_TRAFFIC', 'EMERGENCY')]
        [string]
        $NoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $OtherNoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CustomerEmail,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $PeerReviewedBy,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UnitTested,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $TicketID,

        [Parameter()]
        [string]
        $EdgeRCFile = '~\.edgerc',

        [Parameter()]
        [string]
        $Section = 'default',

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            if ($NoncomplianceReason -eq 'NONE' -and $Network -eq 'Production') {
                if ($CustomerEmail -eq '' -or $PeerReviewedBy -eq '' -or $UnitTested -eq $false) {
                    throw "You must supply the following when NonComplianceReason is 'NONE': CustomerEmail, PeerReviewedBy & UnitTested."
                }
            }

            $Body = @{
                activationType         = 'DEACTIVATE'
                includeVersion         = [int] $IncludeVersion
                network                = $Network.ToUpper()
                note                   = $Note
                useFastFallback        = $useFastFallback.ToBool()
                acknowledgeAllWarnings = $true
                notifyEmails           = $NotifyEmails
            }

            # Only add optional fields if they are present
            $ComplianceRecord = @{}
            if ($NoncomplianceReason) {
                $ComplianceRecord['noncomplianceReason'] = $NoncomplianceReason
            }
            if ($CustomerEmail) {
                $ComplianceRecord['customerEmail'] = $CustomerEmail
            }
            if ($PeerReviewedBy) {
                $ComplianceRecord['peerReviewedBy'] = $PeerReviewedBy
            }
            if ($UnitTested) {
                $ComplianceRecord['unitTested'] = $UnitTested.ToBool()
            }
            if ($TicketID) {
                $ComplianceRecord['ticketId'] = $TicketID
            }
            if ($OtherNoncomplianceReason) {
                $ComplianceRecord['otherNoncomplianceReason'] = $OtherNoncomplianceReason
            }

            # Only add compliance record to body if not empty
            if ($ComplianceRecord.count -gt 0) {
                $Body['complianceRecord'] = $ComplianceRecord
            }
        }

        $Path = "/papi/v1/includes/$IncludeID/activations"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Body.activationLink -Match '\/activations\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'activationId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}

function New-PropertyIncludeVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(ParameterSetName = 'Name & attributes', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('IncludeVersion')]
        [string]
        $CreateFromVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CreateFromVersionEtag,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        $Body,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

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
        $IncludeID, $CreateFromVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{'createFromVersion' = $CreateFromVersion }
            if ($CreateFromVersionEtag) {
                $Body['createFromVersionEtag'] = $CreateFromVersionEtag
            }
        }

        $Path = "/papi/v1/includes/$IncludeID/versions"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Add additional response data
        $Response.Body | Add-Member -NotePropertyName 'includeId' -NotePropertyValue $IncludeID
        if ($Response.Body.versionLink -Match '\/versions\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'includeVersion' -NotePropertyValue ([int] $matches[1])
        }
        if ($ContractId) {
            $Response.Body | Add-Member -NotePropertyName 'contractId' -NotePropertyValue $ContractID
        }
        if ($GroupID) {
            $Response.Body | Add-Member -NotePropertyName 'groupId' -NotePropertyValue $GroupID
        }

        return $Response.Body
    }
}

function New-PropertyVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Name & attributes', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PropertyVersion')]
        [string]
        $CreateFromVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CreateFromVersionEtag,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        $Body,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

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
        $PropertyID, $CreateFromVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{'createFromVersion' = $CreateFromVersion }
            if ($CreateFromVersionEtag) {
                $Body['createFromVersionEtag'] = $CreateFromVersionEtag
            }
        }

        $Path = "/papi/v1/properties/$PropertyID/versions"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Add additional response data
        $Response.Body | Add-Member -NotePropertyName 'propertyId' -NotePropertyValue $PropertyID
        if ($Response.Body.versionLink -Match '\/versions\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'propertyVersion' -NotePropertyValue ([int] $matches[1])
        }
        if ($ContractID) {
            $Response.Body | Add-Member -NotePropertyName 'contractId' -NotePropertyValue $ContractID
        }
        if ($GroupID) {
            $Response.Body | Add-Member -NotePropertyName 'groupId' -NotePropertyValue $GroupID
        }

        return $Response.Body
    }
}

function Remove-BucketHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $HostnamesToRemove,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [switch]
        $IncludeCertStatus,

        [Parameter()]
        [switch]
        $ValidateHostnames,

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
        $CollatedHostnames = New-Object System.Collections.Generic.List[string]
    }

    process {
        $HostnamesToRemove | ForEach-Object {
            $CollatedHostnames.Add($_)
        }
    }

    end {
        # Capitalise $Network, API seems to care
        $Network = $Network.ToUpper()
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/hostnames"
        $QueryParameters = @{
            contractId        = $ContractID
            groupId           = $GroupID
            network           = $Network
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }

        $Body = @{
            'network' = $Network
            'remove'  = $CollatedHostnames
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.hostnames

    }
}

function Remove-Property {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        # Clear data cache
        Clear-AkamaiDataCache -PropertyID $PropertyID
        return $Response.Body
    }
}
function Remove-PropertyHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Mandatory)]
        [string[]]
        $HostnamesToRemove,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [switch]
        $IncludeCertStatus,

        [Parameter()]
        [switch]
        $ValidateHostnames,

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
        $CollatedHostnames = New-Object System.Collections.Generic.List[string]
    }

    process {
        $HostnamesToRemove | ForEach-Object {
            $CollatedHostnames.Add($_)
        }
    }

    end {
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/hostnames"
        $QueryParameters = @{
            contractId        = $ContractID
            groupId           = $GroupID
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }

        $Body = @{
            'remove' = $CollatedHostnames
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Status -lt 300) {
            return $Response.Body.hostnames.items
        }
        else {
            return $Response.Body
        }

    }
}

function Remove-PropertyInclude {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

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
        $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $Path = "/papi/v1/includes/$IncludeID"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        # Clear data cache
        Clear-AkamaiDataCache -IncludeID $IncludeID
        return $Response.Body
    }
}


function Remove-PropertyIncludeRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $RequestPath = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'   = 'remove'
                'path' = $Path
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
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
function Remove-PropertyRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $RequestPath = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'   = 'remove'
                'path' = $Path
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
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


function Resume-PropertyDomainValidation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Domain,

        [Parameter()]
        [string]
        $ContractID,

        [Parameter()]
        [string]
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
        $CollatedDomains = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        $Domain | ForEach-Object {
            $CollatedDomains.Add($_)
        }
    }

    end {
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/hostnames/certificate/domain-validation/proceed"
        $QueryParameters = @{
            'contractId' = $ContractID
            'groupId'    = $GroupID
        }
        $Body = @{
            'domains' = $CollatedDomains
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.domains.items
        }
        catch {
            throw $_
        }
    }
}
function Set-PropertyClientSettings {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $RuleFormat,

        [Parameter(Mandatory)]
        [bool]
        $UsePrefixes,
        
        [Parameter()]
        [bool]
        $UpgradeRules,

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

    $AcceptedRuleFormats = Get-RuleFormat -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
    if ($RuleFormat -notin $AcceptedRuleFormats) {
        throw "$RuleFormat is not an accepted rule format. Run Get-RuleFormat for a full list."
    }
    
    $Path = "/papi/v1/client-settings"
    $Body = @{ 
        'ruleFormat'  = $RuleFormat
        'usePrefixes' = $UsePrefixes
    }
    if ($null -ne $PSBoundParameters.UpgradeRules) {
        $Body['upgradeRules'] = $UpgradeRules
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

function Set-PropertyHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [switch]
        $ValidateHostnames,

        [Parameter()]
        [switch]
        $IncludeCertStatus,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/hostnames"
        $QueryParameters = @{
            contractId        = $ContractId
            groupId           = $GroupID
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }
        if ($MyInvocation.ExpectingInput) {
            $PipedHostnames = New-Object -TypeName System.Collections.Generic.List[Object]
        }
    }

    process {
        if ($MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $PipedHostnames.Add($Body)
        }
    }

    end {
        if ($MyInvocation.ExpectingInput -and $PipedHostnames.count -gt 0) {
            $Body = $PipedHostnames
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.hostnames.items
    }
}


Function Set-PropertyIncludeRules {
    [CmdletBinding(DefaultParameterSetName = 'name-ruletree')]
    Param(
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & file', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & snippets', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & -file', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID &Snippets', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeVersion,

        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [string]
        $InputFile,

        [Parameter(ParameterSetName = 'Name & snippets', Mandatory)]
        [Parameter(ParameterSetName = 'ID & snippets', Mandatory)]
        [string]
        $InputDirectory,

        [Parameter(ParameterSetName = 'Name & snippets')]
        [Parameter(ParameterSetName = 'ID & snippets')]
        [string]
        $DefaultRuleFilename = 'main.json',

        [Parameter(ParameterSetName = 'Name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        if ($RuleFormat) {
            $AdditionalHeaders = @{
                'Content-Type' = "application/vnd.akamai.papirules.$RuleFormat+json"
            }
        }

        if ($InputFile) {
            if (!(Test-Path $InputFile)) {
                throw "Input file $Inputfile does not exist."
            }
            $Body = Get-Content $InputFile -Raw
        }
        elseif ($InputDirectory) {
            if (-not (Test-Path $InputDirectory)) {
                throw "Input directory $Inputfile does not exist."
            }
            if (-not (Test-Path "$InputDirectory/$DefaultRuleFilename")) {
                throw "Default rule filename '$DefaultRuleFilename' does not exist in input directory '$InputDirectory'."
            }
            $Body = Merge-PropertyRules -SourceDirectory $InputDirectory -DefaultRuleFilename $DefaultRuleFilename
        }

        # Add notes if required
        $Body = Get-BodyObject -Source $Body
        if ($VersionNotes) {
            $Body | Add-Member -MemberType NoteProperty -Name 'comments' -Value $VersionNotes -Force
        }

        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters

        $Path = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
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
        return $Response.Body
    }

}


Function Set-PropertyRules {
    [CmdletBinding(DefaultParameterSetName = 'Name & body')]
    Param(
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & file', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & snippets', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & file', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & snippets', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [string]
        $InputFile,

        [Parameter(ParameterSetName = 'Name & snippets', Mandatory)]
        [Parameter(ParameterSetName = 'ID & snippets', Mandatory)]
        [string]
        $InputDirectory,

        [Parameter(ParameterSetName = 'Name & snippets')]
        [Parameter(ParameterSetName = 'ID & snippets')]
        [string]
        $DefaultRuleFilename = 'main.json',

        [Parameter(ParameterSetName = 'Name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        if ($InputFile) {
            if (!(Test-Path $InputFile)) {
                throw "Input file $Inputfile does not exist."
            }
            $Body = Get-Content $InputFile -Raw
        }
        elseif ($InputDirectory) {
            if (-not (Test-Path $InputDirectory)) {
                throw "Input directory $Inputfile does not exist."
            }
            if (-not (Test-Path "$InputDirectory/$DefaultRuleFilename")) {
                throw "Default rule filename '$DefaultRuleFilename' does not exist in input directory '$InputDirectory'."
            }
            $Body = Merge-PropertyRules -SourceDirectory $InputDirectory -DefaultRuleFilename $DefaultRuleFilename
        }

        # Add notes if required
        $Body = Get-BodyObject -Source $Body
        if ($VersionNotes) {
            $Body | Add-Member -MemberType NoteProperty -Name 'comments' -Value $VersionNotes -Force
        }

        # Set ruleformat in headers and body
        if ($RuleFormat) {
            $AdditionalHeaders = @{
                'Content-Type' = "application/vnd.akamai.papirules.$RuleFormat+json"
            }
            $Body.ruleFormat = $RuleFormat
        }

        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
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
        return $Response.Body
    }

}


function Test-PropertyInclude {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Position = 2, Mandatory)]
        [string]
        $IncludeActivationID,

        [Parameter()]
        [int]
        $Offset,

        [Parameter()]
        [int]
        $Limit,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/includes/validation-results/$IncludeActivationID/properties/$PropertyID/versions/$PropertyVersion"
        $QueryParameters = @{
            'contractId' = $ContractId
            'groupId'    = $GroupID
            'limit'      = $PSBoundParameters.limit
            'offset'     = $PSBoundParameters.offset
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
        return $Response.Body
    }
}

function Test-PropertyIncludeRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory)]
        [string]
        $IncludeVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $RequestPath = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'test'
                'path'  = $Path
                'value' = (Get-BodyObject -Source $Value)
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
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
function Test-PropertyRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $RequestPath = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'test'
                'path'  = $Path
                'value' = (Get-BodyObject -Source $Value)
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
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
function Undo-BucketActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Mandatory)]
        [string]
        $HostnameActivationID,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/hostname-activations/$HostnameActivationID"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.hostnameActivations.items
    }
}

function Undo-PropertyActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Restore-Property')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Mandatory)]
        [string]
        $ActivationId,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/activations/$ActivationID"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.activations.items
    }
}

function Undo-PropertyIncludeActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Restore-PropertyInclude')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Mandatory)]
        [string]
        $ActivationId,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters

        $Path = "/papi/v1/includes/$IncludeID/activations/$ActivationId"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.activations.items
    }
}


function Update-PropertyDomainValidation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Domain,

        [Parameter()]
        [string]
        $ContractID,

        [Parameter()]
        [string]
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
        $CollatedDomains = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        $Domain | ForEach-Object {
            $CollatedDomains.Add($_)
        }
    }

    end {
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/hostnames/certificate/domain-validation/authorization/regenerate"
        $QueryParameters = @{
            'contractId' = $ContractID
            'groupId'    = $GroupID
        }
        $Body = @{
            'domains' = $CollatedDomains
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.domains.items
        }
        catch {
            throw $_
        }
    }
}

function Update-PropertyIncludeRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory)]
        [string]
        $IncludeVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $RequestPath = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'replace'
                'path'  = $Path
                'value' = (Get-BodyObject -Source $Value)
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
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
function Update-PropertyRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $RequestPath = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'replace'
                'path'  = $Path
                'value' = (Get-BodyObject -Source $Value)
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD/6noVsIHaAJGG
# nuJJD2CrmZSZTRGbBA8l2hcTqdmeXKCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPSaDSIRPJAdbSNZnw1SAMHbeinl92DN
# e2UANgW1VZj8MA0GCSqGSIb3DQEBAQUABIIBgF7v207wfOiy27SBzVCeTGbLRb1B
# IksbjSclQ8nxcW54yYo8Fv36/VIhTmXP097G0s+rH7xYLaJn6RMiXe+6rbq/BgK8
# lBisEc+3wJYLsLMVgGGmLxZbp1voFsbO97xz6q6A0/ekGtMVqKjSWQ8EAZ+Jh0OD
# QCflBqoUvbcS9nXg75DqlPJSCnHpZqhyQVtd4JGy1YZCLXIdHn06+u92sjFmaUdg
# qfwOXGZT00RJhXHDgdYJnm4WwO35ZFS0pvTRDO+yplkhd5BLVCzBWpAXt7HPgD8L
# NOr1uHkkts+HY74qTnVOjrda8x9yZfIERMCnsd7dxRTgMGty2Seh/xrEHNfH7VXY
# HEWFeu3ZCSI2DLLxyG39DmNmI6OcFW/NCWQXgdoLHL0Vg1GSigyZkx23ci5f6G9y
# jtCY6uD1L+UXs6jRf4+wiU1vSc8eKUfnXd3+O7E7Hy7AZLRL/AWlSDLAe7Btqx6A
# KRCG3VjgNyoy785Tk77/6hEz3Ts1YCfZtKGXIg==
# SIG # End signature block
