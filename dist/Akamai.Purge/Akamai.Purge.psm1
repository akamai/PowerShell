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

function Clear-AkamaiCache {
    [CmdletBinding(DefaultParameterSetName = 'URL')]
    Param(
        [Parameter(ParameterSetName = 'URL', Mandatory)]
        [string[]]
        $URLs,

        [Parameter(ParameterSetName = 'CP code', Mandatory)]
        [int[]]
        $CPCodes,

        [Parameter(ParameterSetName = 'Tag', Mandatory)]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateSet('invalidate', 'delete')]
        [string]
        $Method = 'invalidate',

        [Parameter()]
        [ValidateSet('staging', 'production')]
        [string]
        $Network = 'production',

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'URL') {
            $Objects = $URLs
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'CP code') {
            $Objects = $CPCodes
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Tag') {
            $Objects = $Tags
        }
        $Body = @{ 'objects' = $Objects }

        # Construct request path
        $Method = $Method.ToLower()
        $Network = $Network.ToLower()
        switch ($PSCmdlet.ParameterSetName) {
            'URL' {
                switch ($Method) {
                    'invalidate' {
                        $Path = "/ccu/v3/invalidate/url/$Network"
                    }
                    'delete' {
                        $Path = "/ccu/v3/delete/url/$Network"
                    }
                }
            }
            'CP code' {
                switch ($Method) {
                    'invalidate' {
                        $Path = "/ccu/v3/invalidate/cpcode/$Network"
                    }
                    'delete' {
                        $Path = "/ccu/v3/delete/cpcode/$Network"
                    }
                }
            }
            'Tag' {
                switch ($Method) {
                    'invalidate' {
                        $Path = "/ccu/v3/invalidate/tag/$Network"
                    }
                    'delete' {
                        $Path = "/ccu/v3/delete/tag/$Network"
                    }
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
function Get-PurgeLimit {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('cpcode', 'url', 'tag')]
        [string]
        $PurgeType,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Path = "/ccu/v3/rate-limit-status/$PurgeType"
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

        # Add headers to body
        $RateLimitHeaders = $Response.Headers.Keys | Where-Object { $_ -match '^x-ratelimit' }
        foreach ($Header in $RateLimitHeaders) {
            $HeaderName = $Header -replace '^x-ratelimit-', ''
            $HeaderName = $HeaderName.Replace('-', '')
            $Response.Body | Add-Member -NotePropertyName $HeaderName -NotePropertyValue $Response.Headers[$Header][0]
        }
        return $Response.Body
    }
}

# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBrer9YuN+YyyJ2
# irkhTEpSD8vtWS4w7KrDe8EIxM49f6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJO772TIYWhCWttCq/fhVgPh3aXFZEa+
# AIJttEZFQ/LcMA0GCSqGSIb3DQEBAQUABIIBgG+Ti4zqRK8mYpz5CYPO99O6WYd+
# 8aDNpZK+PAhsuKByyqQfPhJ4lA3GfmePzndcH9dy4Vo1qJfW3S9rBM0PFLuyh/Pf
# 4jS5+vf6cWpJKxRmnae3DgWTqu5A2DxTaMeX0clDlyDzRnNFWpvc+DWN8/L5qgtc
# ilVz4uXGDkxMVO8Zh7gFsu+3dkL9vy0ubUCJ286V/i3PJLtxmkcjNMkbW8ELwb9C
# wKYbyr46wLOslFx9AnhngyCS+hxvf9IWw+QJO6gUVIKWaUb9U9qgU3vap4iQG3ii
# 1FoTq7Jqg4RT3SuVRsLwcdUlm55wuCka4b5jZGcz8yxo2ZJwk3MyuJdhYdi0mfS+
# RCv5CAfXw74+TxMwnIPu3dE0kT9j0uXZTg5OySmp4tSpZCVhEKVgIHRKmeQ+Fe1T
# TmxiB5VsdQozRLF5L0eTegPnRLOLxNjSJ/UrTolQ7PDVqH7BF4D/0ZfAXmlYM5Wu
# ZNGXc5nHjY/FfskOg5FC8hfNDc3YddCBTsjsRg==
# SIG # End signature block
