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


function Add-EDNSProxyZoneManualFilterName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [switch]
        $AddSkipExisting,

        [Parameter()]
        [string[]]
        $FilterNames,

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
        $CollatedNames = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        $FilterNames | ForEach-Object {
            $CollatedNames.Add($_)
        }
    }

    end {
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names/manage"
        $QueryParameters = @{
            'addSkipExisting' = $PSBoundParameters.AddSkipExisting.IsPresent
        }
        $Body = @{
            'add' = $CollatedNames
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
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}

function Compare-EDNSZoneVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('VersionID')]
        [string]
        $From,

        [Parameter(Mandatory)]
        [string]
        $To,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/versions/diff"

        $QueryParameters = @{
            'from' = $From
            'to'   = $To
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.diffs
    }
}


function Convert-EDNSProxyZone {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [ValidateSet('all', 'automatic', 'manual', 'none')]
        [string]
        $Mode,

        [Parameter(Mandatory)]
        [string[]]
        $Name,

        [Parameter(ParameterSetName = 'Manual')]
        [string[]]
        $ManualFilterNames,

        [Parameter(ParameterSetName = 'Automatic', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Automatic', Mandatory)]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Automatic', Mandatory)]
        [string]
        $TSIGKeySecret,

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
        $CollatedProxyZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        $Name | ForEach-Object {
            $CollatedProxyZones.Add($_)
        }
    }

    end {
        if ($Mode -eq 'all') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/filter-mode-convert/to-all"
        }
        if ($Mode -eq 'automatic') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/filter-mode-convert/to-automatic"
        }
        if ($Mode -eq 'manual') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/filter-mode-convert/to-manual"
        }
        if ($Mode -eq 'none') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/filter-mode-convert/to-none"
        }

        $Body = @{
            'proxyZones' = $CollatedProxyZones
        }
        if ($TSIGKeyName) {
            $Body.tsigKey = @{
                'algorithm' = $TSIGKeyAlgorithm
                'name'      = $TSIGKeyName
                'secret'    = $TSIGKeySecret
            }
        }
        if ($ManualFilterNames) {
            $Body.manualFilterNames = @($ManualFilterNames)
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Convert-EDNSZoneToAlias {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Zone,

        [Parameter(Mandatory)]
        [string]
        $TargetZoneName,

        [Parameter()]
        [string]
        $Comment,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        if ($Zone.count -gt 1) {
            $CollatedZones.AddRange($Zone)
        }
        else {
            $CollatedZones.Add($Zone)
        }
    }

    end {
        $Path = "/config-dns/v2/zones/convert-requests/alias"
        $Body = @{
            'targetZoneName' = $TargetZoneName
            'zoneList'       = $CollatedZones
        }
        if ($Comment) {
            $Body.comment = $Comment
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Convert-EDNSZoneToPrimary {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Zone,

        [Parameter()]
        [string]
        $Comment,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        if ($Zone.count -gt 1) {
            $CollatedZones.AddRange($Zone)
        }
        else {
            $CollatedZones.Add($Zone)
        }
    }

    end {
        $Path = "/config-dns/v2/zones/convert-requests/primary"
        $Body = @{
            'zoneList' = $CollatedZones
        }
        if ($Comment) {
            $Body.comment = $Comment
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Convert-EDNSZoneToSecondary {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $Zone,

        [Parameter(Mandatory)]
        [string[]]
        $Masters,

        [Parameter(ParameterSetName = 'Secure transfer', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Secure transfer', Mandatory)]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Secure transfer', Mandatory)]
        [string]
        $TSIGKeySecret,

        [Parameter()]
        [string]
        $Comment,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        # Handle option to provide just names, or both name and soaSerialLock object
        $Zone | Foreach-Object {
            if ($_ -is 'String') {
                $CollatedZones.Add(
                    @{
                        'name' = $_
                    }
                )
            }
            else {
                $CollatedZones.Add($_)
            }
        }
    }

    end {
        $Path = "/config-dns/v2/zones/convert-requests/secondary"
        $Body = @{
            'masters'  = $Masters
            'zoneList' = $CollatedZones
        }
        if ($TSIGKeyName) {
            $Body.tsigKey = @{
                'algorithm' = $TSIGKeyAlgorithm
                'name'      = $TSIGKeyName
                'secret'    = $TSIGKeySecret
            }
        }
        if ($Comment) {
            $Body.comment = $Comment
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Find-EDNSChangeList {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string[]]
        $Zone,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        if ($Zone.count -gt 1) {
            $CollatedZones.AddRange($Zone)
        }
        else {
            $CollatedZones.Add($Zone)
        }
    }

    end {
        $Path = "/config-dns/v2/changelists/search"
        $Body = @{
            'zones' = $CollatedZones
        }
        if ($Comment) {
            $Body.comment = $Comment
        }
        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.changeLists
        }
        catch {
            throw $_
        }
    }

}

function Get-EDNSAuthority {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
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
        $Method = 'GET'
        $Path = "/config-dns/v2/data/authorities"

        $QueryParameters = @{
            'contractIds' = $ContractID -join ','
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.contracts
    }
}

function Get-EDNSChangeList {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'GET'
        if ($Zone) {
            $Path = "/config-dns/v2/changelists/$Zone"
        }
        else {
            $Path = "/config-dns/v2/changelists"
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Zone) {
            return $Response.Body
        }
        else {
            return $Response.Body.changelists
        }
    }
}

function Get-EDNSChangeListDiff {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/changelists/$Zone/diff"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.diffs
    }
}

function Get-EDNSChangeListRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Get all')]
        [string[]]
        $Types,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

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
        $Method = 'GET'
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/config-dns/v2/changelists/$Zone/names/$Name/types/$Type"
        }
        else {
            $Path = "/config-dns/v2/changelists/$Zone/recordsets"
        }

        $QueryParameters = @{
            'sortBy'  = $SortBy
            'types'   = $Types -join ','
            'search'  = $Search
            'showAll' = $true
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            return $Response.Body
        }
        else {
            return $Response.Body.recordsets
        }
    }
}

function Get-EDNSChangeListRecordSetNames {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/changelists/$Zone/names"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.names
    }
}

function Get-EDNSChangeListRecordSetTypes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory)]
        [string]
        $Name,

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
        $Method = 'GET'
        if ($Name -ne $Zone -and $Name -notmatch "\.$Zone\.?$") {
            $Name = "$Name.$Zone"
        }
        # Remove trailing slash if present
        if ($Name.EndsWith('.')) {
            $Name = $Name.TrimEnd('.')
        }
        $Path = "/config-dns/v2/changelists/$Zone/names/$Name/types"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.types
    }
}

function Get-EDNSChangeListSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/changelists/$Zone/settings"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-EDNSContracts {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
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

    process {
        $Method = 'GET'
        $Path = "/config-dns/v2/data/contracts"

        $QueryParameters = @{
            'gid' = $GroupID
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.contracts
    }
}


function Get-EDNSConvertResult {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $RequestID,

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
        $Path = "/config-dns/v2/zones/convert-requests/$RequestID/result"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSConvertStatus {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Get one', ValueFromPipelineByPropertyName)]
        [string]
        $RequestID,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsComplete,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $ShowAll,

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
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/config-dns/v2/zones/convert-requests/$RequestID"
        }
        else {
            $Path = "/config-dns/v2/zones/convert-requests"
            $QueryParameters = @{
                'isComplete' = $PSBoundParameters.IsComplete.IsPresent
                'page'       = $PSBoundParameters.Page
                'pageSize'   = $PSBoundParameters.PageSize
                'showAll'    = $PSBoundParameters.ShowAll.IsPresent
            }
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
            if ($PSCmdlet.ParameterSetName -eq 'Get one') {
                return $Response.Body
            }
            else {
                return $Response.Body.requests
            }
        }
        catch {
            throw $_
        }
    }
}

function Get-EDNSDNSSECAlgorithms {
    [CmdletBinding()]
    param (
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
        $Method = 'GET'
        $Path = "/config-dns/v2/data/dns-sec-algorithms"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.algorithms
    }
}

function Get-EDNSEdgeHostnames {
    [CmdletBinding()]
    param (
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
        $Method = 'GET'
        $Path = "/config-dns/v2/data/edgehostnames"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.edgehostnames
    }
}

function Get-EDNSGroups {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
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

    process {
        $Method = 'GET'
        $Path = "/config-dns/v2/data/groups"

        $QueryParameters = @{
            'gid' = $PSBoundParameters.GroupID
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.groups
    }
}

function Get-EDNSMasterFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/zone-file"

        $AdditionalHeaders = @{
            'accept' = 'text/dns'
        }

        $RequestParams = @{
            'Method'            = $Method
            'Path'              = $Path
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Get-EDNSProxy {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Nameserver,

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
        if ($ProxyID) {
            $Path = "/config-dns/v2/proxies/$ProxyID"
        }
        else {
            $Path = "/config-dns/v2/proxies"
            $QueryParameters = @{
                'nameserver' = $Nameserver
            }
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
            if ($ProxyID) {
                return $Response.Body
            }
            else {
                return $Response.Body.items
            }
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyHealthcheckRecordTypes {
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
        $Path = "/config-dns/v2/proxies/healthcheck-recordset-types"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.types
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyZone {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(ParameterSetName = 'Get one')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $FilterMode,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize = 1000,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

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
        if ($Name) {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name"
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones"
        }
        $QueryParameters = @{
            'search'     = $Search
            'filterMode' = $FilterMode
            'page'       = $PSBoundParameters.Page
            'pageSize'   = $PSBoundParameters.PageSize
            'sortBy'     = $SortBy
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
            if ($Name) {
                return $Response.Body
            }
            else {
                return $Response.Body.proxyZones
            }
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyZoneCreateResult {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $RequestID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $ShowAll,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsComplete,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsExpired,

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
        if ($RequestID) {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/create-requests/$RequestID/result"
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/create-requests"
            $QueryParameters = @{
                'page'       = $PSBoundParameters.Page
                'pageSize'   = $PSBoundParameters.PageSize
                'showAll'    = $PSBoundParameters.ShowAll.IsPresent
                'isComplete' = $PSBoundParameters.IsComplete.IsPresent
                'isExpired'  = $PSBoundParameters.IsExpired.IsPresent
            }
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
            if ($RequestID) {
                return $Response.Body
            }
            else {
                return $Response.Body.requests
            }
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyZoneCreateStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $RequestID,

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
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/create-requests/$RequestID"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyZoneDeleteResult {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $RequestID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $ShowAll,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsComplete,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsExpired,

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
        if ($RequestID) {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/delete-requests/$RequestID/result"
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/delete-requests/results"
            $QueryParameters = @{
                'page'       = $PSBoundParameters.Page
                'pageSize'   = $PSBoundParameters.PageSize
                'showAll'    = $PSBoundParameters.ShowAll.IsPresent
                'isComplete' = $PSBoundParameters.IsComplete.IsPresent
                'isExpired'  = $PSBoundParameters.IsExpired.IsPresent
            }
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
            if ($RequestID) {
                return $Response.Body
            }
            else {
                return $Response.Body.requests
            }
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyZoneDeleteStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $RequestID,

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
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/delete-requests/$RequestID"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyZoneManualFilterReport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

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
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.manualFilterNames
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyZoneTSIGKey {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(ParameterSetName = 'Get one')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

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
        if ($Name) {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/key"
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/keys"
        }
        $QueryParameters = @{
            'page'     = $PSBoundParameters.Page
            'pageSize' = $PSBoundParameters.PageSize
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
            if ($Name) {
                return $Response.Body
            }
            else {
                return $Response.Body.proxyZones
            }
        }
        catch {
            throw $_
        }
    }
}


function Get-EDNSProxyZoneTSIGKeyUsedBy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

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
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/key/used-by"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.items
        }
        catch {
            throw $_
        }
    }
}

function Get-EDNSRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Get one', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Get one', Mandatory)]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Types,

        [Parameter(ParameterSetName = 'Get all')]
        $Search,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/recordsets"

        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            if ($Name -ne $Zone -and $Name -notmatch "\.$Zone\.?$") {
                $Name = "$Name.$Zone"
            }
            # Remove trailing dot if present
            if ($Name.EndsWith('.')) {
                $Name = $Name.TrimEnd('.')
            }
            $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
        }

        $QueryParameters = @{
            'sortBy' = $SortBy
            'types'  = $Types
            'search' = $Search
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters['showAll'] = $true
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            return $Response.Body
        }
        else {
            return $Response.Body.recordsets
        }
    }
}

function Get-EDNSRecordSetTypes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/data/recordset-types"

        $QueryParameters = @{
            'zone' = $Zone
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.types
    }
}


function Get-EDNSSecondarySOA {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Zone,

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
        $Path = "/config-dns/v2/zones/convert-requests/serials"
        $Body = @{
            'zones' = $Zone
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.soaSerialLocks
        }
        catch {
            throw $_
        }
    }
}

function Get-EDNSTSIGAlgorithms {
    [CmdletBinding()]
    param (
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
        $Method = 'GET'
        $Path = "/config-dns/v2/data/tsig-algorithms"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.algorithms
    }
}

function Get-EDNSTSIGKey {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param (
        [Parameter(ParameterSetName = 'Get one', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Get all')]
        $ContractIDs,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

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
        $Method = 'GET'

        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/config-dns/v2/zones/$Zone/key"
        }
        else {
            $Path = "/config-dns/v2/keys"
        }

        $QueryParameters = @{
            'contractIds' = $ContractIDs -join ','
            'search'      = $Search
            'sortBy'      = $SortBy -join ','
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            return $Response.Body.keys
        }
        else {
            return $Response.Body
        }
    }
}


function Get-EDNSTSIGKeyContract {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(Mandatory)]
        [string]
        $TSIGKeyName,

        [Parameter(Mandatory)]
        [string]
        $TSIGKeySecret,

        [Parameter()]
        [ValidateSet('inbound', 'outbound', 'proxy')]
        [string]
        $KeyType,

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
        $Path = "/config-dns/v2/keys/used-by/zone-contract-map"
        $QueryParameters = @{
            'keyType' = $KeyType
        }
        $Body = @{
            'algorithm' = $TSIGKeyAlgorithm
            'name'      = $TSIGKeyName
            'secret'    = $TSIGKeySecret
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
            return $Response.Body.contracts
        }
        catch {
            throw $_
        }
    }
}

function Get-EDNSTSIGKeyUsedBy {
    [CmdletBinding(DefaultParameterSetName = 'Find by key with attributes')]
    param (
        [Parameter(ParameterSetName = 'Find by zone', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Find by key with attributes', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Find by key with attributes', Mandatory)]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Find by key with attributes', Mandatory)]
        [string]
        $TSIGKeySecret,

        [Parameter(ParameterSetName = 'Find by key with body', ValueFromPipeline, Mandatory)]
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
        if ($PSCmdlet.ParameterSetName -eq 'Find by zone') {
            $Method = 'GET'
            $Path = "/config-dns/v2/zones/$Zone/key/used-by"
        }
        else {
            $Method = 'POST'
            $Path = "/config-dns/v2/keys/used-by"

            if ($PSCmdlet.ParameterSetName -ne 'Find by key with body') {
                $Body = @{
                    'algorithm' = $TSIGKeyAlgorithm
                    'name'      = $TSIGKeyName
                    'secret'    = $TSIGKeySecret
                }
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }

        if ($PSCmdlet.ParameterSetName -ne 'Find by zone') {
            $RequestParams['body'] = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.zones
    }
}

function Get-EDNSZone {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ContractIDs,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $SubzoneGrant,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SortBy,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Types,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

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
        $Method = 'GET'
        if ($Zone) {
            $Path = "/config-dns/v2/zones/$Zone"
        }
        else {
            $Path = "/config-dns/v2/zones"
        }

        $QueryParameters = @{
            'contractIds'  = $ContractIDs
            'sortBy'       = $SortBy
            'types'        = $Types
            'search'       = $Search
            'subzoneGrant' = $PSBoundParameters.SubzoneGrant
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters['showAll'] = $true
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            return $Response.Body
        }
        else {
            return $Response.Body.zones
        }
    }
}

function Get-EDNSZoneAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/aliases"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.aliases
    }
}

function Get-EDNSZoneBulkCreateResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RequestID,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/create-requests/$RequestID/result"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-EDNSZoneBulkCreateStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RequestID,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/create-requests/$RequestID"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-EDNSZoneBulkDeleteResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RequestID,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/delete-requests/$RequestID/result"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-EDNSZoneBulkDeleteStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RequestID,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/delete-requests/$RequestID"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-EDNSZoneContract {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter()]
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

    process {
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/contract"

        $QueryParameters = @{
            'gid' = $GroupID
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-EDNSZoneDNSKEY {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/dnskeys"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-EDNSZoneDNSSECStatus {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]
        $Zone,

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
        $CollatedZones = New-Object System.Collections.Generic.List[string]
    }

    process {
        foreach ($SingleZone in $Zone) {
            $CollatedZones.Add($SingleZone)
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/dns-sec-status"

        $Body = @{
            'zones' = $CollatedZones
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.dnsSecStatuses
    }
}

function Get-EDNSZoneTransferStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Zone,

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
        $CollatedZones = New-Object System.Collections.Generic.List[string]
    }

    process {
        foreach ($SingleZone in $Zone) {
            $CollatedZones.Add($SingleZone)
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/zone-transfer-status"

        $Body = @{
            'zones' = $CollatedZones
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.zones
    }
}

function Get-EDNSZoneVersion {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Get one')]
        [Alias("UUID")]
        [string]
        $VersionID,

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
        $Method = 'GET'
        if ($VersionID) {
            $Path = "/config-dns/v2/zones/$Zone/versions/$VersionID"
        }
        else {
            $Path = "/config-dns/v2/zones/$Zone/versions"
        }

        $QueryParameters = @{}
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters['showAll'] = $true
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            return $Response.Body
        }
        else {
            return $Response.Body.versions
        }
    }
}

function Get-EDNSZoneVersionMasterFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("UUID")]
        [string]
        $VersionID,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/versions/$VersionID/zone-file"

        $AdditionalHeaders = @{
            'accept' = 'text/dns'
        }

        $RequestParams = @{
            'Method'          = $Method
            'Path'            = $Path
            EdgeRCFile        = $EdgeRCFile
            Section           = $Section
            AccountSwitchKey  = $AccountSwitchKey
            AdditionalHeaders = $AdditionalHeaders
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-EDNSZoneVersionRecordSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory)]
        [Alias("UUID")]
        [string]
        $VersionID,

        [Parameter()]
        [string[]]
        $Types,

        [Parameter()]
        [string]
        $Search,

        [Parameter()]
        [ValidateSet('name', 'type')]
        [string[]]
        $SortBy,

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
        $Method = 'GET'
        $Path = "/config-dns/v2/zones/$Zone/versions/$VersionID/recordsets"

        if ($SortBy) {
            $SortByString = $SortBy -join ","
        }

        if ($Types) {
            $TypesString = $Types -join ","
        }

        $QueryParameters = @{
            'sortBy'  = $SortByString
            'types'   = $TypesString
            'search'  = $Search
            'showAll' = $true
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.recordsets
    }
}

function New-EDNSChangeList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter()]
        [ValidateSet("any", "stale", "none")]
        [string]
        $Overwrite,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/changelists"

        $QueryParameters = @{
            'zone'      = $Zone
            'overwrite' = $Overwrite
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.changelists
    }
}


function New-EDNSProxy {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContractID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $GroupID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string[]]
        $OriginNameServers,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $ZoneTransferNameServers,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $HealthCheckRecordType,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $HealthCheckRecordName,

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

    process {
        $Path = "/config-dns/v2/proxies"
        $QueryParameters = @{
            'contractId' = $ContractID
            'gid'        = $PSBoundParameters.GroupID
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'name'              = $Name
                'contractId'        = $ContractID
                'healthCheck'       = @{
                    'recordType' = $HealthCheckRecordType
                }
                'originNameServers' = New-Object -TypeName System.Collections.Generic.List[hashtable]
            }

            # Populate name servers
            $OriginNameServers | Foreach-Object {
                if ($_.Contains(":")) {
                    $NSComponents = $_ -split ":"
                    $Body.originNameServers.Add(
                        @{
                            'name' = $NSComponents[0]
                            'port' = $NSComponents[1]
                        }
                    )
                }
                else {
                    $Body.originNameServers.Add(
                        @{
                            'name' = $_
                        }
                    )
                }
            }

            $ZoneTransferNameServers | Foreach-Object {
                $ZTNS = New-Object -TypeName System.Collections.Generic.List[hashtable]
                if ($_.Contains(":")) {
                    $NSComponents = $_ -split ":"
                    $ZTNS.Add(
                        @{
                            'name' = $NSComponents[0]
                            'port' = $NSComponents[1]
                        }
                    )
                }
                else {
                    $ZTNS.Add(
                        @{
                            'name' = $_
                        }
                    )
                }
                $Body.zoneTransferNameservers = $ZTNS
            }

            if ($HealthCheckRecordName) {
                $Body.healthCheck.recordName = $HealthCheckRecordName
            }
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
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function New-EDNSProxyZone {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('NONE', 'ALL', 'MANUAL', 'AUTOMATIC')]
        [string]
        $FilterMode,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TSIGKeySecret,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $ApexAlias,

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

    begin {
        $CollatedProxyZones = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Body') {
            if ($Body -isnot 'String' -and $Body -isnot 'Array') {
                $CollatedProxyZones.Add($Body)
            }
        }
    }

    end {
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/create-requests"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'proxyZones' = @(
                    @{
                        'name'       = $Name
                        'filterMode' = $FilterMode
                    }
                )
            }
            if ($FilterMode -eq 'AUTOMATIC') {
                $Body.proxyZones[0].tsigKey = @{
                    'algorith' = $TSIGKeyAlgorithm
                    'name'     = $TSIGKeyName
                    'secret'   = $TSIGKeySecret
                }
            }

            if ($ApexAlias) {
                $Body.proxyZones[0].apexAlias = $ApexAlias
            }
        }
        else {
            if ($CollatedProxyZones.count -gt 1) {
                $Body = $CollatedProxyZones
            }
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}

function New-EDNSRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $TTL,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string[]]
        $RData,

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

    begin {
        $CollatedRecordSets = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        if ($Body -and $Body -isnot 'String') {
            if ($null -eq $Body.recordsets -and $null -ne $Body.name) {
                # If body has recordsets top-level object then it is not a piped array
                $CollatedRecordSets.Add($Body)
            }
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/$Zone/recordsets"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            if ($Type.ToLower() -eq 'txt') {
                for ($i = 0; $i -lt $RData.count; $i++) {
                    if ($RData[$i] -notmatch '^".*"$') {
                        $RData[$i] = "`"$($RData[$i])`""
                    }
                }
            }
            if ($Name -ne $Zone -and $Name -notmatch "\.$Zone\.?$") {
                $Name = "$Name.$Zone"
            }

            $Body = @{
                'recordsets' = @(
                    @{
                        'name'  = $Name
                        'rdata' = $RData
                        'ttl'   = $TTL
                        'type'  = $Type
                    }
                )
            }
        }
        else {
            if ($CollatedRecordSets.count -gt 0) {
                $Body = @{ 'recordsets' = $CollatedRecordSets }
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function New-EDNSZone {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet("PRIMARY", "SECONDARY", "ALIAS")]
        [string]
        $Type,

        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Comment,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $EndCustomerID,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Masters,

        [Parameter(ParameterSetName = 'Attributes')]
        [bool]
        $SignAndServe,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet("RSA_SHA1", "RSA_SHA256", "RSA_SHA512", "ECDSA_P256_SHA256", "ECDSA_P384_SHA384")]
        [string]
        $SignAndServeAlgorithm,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Target,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TSIGKeySecret,

        [Parameter(ParameterSetName = 'Attributes')]
        [int]
        $TSIGKeyZoneCount,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/zones"

        $QueryParameters = @{
            'contractId' = $ContractID
            'gid'        = $PSBoundParameters.GroupID
        }

        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            $Body = @{
                'zone'                  = $Zone
                'type'                  = $Type
                'comment'               = $PSBoundParameters.Comment
                'signAndServe'          = $PSBoundParameters.SignAndServe
                'signAndServeAlgorithm' = $PSBoundParameters.SignAndServeAlgorithm
                'endCustomerId'         = $PSBoundParameters.EndCustomerID
                'target'                = $PSBoundParameters.Target
                'masters'               = $Masters
            }
        }

        if ($TSIGKeyName -or $TSIGKeyAlgorithm -or $TSIGKeySecret -or $TSIGKeyZoneCount) {
            $TSIGKey = @{
                'algorithm' = $PSBoundParameters.TSIGKeyAlgorithm
                'name'      = $PSBoundParameters.TSIGKeyName
                'secret'    = $PSBoundParameters.TSIGKeySecret
            }
            if ($PSBoundParameters.TSIGKeyZoneCount) {
                $TSIGKey['zonesCount'] = $PSBoundParameters.TSIGKeyZoneCount
            }
            $Body['tsigKey'] = $TSIGKey
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function New-EDNSZoneBulkCreate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter()]
        [int]
        $GroupID,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/create-requests"

        $QueryParameters = @{
            'contractId' = $ContractID
            'gid'        = $GroupID
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function New-EDNSZoneBulkDelete {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Zones')]
        [string[]]
        $Zone,

        [Parameter()]
        [switch]
        $BypassSafetyChecks,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        foreach ($SingleZone in $Zone) {
            $CollatedZones.Add($SingleZone)
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/delete-requests"

        $QueryParameters = @{
            'bypassSafetyChecks' = $BypassSafetyChecks
        }

        $Body = @{
            'zones' = $CollatedZones
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Remove-EDNSChangeList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'DELETE'
        $Path = "/config-dns/v2/changelists/$Zone"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Remove-EDNSProxyZone {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter()]
        [switch]
        $BypassSafetyChecks,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string[]]
        $ProxyZones,

        [Parameter()]
        [string]
        $Comment,

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
        $CollatedProxyZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        if ($ProxyZones.count -gt 1) {
            $CollatedProxyZones.AddRange($ProxyZones)
        }
        else {
            $CollatedProxyZones.Add($ProxyZones)
        }
    }

    end {
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/delete-requests"
        $QueryParameters = @{
            'bypassSafetyChecks' = $PSBoundParameters.BypassSafetyChecks.IsPresent
        }
        $Body = @{
            'proxyZones' = $CollatedProxyZones
        }
        if ($Comment) {
            $Body.comment = $Comment
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
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Remove-EDNSProxyZoneApexAlias {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

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
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/apex-alias"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'DELETE'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function Remove-EDNSProxyZoneManualFilterName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(ValueFromPipeline)]
        [string[]]
        $FilterNames,

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
        $CollatedNames = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        $FilterNames | ForEach-Object {
            $CollatedNames.Add($_)
        }
    }

    end {
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names/manage"
        $Body = @{
            'delete' = $CollatedNames
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
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Remove-EDNSProxyZoneTSIGKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Name,

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
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/key"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'DELETE'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function Remove-EDNSRecordSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Type,

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
        $Method = 'DELETE'
        if ($Name -ne $Zone -and $Name -notmatch "\.$Zone\.?$") {
            $Name = "$Name.$Zone"
        }
        # Remove trailing dot if present
        if ($Name.EndsWith('.')) {
            $Name = $Name.TrimEnd('.')
        }
        $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Remove-EDNSTSIGKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'DELETE'
        $Path = "/config-dns/v2/zones/$Zone/key"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Remove-EDNSZone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter()]
        [switch]
        $BypassSafetyChecks,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        foreach ($SingleZone in $Zone) {
            $CollatedZones.Add($SingleZone)
        }
    }

    end {
        if ($CollatedZones.count -eq 0) {
            return
        }

        $Method = 'POST'
        $Path = "/config-dns/v2/zones/delete-requests"

        $QueryParameters = @{
            'bypassSafetyChecks' = $BypassSafetyChecks
        }

        $Body = @{
            'zones' = $CollatedZones
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Restore-EDNSZoneVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("UUID")]
        [string]
        $VersionID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Comment,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/$Zone/versions/$VersionID/recordsets/activate"

        $QueryParameters = @{
            'comment' = $Comment
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Set-EDNSChangeListMasterFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
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
        $MasterFile = ""
    }

    process {
        foreach ($Line in $Body) {
            $MasterFile += $Line
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/changelists/$Zone/recordsets"

        $AdditionalHeaders = @{
            "content-type" = 'text/dns'
        }

        $RequestParams = @{
            'Method'            = $Method
            'Path'              = $Path
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $MasterFile
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Set-EDNSChangeListRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet("ADD", "EDIT", "DELETE")]
        [string]
        $Op,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TTL,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $RData,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/changelists/$Zone/recordsets/add-change"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            if ($Name -ne $Zone -and $Name -notmatch "\.$Zone\.?$") {
                $Name = "$Name.$Zone"
            }
            $Body = @{
                'name'  = $Name
                'type'  = $Type
                'ttl'   = $TTL
                'rdata' = $RData
                'op'    = $Op
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Set-EDNSChangeListSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

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
        $Method = 'PUT'
        $Path = "/config-dns/v2/changelists/$Zone/settings"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Set-EDNSMasterFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ValueFromPipeline, Mandatory)]
        [string]
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
        $MasterFile = ""
    }

    process {
        foreach ($Line in $Body) {
            $MasterFile += $Line
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/$Zone/zone-file"

        $AdditionalHeaders = @{
            'content-type' = 'text/dns'
        }

        $RequestParams = @{
            'Method'            = $Method
            'Path'              = $Path
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $MasterFile
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Set-EDNSProxy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

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
        $Path = "/config-dns/v2/proxies/$ProxyID"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'PUT'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function Set-EDNSProxyZoneApexAlias {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $ApexAlias,

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
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/apex-alias"
        $Body = @{
            'apexAlias' = $ApexAlias
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'PUT'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function Set-EDNSProxyZoneManualFilterNames {
    [CmdletBinding(DefaultParameterSetName = 'Manage manual filters')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Manage manual filters')]
        [switch]
        $AddSkipExisting,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Manage manual filters')]
        $Body,

        [Parameter(ParameterSetName = 'Zone file')]
        [string]
        $ZoneFile,

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
        if ($PSCmdlet.ParameterSetName -eq 'Manage manual filters') {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names/manage"
            $QueryParameters = @{
                'addSkipExisting' = $PSBoundParameters.AddSkipExisting.IsPresent
            }
        }
        else {
            $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names/zone-file"
            $Body = Get-Content -Path $ZoneFile -Raw
            $AdditionalHeaders = @{
                'content-type' = 'text/dns'
            }
        }

        $RequestParameters = @{
            Path              = $Path
            Method            = 'POST'
            Body              = $Body
            AdditionalHeaders = $AdditionalHeaders
            QueryParameters   = $QueryParameters
            EdgeRCFile        = $EdgeRCFile
            Section           = $Section
            AccountSwitchKey  = $AccountSwitchKey
            Debug             = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function Set-EDNSProxyZoneTSIGKey {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $TSIGKeySecret,

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

    process {
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/key"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'algorithm' = $TSIGKeyAlgorithm
                'name'      = $TSIGKeyName
                'secret'    = $TSIGKeySecret
            }
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'PUT'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function Set-EDNSRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Attributes', SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $TTL,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string[]]
        $RData,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $AutoIncrementSOA,

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
        $CollatedRecordSets = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        if ($Body -and $Body -isnot 'String') {
            if ($null -eq $Body.recordsets -and $null -ne $Body.name) {
                # If body has recordsets top-level object then it is not a piped array
                $CollatedRecordSets.Add($Body)
            }
        }
    }

    end {
        $Method = 'PUT'

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            if ($Name -ne $Zone -and $Name -notmatch "\.$Zone\.?$") {
                $Name = "$Name.$Zone"
            }
            # Remove trailing dot if present
            if ($Name.EndsWith('.')) {
                $Name = $Name.TrimEnd('.')
            }
            $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
            if ($Type.ToLower() -eq 'txt') {
                for ($i = 0; $i -lt $RData.count; $i++) {
                    if ($RData[$i] -notmatch '^".*"$') {
                        $RData[$i] = "`"$($RData[$i])`""
                    }
                }
            }

            $Body = @{
                'name'  = $Name
                'rdata' = $RData
                'ttl'   = $TTL
                'type'  = $Type
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Body') {
            $Path = "/config-dns/v2/zones/$Zone/recordsets"
            # Reconstruct from collated body
            if ($CollatedRecordSets.Count -gt 0) {
                $Body = @{ 'recordsets' = $CollatedRecordSets }
            }

            # Parse recordsets to handle data types and txt quoting
            foreach ($RecordSet in $Body.recordsets) {
                if ($RecordSet.Type.ToLower() -eq 'txt') {
                    for ($i = 0; $i -lt $RecordSet.RData.count; $i++) {
                        if ($RecordSet.RData[$i] -notmatch '^".*"$') {
                            $RecordSet.RData[$i] = "`"$($RecordSet.RData[$i])`""
                        }
                    }
                }
            }

            # Fall back to single update URL if only 1 record is present
            if ($Body.recordsets.count -eq 1) {
                $Body = $Body.recordsets[0]
                $Name = $Body.name
                # Remove trailing dot if present
                if ($Name.EndsWith('.')) {
                    $Name = $Name.TrimEnd('.')
                }
                $Type = $Body.type
                $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
            }
        }

        if ($AutoIncrementSOA) {
            # Convert to object first, if not already
            $Body = Get-BodyObject -Source $Body
            $SOA = $Body.recordsets | Where-Object type -EQ 'SOA'
            if ($SOA) {
                # Should be only one, but you never know
                $SOA | ForEach-Object {
                    # Again, should be only one, but let's not assume
                    for ($i = 0; $i -lt $_.rdata.count; $i++) {
                        $Components = $_.rdata[$i] -split ' '
                        $ExistingSerial = $Components[2]
                        $NewSerial = ([int] $ExistingSerial) + 1
                        $_.rdata[$i] = $_.rdata[$i].replace($ExistingSerial, $NewSerial)
                    }
                }
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }

        # Get confirmation if number of record sets is greater than 1
        if ($Body.recordsets) {
            if ($PSCmdlet.ShouldProcess("Replacing ALL recordsets in zone $Zone", "Are you sure you want to proceed?", "Updating more than one recordset with Set-EDNSRecordSet will result in replacing ALL recordsets in zone: $Zone")) {
                Write-Warning "Replacing all records in zone $Zone"
                $Response = Invoke-AkamaiRequest @RequestParams
            }
        }
        else {
            $Response = Invoke-AkamaiRequest @RequestParams
        }
        return $Response.Body
    }
}

function Set-EDNSTSIGKey {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    param (
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [Alias("algorithm")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [Alias("name")]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [Alias("secret")]
        [string]
        $TSIGKeySecret,

        [Parameter(ParameterSetName = 'Attributes', DontShow)]
        [int]
        $TSIGKeyZoneCount,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string[]]
        $Zone,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/keys/bulk-update"

        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            $TSIGKey = @{
                'algorithm' = $TSIGKeyAlgorithm
                'name'      = $TSIGKeyName
                'secret'    = $TSIGKeySecret
            }
            if ($PSBoundParameters.TSIGKeyZoneCount) {
                $TSIGKey['zonesCount'] = $PSBoundParameters.TSIGKeyZoneCount
            }
            $Body = @{
                'zones' = $Zone
                'key'   = $TSIGKey
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Set-EDNSZone {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter()]
        [switch]
        $SkipSignAndServeSafetyCheck,

        [Parameter(ValueFromPipeline)]
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
        $Method = 'PUT'
        $Path = "/config-dns/v2/zones/$Zone"

        $QueryParameters = @{
            'skipSignAndServeSafetyCheck' = $SkipSignAndServeSafetyCheck.IsPresent
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Zone) {
            return $Response.Body
        }
        else {
            return $Response.Body.zones
        }
    }
}

function Submit-EDNSChangeList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter()]
        [switch]
        $SkipSignAndServeSafetyCheck,

        [Parameter()]
        [string]
        $Comment,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/changelists/$Zone/submit"

        $QueryParameters = @{
            'skipSignAndServeSafetyCheck' = $SkipSignAndServeSafetyCheck
            'comment'                     = $Comment
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Zone) {
            return $Response.Body
        }
        else {
            return $Response.Body
        }
    }
}


# SIG # Begin signature block
# MIIo2QYJKoZIhvcNAQcCoIIoyjCCKMYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAoWmuhFiaFyaxQ
# J979nXfz1rS/T7pidEddvXqLBXIRzKCCDg4wggawMIIEmKADAgECAhAIrUCyYNKc
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
# +3uvPQ8rHHMLbKgncTqSxqtZ73kItOztMYIaITCCGh0CAQEwfTBpMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0
# IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0Ex
# AhAGRzH371ShX6hjGl1wSSyYMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKIXTX+RrtjunE87ZetBLjYy
# u7h6bFw/0ksFAmoYjMCSMA0GCSqGSIb3DQEBAQUABIIBgHnYNGsvHedZKKGD8xNG
# 4TAD0O4hqcz9Pli/PB4taBLIM35x33WtnsDpQbrvBh+X8wOj2jCpxwWKn2uY8Gs4
# k9wJ/jZrWu1BRdWl+NEqX8gTOA/GHdhwwGpHz3Q4p/GlPvCznIxgMAhRW+PpWnt7
# R8qojwhz570zCoKqrsX1k63c/CgqBFWB7JZQG05+Fg6WnKg0e1Iu9/INK8DKq3L0
# ztGBMFX93i0xJFANDn5paoQun6QmsPOTw8TvhRyV4KjMgX+hKu7Gjy8xgVzDDQNg
# yEY0dqW/iQc7IaS91rO6geqOC+g0MIrd4wG2oNLJgmgISGMxKip9JIR0tbK/AwlI
# vl0zhVnWppGquxZCxs1I0MyhYsrLcystr9SF7dKVYLfkPTxdi2we0zATgFc2VE0E
# 9V+uS4Palr7t02qv92GsS8Kzwpu91dGUsa7mszK9bmjOH0vyR1fwS71Y7oLNTc8h
# lBTJPcBZAhPHUNLfxKVsoh3LAlFmu33sP59AknOGMvWSbaGCF3cwghdzBgorBgEE
# AYI3AwMBMYIXYzCCF18GCSqGSIb3DQEHAqCCF1AwghdMAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAweAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCBpaxZOUAvnDevU8NcJvaUUSR6XenK6Cca5ECgfCCcvQgIRAMXO
# N54clyT4g5DuFTCD74IYDzIwMjYwODI1MjI0MTI1WqCCEzowggbtMIIE1aADAgEC
# AhAKgO8YS43xBYLRxHanlXRoMA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1
# c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwHhcN
# MjUwNjA0MDAwMDAwWhcNMzYwOTAzMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFNIQTI1NiBS
# U0E0MDk2IFRpbWVzdGFtcCBSZXNwb25kZXIgMjAyNSAxMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEA0EasLRLGntDqrmBWsytXum9R/4ZwCgHfyjfMGUIw
# YzKomd8U1nH7C8Dr0cVMF3BsfAFI54um8+dnxk36+jx0Tb+k+87H9WPxNyFPJIDZ
# HhAqlUPt281mHrBbZHqRK71Em3/hCGC5KyyneqiZ7syvFXJ9A72wzHpkBaMUNg7M
# OLxI6E9RaUueHTQKWXymOtRwJXcrcTTPPT2V1D/+cFllESviH8YjoPFvZSjKs3SK
# O1QNUdFd2adw44wDcKgH+JRJE5Qg0NP3yiSyi5MxgU6cehGHr7zou1znOM8odbkq
# oK+lJ25LCHBSai25CFyD23DZgPfDrJJJK77epTwMP6eKA0kWa3osAe8fcpK40uhk
# tzUd/Yk0xUvhDU6lvJukx7jphx40DQt82yepyekl4i0r8OEps/FNO4ahfvAk12hE
# 5FVs9HVVWcO5J4dVmVzix4A77p3awLbr89A90/nWGjXMGn7FQhmSlIUDy9Z2hSgc
# taepZTd0ILIUbWuhKuAeNIeWrzHKYueMJtItnj2Q+aTyLLKLM0MheP/9w6CtjuuV
# HJOVoIJ/DtpJRE7Ce7vMRHoRon4CWIvuiNN1Lk9Y+xZ66lazs2kKFSTnnkrT3pXW
# ETTJkhd76CIDBbTRofOsNyEhzZtCGmnQigpFHti58CSmvEyJcAlDVcKacJ+A9/z7
# eacCAwEAAaOCAZUwggGRMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFOQ7/PIx7f39
# 1/ORcWMZUEPPYYzoMB8GA1UdIwQYMBaAFO9vU0rp5AZ8esrikFb2L9RJ7MtOMA4G
# A1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCBlQYIKwYBBQUH
# AQEEgYgwgYUwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBd
# BggrBgEFBQcwAoZRaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3J0MF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNybDAg
# BgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQAD
# ggIBAGUqrfEcJwS5rmBB7NEIRJ5jQHIh+OT2Ik/bNYulCrVvhREafBYF0RkP2AGr
# 181o2YWPoSHz9iZEN/FPsLSTwVQWo2H62yGBvg7ouCODwrx6ULj6hYKqdT8wv2UV
# +Kbz/3ImZlJ7YXwBD9R0oU62PtgxOao872bOySCILdBghQ/ZLcdC8cbUUO75ZSpb
# h1oipOhcUT8lD8QAGB9lctZTTOJM3pHfKBAEcxQFoHlt2s9sXoxFizTeHihsQyfF
# g5fxUFEp7W42fNBVN4ueLaceRf9Cq9ec1v5iQMWTFQa0xNqItH3CPFTG7aEQJmmr
# JTV3Qhtfparz+BW60OiMEgV5GWoBy4RVPRwqxv7Mk0Sy4QHs7v9y69NBqycz0BZw
# hB9WOfOu/CIJnzkQTwtSSpGGhLdjnQ4eBpjtP+XB3pQCtv4E5UCSDag6+iX8MmB1
# 0nfldPF9SVD7weCC3yXZi/uuhqdwkgVxuiMFzGVFwYbQsiGnoa9F5AaAyBjFBtXV
# LcKtapnMG3VH3EmAp/jsJ3FVF3+d1SVDTmjFjLbNFZUWMXuZyvgLfgyPehwJVxwC
# +UpX2MSey2ueIu9THFVkT+um1vshETaWyQo8gmBto/m3acaP9QsuLj3FNwFlTxq2
# 5+T4QwX9xa6ILs84ZPvmpovq90K8eWyG2N01c4IhSOxqt81nMIIGtDCCBJygAwIB
# AgIQDcesVwX/IZkuQEMiDDpJhjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3
# MDAwMDAwWhcNMzgwMTE0MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMO
# RGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGlt
# ZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAtHgx0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1
# mZaDLFTtQ2oRjzUXMmxCqvkbsDpz4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJa
# DNs1+JH7Z+QdSKWM06qchUP+AbdJgMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6A
# o+xh/AS7sQRuQL37QXbDhAktVJMQbzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M98
# 0EpLtlrNyHw0Xm+nt5pnYJU3Gmq6bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC
# 2ZQ8BbfnFRQVESYOszFI2Wv82wnJRfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+Kd
# PvMvaB0WkE/2qHxJ0ucS638ZxqU14lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHk
# ccpL6uoG8pbF0LJAQQZxst7VvwDDjAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8
# hjj/q8d6ylgxCZSKi17yVp2NL+cnT6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDK
# iDEb1AQ8es9Xr/u6bDTnYCTKIsDq1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCB
# ZtVFJfVZ3j7OgWmnhFr4yUozZtqgPrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsg
# Y1MCAwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9v
# U0rp5AZ8esrikFb2L9RJ7MtOMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiu
# HA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEF
# BQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBB
# BggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkw
# FzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsW
# gBz+Bz0RdnEwvb4LyLU0pn/N0IfFiBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j0
# 0DNqhCT3t+s8G0iP5kvN2n7Jd2E4/iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywF
# LerycvZTAz40y8S4F3/a+Z1jEMK/DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2
# e26MHvVY9gCDA/JYsq7pGdogP8HRtrYfctSLANEBfHU16r3J05qX3kId+ZOczgj5
# kjatVB+NdADVZKON/gnZruMvNYY2o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXu
# vTPSegOOzr4EWj7PtspIHBldNE2K9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25
# xUbI7GIN/TpVfHIqQ6Ku/qjTY6hc3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZ
# jE4YtL8Pbzg0c1ugMZyZZd/BdHLiRu7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeq
# GkH/wyW4N7OigizwJWeukcyIPbAvjSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQ
# sfch28bZeUz2rtY/9TCA6TD8dC3JE3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS
# 9/wQD7yFylIz0scmbKvFoW2jNrbM1pD2T7m3XDCCBY0wggR1oAMCAQICEA6bGI75
# 0C3n79tQ4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAw
# MFoXDTMxMTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGln
# aUNlcnQgVHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAv+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuE
# DcQwH/MbpDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNw
# wrK6dZlqczKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs0
# 6wXGXuxbGrzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e
# 5TXnMcvak17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtV
# gkEy19sEcypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85
# tRFYF/ckXEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+S
# kjqePdwA5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1Yxw
# LEFgqrFjGESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzl
# DlJRR3S+Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFr
# b7GrhotPwtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATow
# ggE2MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiu
# HA9PMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQE
# AwIBhjB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2
# hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290
# Q0EuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/
# Q1xV5zhfoKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNK
# ei8ttzjv9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHr
# lnKhSLSZy51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4
# oVaO7KTVPeix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5A
# Y8WYIsGyWfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNN
# n3O3AamfV6peKOK5lDGCA3wwggN4AgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0
# IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMQIQCoDvGEuN8QWC
# 0cR2p5V0aDANBglghkgBZQMEAgEFAKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcN
# AQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTI2MDgyNTIyNDEyNVowKwYLKoZIhvcNAQkQ
# AgwxHDAaMBgwFgQU3WIwrIYKLTBr2jixaHlSMAf7QX4wLwYJKoZIhvcNAQkEMSIE
# IAaJRpKkbCLF3sGbYRU9L0nh39ffEOKSH3EPAbHKxjg1MDcGCyqGSIb3DQEJEAIv
# MSgwJjAkMCIEIEqgP6Is11yExVyTj4KOZ2ucrsqzP+NtJpqjNPFGEQozMA0GCSqG
# SIb3DQEBAQUABIICAHbmyhAFELFQgcvUPfR0aFKoidhwOJY0t77S+6HErwBBQ/mm
# BUOlxj7Gjz+d8K+MYqUPuUlGAb/dd4sbeB9IqkB/x22WdpAJ+MBczEeKYIPshcTz
# 6I2JcSbCSr5f7R+4rSOv9hmeIqGkyZiXZKOPN9zQXkcKjTZdZtZZT5UC1439A7iD
# GX0QU5BClAgU5QWTbfLjKuI9aI6oNnOYKpKlJR+8fM/uHVlMIsua0bZdeVdaXnGH
# IJ3Mob3CEwu6e2dZgRBybaAze9IlexjDlHmq1p9sQ3NU3WpoWQUV9SvU9WFJtTDI
# eZf1Kil8I5JW1RywPeDjYk609zSed4cX63eq1wyLvN5IOklH6kmhI1/HHSeXsB5S
# GEFbjeh8S0fVGgW1ktwTjyASpO/AFcqGGyApNckK1Atr1ZegoujT8YVzTUN9hXqJ
# 3FSKtTzh91EbKbzvA4Yi0hAfMcmnI8YxT8gWq4AEi54Y6tMX0lG+Z2B6nHDNIJIg
# 5rxb4yb7DtrywqYBQPMMygXBifdSy8ry3Em6c/DGald49ooOtAV0Ov6w9S+NVYMZ
# CT9PleXzEm7iDGFwDjnBxPRm9TqYf41s0Wm1yenCH9nWoGveXfzV8xuUFTC52IwZ
# yxaz1SaoXu4mdad/T+BRkouWwyylpq4/A4qETLV9LIGMdEs0llWGIwvWfksl
# SIG # End signature block
