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


function Export-EdgeKVData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $OutputFile,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [int]
        $MaxItems,

        [Parameter()]
        [switch]
        $ShowExpires,

        [Parameter()]
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
        if ($GroupID) {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups/$GroupID/download"
        }
        else {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/download"
        }
        $QueryParameters = @{
            'maxItems'    = $PSBoundParameters.MaxItems
            'showExpires' = $PSBoundParameters.ShowExpires.IsPresent
        }
        $AdditionalHeaders = @{
            'accept' = 'text/csv'
        }

        $RequestParameters = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'QueryParameters'   = $QueryParameters
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
        }
        catch {
            throw $_
        }
        $Response.Body | Out-File $OutputFile -Encoding utf8
        Write-Host "Writing CSV content to " -NoNewline
        Write-Host -ForegroundColor Cyan $OutputFile
    }
}
function Get-EdgeKVAccessToken {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $TokenName,

        [Parameter()]
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
        if ($TokenName) {
            $Path = "/edgekv/v1/tokens/$TokenName"
        }
        else {
            $Path = "/edgekv/v1/tokens"
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
        if ($TokenName) {
            return $Response.Body
        }
        else {
            return $Response.Body.tokens
        }
    }
}


function Get-EdgeKVGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline)]
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
        if ($GroupID) {
            $Path = "/edgekv/v1/auth/groups/$GroupID"
        }
        else {
            $Path = "/edgekv/v1/auth/groups"
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
        if ($GroupID) {
            return $Response.Body
        }
        else {
            return $Response.Body.groups
        }
    }
}


function Get-EdgeKVInitializationStatus {
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

    $Path = "/edgekv/v1/initialize"
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


function Get-EdgeKVItem {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'Get one')]
        [string]
        $ItemID,

        [Parameter()]
        [string]
        $SandboxID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $MaxItems,

        [Parameter()]
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
        if ($ItemID) {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups/$GroupID/items/$ItemID"
        }
        else {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups/$GroupID"
        }
        $QueryParameters = @{
            'sandboxId' = $SandboxID
            'maxItems'  = $PSBoundParameters.MaxItems
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


function Get-EdgeKVNamespace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(ValueFromPipeline)]
        [string]
        $NamespaceID,

        [Parameter()]
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
        if ($NamespaceID) {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID"
        }
        else {
            $Path = "/edgekv/v1/networks/$Network/namespaces"
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
        if ($NamespaceID) {
            return $Response.Body
        }
        else {
            return $Response.Body.namespaces
        }
    }
}


function Get-EdgeKVNamespaceDelete {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/status/scheduled-delete"
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
        # Handle type variations in 5.1/7+
        if ($Response.Body.scheduledDeleteTime -is [string]) {
            $Response.body.scheduledDeleteTime = Get-Date $Response.Body.scheduledDeleteTime
        }
        return $Response.Body
    }
}

function Get-EdgeKVNamespaceGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups"
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


function Get-EdgeKVUpload {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $BulkUploadID,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $IncludeErrors,

        [Parameter(ParameterSetName = 'Get one')]
        [int]
        $MaxItems,

        [Parameter()]
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
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/jobs/$BulkUploadID"
            $QueryParameters = @{
                'includeErrors' = $PSBoundParameters.IncludeErrors.IsPresent
                'maxItems'      = $PSBoundParameters.MaxItems
            }
        }
        else {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/upload"
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($BulkUploadID) {
                return $Response.Body
            }
            else {
                return $Response.Body.jobs
            }
        }
        catch {
            throw $_
        }
    }

}


function Import-EdgeKVData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $InputFile,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [int]
        $MaxItems,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/upload"
        $QueryParameters = @{
            'dryRun'   = $PSBoundParameters.DryRun.IsPresent
            'maxItems' = $PSBoundParameters.MaxItems
        }
        $Body = Get-Content -Raw -Path $InputFile
        $AdditionalHeaders = @{
            'content-type' = 'text/csv'
        }

        $RequestParameters = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'Body'              = $Body
            'QueryParameters'   = $QueryParameters
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
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
function Initialize-EdgeKV {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [switch]
        $AllowNamespacePolicyOverride,
        
        [Parameter()]
        [switch]
        $RestrictDataAccess,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edgekv/v1/initialize"
    $Body = @{
        'dataAccessPolicy' = @{
            'allowNamespacePolicyOverride' = $AllowNamespacePolicyOverride.IsPresent
            'restrictDataAccess'           = $RestrictDataAccess.IsPresent
        }
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


function Move-EdgeKVNamespace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
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
        $Path = "/edgekv/v1/auth/namespaces/$NamespaceID"
        $Body = @{
            groupId = $GroupID
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


function New-EdgeKVAccessToken {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(, ParameterSetName = 'Attributes')]
        [switch]
        $AllowOnProduction,

        [Parameter(, ParameterSetName = 'Attributes')]
        [switch]
        $AllowOnStaging,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Namespace,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Permissions,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $RestrictToEdgeWorkerIds,

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
        $Path = "/edgekv/v1/tokens"
        if ($PSCmdlet.ParameterSetName -eq "Attributes") {
            $Body = @{
                'name'                 = $Name
                'allowOnProduction'    = $AllowOnProduction.IsPresent
                'allowOnStaging'       = $AllowOnStaging.IsPresent
                'namespacePermissions' = @{ $Namespace = @() }
            }

            $Permissions.ToCharArray() | ForEach-Object {
                if ($_ -ne 'r' -and $_ -ne 'w' -and $_ -ne 'd') {
                    throw "Permissions must be 'r', 'w' or 'd'"
                }
                $Body.namespacePermissions.$Namespace += $_
            }

            if ($RestrictToEdgeWorkerIds) {
                $Body.restrictToEdgeWorkerIds = $RestrictToEdgeWorkerIds
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
function New-EdgeKVItem {
    [Alias('Set-EdgeKVItem')]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
        [string]
        $ItemID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups/$GroupID/items/$ItemID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'Body'             = $Value
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

function New-EdgeKVNamespace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        [ValidateSet('STAGING', 'PRODUCTION')]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
        [bool]
        $RestrictDataAccess,

        [Parameter()]
        [string]
        $RetentionInSeconds = 0,

        [Parameter()]
        [ValidateSet('US', 'EU', 'JP', 'GLOBAL')]
        [string]
        $GeoLocation = 'US',

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    if ($Network -eq 'STAGING' -and $GeoLocation -ne 'US') {
        throw 'Only valid GeoLocation for STAGING network is US currently'
    }

    $Path = "/edgekv/v1/networks/$Network/namespaces"

    $Body = @{
        'name'               = $Name
        'geoLocation'        = $GeoLocation
        'retentionInSeconds' = $RetentionInSeconds
        'groupId'            = $GroupID
        'dataAccessPolicy'   = @{
            'restrictDataAccess' = $RestrictDataAccess
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


function Remove-EdgeKVAccessToken {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('name')]
        [string]
        $TokenName,

        [Parameter()]
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
        $Path = "/edgekv/v1/tokens/$TokenName"
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


function Remove-EdgeKVItem {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $ItemID,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups/$GroupID/items/$ItemID"
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


function Remove-EdgeKVNamespace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID"
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
        # Handle type variations in 5.1/7+
        if ($Response.Body.scheduledDeleteTime -is [string]) {
            $Response.body.scheduledDeleteTime = Get-Date $Response.Body.scheduledDeleteTime
        }
        return $Response.Body
    }
}

function Restore-EdgeKVNamespace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/status/scheduled-delete"
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

function Set-EdgeKVDefaultAccessPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $AllowNamespacePolicyOverride,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $RestrictDataAccess,

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
        $Path = "/edgekv/v1/auth/database"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'dataAccessPolicy' = @{
                    'allowNamespacePolicyOverride' = $AllowNamespacePolicyOverride.IsPresent
                    'restrictDataAccess'           = $RestrictDataAccess.IsPresent
                }
            }
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
function Set-EdgeKVNamespace {
    [CmdletBinding(DefaultParameterSetName = 'Body')]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [int]
        $RetentionInSeconds,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $GroupID,

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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                name               = $Name
                retentionInSeconds = $RetentionInSeconds
                groupId            = $GroupID
            }
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
function Set-EdgeKVNamespaceDelete {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [DateTime]
        $ScheduledDeleteTime,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/status/scheduled-delete"
        $FormattedDate = $ScheduledDeleteTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $Body = @{
            'scheduledDeleteTime' = $FormattedDate
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
        # Handle type variations in 5.1/7+
        if ($Response.Body.scheduledDeleteTime -is [string]) {
            $Response.body.scheduledDeleteTime = Get-Date $Response.Body.scheduledDeleteTime
        }
        return $Response.Body
    }
}

function Update-EdgeKVAccessToken {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $TokenName,

        [Parameter()]
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
        $Path = "/edgekv/v1/tokens/$TokenName/refresh"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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


# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA3ftQLhcvfprbO
# lhXSwFsBR5vGn43xzuMQym9hv1InO6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJtZYVTmL4L5E6qdlOi2xz5mDpxE4ORA
# Tm/mxqhk/c24MA0GCSqGSIb3DQEBAQUABIIBgEXRdeVzZOfb5mGNDkvaByAeodGM
# XBsREQ72HNc891KS9LaAxaKucCrZQdZWR5tQ2fqw2pMygzEhFtsTedUgeg9ZVVb4
# 5jaqZzqI3d7Bg6V9qUvLybF869/FE/xdNsEMn0aI/UdT0au1kNQTsorzrbFj2oGi
# StgSRk2bVj9tOnOK+/20NRM1QmkT9szAoULXaHBN0Rm2Szu+rFCzU2l25KLe/5fS
# gDIADcSBpTuvZfWUHdQiORQUY1XqQNLTRO3+PU53UopIg3F6Gb1ytsH/dG4/lM7a
# zJ2eG7PfKEncmXervqSBg27zFceTFMk14DYjDw+rMlvAoeGu4YC/N/3zrP+iEBIX
# 6Zteq6XFOe8HsJ5CTS7p2VzT+oC4oR5kwJA/rrJYfISMbdMwM+v01dREuxsMSt9E
# djrjO+1nCrITMn+nXcfdnm+khLPeXxCXp/g8Hb9UUMKdozELamT5SGhOPVj8iMTw
# u7PHHqGq5Z1LmvZdHjXweiY6yx9njucXY6dxPA==
# SIG # End signature block
