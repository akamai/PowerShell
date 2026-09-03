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

function Get-GTMASMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $MapName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )


    Process {
        if ($MapName) {
            $Path = "/config-gtm/v1/domains/$DomainName/as-maps/$MapName"
        }
        else {
            $Path = "/config-gtm/v1/domains/$DomainName/as-maps"
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        if ($MapName) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}


function Get-GTMCIDRMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $MapName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        if ($MapName) {
            $Path = "/config-gtm/v1/domains/$DomainName/cidr-maps/$MapName"
        }
        else {
            $Path = "/config-gtm/v1/domains/$DomainName/cidr-maps"
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        if ($MapName) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}


function Get-GTMContract {
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

    Process {
        $Path = "/config-gtm/v1/identity/contracts"

        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }

        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.contracts
    }
}
function Get-GTMDatacenter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [int]
        $DatacenterID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        if ($PSBoundParameters.DatacenterID) {
            $Path = "/config-gtm/v1/domains/$DomainName/datacenters/$DatacenterID"
        }
        else {
            $Path = "/config-gtm/v1/domains/$DomainName/datacenters"
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        if ($DatacenterID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}


function Get-GTMDatacenterLatency {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [int]
        $DatacenterID,

        [Parameter(Mandatory)]
        [string]
        $Start,

        [Parameter(Mandatory)]
        [string]
        $End,

        [Parameter()]
        [string]
        $Latency,

        [Parameter()]
        [string]
        $Loss,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        $DateTimeMatch = '[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}Z'
        if (($Start -and $Start -notmatch $DateTimeMatch) -or ($End -and $End -notmatch $DateTimeMatch)) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm:ssZ'"
        }
    
        $Path = "/gtm-api/v1/reports/latency/domains/$DomainName/datacenters/$DatacenterID"
        $QueryParameters = @{
            start   = $Start
            end     = $End
            latency = $Latency
            loss    = $Loss
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


function Get-GTMDemand {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $PropertyName,

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

    Process {
        $Path = "/gtm-api/v1/reports/demand/domains/$DomainName/properties/$PropertyName"
        $QueryParameters = @{
            'start' = $Start
            'end'   = $End
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


function Get-GTMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        if ($DomainName) {
            $Path = "/config-gtm/v1/domains/$DomainName"
        }
        else {
            $Path = "/config-gtm/v1/domains"
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        if ($DomainName) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}


function Get-GTMDomainAuthority {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        $Path = "/config-gtm/v1/domains/$DomainName/authorities"

        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
function Get-GTMDomainHistory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [int]
        $Page,

        [Parameter()]
        [int]
        $PageSize = 1000,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        $Path = "/config-gtm/v1/domains/$DomainName/history"
        $QueryParameters = @{
            'page'     = $PSBoundParameters.page
            'pageSize' = $PageSize
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        return $Response.Body
    }
}


function Get-GTMDomainList {
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

    Process {
        $Path = "/gtm-api/v1/reports/domain-list"

        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
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
function Get-GTMDomainStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        $Path = "/config-gtm/v1/domains/$DomainName/status/current"
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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


function Get-GTMDomainSummary {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        $Path = "/gtm-api/v1/reports/domain-list/$DomainName"

        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
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
function Get-GTMGeoMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $MapName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        if ($MapName) {
            $Path = "/config-gtm/v1/domains/$DomainName/geographic-maps/$MapName"
        }
        else {
            $Path = "/config-gtm/v1/domains/$DomainName/geographic-maps"
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        if ($MapName) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}


function Get-GTMGroup {
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

    Process {
        $Path = "/config-gtm/v1/identity/groups"

        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }

        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.groups
    }
}
function Get-GTMIdentity {
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

    Process {
        $Path = "/config-gtm/v1/identity"

        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
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
function Get-GTMIPAvailability {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $PropertyName,

        [Parameter(Mandatory)]
        [string]
        $Start,

        [Parameter(Mandatory)]
        [string]
        $End,

        [Parameter()]
        [string]
        $IP,

        [Parameter()]
        [switch]
        $MostRecent,

        [Parameter()]
        [int]
        $DatacenterID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        $Path = "/gtm-api/v1/reports/ip-availability/domains/$DomainName/properties/$PropertyName"
        $QueryParameters = @{
            'start'        = $Start
            'end'          = $End
            'ip'           = $IP
            'mostRecent'   = $PSBoundParameters.MostRecent
            'datacenterID' = $PSBoundParameters.DatacenterID
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


function Get-GTMLivenessPerProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $PropertyName,

        [Parameter(Mandatory)]
        [string]
        $Date,

        [Parameter()]
        [string]
        $AgentIP,

        [Parameter()]
        [string]
        $TargetIP,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        $DateMatch = '[\d]{4}-[\d]{2}-[\d]{2}'
        if ($Date -and $Date -notmatch $DateMatch) {
            throw "ERROR: Date must be in the format 'YYYY-MM-DD'"
        }
    
        $Path = "/gtm-api/v1/reports/liveness-tests/domains/$DomainName/properties/$PropertyName"
        $QueryParameters = @{
            'date'     = $Date
            'agentIp'  = $AgentIP
            'targetIp' = $TargetIP
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


function Get-GTMLivenessTestError {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $ErrorCode,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        if ($ErrorCode) {
            $Path = "/gtm-api/v1/reports/liveness-tests/error-code-descriptions/$ErrorCode"
        }
        else {
            $Path = "/gtm-api/v1/reports/liveness-tests/error-code-descriptions"
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
        return $Response.Body.items
    }
}


function Get-GTMLoadData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $ResourceName,

        [Parameter(Mandatory)]
        [int]
        $DatacenterID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        $Path = "/gtm-load-data/v1/$DomainName/$ResourceName/$DatacenterID"
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


function Get-GTMLoadFeedbackReport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $ResourceName,

        [Parameter(Mandatory)]
        [string]
        $Start,

        [Parameter(Mandatory)]
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

    Process {
        $Path = "/gtm-api/v1/reports/load-feedback/domains/$DomainName/resources/$ResourceName"
        $QueryParameters = @{
            'start' = $Start
            'end'   = $End
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


function Get-GTMProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $PropertyName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        if ($PropertyName) {
            $Path = "/config-gtm/v1/domains/$DomainName/properties/$PropertyName"
        }
        else {
            $Path = "/config-gtm/v1/domains/$DomainName/properties"
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        if ($PropertyName) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}


function Get-GTMResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $ResourceName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    Process {
        if ($ResourceName) {
            $Path = "/config-gtm/v1/domains/$DomainName/resources/$ResourceName"
        }
        else {
            $Path = "/config-gtm/v1/domains/$DomainName/resources"
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        if ($ResourceName) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}


function Get-GTMTrafficPerDatacenter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [int]
        $DatacenterID,

        [Parameter(Mandatory)]
        [string]
        $Start,

        [Parameter(Mandatory)]
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

    Process {
        $DateTimeMatch = '[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}Z'
        if (($Start -and $Start -notmatch $DateTimeMatch) -or ($End -and $End -notmatch $DateTimeMatch)) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm:ssZ'"
        }
    
        $Path = "/gtm-api/v1/reports/traffic/domains/$DomainName/datacenters/$DatacenterID"
        $QueryParameters = @{
            'start' = $Start
            'end'   = $End
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


function Get-GTMTrafficPerProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $PropertyName,

        [Parameter(Mandatory)]
        [string]
        $Start,

        [Parameter(Mandatory)]
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

    Process {
        $DateTimeMatch = '[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}Z'
        if ($Start -notmatch $DateTimeMatch -or $End -notmatch $DateTimeMatch) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm:ssZ'"
        }
    
        $Path = "/gtm-api/v1/reports/traffic/domains/$DomainName/properties/$PropertyName"
        $QueryParameters = @{
            'start' = $Start
            'end'   = $End
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


function New-GTMASMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $MapName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/as-maps/$MapName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}  
}


function New-GTMCIDRMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $MapName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/cidr-maps/$MapName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}  
}


function New-GTMDatacenter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/datacenters"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
        }

        # Convert to object (if required) and check for datacenterId
        if ($Body.GetType().Name -eq 'String') {
            $Body = ConvertFrom-Json -Depth 10 $Body
        }
        if ($Body.datacenterId) {
            $Body.PSObject.Members.Remove('datacenterId')
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
        return $Response.Body.resource
    }

    end {}  
}


function New-GTMDefaultDatacenter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/config-gtm/v1/domains/$DomainName/datacenters/default-datacenter-for-maps"
    $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
    $RequestParams = @{
        'Path'              = $Path
        'Method'            = 'POST'
        'AdditionalHeaders' = $AdditionalHeaders
        'EdgeRCFile'        = $EdgeRCFile
        'Section'           = $Section
        'AccountSwitchKey'  = $AccountSwitchKey
        'Debug'             = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body.resource
}


function New-GTMDefaultDatacenterForIP {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [ValidateSet('ipv4', 'ipv6')]
        [string]
        $IPVersion,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    if ($IPVersion -eq 'ipv4') {
        $Path = "/config-gtm/v1/domains/$DomainName/datacenters/datacenter-for-ip-version-selector-ipv4"
    }
    elseif ($IPVersion -eq 'ipv6') {
        $Path = "/config-gtm/v1/domains/$DomainName/datacenters/datacenter-for-ip-version-selector-ipv6"
    }
    $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
    $RequestParams = @{
        'Path'              = $Path
        'Method'            = 'POST'
        'AdditionalHeaders' = $AdditionalHeaders
        'EdgeRCFile'        = $EdgeRCFile
        'Section'           = $Section
        'AccountSwitchKey'  = $AccountSwitchKey
        'Debug'             = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body.resource
}


function New-GTMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains"
        $QueryParameters = @{
            'contractId' = $ContractID
            'gid'        = $GroupID
        }
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource  
    }

    end {}

}


function New-GTMGeoMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $MapName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/geographic-maps/$MapName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {} 
}


function New-GTMProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $PropertyName,

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

    begin {}
    
    process {
        $Path = "/config-gtm/v1/domains/$DomainName/properties/$PropertyName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}
}


function New-GTMResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $ResourceName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/resources/$ResourceName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}
}

function Remove-GTMASMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $MapName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/as-maps/$MapName"
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        return $Response.Body
    }
}


function Remove-GTMCIDRMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $MapName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/cidr-maps/$MapName"
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        return $Response.Body
    }
}


function Remove-GTMDatacenter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $DatacenterID,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/datacenters/$DatacenterID"
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        return $Response.Body
    }
}


function Remove-GTMGeoMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $MapName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/geographic-maps/$MapName"
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        return $Response.Body
    }
}


function Remove-GTMProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $PropertyName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/properties/$PropertyName"
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        return $Response.Body
    }
}


function Remove-GTMResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $ResourceName,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/resources/$ResourceName"
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        return $Response.Body
    }
}


function Set-GTMASMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $MapName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/as-maps/$MapName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}  
}


function Set-GTMCIDRMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $MapName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/cidr-maps/$MapName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}  
}


function Set-GTMDatacenter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $DatacenterID,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/datacenters/$DatacenterID"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}  
}


function Set-GTMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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

    process {
        $Path = "/config-gtm/v1/domains/$DomainName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.resource
        }
    }
}


function Set-GTMGeoMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $MapName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/geographic-maps/$MapName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource 
    }

    end {} 
}


function Set-GTMProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $PropertyName,

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

    begin {}
    
    process {
        $Path = "/config-gtm/v1/domains/$DomainName/properties/$PropertyName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}
}


function Set-GTMResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ResourceName,

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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains/$DomainName/resources/$ResourceName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
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
        return $Response.Body.resource
    }

    end {}
}

function Submit-GTMLoadData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $ResourceName,

        [Parameter(Mandatory)]
        [string]
        $DatacenterID,

        [Parameter(ValueFromPipeline, Mandatory)]
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

    Process {
        $Path = "/gtm-load-data/v1/$DomainName/$ResourceName/$DatacenterID"
        $AdditionalHeaders = @{ 
            'Accept' = 'application/problem+json'
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC3vgLq/WIUJSPu
# qTuaM/A4NcFJOWjhiJHSUMmjsCcrGKCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEIn4zdPPKU326JIJWU4H2PkvRYSrLyJ
# zma6ljuf+6p5MA0GCSqGSIb3DQEBAQUABIIBgAUc05L6FkO/GoE+u53abu62wTpd
# oJZXHtZcQ2MDIQKN4BILPWUJx1FpTjjUGZDH+VXkue/pzdYfVlO9PAaBRqJTFcNj
# spJBB5YmVSAmcYl4H/Wektp2eCcqEfBVtwR/Jabnp+9s2GB9jDafagVZPak2BdfC
# DR/0D1Xun2DxNcyRhW9nx0Qfy86uyoCti2Xxja8OwR1fLRlY2rw7VrGOcpclPBU3
# KuC+/atUreH+o5/+JWjz7itjh5q8voN7Q5pqtCSjsCIUTFtCurSqf0orw5XoM3ur
# E8YKf379nJpl2F4ugwBWu0gYQP7JMjZEj62zLB2SVlZ+AeEQ3gneREB14eojR4wd
# /zp11NDmeNIffPEUl/Wnqt4LBz0wadGTXfsk/pd/ERRb8AQq2nm+34SxmkGJ1/XY
# PlcHHTzHqXIQj7Pppfzxo1LrUf1h6c3ofLp48FuMKfmjKiKdEslJv6bGU+EguRZL
# 348iq01+EJ2uJP5VHkcxg8JlqQWJOg5UKm1lOg==
# SIG # End signature block
