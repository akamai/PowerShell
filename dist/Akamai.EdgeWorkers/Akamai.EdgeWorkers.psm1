function Expand-EdgeWorkerDetails {
    [CmdletBinding()]
    Param(
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
                $EdgeWorker = (Get-EdgeWorker @CommonParams) | Where-Object name -eq $EdgeWorkerName
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
        if ($Version.ToLower() -in "latest", "production", "staging") {
            if ($Version.ToLower() -eq 'latest') {
                try {
                    $Versions = Get-EdgeWorkerVersion -EdgeWorkerID $EdgeWorkerID @CommonParams | Sort-Object -Property sequenceNumber -Descending
                }
                catch {
                    throw $_
                }
                $Version = $Versions[0].version
            }
            elseif ($Version.ToLower() -eq 'production') {
                try {
                    Write-Debug "Expand-EdgeWorkerDetails: retrieving active production activation."
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
                try {
                    Write-Debug "Expand-EdgeWorkerDetails: retrieving active staging activation."
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
                        Write-Debug "Expand-EdgeWorkerDetails: retrieving active production activation."
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
                        Write-Debug "Expand-EdgeWorkerDetails: retrieving active staging activation."
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
    Param(
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

        # Execute tar
        Write-Debug "New-TarArchive: Executing command '$TarCommand'"
        Invoke-Expression $TarCommand | Out-Null
    }
    else {
        throw "tar command not found. Please create .tgz file manually."
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
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory)]
        [string]
        $NewName,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory)]
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
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/clone"
        $Body = @{
            'name'           = $NewName
            'groupId'        = $GroupID
            'resourceTierId' = $ResourceTierID
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
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter()]
        [string]
        $ActivationID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $ActiveOnNetwork,

        [Parameter()]
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
            'activeOnNetwork' = $PSBoundParamters.ActiveOnNetwork.IsPresent
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
    Param(
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
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/edgeworkers/v1/ids"
    
        $Body = @{
            name           = $EdgeWorkerName
            groupId        = $GroupID
            resourceTierId = $ResourceTierID
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
    Param(
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
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBlwuUVLU+csHWH
# 8HCcvIYNB51m5SecaY/QTVmfo67hzKCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINqXl5UlE3ejf2TgUveouNr0VgGImpJ2
# aHGs0qa0Mzg2MA0GCSqGSIb3DQEBAQUABIIBgBGcR8xRFdXRBfYBW7S17eHfCLTp
# Gcjw3UCSO7zLFj1R82TMW7fX0nS/69hy/6aobybAAUYX//m1/Tz9Au7lZjNHg6wn
# DL7Pf00NhZ6nkYhryoB3yUwNINCNfYMw+NcppZFrP3cijdZmv9T+O2OUTX/37WlA
# 2hve01d2xVNlKwaJnkoSyoORsDQChdWYbqqwqonwlsXu6fNPx1GTjR++xPJyOrDx
# oerfmKDT22QTnfdq50lg+j5kXELJz5trG+MG1uHC4xKAZxsTk1mR8HDICpmEQpyO
# RbtVUYe3TaYa8Mc7EQU0lZz73qFWOBvtt1835ZzequL90m+ASxm2VRlI/ZJDTw04
# yAC6xB6yz+XNftY0kW7cs9LDHcL2zK0hwLXSBFmm13NDt5MNcZD2WWWROnM09Zux
# iNIzN8KdK2twOv75FKeC9pSrlqyQGMFtsKeNOUgrGchfA3Ura8wSk0uAxF08ziLb
# BplwR2uBJBiFSYMyThqPlXYWqAf/7PWSVgXzNg==
# SIG # End signature block
