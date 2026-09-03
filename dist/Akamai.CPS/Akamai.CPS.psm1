function Format-CPSResponse {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]
        $ResponseBody
    )

    process {
        # Enrollment member
        if ($ResponseBody.enrollment) {
            if ($ResponseBody.enrollment -match '[\d]+$') {
                $ResponseBody | Add-Member -NotePropertyName enrollmentId -NotePropertyValue ([int] $Matches[0])
            }
        }

        # Basic changes
        if ($ResponseBody.change) {
            if ($ResponseBody.change -match '[\d]+$') {
                $ResponseBody | Add-Member -NotePropertyName changeId -NotePropertyValue ([int] $Matches[0])
            }
        }

        # Enrollment pendingChanges
        if ($ResponseBody.pendingChanges) {
            foreach ($PendingChange in $ResponseBody.pendingChanges) {
                if ($PendingChange.location -match '[\d]+$') {
                    $PendingChange | Add-Member -NotePropertyName changeId -NotePropertyValue ([int] $Matches[0])
                }
            }
        }

        # changes array
        if ($ResponseBody.changes) {
            $ChangeIDs = New-Object -TypeName System.Collections.Generic.List[long]
            $ResponseBody.changes | ForEach-Object {
                if ($_ -match '[\d]+$') {
                    $ChangeIDs.Add([int] $Matches[0])
                }
            }
            if ($ChangeIDs.count -gt 0) {
                $ResponseBody | Add-Member -NotePropertyName changeIds -NotePropertyValue $ChangeIDs
            }
        
        }

        return $ResponseBody
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
        throw "Source param is of an unhandled type '$($Source.GetType().Name)'"
    }

    return $BodyObject
}

function Add-CPSThirdPartyCert {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Certificate,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TrustChain,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('RSA', 'ECDSA')]
        [string]
        $KeyAlgorithm,

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
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/update/third-party-cert-and-trust-chain"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.certificate-and-trust-chain.v2+json'
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'certificatesAndTrustChains' = @(
                    @{
                        'certificate'  = $Certificate
                        'keyAlgorithm' = $KeyAlgorithm
                    }
                )
            }

            if ($TrustChain) {
                $Body.certificatesAndTrustChains[0]['trustChain'] = $TrustChain
            }
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
        return $Response.Body | Format-CPSResponse
    }
}

function Complete-CPSChange {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter(Mandatory)]
        [ValidateSet('acknowledge', 'deny')]
        [string]
        $Acknowledgement,

        [Parameter()]
        [string]
        $Hash,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/update/change-management-ack"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.acknowledgement.v1+json'
        }
        
        $Body = @{
            'acknowledgement' = $Acknowledgement
        }
    
        if ($Hash) {
            $AdditionalHeaders['content-type'] = 'application/vnd.akamai.cps.acknowledgement-with-hash.v1+json'
            $Body['hash'] = $Hash
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
        return $Response.Body | Format-CPSResponse
    }
}

function Confirm-CPSLetsEncryptChallengesCompleted {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter(Mandatory)]
        [ValidateSet('acknowledge', 'deny')]
        [string]
        $Acknowledgement,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/update/lets-encrypt-challenges-completed"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.acknowledgement.v1+json'
        }
        $Body = @{
            'acknowledgement' = $Acknowledgement
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
        return $Response.Body | Format-CPSResponse
    }
}

function Confirm-CPSPostVerificationWarnings {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter(Mandatory)]
        [ValidateSet('acknowledge', 'deny')]
        [string]
        $Acknowledgement,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/update/post-verification-warnings-ack"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.acknowledgement.v1+json'
        }
        $Body = @{
            'acknowledgement' = $Acknowledgement
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
        return $Response.Body | Format-CPSResponse
    }
}

function Confirm-CPSPreVerificationWarnings {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter(Mandatory)]
        [ValidateSet('acknowledge', 'deny')]
        [string]
        $Acknowledgement,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/update/pre-verification-warnings-ack"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.acknowledgement.v1+json'
        }
        $Body = @{
            'acknowledgement' = $Acknowledgement
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
        return $Response.Body | Format-CPSResponse
    }
}

function Get-CPSActiveCertificate {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
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
        $Path = "/cps/v2/active-certificates"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.active-certificates.v2+json'
        }
        $QueryParameters = @{
            'contractId' = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'QueryParameters'   = $QueryParameters
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.enrollments
    }
}

function Get-CPSCertificateHistory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/history/certificates"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.certificate-history.v2+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.certificates 
    }
}

function Get-CPSChangeHistory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/history/changes"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.change-history.v5+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.changes  
    }
}

function Get-CPSChangeStagingStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/info/change-management-info"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.change-management-info.v6+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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


function Get-CPSChangeStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.change.v2+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Get-CPSCSR {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/info/third-party-csr"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.csr.v2+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Get-CPSDeployment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/deployments"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.deployments.v8+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Get-CPSDeploymentSchedule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/deployment-schedule"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.deployment-schedule.v1+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Get-CPSDVHistory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/dv-history"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.dv-history.v1+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.results
    }
}

function Get-CPSEnrollment {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline)]
        [int]
        $EnrollmentID,

        [Parameter(ParameterSetName = 'Get all')]
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
        if ($EnrollmentID) {
            $Path = "/cps/v2/enrollments/$EnrollmentID"
        }
        else {
            $Path = "/cps/v2/enrollments"
        }

        if ($PSBoundParameters.EnrollmentID) {
            $AcceptHeader = 'application/vnd.akamai.cps.enrollment.v12+json'
        }
        else {
            $AcceptHeader = 'application/vnd.akamai.cps.enrollments.v12+json'
        }

        $AdditionalHeaders = @{
            'accept' = $AcceptHeader
        }
        $QueryParameters = @{
            'contractId' = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'QueryParameters'   = $QueryParameters
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSBoundParameters.EnrollmentID) {
            return $Response.Body | Format-CPSResponse
        }
        else {
            return $Response.Body.enrollments | Format-CPSResponse
        }
    }
}

function Get-CPSLetsEncryptChallenges {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/info/lets-encrypt-challenges"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.dv-challenges.v2+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Get-CPSPostVerificationWarnings {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/info/post-verification-warnings"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.warnings.v1+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Get-CPSPreVerificationWarnings {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/info/pre-verification-warnings"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.warnings.v1+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Get-CPSProductionDeployment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/deployments/production"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.deployment.v8+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Get-CPSStagingDeployment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/deployments/staging"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.deployment.v8+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function New-CPSEnrollment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $DeployNotAfter,

        [Parameter()]
        [string]
        $DeployNotBefore,

        [Parameter()]
        [switch]
        $AllowDuplicateCN,

        [Parameter()]
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
        $DateMatch = '[\d]{4}-[\d]{2}-[\d]{2}'
        if (($DeployNotAfter -or $DeployNotBefore) -and ($DeployNotAfter -notmatch $DateMatch -or $DeployNotBefore -notmatch $DateMatch)) {
            throw "ERROR: DeployNotAfter & DeployNotBefore must be in the format 'YYYY-MM-DD'"
        }

        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.enrollment-status.v1+json'
            'content-type' = 'application/vnd.akamai.cps.enrollment.v12+json'
        }
        $Path = "/cps/v2/enrollments"
        $QueryParameters = @{
            'contractId'        = $ContractID
            'deploy-not-after'  = $DeployNotAfter
            'deploy-not-before' = $DeployNotBefore
            'allowDuplicateCN'  = $PSBoundParameters.AllowDuplicateCN
        }
    }
    process {
        # Cleanup request body to remove additional elements added in Get-CPSEnrollment
        $Body = Get-BodyObject -Source $Body
        if ($Body.pendingChanges) {
            $Body.pendingChanges | ForEach-Object {
                if ($_.changeId) {
                    $_.PSObject.Members.Remove('changeId')
                }
            }
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
        return $Response.Body | Format-CPSResponse
    }
}

function Remove-CPSChange {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID"
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.change-id.v1+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'DELETE'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body | Format-CPSResponse
    }
}

function Remove-CPSEnrollment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter()]
        [switch]
        $AllowCancelPendingChanges,

        [Parameter()]
        [string]
        $DeployNotAfter,

        [Parameter()]
        [string]
        $DeployNotBefore,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $DateMatch = '[\d]{4}-[\d]{2}-[\d]{2}'
        if (($DeployNotAfter -or $DeployNotBefore) -and ($DeployNotAfter -notmatch $DateMatch -or $DeployNotBefore -notmatch $DateMatch)) {
            throw "ERROR: DeployNotAfter & DeployNotBefore must be in the format 'YYYY-MM-DD'"
        }
    
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.enrollment-status.v1+json'
        }
        $Path = "/cps/v2/enrollments/$EnrollmentID"
        $QueryParameters = @{
            'allow-cancel-pending-changes' = $PSBoundParameters.AllowCancelPendingChanges
            'deploy-not-after'             = $DeployNotAfter
            'deploy-not-before'            = $DeployNotBefore
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'DELETE'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body | Format-CPSResponse
    }
}

function Set-CPSDeploymentSchedule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $NotAfter,

        [Parameter()]
        [string]
        $NotBefore,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/deployment-schedule"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.deployment-schedule.v1+json'
        }
    
        $Body = @{}
        if ($NotAfter) {
            $Body['notAfter'] = $NotAfter
        }
        if ($NotBefore) {
            $Body['notBefore'] = $NotBefore
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body | Format-CPSResponse
    }
}

function Set-CPSEnrollment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $AllowCancelPendingChanges,

        [Parameter()]
        [switch]
        $AllowStagingBypass,

        [Parameter()]
        [string]
        $DeployNotAfter,

        [Parameter()]
        [string]
        $DeployNotBefore,

        [Parameter()]
        [switch]
        $ForceRenewal,

        [Parameter()]
        [switch]
        $RenewalDateCheckOverride,

        [Parameter()]
        [switch]
        $AllowMissingCertificateAddition,

        [Parameter()]
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
        $DateMatch = '[\d]{4}-[\d]{2}-[\d]{2}'
        if (($DeployNotAfter -or $DeployNotBefore) -and ($DeployNotAfter -notmatch $DateMatch -or $DeployNotBefore -notmatch $DateMatch)) {
            throw "ERROR: DeployNotAfter & DeployNotBefore must be in the format 'YYYY-MM-DD'"
        }

        $QueryParameters = @{
            'allow-cancel-pending-changes'       = $PSBoundParameters.AllowCancelPendingChanges
            'allow-staging-bypass'               = $PSBoundParameters.AllowStagingBypass
            'force-renewal'                      = $PSBoundParameters.ForceRenewal
            'renewal-date-check-override'        = $PSBoundParameters.RenewalDateCheckOverride
            'allow-missing-certificate-addition' = $PSBoundParameters.AllowMissingCertificateAddition
        }
        
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.enrollment-status.v1+json'
            'content-type' = 'application/vnd.akamai.cps.enrollment.v12+json'
        }
    }
    
    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID"
        # Cleanup request body to remove additional elements added in Get-CPSEnrollment
        $Body = Get-BodyObject -Source $Body
        if ($Body.pendingChanges) {
            $Body.pendingChanges | ForEach-Object {
                if ($_.changeId) {
                    $_.PSObject.Members.Remove('changeId')
                }
            }
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
        return $Response.Body | Format-CPSResponse
    }
}


# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCvrD6hX4MGpTN3
# u3KmlaVK9SLgipwUEOE18/ydD62DLaCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDoahmMkBQXjJlKpp3HEFYVLgAr+66W4
# uUZUOCXgvJ7yMA0GCSqGSIb3DQEBAQUABIIBgByAGeXVxqtzmPrvcI0KF+JJTSUJ
# Dojzz7vNEBCTaBAhoBQLGwOOU7zRGH8DV2M9d+hDmMc64+h2WlYSn49RsBsO4UAZ
# StNSyTsTPAW4q9w8FrvK+931An+fDrMFywGmt7WOUIm/WbzZq/a5ZIOHC7M9siL3
# q8qmDnNB2IgjfdnCXgGDWkGkXOxIYcka05is4xcicZvvvMgRkpZjfJxxJ0Nu3gG4
# vtCdgrylUHW5C4cnTccboMFHdZnQxenL5+Fm4WSduLcdEhG5CYtNh59dqMqw4NKF
# Js5cjjETVGkw+XUil5p9wFhH/2mRLRNFN2m8l6MK8YZ+gvsGKN65UFIv+PC2g40U
# SAvGKfM/CF3uussy2cSqZtNNz+fgr/kxi1bPKwvm6zvUEGsfAmFuZoMTBYdqzHf3
# LoTIxrQRIOA+x335PYEf+ei0bEflFqa52v3LSuaThNvUAfE89pD/sjaw82OO7TJV
# JYIhiExpaLbfOlSuIUfCgx/sOqcvKSvXew1XbQ==
# SIG # End signature block
