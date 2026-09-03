function Expand-METSCASetDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $CASetName,
        
        [Parameter()]
        $CASetID,

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
    if ($CASetName -ne '') {
        # Check cache if enabled
        if ($Global:AkamaiOptions.EnableDataCache) {
            $CASetID = $Global:AkamaiDataCache.METS.CASets.$CASetName.CASetID
        }

        if (-not $CASetID) {
            Write-Debug "Expand-METSCASetDetails: '$CASetName' - Retrieving CASet details."
            $CASet = Get-METSCASet -CASetName $CASetName @CommonParams | Where-Object caSetName -eq $CASetName
            if ($null -eq $CASet) {
                throw "CA Set '$CASetName' not found"
            }
            elseif ($CASet.count -gt 1) {
                # Name match is not exact, so filter for exact name
                $CASet = $CASet | Where-Object { $_.caSetName -eq $CASetName -and $_.caSetStatus -ne 'DELETED' }
                # If you still have more than 1, throw an error as we can't know which one the user wants
                if ($CASet.count -gt 1) {
                    throw "Multiple CA Sets with name '$CASetName' found. Please use -CASetID instead"
                } 
            }
            $CASetID = $CASet.caSetId
        }

        # Add to data cache
        if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.METS.CASets.$CASetName) {
            $Global:AkamaiDataCache.METS.CASets.$CASetName = @{
                'CASetID' = $CASetID
            }
        }
        Write-Debug "Expand-METSCASetDetails: CASetID = $CASetID"
    }

    return $CASetID
}

function Format-CASetVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        $Version
    )

    $TopLevelAllowedProperties = @(
        'allowInsecureSha1',
        'certificates',
        'description'
    )
    $CertificateAllowedProperties = @(
        'certificatePem',
        'description'
    )
    $FormattedVersion = Get-BodyObject -Source $Version
    # Remove null FormattedVersion members
    foreach ($Property in $FormattedVersion.PSObject.Properties.Name) {
        if ($null -eq $FormattedVersion.$Property) {
            $FormattedVersion.PSObject.Properties.Remove($Property)
        }
        if ($Property -notin $TopLevelAllowedProperties) {
            $FormattedVersion.PSObject.Properties.Remove($Property)
        }
    }
    foreach ($Certificate in $FormattedVersion.certificates) {
        foreach ($Property in $Certificate.PSObject.Properties.Name) {
            if ($null -eq $Certificate.$Property) {
                $Certificate.PSObject.Properties.Remove($Property)
            }
            if ($Property -notin $CertificateAllowedProperties) {
                $Certificate.PSObject.Properties.Remove($Property)
            }
        }
    }

    # Convert comments to description to support v1-format bodies
    if ($FormattedVersion.comments) {
        $FormattedVersion | Add-Member -NotePropertyName description -NotePropertyValue $FormattedVersion.comments.PSObject.Copy()
        $FormattedVersion.PSObject.Properties.Remove('comments')
    }

    return $FormattedVersion
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
        throw "Source param is of an unhandled type '$($Source.GetType().Name)'"
    }

    return $BodyObject
}

function Copy-METSCASet {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('version')]
        [int]
        $CloneFromVersion,

        [Parameter(Mandatory)]
        [string]
        $NewCASetName,

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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/clone"
        $Body = @{
            'caSetName' = $NewCASetName
        }
        if ($Description) { $Body['description'] = $Description }
        $QueryParameters = @{
            'cloneFromVersion' = $PSBoundParameters.CloneFromVersion
        }

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                Set-AkamaiDataCache -METSCaSetName $Response.body.caSetName -METSCaSetID $Response.body.caSetId
            }

            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
function Copy-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/clone"

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-METSCASet {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(ParameterSetName = 'Get one by name')]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CASetNamePrefix,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ActivatedOn,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $QueryParameters = @{
            'caSetNamePrefix' = $CASetNamePrefix
            'activatedOn'     = $ActivatedOn
        }

        if ($CASetID) {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID"
        }
        else {
            $Path = "/mtls-edge-truststore/v2/ca-sets"
        }

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            $Response = Invoke-AkamaiRequest @RequestParams
            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                if ($CASetID) {
                    Set-AkamaiDataCache -METSCaSetName $Response.Body.caSetName -METSCaSetID $Response.Body.caSetId
                }
                else {
                    # Process is delete first, such that any live sets with the same name win
                    $DeletedCASets = @($Response.Body.caSets | Where-Object caSetStatus -eq 'DELETED')
                    $LiveCASets = @($Response.Body.caSets | Where-Object caSetStatus -ne 'DELETED')
                    foreach ($CASet in @($DeletedCASets + $LiveCASets)) {
                        Set-AkamaiDataCache -METSCaSetName $CASet.caSetName -METSCaSetID $CASet.caSetId
                    }
                }
            }

            if ($CASetID) {
                return $Response.Body
            }
            elseif ($CASetName) {
                return $Response.Body.caSets | Where-Object caSetName -eq $CASetName
            }
            else {
                return $Response.body.caSets
            }
        }
        catch {
            throw $_
        }
    }
}

function Get-METSCASetActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $Version,

        [Parameter()]
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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        if ($ActivationID) {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/activations/$ActivationID"
        }
        else {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/activations"
        }

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($ActivationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.activations
        }
    }
}

function Get-METSCASetActivities {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter()]
        [string]
        $Start,

        [Parameter()]
        [string]
        $End,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/activities"
        $QueryParameters = @{
            'start' = $Start
            'end'   = $End
        }

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.activities
    }
}

function Get-METSCASetAssociation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter()]
        [ValidateSet('enrollments', 'properties')]
        [string]
        $AssociationType,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/associations"
        $QueryParameters = @{
            'associationType' = $AssociationType
        }

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.associations
    }
}
function Get-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter()]
        [int]
        $Version,

        [Parameter()]
        [switch]
        $IncludeCertificates,

        [Parameter()]
        [switch]
        $ActiveVersionsOnly,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $QueryParameters = @{
            'includeCertificates' = $PSBoundParameters.IncludeCertificates.IsPresent
            'activeVersionsOnly'  = $PSBoundParameters.ActiveVersionsOnly.IsPresent
        }
        if ($Version) {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version"
        }
        else {
            $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions"
        }

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Version) {
            return $Response.Body
        }
        else {
            return $Response.Body.versions
        }
    }
}

function Get-METSCASetVersionCertificate {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/certificates"

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.certificates
    }
}

function Get-METSRemoval {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/status/delete"

        $RequestParams = @{
            'Method'           = 'GET'
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function New-METSCASet {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Description,

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
        $Path = "/mtls-edge-truststore/v2/ca-sets"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'caSetName' = $CASetName
            }
            if ($Description) { $Body['description'] = $Description }
        }

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                Set-AkamaiDataCache -METSCaSetName $Response.body.caSetName -METSCaSetID $Response.body.caSetId
            }

            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function New-METSCASetActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Deploy-METSCASet')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/activate"
        $Body = @{
            'network' = $Network
        }

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function New-METSCASetDeactivation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Alias('Disable-METSCASet')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version/deactivate"
        $Body = @{
            'network' = $Network
        }

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function New-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & body')]
    Param(
        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [int]
        $CASetID,

        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [string]
        $CertificatesFile,

        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory)]
        [string]
        $CertificatesDirectory,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [Alias('Comments')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $AllowInsecureSha1,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name & body')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ID & body')]
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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions"

        if (-not $PSCmdlet.ParameterSetName.Contains('body')) {
            $PEMMatch = '-----BEGIN CERTIFICATE-----[a-zA-Z0-9\/\+\r\n=]+-----END CERTIFICATE-----'
            $CertFiles = @()
            $Certificates = @()
            if ($PSCmdlet.ParameterSetName.Contains('file')) {
                if (-not (Test-Path $CertificatesFile)) {
                    throw "Certificates file '$CertificatesFile' does not exist"
                }
                $CertFiles += Get-Item $CertificatesFile
            }
            else {
                if (-not (Test-Path $CertificatesDirectory)) {
                    throw "Certificates directory '$CertificatesDirectory' does not exist"
                }
                $CertFiles += Get-ChildItem $CertificatesDirectory
            }
            foreach ($CertFile in $CertFiles) {
                $FileContent = Get-Content -Raw $CertFile.FullName
                $CertMatches = Select-String -InputObject $FileContent -Pattern $PEMMatch -AllMatches
                foreach ($CertMatch in $CertMatches.matches) {
                    $Certificates += ($CertMatch.value -replace '[\r\n]*', '')
                }
            }
            # De-duplicate certs
            $Certificates = $Certificates | Select-Object -Unique

            $Body = @{
                'certificates' = @()
            }
            $Certificates | ForEach-Object {
                $Body['certificates'] += @{ 'certificatePem' = $_ }
            }
            if ($Comments) {
                $Body['description'] = $Description
            }
            if ($AllowInsecureSha1) {
                $Body['allowInsecureSha1'] = $true
            }
        }

        $Body = Format-CASetVersion -Version $Body

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Remove-METSCASet {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID"

        $RequestParams = @{
            'Method'           = 'DELETE'
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        # Clear data cache
        Clear-AkamaiDataCache -METSCASetID $CASetID
        return $Response.Body
    }
}

function Remove-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version"

        $RequestParams = @{
            'Method'           = 'DELETE'
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Set-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & body')]
    Param(
        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $Version,

        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [string]
        $CertificatesFile,

        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory)]
        [string]
        $CertificatesDirectory,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [Alias('Comments')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $AllowInsecureSha1,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name & body')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ID & body')]
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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version"

        if (-not $PSCmdlet.ParameterSetName.Contains('body')) {
            $PEMMatch = '-----BEGIN CERTIFICATE-----[a-zA-Z0-9\/\+\r\n=]+-----END CERTIFICATE-----'
            $CertFiles = @()
            $Certificates = @()
            if ($PSCmdlet.ParameterSetName.Contains('file')) {
                if (-not (Test-Path $CertificatesFile)) {
                    throw "Certificates file '$CertificatesFile' does not exist"
                }
                $CertFiles += Get-Item $CertificatesFile
            }
            else {
                if (-not (Test-Path $CertificatesDirectory)) {
                    throw "Certificates directory '$CertificatesDirectory' does not exist"
                }
                $CertFiles += Get-ChildItem $CertificatesDirectory
            }
            foreach ($CertFile in $CertFiles) {
                $FileContent = Get-Content -Raw $CertFile.FullName
                $CertMatches = Select-String -InputObject $FileContent -Pattern $PEMMatch -AllMatches
                foreach ($CertMatch in $CertMatches.matches) {
                    $Certificates += ($CertMatch.value -replace '[\r\n]*', '')
                }
            }
            # De-duplicate certs
            $Certificates = $Certificates | Select-Object -Unique

            $Body = @{
                'certificates' = @()
            }
            $Certificates | ForEach-Object {
                $Body['certificates'] += @{ 'certificatePem' = $_ }
            }
            if ($Description) {
                $Body['description'] = $Description
            }
            if ($AllowInsecureSha1) {
                $Body['allowInsecureSha1'] = $true
            }
        }

        $Body = Format-CASetVersion -Version $Body

        $RequestParams = @{
            'Method'           = 'PUT'
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Test-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'body')]
    Param(
        [Parameter(ParameterSetName = 'File', Mandatory)]
        [string]
        $CertificatesFile,

        [Parameter(ParameterSetName = 'Directory', Mandatory)]
        [string]
        $CertificatesDirectory,

        [Parameter()]
        [switch]
        $AllowInsecureSha1,

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
        $Path = "/mtls-edge-truststore/v2/certificates/validate"
        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            $PEMMatch = '-----BEGIN CERTIFICATE-----[a-zA-Z0-9\/\+\r\n=]+-----END CERTIFICATE-----'
            $CertFiles = @()
            $Certificates = @()
            if ($PSCmdlet.ParameterSetName -eq 'File') {
                if (-not (Test-Path $CertificatesFile)) {
                    throw "Certificates file '$CertificatesFile' does not exist"
                }
                $CertFiles += Get-Item $CertificatesFile
            }
            else {
                if (-not (Test-Path $CertificatesDirectory)) {
                    throw "Certificates directory '$CertificatesDirectory' does not exist"
                }
                $CertFiles += Get-ChildItem $CertificatesDirectory
            }
            foreach ($CertFile in $CertFiles) {
                $FileContent = Get-Content -Raw $CertFile.FullName
                $CertMatches = Select-String -InputObject $FileContent -Pattern $PEMMatch -AllMatches
                foreach ($CertMatch in $CertMatches.matches) {
                    $Certificates += ($CertMatch.value -replace '[\r\n]*', '')
                }
            }
            # De-duplicate certs
            $Certificates = $Certificates | Select-Object -Unique

            $Body = @{
                'certificates' = @()
            }
            $Certificates | ForEach-Object {
                $Body['certificates'] += @{ 'certificatePem' = $_ }
            }
            if ($AllowInsecureSha1) {
                $Body['allowInsecureSha1'] = $true
            }
        }

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDBiNtKr4Z/mZqq
# pDTVv49hn9mSE05NxMnpPSAMMr/aeKCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEmA/5FadhEel3L7xDrbDR6sgbyoMxgU
# kd9v48SED8pKMA0GCSqGSIb3DQEBAQUABIIBgCBYbun7fKf0vSMXnSGiHqeoxk+p
# SlcY0xW8WM5XwxCWaCOCGXtUcDmyq+4iAz5NiRZxbNYMJ49CXKQbMnXSQ+R2qYub
# danDtSh6zII0J2HrbLG8kiXDAyS889REm0ujU5dcAJUtOpRR08+/MP9IBwnLPKM8
# nSjd4fn6cX2pZqu33/6jIklXmVapngdPoBy7n9S1BMiW5G6Qh3JClikjJm9gF6aW
# ona3ClNvwQoFpyqMejorOhH4iyiZ/wXeOUGpqh2B6mcfhkPyDg3O5jL3zXh/jNT6
# KufUZPSTv1uCrqzkvcv4K+gV1O+11Ub3tpB15Nkje88XBVxgtsfyrd1tAPX5jYgy
# 3z+lJPnRUqkd1umltcYvK0tKYdG3XgVGqlTsvZedvzHxfAiBIPht8W/ggGSFE4r6
# 6cmQrWtUEViDfb4Nudh42jLmIRxdROIlrVO5DQFrSPLFOGxeijFWRup4Nn5Estsg
# MlBlyeeogfoEfZIXkZBbl+ml0mQN2nWXqcA2gA==
# SIG # End signature block
