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

function Add-NetstorageUploadAccountFTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Key,

        [Parameter()]
        [string]
        $Comments,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ftp"
        $Body = @{
            key = $Key
        }
        if ($null -ne $Comments) {
            $Body.comments = $Comments
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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



function Add-NetstorageUploadAccountHTTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/g2o"
        $RequestParams = @{
            Path             = $Path
            Method           = 'PUT'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

function Add-NetstorageUploadAccountRSyncKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Key,

        [Parameter()]
        [string]
        $Comments,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/rsync"
        $Body = @{
            key = $Key
        }
        if ($null -ne $Comments) {
            $Body.comments = $Comments
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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


function Add-NetstorageUploadAccountSSHKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Key,

        [Parameter()]
        [string]
        $EmailID,

        [Parameter()]
        [string]
        $Comments,

        [Parameter()]
        [switch]
        $Update,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ssh/$Identity"
        $QueryParameters = @{
            'update' = $PSBoundParameters.Update
        }
        $Body = @{
            key = $Key
        }
        if ($EmailID) {
            $Body.emailId = $EmailID
        }
        if ($Comments) {
            $Body.comments = $Comments
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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

function Disable-NetstorageUploadAccount {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UploadAccountID,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/disable"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Disable-NetstorageUploadAccountFTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ftp/$Identity/disable"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}



function Disable-NetstorageUploadAccountHTTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/g2o/$Identity/disable"
        $RequestParams = @{
            Path             = $Path
            Method           = 'POST'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

function Disable-NetstorageUploadAccountRSyncKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/rsync/$Identity/disable"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Disable-NetstorageUploadAccountSSHKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ssh/$Identity/disable"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Enable-NetstorageUploadAccount {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UploadAccountID,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/enable"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Enable-NetstorageUploadAccountFTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ftp/$Identity/enable"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}



function Enable-NetstorageUploadAccountHTTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/g2o/$Identity/enable"
        $RequestParams = @{
            Path             = $Path
            Method           = 'POST'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

function Enable-NetstorageUploadAccountRSyncKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/rsync/$Identity/enable"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Enable-NetstorageUploadAccountSSHKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ssh/$Identity/enable"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-NetstorageCPCode {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [switch]
        $Unused,

        [Parameter()]
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
        if ($Unused) {
            $Path = "/storage/v1/cpcodes/unused"
        }
        else {
            $Path = "/storage/v1/cpcodes/used"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.items
    }

}

function Get-NetstorageCPCodePurgeRoutine {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CPCodeID,

        [Parameter()]
        [string]
        $AgeDeletionDirectoryPrefix,

        [Parameter()]
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
        $Path = "/storage/v1/cpcodes/$CPCodeID/age-deletions"
        $QueryParameters = @{
            'ageDeletionDirectoryPrefix' = $AgeDeletionDirectoryPrefix
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return @($Response.Body)
    }

}

function Get-NetstorageDirectory {
    [CmdletBinding(DefaultParameterSetName = 'Directory')]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(ParameterSetName = 'Directory')]
        [string]
        $Prefix,

        [Parameter(ParameterSetName = 'List')]
        [switch]
        $Recurse,

        [Parameter(ParameterSetName = 'Directory')]
        [string]
        $StartPath,

        [Parameter()]
        [string]
        $EndPath,

        [Parameter()]
        [int]
        $MaxEntries,

        [Parameter()]
        [string]
        $Encoding,

        [Parameter()]
        [switch]
        $SlashBoth,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'dir'
        if ($PSCmdlet.ParameterSetName -eq 'List') {
            $Action = 'list'
            # Add end param to list action if missing. Otherwise the API returns everything
            if ($Path -ne '/' -and -not $EndPath) {
                $EndPath = $Path
            }
        }

        $AdditionalOptions = @{
            'format' = 'sql'
        }

        if ($StartPath) {
            $AdditionalOptions['start'] = $StartPath
        }
        if ($EndPath) {
            $AdditionalOptions['end'] = $EndPath
        }
        if ($MaxEntries) {
            $AdditionalOptions['max_entries'] = $MaxEntries
        }
        if ($Encoding) {
            $AdditionalOptions['encoding'] = $Encoding
        }
        if ($Prefix -ne '') {
            $AdditionalOptions['prefix'] = $Prefix
        }

        if ($SlashBoth) {
            $AdditionalOptions['slash'] = 'both'
        }

        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            if ($PSCmdlet.ParameterSetName -eq 'Directory') {
                return $Response.stat.file
            }
            else {
                return $Response.list.file
            }
        }
        catch {
            throw $_
        }
    }
}

function Get-NetstorageDirectoryUsage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = "du"
        $AdditionalOptions = @{
            'format' = 'sql'
        }

        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response.du.'du-info'
        }
        catch {
            throw $_
        }
    }
}

function Get-NetstorageGroup {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $CPCodeID,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('NETSTORAGE', 'EDGESTREAM', 'EDGESTREAM_IPHONE', 'ADAPTIVEEDGE', 'AD_INSERTION', 'CONTENT_PREPARATION', 'MSL_ORIGIN', 'FEO')]
        [string]
        $StorageGroupPurpose,

        [Parameter()]
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
        if ($StorageGroupID) {
            $Path = "/storage/v1/storage-groups/$StorageGroupID"
        }
        else {
            $Path = "/storage/v1/storage-groups"
        }
        $QueryParameters = @{
            'cpcodeId'            = $PSBoundParameters.CPCodeID
            'storageGroupPurpose' = $StorageGroupPurpose
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($StorageGroupID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}

function Get-NetstorageRuleSet {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RuleSetID,

        [Parameter()]
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
        if ($RuleSetID) {
            $Path = "/storage/v1/rule-sets/$RuleSetID"
        }
        else {
            $Path = "/storage/v1/rule-sets"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($RuleSetID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}

function Get-NetstorageSnapshot {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $SnapShotID,

        [Parameter()]
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
        if ($SnapShotID) {
            $Path = "/storage/v1/site-snapshots/$SnapShotID"
        }
        else {
            $Path = "/storage/v1/site-snapshots"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($SnapShotID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}

function Get-NetstorageUploadAccount {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UploadAccountID,

        [Parameter()]
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
        if ($UploadAccountID) {
            $Path = "/storage/v1/upload-accounts/$UploadAccountID"
        }
        else {
            $Path = "/storage/v1/upload-accounts"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($UploadAccountID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}

function Get-NetstorageZones {
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
        $Path = "/storage/v1/zones"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.zones.zoneName
    }
}

function Measure-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter()]
        [string]
        $Encoding,

        [Parameter()]
        [switch]
        $Implicit,

        [Parameter()]
        [switch]
        $SlashBoth,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'stat'

        $AdditionalOptions = @{
            'format'   = 'sql'
            'encoding' = $Encoding
        }

        if ($Implicit) {
            $AdditionalOptions['implicit'] = 'yes'
        }
        if ($SlashBoth) {
            $AdditionalOptions['slash'] = 'both'
        }

        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response.stat.file
        }
        catch {
            throw $_
        }
    }
}
function New-NetstorageCPCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $CPCodeName,

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
        $Path = "/storage/v1/cpcodes"
        $Body = @{
            'contractId' = $ContractID
            'cpcodeName' = $CPCodeName
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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

function New-NetstorageCredentials {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UploadAccountID,

        [Parameter()]
        [string]
        $APIKey,

        [Parameter()]
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
        # ----------------- Get credentials

        # Gets the given upload account's details.
        #
        # The response contains two values needed for the auth file, the HTTP API key and the storage group ID.

        $UploadAccountParams = @{
            'UploadAccountID'  = $UploadAccountID
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        $UploadAccount = Get-NetstorageUploadAccount @UploadAccountParams

        # Check if upload account has http api access
        if (-not $UploadAccount.hasHttpApiAccess) {
            throw "Upload account ID $UploadAccountID does not have HTTP API access enabled. Please enable and try again."
        }

        # Select the API key from the upload user, unless provided
        if (-not $APIKey) {
            # Warn the user if account has multiple g2o keys
            if ($UploadAccount.keys.g2o.Count -gt 1) {
                Write-Warning "Upload account ID $UploadAccountID has multiple g2o keys, we will use the first one returned by the API. If you want to specify a different key, please provide it with the -APIKey parameter."
            }
            $APIKey = $UploadAccount.keys.g2o[0].key
        }

        # Gets the given storage group's details.
        #
        # The response contains two additional values needed for the auth file, the HTTP domain name and upload directory's CP code.

        $GroupParams = @{
            'StorageGroupID'   = $UploadAccount.storageGroupId
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        $StorageGroup = Get-NetstorageGroup @GroupParams

        # The content of the NS auth resource file.

        return [PSCustomObject] @{
            'key'    = $APIKey
            'id'     = $UploadAccountID
            'group'  = $UploadAccount.storageGroupId
            'host'   = "$($StorageGroup.domainprefix)-nsu.akamaihd.net"
            'cpcode' = $StorageGroup.cpcodes[0].cpcodeId
        }
    }
}

function New-NetstorageDirectory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = "mkdir"
        $RequestParams = @{
            'Path'     = $Path
            'Action'   = $Action
            'NSRCFile' = $NSRCFile
            'Section'  = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}

function New-NetstorageGroup {
    [CmdletBinding()]
    Param(
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
        $Path = "/storage/v1/storage-groups"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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

function New-NetstorageRuleSet {
    [CmdletBinding()]
    Param(
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
        $Path = "/storage/v1/rule-sets"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.items
    }
}

function New-NetstorageSnapshot {
    [CmdletBinding()]
    Param(
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
        $Path = "/storage/v1/site-snapshots"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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

function New-NetstorageSymlink {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $TargetPath,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'symlink'
        $Body = ''
        $EncodedTargetPath = [System.Web.HttpUtility]::UrlEncode($TargetPath)
        $AdditionalOptions = @{
            'target' = $EncodedTargetPath
        }

        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'Body'              = $Body
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}
function New-NetstorageUploadAccount {
    [CmdletBinding()]
    Param(
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
        $Path = "/storage/v1/upload-accounts"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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

function Read-NetstorageDirectory {
    [CmdletBinding(DefaultParameterSetName = 'Directory')]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(ParameterSetName = 'Directory')]
        [string]
        $Prefix,

        [Parameter(ParameterSetName = 'List')]
        [switch]
        $Recurse,

        [Parameter(Mandatory)]
        [string]
        $OutputDirectory,

        [Parameter()]
        [string]
        $StartPath,

        [Parameter()]
        [string]
        $EndPath,

        [Parameter()]
        [int]
        $MaxEntries,

        [Parameter()]
        [string]
        $Encoding,

        [Parameter()]
        [switch]
        $SlashBoth,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        # Set common params for Read calls
        $CommonParams = @{
            NSRCFile = $NSRCFile
            Section  = $Section
        }

        if (-not (Test-Path $OutputDirectory)) {
            Write-Host 'Creating output directory ' -NoNewline
            Write-Host -ForegroundColor Cyan $OutputDirectory -NoNewline
            Write-Host '.'
            New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
        }

        # Get list of files
        $GetParams = $PSBoundParameters.PSObject.Copy()
        $GetParams.Remove('OutputDirectory') | Out-Null
        $NetstorageFiles = Get-NetstorageDirectory @GetParams

        $Files = $NetstorageFiles | Where-Object type -eq file
        Write-Debug "Retrieving $($Files.count) files"
        $Files | ForEach-Object {
            $LocalPath = "$OutputDirectory/$($_.name)"
            Read-NetstorageObject -RemotePath $_.name -LocalPath $LocalPath @CommonParams
        }
    }
}

function Read-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $RemotePath,

        [Parameter()]
        [string]
        $LocalPath,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = "download"

        if (!$LocalPath) {
            $FileName = $RemotePath.Substring($RemotePath.LastIndexOf("/") + 1)
            $LocalPath = ".\$FileName"
        }

        # Track path creation
        $NewItemCreated = $false
        # Create local path with parents
        if (-not (Test-Path $LocalPath)) {
            New-Item -Path $LocalPath -Force | Out-Null
            $NewItemCreated = $true
        }
        Write-Host "Downloading Netstorage file '" -NoNewline
        Write-Host -ForegroundColor Cyan $RemotePath -NoNewline
        Write-Host "' to '" -NoNewline
        Write-Host -ForegroundColor Cyan $LocalPath -NoNewline
        Write-Host "'."
        $RequestParams = @{
            'Path'       = $RemotePath
            'Action'     = $Action
            'Outputfile' = $LocalPath
            'NSRCFile'   = $NSRCFile
            'Section'    = $Section
        }
        try {
            Invoke-NetstorageRequest @RequestParams
        }
        catch {
            if ($NewItemCreated) {
                Remove-Item -Force -Path $LocalPath
            }
            throw $_
        }
    }
}


function Remove-NetstorageCPCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CPCodeID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

        [Parameter()]
        [switch]
        $ForceDelete,

        [Parameter()]
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
        $Path = "/storage/v1/storage-groups/$StorageGroupID/cpcodes/$CpcodeID"
        $QueryParameters = @{
            'forceDelete' = $PSBoundParameters.ForceDelete.IsPresent
        }

        $RequestParams = @{
            Path             = $Path
            Method           = 'DELETE'
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

function Remove-NetstorageCPCodePurgeRoutine {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CPCodeID,

        [Parameter()]
        [string]
        $AgeDeletionDirectoryPrefix,

        [Parameter()]
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
        $Path = "/storage/v1/cpcodes/$CPCodeID/age-deletions"
        $Body = "ageDeletionDirectoryPrefix=$AgeDeletionDirectoryPrefix"
        $AdditionalHeaders = @{
            'content-type' = 'application/x-www-form-urlencoded'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'DELETE'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

function Remove-NetstorageDirectory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $DirectoryIsEmpty,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        if ($DirectoryIsEmpty) {
            $Action = 'rmdir'
            $Body = ''
            $AdditionalOptions = @{}
        }

        else {
            if (!$Force) {
                $Sure = Read-Host "This operation will delete the directory $Path with no further confirmation. Are you really, really sure?[y/n]"
                if ($Sure.ToLower() -ne "y") {
                    Write-Host -ForegroundColor "Red" "Delete cancelled."
                    return
                }
            }

            $Action = 'quick-delete'
            $Body = ''
            $AdditionalOptions = @{
                'quick-delete' = 'imreallyreallysure'
            }
        }

        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'Body'              = $Body
            'AdditionalOptions' = $AdditionalOptions
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}

function Remove-NetstorageGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

        [Parameter()]
        [switch]
        $ForceDelete,

        [Parameter()]
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
        $Path = "/storage/v1/storage-groups/$StorageGroupID"
        $QueryParameters = @{
            'forceDelete' = $PSBoundParameters.ForceDelete.IsPresent
        }
        $RequestParams = @{
            Path             = $Path
            Method           = 'DELETE'
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

function Remove-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = "delete"
        $Body = ''

        $RequestParams = @{
            'Path'     = $Path
            'Action'   = $Action
            'Body'     = $Body
            'NSRCFile' = $NSRCFile
            'Section'  = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}

function Remove-NetstorageRuleSet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RuleSetID,

        [Parameter()]
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

        $Path = "/storage/v1/rule-sets/$RuleSetID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Remove-NetstorageSnapshot {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $SnapShotID,

        [Parameter()]
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
        $Path = "/storage/v1/site-snapshots/$SnapShotID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Remove-NetstorageUploadAccount {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UploadAccountID,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Remove-NetstorageUploadAccountFTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ftp/$Identity"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}



function Remove-NetstorageUploadAccountHTTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/g2o/$Identity"
        $RequestParams = @{
            Path             = $Path
            Method           = 'DELETE'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

function Remove-NetstorageUploadAccountRSyncKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/rsync/$Identity"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Remove-NetstorageUploadAccountSSHKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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

        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ssh/$Identity"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Rename-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $NewFilename,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'rename'
        $Body = ''
        $OldFilename = $Path.Substring($Path.LastIndexOf("/") + 1)
        $NewPath = $Path.Replace($OldFilename, $NewFilename)
        $EncodedNewPath = [System.Web.HttpUtility]::UrlEncode($NewPath)
        $AdditionalOptions = @{
            'destination' = $EncodedNewPath
        }

        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'Body'              = $Body
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}

function Restore-NetstorageCPCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CpcodeID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

        [Parameter()]
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
        $Path = "/storage/v1/storage-groups/$StorageGroupID/cpcodes/$CpcodeID/cancel-delete"
        $RequestParams = @{
            Path             = $Path
            Method           = 'POST'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}


function Restore-NetstorageGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

        [Parameter()]
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
        $Path = "/storage/v1/storage-groups/$StorageGroupID/cancel-delete"
        $RequestParams = @{
            Path             = $Path
            Method           = 'POST'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

function Set-NetstorageCPCodePurgeRoutine {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $CPCodeID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $AgeDeletionDirectoryPrefix,

        [Parameter()]
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
        $Path = "/storage/v1/cpcodes/$CPCodeID/age-deletions"
        $QueryParameters = @{
            'ageDeletionDirectoryPrefix' = $AgeDeletionDirectoryPrefix
        }

        # Convert body to object in order to check it is an array of objects, rather than a single
        if ($Body -is 'String') {
            $Body = ConvertFrom-Json $Body
        }
        if ($Body -isnot 'Array') {
            $Body = @($Body)
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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

function Set-NetstorageGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

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
        $Path = "/storage/v1/storage-groups/$StorageGroupID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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


function Set-NetstorageObjectMTime {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $mtime,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = "mtime"
        $Body = ''
        $AdditionalOptions = @{
            'mtime' = $mtime
        }

        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'Body'              = $Body
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}

function Set-NetstorageRuleSet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $RuleSetID,

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
        $Path = "/storage/v1/rule-sets/$RuleSetID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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

function Set-NetstorageSnapshot {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $SnapShotID,

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
        $Path = "/storage/v1/site-snapshots/$SnapShotID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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

function Set-NetstorageUploadAccount {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $UploadAccountID,

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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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


function Set-NetstorageUploadAccountFTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Identity,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Key,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Comments,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ftp/$Identity"
        $Body = @{
            key = $Key
        }
        if ($null -ne $Comments) {
            $Body.comments = $Comments
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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


function Start-NetstorageSnapshot {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $SnapShotID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $SnapshotName,

        [Parameter()]
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
        $Path = "/storage/v1/site-snapshots/schedule-now"
        $QueryParameters = @{
            'snapshotId'   = $SnapShotID
            'snapshotName' = $SnapshotName
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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

function Update-NetstorageUploadAccountFTPKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $Identity,

        [Parameter()]
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ftp/$Identity/extend"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Write-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1)]
        [string]
        $LocalPath,

        [Parameter(Mandatory)]
        [string]
        $RemotePath,

        [Parameter()]
        [string]
        $MTime,

        [Parameter()]
        [string]
        $Size,

        [Parameter()]
        [switch]
        $CheckHash,

        [Parameter()]
        [switch]
        $IndexZip,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'upload'
        # Assume if path ends with / we are uploading to a folder and append the filename
        if ($RemotePath.EndsWith("/")) {
            $File = Get-Item $LocalPath
            $RemotePath += $($File.Name)
        }

        $AdditionalOptions = @{
            'mtime' = $MTime
            'size'  = $Size
        }

        if ($CheckHash) {
            $Hash = (Get-FileHash -Path $LocalPath -Algorithm SHA256).Hash
            $AdditionalOptions['sha256'] = $Hash
        }

        if ($IndexZip) {
            $AdditionalOptions['index-zip'] = 1
        }

        $RequestParams = @{
            'Path'              = $RemotePath
            'Action'            = $Action
            'InputFile'         = $LocalPath
            'AdditionalOptions' = $AdditionalOptions
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}


# SIG # Begin signature block
# MIIo2AYJKoZIhvcNAQcCoIIoyTCCKMUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBRuDidXO9VSyLP
# y3ubkPsu5uys0WeARQaL5z+kxm4nyqCCDg4wggawMIIEmKADAgECAhAIrUCyYNKc
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBhmFtBPyLmUTvg3lYMq4npu
# t7Qyraf5THAZvFsvTqLkMA0GCSqGSIb3DQEBAQUABIIBgAWD7f1mWru6RmSJAAiE
# 70ZIfgTtgU7thScJnG9QF6xnRpg5CnZPrS3WBLuLBaUEE+dAeW/d2QOQA+NJGHII
# 2AY5APhkUQZN2Bd0lJ7DFSctzVYG9Pln3XRM+RCoi8GNywyV0Acd7M0dJEKaCM0J
# WRaCemnJs5TLkmVNlC4NNfV6rNlLIGOElq0sU4EzNOP6Snm5hBKqbGOik2Ehzj2B
# 24/2L1nktE6j2pOX5x5S5iN4OpQOSyfcZTsB06HsBsz05hGHaGXW5WyDNUjHzQWu
# QO53VYgX/yYYhErkWLEp0runz+AN7Fz9/qDfZL8VeHw5QEEe915uDpKGqkMjz7ad
# GlapJBzkTpWN2aex0ws/Z8Z8ROYbiShP1+Fx7Ob3qvXbo6hbGVYoQ29KG0FMjgGA
# IuKiF5pghtj7lQc3bLx8KJMfc4851tDoSwtnkCrh7hQKbTkZMoBvEVJEfC2ODGzj
# hD6O7ITOIBIDwDAUAXw2IjqQSRWcSalZAeDm7o3RtpxNpKGCF3YwghdyBgorBgEE
# AYI3AwMBMYIXYjCCF14GCSqGSIb3DQEHAqCCF08wghdLAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCB+qV/UCQZgjdYPC6dTc38vMVjDu+FAGQbquhfWv4cgegIQfrxT
# lOG7D3aif58jMmmIMhgPMjAyNjA4MjUyMjQwNThaoIITOjCCBu0wggTVoAMCAQIC
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
# CRABBDAcBgkqhkiG9w0BCQUxDxcNMjYwODI1MjI0MDU4WjArBgsqhkiG9w0BCRAC
# DDEcMBowGDAWBBTdYjCshgotMGvaOLFoeVIwB/tBfjAvBgkqhkiG9w0BCQQxIgQg
# yavDIcGa+jQouzGNk8wyUwZ2GFEKS9tQmCWeGfFPGsQwNwYLKoZIhvcNAQkQAi8x
# KDAmMCQwIgQgSqA/oizXXITFXJOPgo5na5yuyrM/420mmqM08UYRCjMwDQYJKoZI
# hvcNAQEBBQAEggIAKNHIXwvhh4WkqZrTRpRaIS7TZdDdjeM/p/xM5E11Vh55d8Ll
# vOEAtTw8AIiC+VfmMqzdRNfsX6aAJXCvWZ0vyvCBBMsPb6IR5LPUKZBKMkyAUBBa
# H14z4NOuT+3+4vGfcE8+jVrme0mDku5Vazs0Vv340TlRo0rnUkaxaS2RYTIht37E
# 7D/5haH3Fx9itS67IUzq1FUfLa9Qt4fKMujrXf0zXVOZEnteHwu66iuAvhOHuEFq
# 2HslAiExIcaVXJPvXBWJ+ImOSpjk1uaZmKj+tElz3ur2mbq53W5REwAUzEn8+mJU
# ZZ3qikWNZBfsxy5xgkx5N5PTp0mF0rz3DIOy65j2qAguXpaSiVzUkulOU1pBj3K4
# ROk776c7PQgOD6QVSMp39Y3O2XI9VJF79R1Y5t7/55pg0tH3pice6vHFnVdCi6NX
# 8DZSonJ+Vf4t+NRlX3tkpjXsE809jRaxOCPzhPtoQNW9c3dZCqWsEhRCzSjK6gmh
# fkJxTv1VZCad+WqPtoT540O1cPM7d/mPgm2VfjHrgKH0LC4VbjP08R2ed3siyv/C
# iuVQ60qXlrVME6KSwWGYmgXOjLbSGgBFhM3LhROUQSGdEH1f8+D4vzz+gsSIVNk7
# DN8nHeDnB76/Taz7kLLvoWBnnQoSemquAqnBMkwHs87vLRdQD60ithDBM5k=
# SIG # End signature block
