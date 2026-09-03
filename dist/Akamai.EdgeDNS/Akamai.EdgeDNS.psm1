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
                $Type = $Body.type
                $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
            }
        }

        if ($AutoIncrementSOA) {
            # Convert to object first, if not already
            $Body = Get-BodyObject -Source $Body
            $SOA = $Body.recordsets | Where-Object type -eq 'SOA'
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
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDcML4z2ECxm0zp
# UXqkjLGt1PRBPg/FkKs4MNRgSJ4YVqCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIM7Vo+lTbwPgyvK4wWTkcq8GEEyzwBxe
# /T5ChkB/OIZpMA0GCSqGSIb3DQEBAQUABIIBgCuYdVPJHLCbVPUycMC8jwwQwJYF
# s/wRdSfi3NfhnwI3MbJnC3GgtpHAf8WWCA7Ea0zRFE8HDIyMbBW18Fhq8BKdgldT
# revbS1dvAumRDi54vACCggQGR3tf/k7V7EMHJRuIh20ob39HstdiI6tzqHf/2Ws9
# 365nlKmchRPHjlkpxJVcve+JdBg3ShAsCjiwtLGhHIfcA3RcIkF3BFAZv7XuF9/U
# 5jCtg7uH8lKHrFokgIoAI7WXUINoozNJcbZ2ty9xgF2Pvx+Tkc2tZgDiDp8rOAK0
# UxjzB/FqcotB7fJRJIX0ydiFgA5fTqY7WWItVTW1p26DrL2MBXM6SbDTNJXih6Og
# hrBu3DPW8n+r77XWh3UJLVWnWmKK2tzzjnUuJJiFIP9VJNhp30MBs/qdqCQ7OXZq
# Xf2/TLD8opVffJpakp1T3cp4OUQXkATyxs2vKdMNvKntodHCJIu72gcAuLK4IoU7
# kKdd+WOC9XdZIDWWSkduB8pdg5CTBMQa33e7+A==
# SIG # End signature block
