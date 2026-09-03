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

function Get-LegacyReport {
    [CmdletBinding(DefaultParameterSetName = 'Get by IDs')]
    Param(

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Version,

        [Parameter(Mandatory)]
        [String]
        $Start,

        [Parameter(Mandatory)]
        [String]
        $End,

        [Parameter(ParameterSetName = 'Get by IDs')]
        [String[]]
        $ObjectIDs,

        [Parameter(ParameterSetName = 'Get all IDs')]
        [Switch]
        $AllObjectIDs,

        [Parameter(Mandatory)]
        [ValidateSet("FIVE_MINUTES", "HOUR", "DAY", "WEEK", "MONTH")]
        [String]
        $Interval,

        [Parameter()]
        [String]
        $Filters,

        [Parameter()]
        [String[]]
        $Metrics,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $ISO8601Match = '^[\d]{4}-[\d]{2}-[\d]{2}(T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?)?$'
        if ($Start -notmatch $ISO8601Match -or $End -notmatch $ISO8601Match) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
        }

        $Path = "/reporting-api/v1/reports/$Name/versions/$Version/report-data"

        $QueryParameters = @{
            'start'        = $Start
            'end'          = $End
            'interval'     = $Interval
            'allObjectIds' = $PSBoundParameters.AllObjectIDs
            'filters'      = $Filters
            'metrics'      = ($Metrics -join ',')
            'objectIds'    = ($ObjectIds -join ',')
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
function Get-LegacyReportType {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Get one')]
        [String]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Get one')]
        [String]
        $Version,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $ShowDeprecated,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $ShowUnavailable,

        [Parameter()]
        [string]
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
            $Path = "/reporting-api/v1/reports/$Name/versions/$Version"
        }
        else {
            $Path = "/reporting-api/v1/reports"
            $QueryParameters = @{
                'showDeprecated'  = $PSBoundParameters.ShowDeprecated
                'showUnavailable' = $PSBoundParameters.ShowUnavailable
            }
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
function Get-LegacyReportTypeVersions {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [switch]
        $ShowDeprecated,

        [Parameter()]
        [switch]
        $ShowUnavailable,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/reporting-api/v1/reports/$Name/versions"
        $QueryParameters = @{
            'showDeprecated'  = $PSBoundParameters.ShowDeprecated
            'showUnavailable' = $PSBoundParameters.ShowUnavailable
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
function Get-Report {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Report,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ProductFamily,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ReportingArea,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $QueryID,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Path = "/reporting-api/v2/reports/$ProductFamily/$ReportingArea/$Report/queries/$QueryID"

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

        if ($Response.Status -eq 303) {
            Write-Warning "Reporting pending. Please try again in a few seconds."
            return
        }

        return $Response.Body
    }
}
function Get-ReportingArea {
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
        $CommonParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        $Reports = Get-ReportType @CommonParams
        return $Reports.ReportingArea | Sort-Object -Unique
    }
}
function Get-ReportProductFamily {
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
        $CommonParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        $Reports = Get-ReportType @CommonParams
        return $Reports.ProductFamily | Sort-Object -Unique
    }
}
function Get-ReportType {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ProductFamily,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ReportingArea,
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Report,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        # Throw error for bad parameter combinations
        if ($Report -and -not ($ProductFamily -and $ReportingArea)) {
            throw "Report parameter requires ProductFamily and ReportingArea parameters."
        }
        if ($ReportingArea -and -not $ProductFamily) {
            throw "ReportingArea parameter requires ProductFamily parameter."
        }

        $Path = "/reporting-api/v2/reports"
        if ($ProductFamily) {
            $Path = "/reporting-api/v2/reports/$ProductFamily"
            if ($ReportingArea) {
                $Path = "/reporting-api/v2/reports/$ProductFamily/$ReportingArea"
                if ($Report) {
                    $Path = "/reporting-api/v2/reports/$ProductFamily/$ReportingArea/$Report"
                }
            }
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

        if ($Report) {
            return $Response.body
        }
        else {
            foreach ($ResponseReport in $Response.body.reports) {
                $LinkElements = $ResponseReport.reportLink -Split "/"
                $ResponseReport | Add-Member -MemberType NoteProperty -Name "ProductFamily" -Value $LinkElements[4]
                $ResponseReport | Add-Member -MemberType NoteProperty -Name "ReportingArea" -Value $LinkElements[5]
                $ResponseReport | Add-Member -MemberType NoteProperty -Name "Report" -Value $LinkElements[6]
            }
            return $Response.body.reports
        }
    }
}

function New-LegacyReport {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [int]
        $Version,

        [Parameter(Mandatory)]
        [String]
        $Start,

        [Parameter(Mandatory)]
        [String]
        $End,

        [Parameter()]
        [String]
        $DataWrapLabel,

        [Parameter()]
        [int]
        $DataWrapNumberOfItems,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string[]]
        $ObjectIDs,

        [Parameter(Mandatory)]
        [ValidateSet('FIVE_MINUTES', 'HOUR', 'DAY', 'WEEK', 'MONTH')]
        [String]
        $Interval,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Filters,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Metrics,

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
        $ISO8601Match = '^[\d]{4}-[\d]{2}-[\d]{2}(T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?)?$'
        if ($Start -notmatch $ISO8601Match -or $End -notmatch $ISO8601Match) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
        }

        $Path = "/reporting-api/v1/reports/$Name/versions/$Version/report-data"
        $QueryParameters = @{
            'start'                 = $Start
            'end'                   = $End
            'interval'              = $Interval
            'dataWrapLabel'         = $DataWrapLabel
            'dataWrapNumberOfItems' = $PSBoundParameters.DataWrapNumberOfItems
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'objectIds' = $ObjectIds
            }
            if ($Metrics) { $Body['metrics'] = $Metrics }
            if ($Filters) {
                $Body['filters'] = @{}
                $Filters | ForEach-Object {
                    $Key, $Value = $_.Split('=', 2)
                    if (-not $key -or -not $Value) {
                        throw "ERROR: Filters must be in the format 'filterName=filterValue'"
                    }
                    if ($Key -in $Body['filters'].Keys) {
                        # If the filter already exists, convert to array or append to existing array
                        $Body['filters'][$Key] += $Value
                    }
                    else {
                        $Body['filters'][$Key] = @($Value)
                    }
                }
            }
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
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
function New-Report {
    [CmdletBinding(DefaultParameterSetName = 'Time range')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Report,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ProductFamily,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ReportingArea,

        [Parameter(Mandatory, ParameterSetName = 'Date range')]
        [String]
        $Start,

        [Parameter(Mandatory, ParameterSetName = 'Date range')]
        [String]
        $End,

        [Parameter(Mandatory, ParameterSetName = 'Time range')]
        [string]
        [ValidateSet("LAST_15_MINUTES", "LAST_30_MINUTES", "LAST_1_HOUR", "LAST_3_HOURS", "LAST_6_HOURS", "LAST_12_HOURS", "LAST_1_DAY", "LAST_2_DAYS", "LAST_1_WEEK", "LAST_30_DAYS", "LAST_90_DAYS")]
        $TimeRange,

        [Parameter()]
        $Body,

        [Parameter()]
        [switch]
        $Async,

        [Parameter()]
        [int]
        $PageSize = 50000,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Date range') {
            $ISO8601Match = '^[\d]{4}-[\d]{2}-[\d]{2}(T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?)?$'
            if ($Start -notmatch $ISO8601Match -or $End -notmatch $ISO8601Match) {
                throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
            }
        }

        $Path = "/reporting-api/v2/reports/$ProductFamily/$ReportingArea/$Report/data"

        $QueryParameters = @{
            'start'     = $Start
            'end'       = $End
            'timeRange' = $TimeRange
            'async'     = $Async
            'pageSize'  = $PageSize
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Handle 303 response, which does not error in PS5.1
            if ($Response.Status -eq 303) {
                $QueryID = $Response.Headers.Location | Where-Object { $_ -Match '\/queries\/([^\?]+)' }
                $QueryID = $matches[1]
                $Response = [PSCustomObject] @{
                    QueryID       = $QueryID
                    ProductFamily = $ProductFamily
                    ReportingArea = $ReportingArea
                    Report        = $Report
                }
                return $Response
            }

            return $Response.body
        }
        catch {
            if ([int]$_.Exception.Response.StatusCode -eq 303) {
                $QueryID = $_.Exception.Response.Headers.Location | Where-Object { $_ -Match '\/queries\/([^\?]+)' }
                $QueryID = $matches[1]
                $Response = [PSCustomObject] @{
                    QueryID       = $QueryID
                    ProductFamily = $ProductFamily
                    ReportingArea = $ReportingArea
                    Report        = $Report
                }
                return $Response
            }

            else {
                throw $_
            }
        }
    }
}

# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1dpo5qdU0pvRi
# fS++OemYJHUuN71uVlO8yt0WgfRH06CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICDeNMiCjnmtKal1RyrN3WhNfcB1LJ7d
# WGAYzcd1mYkqMA0GCSqGSIb3DQEBAQUABIIBgC07Qjf3EBEEbGLYQnZHQbJKTvM5
# PF4QLktEUN3SpUW/+dMcsi9nGsgzE0Kkk6jXl6jOemzQemWngQMpmU/mjA4mz1Z0
# zhmo9q0Py+Zsxi8eW0q0PfhSRwrYppqNO9TgPtk197w3L42Colw8INxHHkd846f9
# YsPriF6m450ve+eJq1wrOGglf5AUxgEOLiMWjX7aHh99ltaZuKy9NrNpDMl+mBwn
# 6ZxEyFZnbaKJrfou/2ZmUxya0aBZTGqxOLqEqLiSYE8k8TuBF297SsL4zrOg1jyN
# WihqJ2wIz6i31DAWMYlFwe/PPpOMZXdQAn3YBc7AglS6K9hgzVxC0UkO/Ni80AH+
# YA+jJLeq0xY5JA6mvUAS6bbzcKgIoqFwsYsLWqzgicdfMOwsXaHxDavnaIFgLfE6
# thFH0JDZlNAOaSjdGPah/i2l2JZDeIeVZ7PT5jDOCwYERF5m/zh873c/jky4stvb
# wUaYdFauk8EwXdpmAj7QZbXF9pcFICBdJVbC1A==
# SIG # End signature block
