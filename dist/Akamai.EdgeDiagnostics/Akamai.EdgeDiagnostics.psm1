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

function Find-IPAddress {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $IPAddress,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/edge-diagnostics/v1/locate-ip"
        $Body = @{
            'ipAddresses' = $IPAddress
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
        return $Response.Body.results
    }
}


function Get-EdgeDiagnosticsConnectivityProblem {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RequestID,
        
        [Parameter()]
        [switch]
        $IncludeContentResponseBody,
        
        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edge-diagnostics/v1/connectivity-problems/requests/$RequestID"
    $QueryParameters = @{
        'includeContentResponseBody' = $PSBoundParameters.IncludeContentResponseBody.IsPresent
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


function Get-EdgeDiagnosticsContentProblem {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RequestID,
        
        [Parameter()]
        [switch]
        $IncludeContentResponseBody,
        
        [Parameter()]
        [switch]
        $AsHashTable,
        
        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edge-diagnostics/v1/content-problems/requests/$RequestID"
    $QueryParameters = @{
        'includeContentResponseBody' = $PSBoundParameters.IncludeContentResponseBody.IsPresent
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
    if ($Response.Body -is 'String') {
        #JSON conversion fails due to object names differing only by case
        $Response.BodyHash = $Response.Body | ConvertFrom-Json -AsHashtable
        if ($AsHashTable) {
            return $Response.BodyHash
        }
        else {
            $Response.BodyHash['logLines'][0]['result'].Remove('legend')
            $Response.BodyHash['summary']['logLines'][0]['result'].Remove('legend')
            $Response.Body = $Response.BodyHash | ConvertTo-Json -depth 100 | ConvertFrom-Json
        }
    }
        
    return $Response.Body
}


function Get-EdgeDiagnosticsErrorStatistics {
    [CmdletBinding(DefaultParameterSetName = 'CP code')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'CP code')]
        [int]
        $CPCode,

        [Parameter(Mandatory, ParameterSetName = 'URL')]
        [string]
        $URL,

        [Parameter()]
        [ValidateSet('EDGE_ERRORS', 'ORIGIN_ERRORS')]
        [string]
        $ErrorType,

        [Parameter()]
        [ValidateSet('STANDARD_TLS', 'ENHANCED_TLS')]
        [string]
        $Delivery,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edge-diagnostics/v1/estats"
    $Body = @{}
    if ($CPCode) { $Body['cpCode'] = $CPCode }
    if ($URL) { $Body['url'] = $URL }
    if ($ErrorType) { $Body['errorType'] = $ErrorType }
    if ($Delivery) { $Body['delivery'] = $Delivery }
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


function Get-EdgeDiagnosticsErrorTranslation {
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

    $Path = "/edge-diagnostics/v1/error-translator/requests/$RequestID"
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


function Get-EdgeDiagnosticsGrep {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
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

    $Path = "/edge-diagnostics/v1/grep/requests/$RequestID"
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


function Get-EdgeDiagnosticsGroup {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter()]
        [switch]
        $IncludeCurl,

        [Parameter()]
        [switch]
        $IncludeDig,

        [Parameter()]
        [switch]
        $IncludeMTR,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    if ($GroupID) {
        $Path = "/edge-diagnostics/v1/user-diagnostic-data/groups/$GroupID/records"
        $QueryParameters = @{
            'includeCurl' = $PSBoundParameters.IncludeCurl.IsPresent
            'includeDig'  = $PSBoundParameters.IncludeDig.IsPresent
            'includeMtr'  = $PSBoundParameters.IncludeMTR.IsPresent
        }
    }
    else {
        $Path = "/edge-diagnostics/v1/user-diagnostic-data/groups"
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
    if ($GroupID) {
        return $Response.Body
    }
    else {
        return $Response.Body.groups
    }
}


function Get-EdgeDiagnosticsGTMProperties {
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

    $Path = "/edge-diagnostics/v1/gtm/gtm-properties"
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
    return $Response.Body.gtmProperties
}


function Get-EdgeDiagnosticsGTMPropertyIPs {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Domain,
        
        [Parameter(Mandatory)]
        [string]
        $Property,
        
        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edge-diagnostics/v1/gtm/$Property/$Domain/gtm-property-ips"
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
    return $Response.Body.gtmPropertyIps
}


function Get-EdgeDiagnosticsIPAHostnames {
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

    $Path = "/edge-diagnostics/v1/ipa/hostnames"
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
    return $Response.Body.hostnames
}


function Get-EdgeDiagnosticsLocations {
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

    $Path = "/edge-diagnostics/v1/edge-locations"
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
    return $Response.Body.edgeLocations
}


function Get-EdgeDiagnosticsLogs {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $EdgeIP,

        [Parameter(Mandatory)]
        [int]
        $CPCode,

        [Parameter()]
        [string]
        $ClientIP,

        [Parameter()]
        [string]
        $ObjectStatus,

        [Parameter()]
        [string]
        $HttpStatusCode,

        [Parameter()]
        [string]
        $UserAgent,

        [Parameter()]
        [string]
        $ARL,

        [Parameter()]
        [string]
        $Start,

        [Parameter(Mandatory)]
        [string]
        $End,

        [Parameter()]
        [ValidateSet('R', 'F')]
        [string]
        $LogType,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $ISO8601Match = '[\d]{4}-[\d]{2}-[\d]{2}(T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?)?'
    if ($Start) {
        if ($Start -notmatch $ISO8601Match) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
        }
    }
    if ($End) {
        if ($End -notmatch $ISO8601Match) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
        }
    }

    $Path = "/edge-diagnostics/v1/grep"
    $QueryParameters = @{
        'edgeIp'         = $EdgeIP
        'cpCode'         = $PSBoundParameters.CPCode
        'clientIp'       = $ClientIP
        'objectStatus'   = $ObjectStatus
        'httpStatusCode' = $HTTPStatusCode
        'userAgent'      = $UserAgent
        'arl'            = $ARL
        'start'          = $Start
        'end'            = $End
        'logType'        = $LogType
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


function Get-EdgeDiagnosticsMetadataTrace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $RequestID,

        [Parameter()]
        [switch]
        $HTMLFormat,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edge-diagnostics/v1/metadata-tracer/requests/$RequestID"
    if ($HTMLFormat) {
        $AdditionalHeaders = @{
            'Accept' = 'text/html'
        }
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


function Get-EdgeDiagnosticsMetadataTraceLocations {
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

    $Path = "/edge-diagnostics/v1/metadata-tracer/locations"
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
    return $Response.Body.mdtLocations
}


function Get-EdgeDiagnosticsURLHealthCheck {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RequestID,
        
        [Parameter()]
        [switch]
        $IncludeContentResponseBody,
        
        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edge-diagnostics/v1/url-health-check/requests/$RequestID"
    $QueryParameters = @{
        'includeContentResponseBody' = $PSBoundParameters.IncludeContentResponseBody.IsPresent
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


function Get-EdgeDiagnosticsURLTranslation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $URL,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edge-diagnostics/v1/translated-url"
    $Body = @{
        url = $URL
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
    return $Response.Body.translatedUrl
}


function New-EdgeDiagnosticsConnectivityProblem {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $URL,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $ClientIP,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $EdgeLocationID,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('IPV4', 'IPV6')]
        [string]
        $IPVersion,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('TCP', 'ICMP')]
        [string]
        $PacketType,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet(80, 443)]
        [int]
        $Port,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $RunFromSiteshield,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $SensitiveRequestHeaderKeys,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $SpoofEdgeIP,

        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'Body')]
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
        $Path = "/edge-diagnostics/v1/connectivity-problems"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'url' = $URL
            }

            if ($ClientIP) { $Body['clientIp'] = $ClientIP }
            if ($EdgeLocationID) { $Body['edgeLocationId'] = $EdgeLocationID }
            if ($IPVersion) { $Body['ipVersion'] = $IPVersion }
            if ($PacketType) { $Body['packetType'] = $PacketType }
            if ($null -ne $PSBoundParameters.Port) { $Body['port'] = $Port }
            if ($RequestHeaders) { $Body['requestHeaders'] = $RequestHeaders }
            if ($RunFromSiteshield) { $Body['runFromSiteShield'] = 'true' }
            if ($SensitiveRequestHeaderKeys) { $Body['sensitiveRequestHeaderKeys'] = $SensitiveRequestHeaderKeys }
            if ($SpoofEdgeIP) { $Body['spoofEdgeIp'] = $SpoofEdgeIP }
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


function New-EdgeDiagnosticsContentProblem {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $URL,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $EdgeLocationID,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('IPV4', 'IPV6')]
        [string]
        $IPVersion,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $RunFromSiteshield,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $SensitiveRequestHeaderKeys,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $SpoofEdgeIP,

        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'Body')]
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
        $Path = "/edge-diagnostics/v1/content-problems"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'url' = $URL
            }

            if ($EdgeLocationID) { $Body['edgeLocationId'] = $EdgeLocationID }
            if ($IPVersion) { $Body['ipVersion'] = $IPVersion }
            if ($RequestHeaders) { $Body['requestHeaders'] = $RequestHeaders }
            if ($RunFromSiteshield) { $Body['runFromSiteShield'] = 'true' }
            if ($SensitiveRequestHeaderKeys) { $Body['sensitiveRequestHeaderKeys'] = $SensitiveRequestHeaderKeys }
            if ($SpoofEdgeIP) { $Body['spoofEdgeIp'] = $SpoofEdgeIP }
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


function New-EdgeDiagnosticsCurl {
    [CmdletBinding(DefaultParameterSetName = 'IP & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [string]
        $URL,

        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [ValidateSet('IPV4', 'IPV6')]
        [string]
        $IPVersion,

        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [string]
        $EdgeIP,

        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [string]
        $EdgeLocationID,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [string]
        $SpoofEdgeIP,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [string[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [switch]
        $RunFromSiteshield,

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
        $Path = "/edge-diagnostics/v1/curl"

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                url       = $URL
                ipVersion = $IPVersion
            }

            if ($EdgeIP) {
                $Body['edgeIp'] = $EdgeIP
            }

            if ($EdgeLocationID) {
                $Body['edgeLocationId'] = $EdgeLocationID
            }

            if ($SpoofEdgeIP) {
                $Body['spoofEdgeIP'] = $SpoofEdgeIP
            }

            if ($RequestHeaders) {
                $Body['requestHeaders'] = $RequestHeaders
            }

            if ($RunFromSiteshield) {
                $Body['runFromSiteshield'] = $true
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


function New-EdgeDiagnosticsDig {
    [CmdletBinding(DefaultParameterSetName = 'IP & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [ValidateSet('A', 'AAAA', 'SOA', 'CNAME', 'PTR', 'MX', 'NS', 'TXT', 'SRV', 'CAA', 'ANY')]
        [string]
        $QueryType = 'ANY',

        [Parameter(ParameterSetName = 'IP & attributes')]
        [string]
        $EdgeIP,

        [Parameter(ParameterSetName = 'Location & attributes')]
        [string]
        $EdgeLocationID,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [switch]
        $IsGTMHostname,

        [Parameter(Mandatory, ParameterSetName = 'Body')]
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
        $Path = "/edge-diagnostics/v1/dig"

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'hostname'      = $Hostname
                'queryType'     = $QueryType
                'isGtmHostname' = $IsGTMHostname.IsPresent
            }

            if ($EdgeIP) {
                $Body['edgeIp'] = $EdgeIP
            }

            if ($EdgeLocationID) {
                $Body['edgeLocationId'] = $EdgeLocationID
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


function New-EdgeDiagnosticsErrorTranslation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $ErrorCode,

        [Parameter()]
        [switch]
        $TraceForwardLogs,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/edge-diagnostics/v1/error-translator"
    $Body = @{
        'errorCode'        = $ErrorCode
        'traceForwardLogs' = $TraceForwardLogs.IsPresent
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


function New-EdgeDiagnosticsESIDebug {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $URL,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $ClientIP,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $ClientRequestHeaders,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $OriginServer,

        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'Body')]
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
        $Path = "/edge-diagnostics/v1/esi-debugger-api/v1/debug"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'url' = $URL
            }

            if ($ClientIP) { $Body['clientIp'] = $ClientIP }
            if ($ClientRequestHeaders) {
                $Body['clientRequestHeaders'] = @{}
                foreach ($Header in $ClientRequestHeaders) {
                    $SplitHeader = $Header.Split(":", 2)
                    if ($SplitHeader.Count -eq 2) {
                        $HeaderName = $SplitHeader[0].Trim()
                        $HeaderValue = $SplitHeader[1].Trim()
                        $Body['clientRequestHeaders'][$HeaderName] = $HeaderValue
                    }
                    else {
                        Write-Warning "Invalid header format: '$Header'. Expected format is 'Header-Name: Header Value'. Skipping this header."
                    }
                }
            }
            if ($OriginServer) { $Body['originServer'] = $OriginServer }
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


function New-EdgeDiagnosticsGrep {
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
        $Path = "/edge-diagnostics/v1/grep"
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


function New-EdgeDiagnosticsLink {
    [CmdletBinding(DefaultParameterSetName = 'URL & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'URL & attributes')]
        [string]
        $URL,

        [Parameter(Mandatory, ParameterSetName = 'IPA & attributes')]
        [string]
        $IPAHostname,

        [Parameter(ParameterSetName = 'URL & attributes')]
        [Parameter(ParameterSetName = 'IPA & attributes')]
        [string]
        $Note,

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
        $Path = "/edge-diagnostics/v1/user-diagnostic-data/groups"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{}
            if ($URL) {
                $Body['url'] = $URL
            }
            if ($IPAHostname) {
                $Body['ipaHostname'] = $IPAHostname
            }
            if ($Note) {
                $Body['note'] = $Note
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


function New-EdgeDiagnosticsMetadataTrace {
    [CmdletBinding(DefaultParameterSetName = 'IP & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [string]
        $URL,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [ValidateSet('HEAD', 'POST', 'GET')]
        [string]
        $HTTPMethod,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [string]
        $EdgeIP,

        [Parameter(ParameterSetName = 'Location & attributes')]
        [string]
        $MDTLocationID,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [string[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [string[]]
        $SensitiveRequestHeaderKeys,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [switch]
        $UseStaging,

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
        $Path = "/edge-diagnostics/v1/metadata-tracer"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'url'        = $URL
                'useStaging' = $UseStaging.IsPresent
            }

            if ($HTTPMethod) { $Body['httpMethod'] = $HTTPMethod }
            if ($EdgeIP) { $Body['edgeIp'] = $EdgeIP }
            if ($MDTLocationID) { $Body['mdtLocationId'] = $MDTLocationID }
            if ($RequestHeaders) {
                $Body['requestHeaders'] = $RequestHeaders
            }
            if ($SensitiveRequestHeaderKeys) {
                $Body['sensitiveRequestHeaderKeys'] = $SensitiveRequestHeaderKeys
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

function New-EdgeDiagnosticsMTR {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Destination,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('IP', 'HOST')]
        [string]
        $DestinationType,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('ICMP', 'TCP')]
        [string]
        $PacketType,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet(80, 443)]
        [int]
        $Port,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $ResolveDNS,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $ShowIPs,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $ShowLocations,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $SiteShieldHostname,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Source,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('EDGE_IP', 'LOCATION')]
        [string]
        $SourceType,

        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'body')]
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
        $Path = "/edge-diagnostics/v1/mtr"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'destination'     = $Destination
                'destinationType' = $DestinationType
                'packetType'      = $PacketType
                'resolveDns'      = $ResolveDNS.IsPresent
                'showIps'         = $ShowIPs.IsPresent
                'showLocations'   = $ShowLocations.IsPresent
            }

            if ($Port) { $Body['port'] = $Port }
            if ($SiteShieldHostname) { $Body['siteShieldHostname'] = $SiteShieldHostname }
            if ($Source) { $Body['source'] = $Source }
            if ($SourceType) { $Body['sourceType'] = $SourceType }
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


function New-EdgeDiagnosticsURLHealthCheck {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $URL,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $EdgeLocationID,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('IPV4', 'IPV6')]
        [string]
        $IPVersion,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('TCP', 'ICMP')]
        [string]
        $PacketType,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet(80, 443)]
        [int]
        $Port,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('A', 'AAAA', 'SOA', 'CNAME', 'PTR', 'MX', 'NS', 'TXT', 'SRV', 'CAA', 'ANY')]
        [string]
        $QueryType,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $RunFromSiteshield,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $SensitiveRequestHeaderKeys,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $SpoofEdgeIP,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $ViewsAllowed,

        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'Body')]
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
        $Path = "/edge-diagnostics/v1/url-health-check"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'url' = $URL
            }

            if ($EdgeLocationID) { $Body['edgeLocationId'] = $EdgeLocationID }
            if ($IPVersion) { $Body['ipVersion'] = $IPVersion }
            if ($PacketType) { $Body['packetType'] = $PacketType }
            if ($null -ne $PSBoundParameters.Port) { $Body['port'] = $Port }
            if ($QueryType) { $Body['queryType'] = $QueryType }
            if ($RequestHeaders) { $Body['requestHeaders'] = $RequestHeaders }
            if ($RunFromSiteshield) { $Body['runFromSiteShield'] = 'true' }
            if ($SensitiveRequestHeaderKeys) { $Body['sensitiveRequestHeaderKeys'] = $SensitiveRequestHeaderKeys }
            if ($SpoofEdgeIP) { $Body['spoofEdgeIp'] = $SpoofEdgeIP }
            if ($ViewsAllowed) { $Body['viewsAllowed'] = $ViewsAllowed }
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


function Test-EdgeDiagnosticsIP {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $IPAddress,
        
        [Parameter()]
        [switch]
        $IncludeLocation,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    if ($IncludeLocation) {
        $Path = "/edge-diagnostics/v1/verify-locate-ip"
        if ($IPAddress.Count -gt 1) {
            throw "Only one IP address can be included when using the -IncludeLocation switch."
        }
        $Body = @{
            'ipAddress' = $IPAddress[0]
        }
    }
    else {
        $Path = "/edge-diagnostics/v1/verify-edge-ip"
        $Body = @{
            'ipAddresses' = $IPAddress
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



# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAELE1uka33PZPy
# 4psSaw4KBYN85yc5imVdvSsywEKfV6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJom1ZVRwNIPmUReTvk7agL1U1FL7Bp3
# mIjoXXdg5wi5MA0GCSqGSIb3DQEBAQUABIIBgH4RxvODQ/L5YhtCzt7YQ05Ex+kK
# ki5QXUvKfGKafV0S0EqP3xqDpT1Z3DobTPyzCv0q3yS7mWldQ9dm4FJq4TPtIXP0
# 9e4I0ob1lIPBl+y9QIOYl7gCEIfbFyYT1+HShwB09rub07ANH89TutBCM1fi5QOx
# ZcZFE/j3KeL2FWxuyds4e5R1TliEpBTfXQ0/o5SqULt6w9JAEOYLhxTGFw+QhVUk
# Dj3+VTNh6Dc5XxmNZbOgtQ87jYmP4Cgdqbd8bnuFxY7N1s3Bo7LaJ5AnXCJvpRCk
# 5zAWCW03F1XW36E9Km/y/1Abwjvuhgzv8N9WiwRlszMLmbjyUICYLKGPSRGITJL8
# bemI0mOOjsdGPPXy3EsRU2o5oe7LxcY1D/N0x2LDohFvV4/yzYq0KcuhcbAZeCUR
# jqj+8rW5xX4Ql+VAvjiwoj65R/JU7yB1n+SgWJx7yrWnOODwqztxH+A6XuunvZga
# 1r+gi9S4OQ0ZbToQLdlIOiDTPlOn7RoHqhSqVg==
# SIG # End signature block
