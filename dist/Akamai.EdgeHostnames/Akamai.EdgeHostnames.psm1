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

function Get-EdgeHostname {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Position = 0, ParameterSetName = 'Get one by ID', ValueFromPipeline)]
        [int]
        $EdgeHostnameID,

        [Parameter(ParameterSetName = 'Get one by components', Mandatory)]
        [string]
        $RecordName,

        [Parameter(ParameterSetName = 'Get all')]
        [Parameter(ParameterSetName = 'Get one by components', Mandatory)]
        [string]
        $DNSZone,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $ChinaCDNEnabled,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Comments,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CustomTarget,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsEdgeIPBindingEnabled,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Map,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $MapAlias,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $RecordNameSubstring,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $SecurityType,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $SlotNumber,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $TTL,

        [Parameter()]
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
        if ($EdgeHostnameID) {
            $Path = "/hapi/v1/edge-hostnames/$EdgeHostnameID"
        }
        else {
            $Path = "/hapi/v1/edge-hostnames"
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters = @{
                'chinaCdnEnabled'        = $PSBoundParameters.ChinaCDNEnabled
                'comments'               = $Comments
                'customTarget'           = $CustomTarget
                'dnsZone'                = $DNSZone
                'isEdgeIPBindingEnabled' = $PSBoundParameters.IsEdgeIPBindingEnabled
                'map'                    = $Map
                'mapAlias'               = $MapAlias
                'recordNameSubstring'    = $RecordNameSubstring
                'securityType'           = $SecurityType
                'slotNumber'             = $PSBoundParameters.SlotNumber
                'ttl'                    = $PSBoundParameters.TTL
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Get one by components') {
            $Path = "/hapi/v1/dns-zones/$DNSZone/edge-hostnames/$RecordName"
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
            return $Response.Body.edgeHostnames
        }
        else {
            return $Response.Body
        }
    }
}

function Get-EdgeHostnameCertificate {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RecordName,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $DNSZone,

        [Parameter()]
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
        $Path = "/hapi/v1/dns-zones/$DNSZone/edge-hostnames/$RecordName/certificate"
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

function Get-EdgeHostnameChangeRequest {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipeline)]
        [string]
        $ChangeID,

        [Parameter(ParameterSetName = 'Get one by components', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RecordName,

        [Parameter(ParameterSetName = 'Get one by components', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $DNSZone,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        [ValidateSet('PENDING')]
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

    process {
        if ($ChangeID) {
            $Path = "/hapi/v1/change-requests/$ChangeID"
        }
        else {
            $Path = "/hapi/v1/change-requests"
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters = @{
                'status' = $Status
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Get one by components') {
            $Path = "/hapi/v1/dns-zones/$DNSZone/edge-hostnames/$RecordName/change-requests"
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
        if ($ChangeID) {
            return $Response.Body
        }
        else {
            return $Response.Body.changeRequests
        }
    }
}

function Get-EdgeHostnameLocalizationData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        [ValidateSet('de_DE', 'en_US', 'es_ES', 'es_LA', 'fr_FR', 'it_IT', 'ja_JP', 'ko_KR', 'pt_BR', 'zh_CN', 'zh_TW')]
        $Language,

        [Parameter()]
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
        $Path = "/hapi/v1/i18n/$Language"
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
        return $Response.Body.hapi.problems
    }
}

function Get-EdgeHostnameProduct {
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
        $Path = "/hapi/v1/products/display-names"
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
        return $Response.Body.productDisplayNames
    }
}

function Remove-EdgeHostname {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $RecordName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $DNSZone,

        [Parameter()]
        [string]
        $Comments,

        [Parameter()]
        [string]
        $StatusUpdateEmail,

        [Parameter()]
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
        $Path = "/hapi/v1/dns-zones/$DNSZone/edge-hostnames/$RecordName"
        $QueryParameters = @{
            'comments'          = $Comments
            'statusUpdateEmail' = $StatusUpdateEmail
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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

function Set-EdgeHostname {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RecordName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $DNSZone,

        [Parameter(Mandatory)]
        [ValidateSet('ttl', 'ipVersionBehavior')]
        [string]
        $Attribute,

        [Parameter(Mandatory)]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Comments,

        [Parameter()]
        [string]
        $StatusUpdateEmail,

        [Parameter()]
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
        $Path = "/hapi/v1/dns-zones/$DNSZone/edge-hostnames/$RecordName"
        $QueryParameters = @{
            'comments'          = $Comments
            'statusUpdateEmail' = $StatusUpdateEmail
        }
        $AdditionalHeaders = @{
            'Content-Type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'replace'
                'path'  = "/$Attribute"
                'value' = $Value
            }
        )
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PATCH'
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
        return $Response.Body
    }
}


# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB+Wl+VeFmqYwEu
# 1NL9urofjkQpkXv4cg4G3EEdC7QZ5qCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILbWeGi+Jw2yGjpFk7mPE6mnfE4WnHq0
# FPDbgrvMmk78MA0GCSqGSIb3DQEBAQUABIIBgEbyMjQRrYXAbTrNzNOXe63aPwcv
# PncleVQ1XQ6b2tTZXFfTddpqdkHePRFZjqJU+3aX9h/6lt6OIoAIlqny1axO0zbx
# EfbHldSEIr/S24bB3eG70HxNBlAM+LShKXEx579XI6sqdLg+3rdSphxYBjz7gcD8
# XaRnQS610TfSgTYDW/JdEW5BuRzUXMDHdadnIADftNAFULl73MXUtdZI4INd1wLH
# yVrwP4dF7hmiquw7/H1YGeMNkEw40RlfCpsWlnXqiWOXCXm2SmKk91sAfDl95mK9
# jhNSy+7p/S5a8ex32vFq6OrxA9oosJIqneazgi06jtZOuB+nGQkDX/Bu2mVP3kvd
# 9pMkVkoH3jYfvrw0i5Ac+unxIJTM0L8ksmLn+QDg1kn9JoQuMbr2WXy3vultpvqo
# 4qTBruR6OO7XMpVhfVZDeFWDcu15hp4MeSSKDPtobSGDjXJVkrwTwwnroj5QXl5w
# tXJO/xToxKcbDs4QAE1dGk3YofWstJevtLHLaA==
# SIG # End signature block
