function Expand-EdgeWorkerDetails {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $EdgeWorkerName,

        [Parameter()]
        $EdgeWorkerID,

        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [string]
        $ActivationID,

        [Parameter()]
        [string]
        $DeactivationID,

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

        $ProductionActivationRetrieved = $false
        $StagingActivationRetrieved = $false

        if ($EdgeWorkerName) {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $EdgeWorkerID = $Global:AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName.EdgeWorkerID
            }

            try {
                $EdgeWorker = (Get-EdgeWorker @CommonParams) | Where-Object name -EQ $EdgeWorkerName
                if ($EdgeWorker.count -gt 1) {
                    throw "Multiple EdgeWorkers found with name '$EdgeWorkerName'. Use -EdgeWorkerID instead to specify which one you wish to use."
                }
                $EdgeWorkerID = $EdgeWorker.edgeWorkerId
                if (-not $EdgeWorkerID) {
                    throw "EdgeWorker $EdgeWorkerName not found."
                }
            }
            catch {
                throw $_
            }

            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName) {
                $Global:AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName = @{'EdgeWorkerID' = $EdgeWorkerID }
            }
            Write-Debug "Expand-EdgeWorkerDetails: EdgeWorkerID = $EdgeWorkerID."
        }

        # ---- Expand version
        if ($Version.ToLower() -in 'latest', "production", "staging") {
            if ($Version.ToLower() -eq 'latest') {
                Write-Debug 'Expand-EdgeWorkerDetails: retrieving active production activation.'
                try {
                    $Versions = Get-EdgeWorkerVersion -EdgeWorkerID $EdgeWorkerID @CommonParams | Sort-Object -Property sequenceNumber -Descending
                }
                catch {
                    throw $_
                }
                $Version = $Versions[0].version
            }
            elseif ($Version.ToLower() -eq 'production') {
                Write-Debug 'Expand-EdgeWorkerDetails: retrieving active production activation.'
                try {
                    $ProductionActivation = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID -ActiveOnNetwork -Network PRODUCTION @CommonParams
                    $ProductionActivationRetrieved = $true
                }
                catch {
                    throw "Failed to retrieve production activation: $_."
                }
                if ($ProductionActivation) {
                    $Version = $ProductionActivation.version
                }
                else {
                    throw "No production-active version of EdgeWorker $EdgeWorkerID."
                }
            }
            elseif ($Version.ToLower() -eq 'staging') {
                Write-Debug 'Expand-EdgeWorkerDetails: retrieving active staging activation.'
                try {
                    $StagingActivation = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID -ActiveOnNetwork -Network STAGING @CommonParams
                    $StagingActivationRetrieved = $true
                }
                catch {
                    throw "Failed to retrieve staging activation: $_."
                }
                if ($StagingActivation) {
                    $Version = $StagingActivation.version
                }
                else {
                    throw "No staging-active version of EdgeWorker $EdgeWorkerID."
                }
            }
        }

        # ---- Expand ActivationID
        if ($ActivationID.ToLower() -in 'latest', 'production', 'staging') {
            if ($ActivationID.ToLower() -eq 'latest') {
                try {
                    $Activations = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID @CommonParams
                    $ActivationID = $Activations[0].activationId
                }
                catch {
                    throw $_
                }
            }
            elseif ($ActivationID.ToLower() -eq 'production') {
                if ($ProductionActivationRetrieved -eq $false) {
                    try {
                        Write-Debug 'Expand-EdgeWorkerDetails: retrieving active production activation.'
                        $ProductionActivation = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID -ActiveOnNetwork -Network PRODUCTION @CommonParams
                    }
                    catch {
                        throw "Failed to retrieve production activation: $_."
                    }
                }
                if ($ProductionActivation) {
                    $ActivationID = $ProductionActivation.activationId
                }
                else {
                    throw "No production-active version of EdgeWorker $EdgeWorkerID."
                }
            }
            elseif ($ActivationID.ToLower() -eq 'staging') {
                if ($StagingActivationRetrieved -eq $false) {
                    try {
                        Write-Debug 'Expand-EdgeWorkerDetails: retrieving active staging activation.'
                        $StagingActivation = Get-EdgeWorkerActivation -EdgeWorkerID $EdgeWorkerID -ActiveOnNetwork -Network STAGING @CommonParams
                    }
                    catch {
                        throw "Failed to retrieve staging activation: $_."
                    }
                }
                if ($StagingActivation) {
                    $ActivationID = $StagingActivation.activationId
                }
                else {
                    throw "No staging-active version of EdgeWorker $EdgeWorkerID."
                }
            }
        }

        # ---- Expand DeactivationID
        if ($DeactivationID.ToLower() -eq 'latest') {
            try {
                $Deactivations = Get-EdgeWorkerDeactivation -EdgeWorkerID $EdgeWorkerID @CommonParams
                $DeactivationID = $Deactivations[0].deactivationId
            }
            catch {
                throw $_
            }
        }

        return $EdgeWorkerID, $Version, $ActivationID, $DeactivationID
    }
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

function New-TarArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $SourceDirectory,

        [Parameter(Mandatory)]
        [string]
        $OutputFile
    )

    if ( Get-Command tar -ErrorAction SilentlyContinue) {
        # Work out if we're using 5.1 or later
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $PowerShellBinary = 'pwsh'
        }
        else {
            $PowerShellBinary = 'powershell'
        }

        $InDir = Get-Item $SourceDirectory | Select-Object -ExpandProperty FullName
        $OutFile = New-Item -ItemType File -Path $OutputFile -Force | Select-Object -ExpandProperty FullName

        $TarCommand = "$PowerShellBinary -NoProfile -Command `"Set-Location $InDir; tar -czf $OutFile --exclude='*.tgz' *`""
        # Handle xattr issue on MacOS
        if ($IsMacOS) {
            $TarCommand = $TarCommand.Replace('tar', 'tar --disable-copyfile')
        }

        # Execute tar
        Write-Debug "New-TarArchive: Executing command '$TarCommand'"
        Invoke-Expression $TarCommand | Out-Null
    }
    else {
        throw 'tar command not found. Please create .tgz file manually.'
    }
}

function Compare-EdgeworkerRevision {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RevisionID,

        [Parameter(Mandatory)]
        [string]
        $ComparisonRevisionID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/compare"
        $Body = @{
            'revisionId' = $ComparisonRevisionID
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

function Copy-EdgeWorker {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Version = 'production',

        [Parameter(Mandatory)]
        [string]
        $NewName,

        [Parameter()]
        [int]
        $GroupID,

        [Parameter()]
        [ValidateSet(100, 200, 400)]
        [int]
        $ResourceTierID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $AuthParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }

        # 0. Find existing EdgeWorker
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters -Version $Version # Version has a default, which will not be included in PSBoundParameters

        # 1. Get the specified version of the old EdgeWorker
        $Local:VersionFile = New-TemporaryFile
        $GetCodeBundleParams = @{
            'EdgeWorkerID' = $EdgeWorkerID
            'Version'      = $Version
            'OutputFile'   = $Local:VersionFile
        }
        Write-Debug "Copy-EdgeWorker: Downloading code bundle for EdgeWorker ID $EdgeWorkerID, version $Version to temporary file $($Local:VersionFile.FullName)"
        try {
            Get-EdgeWorkerCodeBundle @GetCodeBundleParams @AuthParams | Out-Null
        }
        catch {
            throw $_
        }

        # 2. Get EdgeWorker for group, resource tier & description, if required
        if (-not $GroupID -or -not $ResourceTierID) {
            $ExistingEdgeWorker = Get-EdgeWorker -EdgeWorkerID $EdgeWorkerID @AuthParams

            if (-not $ResourceTierID) {
                $ResourceTierID = $ExistingEdgeWorker.resourceTierId
            }
            if (-not $GroupID) {
                $GroupID = $ExistingEdgeWorker.groupId
            }
            if (-not $Description) {
                $Description = $ExistingEdgeWorker.description
            }
        }

        # 3. Create the new EdgeWorker
        $NewEdgeWorkerParams = @{
            'EdgeWorkerName' = $NewName
            'GroupID'        = $GroupID
            'ResourceTierID' = $ResourceTierID
        }

        if ($Description) {
            $NewEdgeWorkerParams['Description'] = $Description
        }

        Write-Debug "Copy-EdgeWorker: Creating new EdgeWorker with name $NewName, group ID $GroupID, resource tier ID $ResourceTierID & description $Description"
        try {
            $Local:NewEdgeWorker = New-EdgeWorker @NewEdgeWorkerParams @AuthParams
        }
        catch {
            throw $_
        }

        # 4. Apply saved version to new EdgeWorker
        $NewVersionParams = @{
            'EdgeWorkerID' = $Local:NewEdgeWorker.EdgeWorkerID
            'CodeBundle'   = $Local:VersionFile
        }
        Write-Debug "Copy-EdgeWorker: Creating new version $Version for EdgeWorker ID $($Local:NewEdgeWorker.EdgeWorkerID) using code bundle from temporary file $($Local:VersionFile.FullName)"
        try {
            New-EdgeWorkerVersion @NewVersionParams @AuthParams | Out-Null
        }
        catch {
            throw $_
        }

        return $Local:NewEdgeWorker
    }
}

function Get-EdgeWorker {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name')]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Get all')]
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
        if ($EdgeWorkerID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID"
        }
        else {
            $Path = "/edgeworkers/v1/ids"
        }
        $QueryParameters = @{
            'groupId' = $PSBoundParameters.GroupID
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
                if ($EdgeWorkerID) {
                    Set-AkamaiDataCache -EdgeWorkerName $Response.Body.name -EdgeWorkerID $Response.Body.edgeWorkerId
                }
                else {
                    foreach ($EdgeWorker in $Response.Body.edgeworkerIds) {
                        Set-AkamaiDataCache -EdgeWorkerName $EdgeWorker.name -EdgeWorkerID $EdgeWorker.edgeWorkerId
                    }
                }
            }

            if ($PSCmdlet.ParameterSetName -eq 'Get all') {
                return $Response.Body.edgeWorkerIds
            }
            elseif ($PSCmdlet.ParameterSetName.contains('name')) {
                return $Response.Body.edgeworkerIds | Where-Object name -eq $EdgeWorkerName
            }
            else {
                return $Response.Body
            }
        }
        catch {
            throw $_
        }
    }
}

function Get-EdgeWorkerActivation {
    [CmdletBinding(DefaultParameterSetName = 'Get all by name')]
    param(
        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get all by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [string]
        $ActivationID,

        [Parameter(ParameterSetName = 'Get all by name', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all by ID', ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(ParameterSetName = 'Get all by name')]
        [Parameter(ParameterSetName = 'Get all by ID')]
        [switch]
        $ActiveOnNetwork,

        [Parameter(ParameterSetName = 'Get all by name')]
        [Parameter(ParameterSetName = 'Get all by ID')]
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
        $EdgeWorkerID, $Version, $ActivationID, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($ActivationID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/activations/$ActivationID"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/activations"
        }
        $QueryParameters = @{
            'version'         = $Version
            'activeOnNetwork' = $PSBoundParameters.ActiveOnNetwork.IsPresent
            'network'         = $Network
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
        if ($ActivationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.activations
        }
    }
}

function Get-EdgeWorkerCodeBundle {
    [CmdletBinding(DefaultParameterSetName = 'Name & file')]
    param(
        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID & file', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [string]
        $OutputFile,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [string]
        $OutputDirectory,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/versions/$Version/content"
        $AdditionalHeaders = @{
            accept = 'application/gzip'
        }

        # Set output file name
        if (-not $OutputFile) {
            if ($EdgeWorkerName) {
                $OutputFile = "$EdgeWorkerName-$Version.tgz"
            }
            else {
                $OutputFile = "$EdgeWorkerID-$Version.tgz"
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'OutputFile'        = $OutputFile
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName.contains('directory')) {
            if (-not (Test-Path $OutputFile)) {
                throw "Could not find output file $OutputFile to decompress."
            }
            if (-not (Test-Path $OutputDirectory)) {
                New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
            }
            else {
                $ExistingFiles = Get-ChildItem -Path $OutputDirectory
                if ($ExistingFiles.count -gt 0) {
                    Write-Warning "Output directory '$OutputDirectory' is not empty and existing files will not be overwritten. Command may produce unexpected results."
                }
            }
            tar -xvf $OutputFile -C $OutputDirectory/
            Remove-Item -Force $OutputFile
        }
        return $Response.Body
    }
}

function Get-EdgeWorkerContract {
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

    $Path = "/edgeworkers/v1/contracts"
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
    return $Response.Body.contractIds
}

function Get-EdgeWorkerDeactivation {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $DeactivationID,

        [Parameter(ValueFromPipelineByPropertyName)]
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
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $Version, $null, $DeactivationID = Expand-EdgeWorkerDetails @PSBoundParameters

        if ($DeactivationID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/deactivations/$DeactivationID"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/deactivations"
        }
        $QueryParameters = @{
            'version' = $Version
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
        if ($DeactivationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.deactivations
        }
    }
}

function Get-EdgeWorkerGroup {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
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
            $Path = "/edgeworkers/v1/groups/$GroupID"
        }
        else {
            $Path = "/edgeworkers/v1/groups"
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

function Get-EdgeWorkerLimit {
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

    $Path = "/edgeworkers/v1/limits"
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
    return $Response.Body.limits
}


function Get-EdgeWorkerLoggingOverride {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter()]
        [int]
        $LoggingID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($LoggingID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/loggings/$LoggingID"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/loggings"
        }

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
            if ($LoggingID) {
                return $Response.Body
            }
            else {
                return $Response.Body.loggings
            }
        }
        catch {
            throw $_
        }
    }
}

function Get-EdgeWorkerProperties {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter()]
        [switch]
        $ActiveOnly,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/properties"
        $QueryParameters = @{
            'activeOnly' = $PSBoundParameters.ActiveOnly
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
        return $Response.Body.properties
    }
}

function Get-EdgeWorkerReport {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [int]
        $ReportID,

        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [string]
        $Start,

        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [string]
        $End,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [ValidateSet('onClientRequest', 'onOriginRequest', 'onOriginResponse', 'onClientResponse', 'responseProvider')]
        [string]
        $EventHandler,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [ValidateSet('success', 'genericError', 'unknownEdgeWorkerId', 'unimplementedEventHandler', 'runtimeError', 'executionError', 'timeoutError', 'resourceLimitHit')]
        [string]
        $Status,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    if ($null -ne $PSBoundParameters.ReportID) {
        # Expand to get EdgeWorkerID
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/reports/$ReportID"
        $QueryParameters = @{
            'start'        = $Start
            'end'          = $End
            'edgeWorker'   = $EdgeWorkerID
            'status'       = $Status
            'eventHandler' = $EventHandler
        }
    }
    else {
        $Path = "/edgeworkers/v1/reports"
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
    if ($null -ne $PSBoundParameters.ReportID) {
        return $Response.Body
    }
    else {
        return $Response.Body.reports
    }
}

function Get-EdgeWorkerResourceTier {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name')]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Get all', Mandatory)]
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
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $Path = "/edgeworkers/v1/resource-tiers"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/resource-tier"
        }
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
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            return $Response.Body.resourceTiers
        }
        else {
            return $Response.Body
        }
    }
}


function Get-EdgeworkerRevision {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $RevisionID,

        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [int]
        $ActivationID,

        [Parameter()]
        [string]
        $Network,

        [Parameter()]
        [switch]
        $PinnedOnly,

        [Parameter()]
        [switch]
        $CurrentlyPinned,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $Version, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($RevisionID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions"
        }
        $QueryParameters = @{
            'version'         = $Version
            'activationId'    = $PSBoundParameters.ActivationID
            'network'         = $Network
            'pinnedOnly'      = $PSBoundParameters.PinnedOnly.IsPresent
            'currentlyPinned' = $PSBoundParameters.CurrentlyPinned.IsPresent
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
        if ($RevisionID) {
            return $Response.Body
        }
        else {
            return $Response.Body.revisions
        }
    }
}


function Get-EdgeworkerRevisionActivation {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int]
        $ActivationID,

        [Parameter()]
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
        $EdgeWorkerID, $Version, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/activations"
        $QueryParameters = @{
            'version'      = $Version
            'activationId' = $PSBoundParameters.ActivationID
            'network'      = $Network
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
        return $Response.Body.revisionActivations
    }
}


function Get-EdgeworkerRevisionBom {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RevisionID,

        [Parameter()]
        [switch]
        $IncludeActiveVersions,

        [Parameter()]
        [switch]
        $IncludePinnedRevisions,

        [Parameter()]
        [switch]
        $IncludeCurrentlyPinnedRevisions,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/bom"
        $QueryParameters = @{
            'includeActiveVersions'           = $PSBoundParameters.IncludeActiveVersions.IsPresent
            'includePinnedRevisions'          = $PSBoundParameters.IncludePinnedRevisions.IsPresent
            'includeCurrentlyPinnedRevisions' = $PSBoundParameters.IncludeCurrentlyPinnedRevisions.IsPresent
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


function Get-EdgeworkerRevisionCodeBundle {
    [CmdletBinding(DefaultParameterSetName = 'Name & file')]
    Param(
        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID & file', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RevisionID,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [string]
        $OutputFile,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [string]
        $OutputDirectory,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/content"
        $AdditionalHeaders = @{
            accept = 'application/gzip'
        }

        # Set output file name
        if (-not $OutputFile) {
            if ($PSCmdlet.ParameterSetName.contains('file')) {
                if ($EdgeWorkerName) {
                    $OutputFile = "$EdgeWorkerName-$RevisionID.tgz"
                }
                else {
                    $OutputFile = "$EdgeWorkerID-$RevisionID.tgz"
                }
            }
            else {
                $OutputFile = 'ew-temp.tgz'
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'OutputFile'        = $OutputFile
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName.contains('directory')) {
            if (-not (Test-Path $OutputFile)) {
                throw "Could not find output file $OutputFile to decompress."
            }
            if (-not (Test-Path $OutputDirectory)) {
                New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
            }
            else {
                $ExistingFiles = Get-ChildItem -Path $OutputDirectory
                if ($ExistingFiles.count -gt 0) {
                    Write-Warning "Output directory '$OutputDirectory' is not empty and existing files will not be overwritten. Command may produce unexpected results."
                }
            }
            tar -xvf $OutputFile -C $OutputDirectory/
            Remove-Item -Force $OutputFile
        }
        return $Response.Body
    }
}

function Get-EdgeWorkerVersion {
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ValueFromPipelineByPropertyName)]
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
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($Version) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/versions/$Version"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/versions"
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
        if ($Version) {
            return $Response.Body
        }
        else {
            return $Response.Body.versions
        }
    }
}

function New-EdgeWorker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $EdgeWorkerName,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory)]
        [ValidateSet(100, 200, 400)]
        [int]
        $ResourceTierID,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = '/edgeworkers/v1/ids'

        $Body = @{
            name           = $EdgeWorkerName
            groupId        = $GroupID
            resourceTierId = $ResourceTierID
        }

        if ($Description) {
            $Body.description = $Description
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
                Set-AkamaiDataCache -EdgeWorkerName $Response.Body.name -EdgeWorkerID $Response.Body.edgeWorkerId
            }

            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function New-EdgeWorkerActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Deploy-EdgeWorker')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

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
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/activations"

        $Body = @{
            network = $Network
            version = $Version
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

function New-EdgeWorkerAuthToken {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $Hostnames,

        [Parameter()]
        [int]
        $Expiry,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edgeworkers/v1/secure-token"
    $Body = @{
        'hostnames' = @('/*')
    }

    if ($null -ne $PSBoundParameters.Expiry) {
        $Body['expiry'] = $Expiry
    }

    # Set default value for all hostnames and override if provided
    if ($null -ne $PSBoundParameters.Hostnames) {
        $Body['hostnames'] = ($Hostnames -split ',')
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
    return $Response.Body.akamaiEwTrace
}

function New-EdgeWorkerDeactivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Disable-EdgeWorker')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

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
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/deactivations"

        $Body = @{
            network = $Network
            version = $Version
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


function New-EdgeWorkerLoggingOverride {
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [ValidateSet('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]
        $Level,

        [Parameter()]
        [string]
        $Schema,

        [Parameter()]
        [string]
        $Timeout,

        [Parameter()]
        [int]
        $DS2ID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/loggings"
        $Body = @{
            network = $Network
            level   = $Level
        }
        if ($Schema) {
            $Body.schema = $Schema
        }
        if ($Timeout) {
            $Body.timeout = $Timeout
        }
        if ($null -ne $PSBoundParameters.DS2ID) {
            $Body.schema = $Schema
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


function New-EdgeworkerRevisionActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Deploy-EdgeWorkerRevision')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RevisionID,

        [Parameter()]
        [string]
        $Note,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/activations"
        $Body = @{
            'revisionId' = $RevisionID
        }
        if ($Note) {
            $Body['note'] = $Note
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

function New-EdgeWorkerVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & directory')]
    Param(
        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'Name & bundle', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID & directory', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & bundle', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory)]
        [string]
        $CodeDirectory,

        [Parameter(ParameterSetName = 'Name & bundle', Mandatory)]
        [Parameter(ParameterSetName = 'ID & bundle', Mandatory)]
        [string]
        $CodeBundle,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [system.version]
        $Version,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $Patch,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $Minor,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $Major,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [string]
        $SaveBundleTo,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        # Validate version params
        if ($Version -and ($Patch -or $Minor -or $Major)) {
            throw "Cannot use -Version parameter with -Patch, -Minor, or -Major parameters."
        }
        if ($Patch -and ($Minor -or $Major)) {
            throw "Cannot use -Patch parameter with -Minor or -Major parameters."
        }
        if ($Minor -and ($Patch -or $Major)) {
            throw "Cannot use -Minor parameter with -Patch or -Major parameters."
        }
        if ($Major -and ($Patch -or $Minor)) {
            throw "Cannot use -Major parameter with -Patch or -Minor parameters."
        }

        # Check codedirectory exists
        if ($CodeDirectory -and -not (Test-Path $CodeDirectory)) {
            throw "Code directory '$CodeDirectory' not found."
        }


        $EdgeWorkerID, $null = Expand-EdgeWorkerDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('directory')) {
            if ( Get-Command tar -ErrorAction SilentlyContinue) {
                if (-not $EdgeWorkerName) {
                    $EdgeWorker = Get-EdgeWorker -EdgeWorkerID $EdgeWorkerID -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
                    $EdgeWorkerName = $EdgeWorker.Name
                }
                $Directory = Get-Item $CodeDirectory
                $BundleFile = "$($Directory.FullName)/bundle.json"
                $Bundle = ConvertFrom-Json (Get-Content $BundleFile -Raw)

                $CurrentVersion = [system.version]$Bundle.'edgeworker-version'
                if ($Version) {
                    $BundleVersion = $Version
                }
                elseif ($Patch -or $Minor -or $Major) {
                    if ($Patch) {
                        $BundleVersion = [system.version]::new($CurrentVersion.Major, $CurrentVersion.Minor, $CurrentVersion.Build + 1)
                    }
                    elseif ($Minor) {
                        $BundleVersion = [system.version]::new($CurrentVersion.Major, $CurrentVersion.Minor + 1, 0)
                    }
                    elseif ($Major) {
                        $BundleVersion = [system.version]::new($CurrentVersion.Major + 1, 0, 0)
                    }
                }
                else {
                    $BundleVersion = $CurrentVersion
                }
                # Update bundle.json
                $Bundle.'edgeworker-version' = $BundleVersion.ToString()

                # Update description
                if ($Description) {
                    $Bundle.description = $Description
                }

                # Export updated bundle.json
                $Bundle | ConvertTo-Json -Depth 10 | Set-Content $BundleFile

                if ($SaveBundleTo) {
                    $CodeBundle = New-Item $SaveBundleTo | Select-Object -ExpandProperty FullName
                }
                else {
                    $CodeBundle = New-TemporaryFile
                }

                # Create bundle
                Write-Debug "Creating tarball '$CodeBundle' from directory $($Directory.fullName)."
                New-TarArchive -SourceDirectory $Directory.FullName -OutputFile $CodeBundle
            }
            else {
                throw "tar command not found. Please create .tgz file manually and use -CodeBundle parameter."
            }
        }

        elseif ($PSCmdlet.ParameterSetName.Contains('bundle')) {
            if (-not (Test-Path $CodeBundle)) {
                throw "Code Bundle $CodeBundle could not be found."
            }
        }

        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/versions"
        $AdditionalHeaders = @{
            'Content-Type' = 'application/gzip'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'InputFile'         = $CodeBundle
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

function Remove-EdgeWorker {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID"
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

function Remove-EdgeWorkerActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
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
        $EdgeWorkerID, $null, $ActivationID, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/activations/$ActivationID"
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

function Remove-EdgeWorkerVersion {
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/versions/$Version"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'InputFile'        = $CodeBundle
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

function Set-EdgeWorker {
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter()]
        [string]
        $NewName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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
        $EdgeWorkerID, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID"

        ### Set body to update name
        if ($NewName) {
            $EdgeWorkerName = $NewName
        }
        ### Use old name if NewName missing
        else {
            if (!$EdgeWorkerName) {
                $EdgeWorker = Get-EdgeWorker -EdgeWorkerID $EdgeWorkerID -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
                $EdgeWorkerName = $EdgeWorker.name
            }
        }

        $Body = @{
            name    = $EdgeWorkerName
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


function Set-EdgeworkerRevision {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RevisionID,

        [Parameter(Mandatory)]
        [ValidateSet('pin', 'unpin')]
        [string]
        $Operation,

        [Parameter()]
        [string]
        $Note,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($Operation -eq 'pin') {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/pin"
            if ($Note) {
                $Body = @{
                    'pinNote' = $Note
                }
            }
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/unpin"
            if ($Note) {
                $Body = @{
                    'unpinNote' = $Note
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
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Test-EdgeWorkerCodeBundle {
    [CmdletBinding(DefaultParameterSetName = 'Directory')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Directory')]
        [string]
        $CodeDirectory,

        [Parameter(Mandatory, ParameterSetName = 'Bundle')]
        [string]
        $CodeBundle,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Directory') {
            if ( Get-Command tar -ErrorAction SilentlyContinue) {
                $Directory = Get-Item $CodeDirectory
                $Bundle = Get-Content "$($Directory.FullName)\bundle.json" | ConvertFrom-Json
                $CodeBundle = New-TemporaryFile

                # Create bundle
                Write-Debug "Creating tarball $CodeBundle from directory $($Directory.fullName)."
                New-TarArchive -SourceDirectory $Directory.FullName -OutputFile $CodeBundle
            }
            else {
                throw "tar command not found. Please create .tgz file manually and use -CodeBundle parameter."
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'bundle') {
            if (-not (Test-Path $CodeBundle)) {
                throw "Code Bundle $CodeBundle could not be found."
            }
        }

        $Path = "/edgeworkers/v1/validations"
        $AdditionalHeaders = @{
            'Content-Type' = 'application/gzip'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'InputFile'         = $CodeBundle
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

function Undo-EdgeWorkerActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter()]
        [string]
        $Note,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $EdgeWorkerID, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerId/activations/rollback"

        $Body = @{
            network = $Network
        }
        if ($Note) {
            $Body['note'] = $Note
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


# SIG # Begin signature block
# MIIo2QYJKoZIhvcNAQcCoIIoyjCCKMYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA7K5qWla8bxy5f
# /hop8a344AuIxzPPZv/V7ABHUyGju6CCDg4wggawMIIEmKADAgECAhAIrUCyYNKc
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGPjq9b8c7uODSioOYe2sKoc
# hGpqQnoJ9SO5HlCb5IXBMA0GCSqGSIb3DQEBAQUABIIBgDoCKRpnx/YU29WInh3A
# H+5Su4zcsXxQzXoJUmuAl3PKbvRj9tZka7sHhRVmyz2ISdyLtNZRqTwLeC32m846
# BrMEntm21NwYRl0ryF8K6STKsbL/Dt5T7jHG/77QAt7C7gQuuacuTQuUfAF3GwmI
# H1q6uE2K6+MLgzXx9eGor0jTIPHNCP9Mb4oBplHfx3Btq2utEZqvF1AIsOb0sBiJ
# aTyWz9Q7PHiXlIJvVFzqcBfoh0jDysQJMECwaV2kKA/0GfCqLkW9e3cYoLxSXSa7
# 5NChFEO1Ad/aNhHhFrtix4B1rXNIbLIRuh733f/ofnbjr2Li2tJ0/TR7qlAtoXhG
# +GbRJJbqzdZrjp4zniveasUwnekR45lPQYJzCnkXbQWG5/D/8H6qbqkc97eRdKrZ
# ZlzWTMu+PHcPj3krFR8BhZ5WgqPwwApYzeMvo/m9CR2gm7F3O+OtiD0x6xLPzfCu
# qCIU7a5yHolMKBnSJkJWM+YF5lajHMuN5IZFyjkC1y7ReKGCF3cwghdzBgorBgEE
# AYI3AwMBMYIXYzCCF18GCSqGSIb3DQEHAqCCF1AwghdMAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAweAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCBGeu+vVD/anCduO88aPnUEv0vGCBPNSB3bXRRYQhYZCwIRAP7/
# UbOYNdqqSEcqau4w+T8YDzIwMjYwODI1MjI0MTEyWqCCEzowggbtMIIE1aADAgEC
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
# AQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTI2MDgyNTIyNDExMlowKwYLKoZIhvcNAQkQ
# AgwxHDAaMBgwFgQU3WIwrIYKLTBr2jixaHlSMAf7QX4wLwYJKoZIhvcNAQkEMSIE
# IOWR0KMjgE0Ev9y8l3xLSpyJB57m0bVQDc1ZK2NKeRhFMDcGCyqGSIb3DQEJEAIv
# MSgwJjAkMCIEIEqgP6Is11yExVyTj4KOZ2ucrsqzP+NtJpqjNPFGEQozMA0GCSqG
# SIb3DQEBAQUABIICAGITo7dtiJnFMKPP+6iiiEQS+zz4sj56BE9B/Bq4whW6s1sa
# lGc//dvjiXwLdXCg5k10dWDKPAyungpkeMGU3uY4lXu5WL/vYlnqKWseEZp5WEJU
# OsUPqJqGnwzhgMSVDm06+5Xyfovhi7g+TGsw6uy4fAXV84TV8mi0G6aJWVFboJY0
# n5MDK39se9WXse2dFrBcfUYd2n8l5n+MgVWhcqOOzi5mXHc9sQ6uMBKXO2L8ze2v
# vkWCaXjuJvS8dGvwUFU8a/HbTEJd1JcCMCa4plc3sjvI0Z2flNYJJ6b31PHRpQpw
# N1LWpWmPuD4AzRqNIEk0D+ITrX3Ae6a2sJUn0sCbasP9mc8/sSm5+TZEpA81jIAo
# iG5Vg3xA6qKke5rD4Tdm8rOZg16GKGTBpCtL2m0+PtNJ57ti7JW1r0Lmh+O9VG32
# +azN1ZsWQU1IBBlTDKPGzGYCfS/6G5df1aQrxVuuUoYTQogC9L8OPk/J9YZQKkL6
# grDno1RpNJAZe2DSe80nwjj0F/PndlXzYXvQiOML6sLJ+JrVPGx+S7w73PcO2dP3
# MUGVkmaaraJFf3Z+Q0L5S8etSWLXcdRo71DZSiRccfISDTia+yf4aseXFH4xRjYj
# W5V5JOj85ipKovYMQB/08rCvl9uDXTiBzm7SoTtVPhjD16i+7XuJqUz+cwuL
# SIG # End signature block
