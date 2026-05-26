function ConvertFrom-Base64 {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $EncodedString
    )

    Write-Debug "Decoding '$EncodedString'"
    try {
        $DecodedString = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedString))
        return $DecodedString
    }
    catch {
        Write-Debug "Error decoding '$EncodedString'"
        Write-Debug $_
        return $EncodedString
    }
}

function Format-SIEMEvent {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [object]
        $SIEMEvent
    )

    $AttackDataAttributes = @(
        'rules',
        'ruleVersions',
        'ruleMessages',
        'ruleTags',
        'ruleData',
        'ruleSelectors',
        'ruleActions'
    )

    $httpMessageAttributes = @(
        'query',
        'requestHeaders',
        'responseHeaders'
    )

    $AttackDataAttributes | ForEach-Object {
        Write-Debug "Parsing $_"
        ### Encoded data sometimes contains pluses (+) which should not be decoded
        $PlusSafeString = $SIEMEvent.attackData.$_.Replace("+", "%2b")
        $URLdecodedString = [System.Net.WebUtility]::UrlDecode($PlusSafeString)
        $Entries = $URLdecodedString -split ";"
        foreach ($Entry in $Entries) {
            if ($Entry -ne '') {
                $DecodedEntry = ConvertFrom-Base64 -EncodedString $Entry
                $URLdecodedString = $URLdecodedString.Replace($Entry, $DecodedEntry)
            }
        }
        $SIEMEvent.attackData.$_ = $URLdecodedString
    }

    $httpMessageAttributes | ForEach-Object {
        if ($SIEMEvent.httpMessage.$_) {
            Write-Debug "Parsing $_"
            $URLdecodedString = [System.Net.WebUtility]::UrlDecode($SIEMEvent.httpMessage.$_)
            $SIEMEvent.httpMessage.$_ = $URLdecodedString -split "`n" | Where-Object { $_ -ne '' }
        }
    }

    return $SIEMEvent
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

function Get-SIEMData {
    [CmdletBinding(DefaultParameterSetName = 'Offset')]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Mandatory, ParameterSetName = 'Offset')]
        [string]
        $Offset,

        [Parameter(Mandatory, ParameterSetName = 'Time period')]
        [int]
        $From,

        [Parameter(ParameterSetName = 'Time period')]
        [int]
        $To,

        [Parameter()]
        [int]
        $Limit,

        [Parameter()]
        [switch]
        $Decode,

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
        $Path = "/siem/v1/configs/$ConfigID"
        $QueryParameters = @{
            'offset' = $PSBoundParameters.offset
            'limit'  = $PSBoundParameters.limit
            'from'   = $PSBoundParameters.from
            'to'     = $PSBoundParameters.to
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

        $SIEMEvents = New-Object -TypeName System.Collections.ArrayList
        $Output = New-Object -TypeName PSCustomObject

        ### Invoke-RestMethod doesn't handle the json due to it being multiple objects, so we split on line breaks, then convert to objects in an array
        if ($Response.Body -is "String") {
            ## Parse out empty last line
            if ($Response.Body.EndsWith("`n")) {
                $Response.Body = $Response.Body.SubString(0, ($Response.Body.Length - 1))
            }
            $ResponseArray = $Response.Body -split "`n"
            $ResponseContext = $ResponseArray[-1] | ConvertFrom-Json -Depth 100

            if ($ResponseArray.count -gt 1) {
                $UnprocessedEvents = $ResponseArray[0..($ResponseArray.Count - 2)]
                foreach ($JSONEvent in $UnprocessedEvents) {
                    $SIEMEvent = $JSONEvent | ConvertFrom-Json -Depth 100
                    if ($Decode) {
                        ## Call parsing function to url and base64-decode event members
                        $ParsedEvent = Format-SIEMEvent -SIEMEvent $SIEMEvent
                        $SIEMEvents.Add($ParsedEvent) | Out-Null
                    }
                    else {
                        $SIEMEvents.Add($SIEMEvent) | Out-Null
                    }
                }
            }
            else {
                $SIEMEvents = $null
            }

            $Output | Add-Member -MemberType NoteProperty -Name "Events" -Value $SIEMEvents
            $Output | Add-Member -MemberType NoteProperty -Name "ResponseContext" -Value $ResponseContext
        }
        else {
            $Output | Add-Member -MemberType NoteProperty -Name "Events" -Value $null
            $Output | Add-Member -MemberType NoteProperty -Name "ResponseContext" -Value $Response.Body
        }

        return $Output
    }
}

# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCWSxKfTrBAkCha
# j3rzlB0LGd8gpornTH/8ogkQiO6p/aCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF422iA4ak+oOhiTKpb4wNnFG7wWI0Yu
# /X6khrM9ovqqMA0GCSqGSIb3DQEBAQUABIIBgHzy1rSqujhtIYY1wmN4ArfoauJh
# +E8GwaZjicqCaGha7MNWuolkxR8XMmyrD+hLNOyqwXhBLh2+iUfVgeQ9mdBC+00m
# jBvcvoyPg92vEUsF4CmdYPq3PpmZPpYe3nZNStH06dZfdi7NB9KpeUU4eKx92Y8d
# /qfyO+NEMYvTPYlyxQCVsm/pWUyfDfgVs161XUuvYOUOOqeNzHrVMoqlYG4rFLWn
# eOBK7q6d38lSE84S7VDeESE1AI5UFuWfoJvJwNENs81xLQCrZ/m5/i3DLkhIGVZ7
# DWXD50qjK0xdFrKl2M0CRmHnQDoPiXLsoNnxybybz7SvbH0Wyj1j0Fx+9ogv/lsY
# lF32dmUWLXARJcqFQ5qXFAmiphPPN8C3M6WUyA57DA+/CiZWmH1Vvlmwb9c0fd61
# ZVt8EG5cjUdKcIdS/NTo6248tAPaZe0ldKZ8CW0TSlVp1NUO0DogmGiwGVK9VpDP
# JPRkk9WZWgTimo18N2KVjLssi8KPw8m62oVLbg==
# SIG # End signature block
