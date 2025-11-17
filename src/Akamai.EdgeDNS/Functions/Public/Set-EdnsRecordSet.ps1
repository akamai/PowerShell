function Set-EDNSRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'attributes', SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'attributes', Mandatory)]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'attributes', Mandatory)]
        [string]
        $TTL,

        [Parameter(ParameterSetName = 'attributes', Mandatory)]
        $RData,

        [Parameter(ParameterSetName = 'postbody', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $AutoIncrementSOA,

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
        $CollatedRecordSets = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        if ($Body -and $Body -isnot 'String') {
            if ($null -eq $Body.recordsets -and $null -ne $Body.name) {
                # If body has recordsets top-level object then it is not a piped array
                $CollatedRecordSets.Add($Body)
            }
        }
    }

    end {
        $Method = 'PUT'
        
        if ($PSCmdlet.ParameterSetName -eq 'attributes') {
            $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
            if ($RData -is [string]) { 
                $RData = $RData.Split(",")
            }

            if ($Type.ToLower() -eq 'txt') {
                for ($i = 0; $i -lt $RData.count; $i++) {
                    if ($RData[$i] -notmatch '^".*"$') {
                        $RData[$i] = "`"$($RData[$i])`""
                    }
                }
            } 
            
            $Body = @{
                'name'  = $Name
                'rdata' = $RData
                'ttl'   = $TTL
                'type'  = $Type
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'postbody') {
            $Path = "/config-dns/v2/zones/$Zone/recordsets"
            # Reconstruct from collated body
            if ($CollatedRecordSets.Count -gt 0) {
                $Body = @{ 'recordsets' = $CollatedRecordSets }
            }

            # Parse recordsets to handle data types and txt quoting
            foreach ($RecordSet in $Body.recordsets) {
                if ($RecordSet.RData -is [string]) {
                    $RecordSet.RData = $RecordSet.RData.Split(",")
                }
                if ($RecordSet.Type.ToLower() -eq 'txt') {
                    for ($i = 0; $i -lt $RecordSet.RData.count; $i++) {
                        if ($RecordSet.RData[$i] -notmatch '^".*"$') {
                            $RecordSet.RData[$i] = "`"$($RecordSet.RData[$i])`""
                        }
                    }
                }
            }

            # Fall back to single update URL if only 1 record is present
            if ($Body.recordsets.count -eq 1) {
                $Body = $Body.recordsets[0]
                $Name = $Body.name
                $Type = $Body.type
                $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
            }
        }

        if ($AutoIncrementSOA) {
            # Convert to object first, if not already
            $Body = Get-BodyObject -Source $Body
            $SOA = $Body.recordsets | Where-Object type -eq 'SOA'
            if ($SOA) {
                # Should be only one, but you never know
                $SOA | ForEach-Object {
                    # Again, should be only one, but let's not assume
                    for ($i = 0; $i -lt $_.rdata.count; $i++) {
                        $Components = $_.rdata[$i] -split ' '
                        $ExistingSerial = $Components[2]
                        $NewSerial = ([int] $ExistingSerial) + 1
                        $_.rdata[$i] = $_.rdata[$i].replace($ExistingSerial, $NewSerial)
                    }
                }
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }

        # Get confirmation if number of record sets is greater than 1
        if ($Body.recordsets) {
            if ($PSCmdlet.ShouldProcess("Replacing ALL recordsets in zone $Zone", "Are you sure you want to proceed?", "Updating more than one recordset with Set-EDNSRecordSet will result in replacing ALL recordsets in zone: $Zone")) {
                Write-Warning "Replacing all records in zone $Zone"
                $Response = Invoke-AkamaiRequest @RequestParams
            }
        }
        else {
            $Response = Invoke-AkamaiRequest @RequestParams
        }
        return $Response.Body
    }
}

# SIG # Begin signature block
# MIIp2QYJKoZIhvcNAQcCoIIpyjCCKcYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCD8y57WJvxJu3l
# dh1QaRx8AgOTGkoCDlbG4f2aL0kNcaCCDo4wggawMIIEmKADAgECAhAIrUCyYNKc
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
# yK+p/pQd52MbOoZWeE4wggfWMIIFvqADAgECAhAJS8amgSAG6MIweRq3uiU3MA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjUwNzAxMDAwMDAwWhcNMjYwMzA3
# MjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEDAOBgNV
# BAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRz
# MRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1haSBUZWNobm9sb2dp
# ZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVzIEluYzCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAMf1sSwHg7wzLGx81ZgJvrYMiCwYtKGv
# KNsDCkQsgYkqnuJYfiiRQ6kuk9RRUyqPLa9lLXa6xu6nBI8M6OzG9gxKNg7563G9
# 2P+lC1Gs6V8/uv5ZjzKwbKx3i40b4lHn+VeMNyooPZkzAjG9H8gNrCyCrk8FL7pL
# 1eOOPU1Hi3UWX9QHfBbI8HABRgyUPz7sNLDq0rRgcGIwvyIh5pqAoyBJE/HDXMCX
# ktktW+OMIIXXpSm9pcCVLT90etajQxCtH6LBV+CFDK/cxFeuDIyWdCR8DMC/oCdz
# ZoHbT3taOfN+lyMHUPWC8t7MkPg4OMqNG6nsF9yHDOAvL5h7PZe+npK/X4MYYsr1
# 7XFiak5H6hwiycQ8cVdPp+d0IeaQEnSqv5rI7IHc+V46sYmcmm/z5kvH9XWWD2VN
# Aj2Sdald4A9aipa143yG7yvyhmm/TCPco1QboXUuaZh6vpfH6u7mDFiQmOc15hw5
# Bc63ktDaGqHqujU2Fy9CGReZznEqrLv7jXNRuNyRnfc5oF2h8x8s2g0NaB3e3JVD
# l4utM2cYNe//akXajWRWWiEG21d2881vtRqyw/eE5fFDHJEdD633EBaLlkrn3K3x
# RoIhgsaEFUum9N43y1Cv3QVROED9jfTi5xTZnzSC36/uThhlJE+CFkEJeWGIrANx
# x3T+6/gEnQFZAgMBAAGjggICMIIB/jAfBgNVHSMEGDAWgBRoN+Drtjv4XxGG+/5h
# ewiIZfROQjAdBgNVHQ4EFgQUU+SbrrGchS0n0MB/su/rrjrMnMQwPQYDVR0gBDYw
# NDAyBgVngQwBAzApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNv
# bS9DUFMwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMIG1BgNV
# HR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMFOg
# UaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRD
# b2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDCBlAYIKwYBBQUHAQEE
# gYcwgYQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBcBggr
# BgEFBQcwAoZQaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcnQwCQYDVR0T
# BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAVV2MjlQ7ejh5cR4thBQn3dxFI8z6OSFP
# ZURget+GnxVXGUlX2Qe4aNDHTV6GXqb7+JFTuT68WnAe6aWifWr+WmpoNJ7uQxJH
# T5t8OW+nK+eXcZLxF3weAQbxwaImGcEC/LKUwYnGttEM6ZsaqIg7H96w4/egNN/V
# i3CrIn4ASbganOwnHRW02DIw0lE6KLWcxDdLx07nLJxrjyAfxQqV2mrnPC9kAIJe
# U98TlkTaAzro8OWjiPxdQQ0AVd17hGLsKsjA8nz8HlCB9RmtvQ1LeRtVpHM/A6jX
# lP1Cl1mi6HRfAbck1ymomvNwbhLqCHsdoNJUFjZuYRaGHdtLAt+NJkXr5E9kOwoJ
# Isiq1n+D60HX4jOZ8crR0RsG2cbz/UD917kjWWRBoY5r4OLnVwCpOpjcFDlun2Bq
# usQg+UNWp2Tr6K2MhDePbHTQ2NEbnM89LKLtYHjDoh/zIRGlFqBNwEdCXG6HiThj
# fiAm40DhwxwJN7KsN/BJbPlXsNUL0I9YWtxnluFkkwxzWuee5hkweO71qCFJaJHx
# fd2/AakHLAgHa7EoOBYlqnjgp+MIIu9Stoi8EhdjeZOCE2JmH/dOstP6TLF2HlZy
# pvVaxOMZ0L1syN5z7pebN9dJ1qEsSdPQgxqRijFvbXILCSPrkDl9GO69AEh2HiMe
# i8g8MkCqzXMxghqhMIIanQIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2Rl
# IFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEAlLxqaBIAbowjB5Gre6
# JTcwDQYJYIZIAWUDBAIBBQCgfDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAv
# BgkqhkiG9w0BCQQxIgQgW/5H6j4hvbHNZ/tcZLoZeIrkDE+DrjC5YcfZHiKqLBIw
# DQYJKoZIhvcNAQEBBQAEggIAp+Ssq0Bn2zbPLYw6AZah3Y4JS7RV0bCXB1rc4iOb
# tNePKDLV7g0++yDVePUPH9ydACnZtKa2p9Jy2AyiduwQ6krQ1f+PCb9vWG4z68qW
# 0EroPPo1TxwsR2OBqWBg1AihMDs/srXp5sAstG/7WrT5lchVzUt8dJ0LMDvwEjHb
# cC/SxNd34YfVSu4IElS5Bs/jaRa1UM5Mq5epydSHW6uBbumeuBliEuYDePuFtuYn
# vs5muE860H+rugcag/84dSe1H5JxL3LR9CI/OOV1qzZypIjU58U9NeBnl7a4kUUJ
# iOx4KiFOdBuLxSHyW2mrzQLw4slx57tqIZgm4sD1PzLOhmP/SdkiKrdzGe0TphX7
# YYFOONyneZ/VK084dgJUfeTjrUkK6YOE9Y3S07mWcgEQId2Hi59dVvrO+YyuaTHr
# DyXO0Vj6lndxd7ne8KTpPbBfTN6/t1XGDcFm/cFYg4iaNl24UkUCuSJYeAzSZ1KJ
# Sg8U2TVwohwEME/M5kd5jkZfqTGQKizpDXzV1OMxu/PFgHGhyLv0O0SLY2iw8sWJ
# YeNE6OFvCnt5l1gxRFxQZYML2vpi3NEuTkKZK3qNTUEfHXYH/9mmgO+BLhWTEErf
# kyjpEGfKCfEhUQkhJexbkJUfWsVNPEdDH4CfnAk7b9/u9MwZIycPNUFcb8GuxcQQ
# 5CWhghd3MIIXcwYKKwYBBAGCNwMDATGCF2MwghdfBgkqhkiG9w0BBwKgghdQMIIX
# TAIBAzEPMA0GCWCGSAFlAwQCAQUAMHgGCyqGSIb3DQEJEAEEoGkEZzBlAgEBBglg
# hkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgRxxOEi+uzdWV7CShxmaaMVnPs5W0
# JbG1z4BKGcMUjisCEQDPvHVUdn7sN9+qDtPdYHMmGA8yMDI1MTExNDAwNDUzMlqg
# ghM6MIIG7TCCBNWgAwIBAgIQCoDvGEuN8QWC0cR2p5V0aDANBgkqhkiG9w0BAQsF
# ADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hB
# MjU2IDIwMjUgQ0ExMB4XDTI1MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzEL
# MAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJE
# aWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUg
# MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANBGrC0Sxp7Q6q5gVrMr
# V7pvUf+GcAoB38o3zBlCMGMyqJnfFNZx+wvA69HFTBdwbHwBSOeLpvPnZ8ZN+vo8
# dE2/pPvOx/Vj8TchTySA2R4QKpVD7dvNZh6wW2R6kSu9RJt/4QhguSssp3qome7M
# rxVyfQO9sMx6ZAWjFDYOzDi8SOhPUWlLnh00Cll8pjrUcCV3K3E0zz09ldQ//nBZ
# ZREr4h/GI6Dxb2UoyrN0ijtUDVHRXdmncOOMA3CoB/iUSROUINDT98oksouTMYFO
# nHoRh6+86Ltc5zjPKHW5KqCvpSduSwhwUmotuQhcg9tw2YD3w6ySSSu+3qU8DD+n
# igNJFmt6LAHvH3KSuNLoZLc1Hf2JNMVL4Q1OpbybpMe46YceNA0LfNsnqcnpJeIt
# K/DhKbPxTTuGoX7wJNdoRORVbPR1VVnDuSeHVZlc4seAO+6d2sC26/PQPdP51ho1
# zBp+xUIZkpSFA8vWdoUoHLWnqWU3dCCyFG1roSrgHjSHlq8xymLnjCbSLZ49kPmk
# 8iyyizNDIXj//cOgrY7rlRyTlaCCfw7aSUROwnu7zER6EaJ+AliL7ojTdS5PWPsW
# eupWs7NpChUk555K096V1hE0yZIXe+giAwW00aHzrDchIc2bQhpp0IoKRR7YufAk
# prxMiXAJQ1XCmnCfgPf8+3mnAgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0G
# A1UdDgQWBBTkO/zyMe39/dfzkXFjGVBDz2GM6DAfBgNVHSMEGDAWgBTvb1NK6eQG
# fHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYB
# BQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEy
# NTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hB
# MjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcB
# MA0GCSqGSIb3DQEBCwUAA4ICAQBlKq3xHCcEua5gQezRCESeY0ByIfjk9iJP2zWL
# pQq1b4URGnwWBdEZD9gBq9fNaNmFj6Eh8/YmRDfxT7C0k8FUFqNh+tshgb4O6Lgj
# g8K8elC4+oWCqnU/ML9lFfim8/9yJmZSe2F8AQ/UdKFOtj7YMTmqPO9mzskgiC3Q
# YIUP2S3HQvHG1FDu+WUqW4daIqToXFE/JQ/EABgfZXLWU0ziTN6R3ygQBHMUBaB5
# bdrPbF6MRYs03h4obEMnxYOX8VBRKe1uNnzQVTeLni2nHkX/QqvXnNb+YkDFkxUG
# tMTaiLR9wjxUxu2hECZpqyU1d0IbX6Wq8/gVutDojBIFeRlqAcuEVT0cKsb+zJNE
# suEB7O7/cuvTQasnM9AWcIQfVjnzrvwiCZ85EE8LUkqRhoS3Y50OHgaY7T/lwd6U
# Arb+BOVAkg2oOvol/DJgddJ35XTxfUlQ+8Hggt8l2Yv7roancJIFcbojBcxlRcGG
# 0LIhp6GvReQGgMgYxQbV1S3CrWqZzBt1R9xJgKf47CdxVRd/ndUlQ05oxYy2zRWV
# FjF7mcr4C34Mj3ocCVccAvlKV9jEnstrniLvUxxVZE/rptb7IRE2lskKPIJgbaP5
# t2nGj/ULLi49xTcBZU8atufk+EMF/cWuiC7POGT75qaL6vdCvHlshtjdNXOCIUjs
# arfNZzCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYwDQYJKoZIhvcNAQEL
# BQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBS
# b290IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1OVowaTELMAkGA1UE
# BhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2Vy
# dCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENB
# MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4MdMKmEFyvjxGwBys
# ddujRmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6c+Gh/qm8Xi4aPCOo
# 2N8S9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3SYDEAd4dg2dDGpeZ
# GKe+42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVSTEG8yAR2CQWIM1iI5
# PHg62IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpqumzTCNSOxm+SAWSu
# Ir21Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJyUXzdtFUUt4aS4CE
# eIY8y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/GcalNeJQ55IuwnKCgs+n
# rpuQNfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8Aw4wJkhU1JrPsFfxW
# 1gaou30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/nJ0+k6MvqzfpzPDOy
# 5y6gqztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA6tQbZl1KhBtTasyS
# kuJDpsZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2baoD6x0VR4RjSpWM8o
# 5a6D8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAfBgNVHSMEGDAWgBTs
# 1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYI
# KwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2
# oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290
# RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG
# 9w0BAQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCHxYgaMH9Pw5tcBnPw
# 6O6FTGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdhOP4hCFATuNT+ReOP
# K0mCefSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDCvwzJv2sRUoKEfJ+n
# N57mQfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B0ba2H3LUiwDRAXx1
# Neq9ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWGNqNX+DF0SQzHU0pT
# i4dBwp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRNivYuve3L2oiKNqet
# RHdqfMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02OoXN4bFzK0vlNMsvhl
# qgF2puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy4kbu4QFhOm0xJuF2
# EZAOk5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2wL40mm53+/j7tFaxY
# KIqL0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQtyRN62JK4S1C8uw3P
# dBunvAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2zNaQ9k+5t1wwggWN
# MIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBD
# QTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZI
# hvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK
# 2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/G
# nhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJ
# IB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4M
# K7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN
# 2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I
# 11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KIS
# G2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9
# HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4
# pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpy
# FiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS31
# 2amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs
# 1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd
# 823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQw
# RQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZI
# hvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4
# hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3
# rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs
# 9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K
# 2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0n
# ftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQxggN8MIIDeAIBATB9MGkxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGln
# aUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAy
# NSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCggdEwGgYJKoZI
# hvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yNTExMTQwMDQ1
# MzJaMCsGCyqGSIb3DQEJEAIMMRwwGjAYMBYEFN1iMKyGCi0wa9o4sWh5UjAH+0F+
# MC8GCSqGSIb3DQEJBDEiBCAVtiOIA0G4cpzs6+BZv91+5iR4zyD4xjvIu1IhP34S
# jDA3BgsqhkiG9w0BCRACLzEoMCYwJDAiBCBKoD+iLNdchMVck4+CjmdrnK7Ksz/j
# bSaaozTxRhEKMzANBgkqhkiG9w0BAQEFAASCAgC7rYp2Z2HUOsuM6yeIYcssvIh4
# 3TxuVeSFeJgGxx+jt1pod0BKZnpJvncznVPypyU9BkJwuzgEzDd5NsxBGFiASu1Z
# YESaY7JTPxEsNGM5bfhlThbMXCf+onuaSMxuawwXDF4U42Z1QtZMEPL9YyO7c6ph
# K1X2vyMSc6iYQfOoYUHZoubxQTspEYLjuEnOGSEOms/3M9mD9Oa3EVuxmC4BKVdX
# oj9j1EPtR7T4pZieuejUqYdtnl4H8/qaOFkje1nLJqchjd0GQ+tQFAJ8MChgRjvQ
# b+TFaUwlnLEQLbr8kLseFIxlnXuZkb0ibntfdrV9IMO+Rs/B80nMj7qeM6g6tsJ8
# 4DUK6NsIxV3TjP7dxImBF1kYLrNcubk1Ce3PZ6sQoZqNe1vxWFCkpatAWDbhfT6V
# rECvUMejJho1zd6VoD3PaPYylZ9uGPnmHWVtJIFWNnJv4UJb8gZ2SgFQASm5IntM
# VmcZ7skvZzL28RwQqEOrYLHbpSJYfGmCgdEkXsgrqsJ3D/FmffjqBd06MirmfhO1
# nL9ci7F7SRkzeVY49mYNCIA/QCXU/8aDYvaD/sxBhanSWZb+1QitNmop+DAufriO
# efQ+BCH/Y4hAPjQcbajgvFXufd8dVtgA0YnClpgssKu4YYTkB4b1zgm+spaW6MvU
# v2q2JFmmG52+AQU1IA==
# SIG # End signature block
