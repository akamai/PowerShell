function Uninstall-Akamai {
    [CmdletBinding(DefaultParameterSetName = 'version', SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        [Parameter(ParameterSetName = 'version', Mandatory)]
        [ValidatePattern('^[\d]+(\.[\d]+)?(\.[\d]+)?$')]
        [string]
        $Version,
        
        [Parameter(ParameterSetName = 'all')]
        [switch]
        $All,
        
        [Parameter(ParameterSetName = 'allv1')]
        [switch]
        $AllV1,

        [Parameter(ParameterSetName = 'allbutlatest')]
        [switch]
        $AllButLatest,
        
        [Parameter()]
        [string]
        $ModulePath
    )

    # Convert version to System.Version to parse
    if ($Version) {
        if ($Version -match '^[\d]+$') {
            $ParsedVersion = [System.Version] "$Version.0"
        }
        else {
            $ParsedVersion = [System.Version] $Version
        }
        Write-Debug "Parsed version to $ParsedVersion"
    }
    
    # Track deletions
    $DeletionsPerformed = $false

    # List module locations
    if ($ModulePath) {
        $ModulePaths = @($ModulePath)
    }
    else {
        $ModulePaths = $env:PSModulePath -split [System.IO.Path]::PathSeparator
    }

    # Iterate across module paths
    :modulepaths
    foreach ($ModulePath in $ModulePaths) {
        Write-Debug "Parsing module directory $ModulePath for Akamai modules"
        if (-not (Test-Path $ModulePath)) {
            Write-Debug "Module path $ModulePath does not exist"
            continue
        }
        $VersionsToDelete = @()
        $V1Path = "$ModulePath/akamaipowershell"
        if ($AllV1) {
            if (Test-Path $V1Path) {
                $VersionsToDelete += @(Get-Item $V1Path)
            }
        }
        else {
            $AkamaiDirectories = Get-ChildItem -Directory -Path $ModulePath/Akamai*
            :directories
            foreach ($AkamaiDirectory in $AkamaiDirectories) {
                Write-Debug "---- Parsing Akamai directory $($AkamaiDirectory.Name)"
                $ModuleVersions = Get-ChildItem -Directory -Path $AkamaiDirectory | Where-Object Name -match '^[\d]+(\.[\d]+)?(\.[\d]+)?$'
                # Remove specific version
                if ($Version) {
                    if ($ParsedVersion.Build -ne -1) {
                        $VersionsToDelete += $ModuleVersions | Where-Object Name -eq $Version
                    }
                    else {
                        $VersionsToDelete += $ModuleVersions | Where-Object { $_.Name.StartsWith($Version) }
                    }
                }
                # Remove all but latest version
                elseif ($AllButLatest) {
                    # If v2 present, remove all of v1
                    $V2Present = $false
                    :v2check
                    foreach ($AkaDir in $AkamaiDirectories) {
                        if ($AkaDir.Name.StartsWith('Akamai.')) {
                            $V2Present = $true
                            break v2check
                        }
                    }
                    if ($AkamaiDirectory.Name -eq 'AkamaiPowershell' -and $V2Present) {
                        $VersionsToDelete += $ModuleVersions
                    }
                    # Othwerwise sort versions by version and remove all but the highest
                    else {
                        $SortedVersionStrings = $ModuleVersions |
                        Sort-Object -Property { $_.Name -as [System.Version] } -Descending
                        $VersionsToDelete += $SortedVersionStrings[1..$($SortedVersionStrings.count - 1)]
                    }
                }
                # Remove all versions
                elseif ($All) {
                    $VersionsToDelete += $ModuleVersions
                }

            }
        }
        # Delete folders
        if ($VersionsToDelete) {
            $ErrorsOccurred = $false
            $VersionsToDelete | ForEach-Object {
                if ($PSCmdlet.ShouldProcess("Removing module directory $($_.FullName)", $_.FullName, "Remove module directory")) {
                    Write-Warning "Removing module directory '$($_.FullName)'."
                    try {
                        Remove-Item -Recurse -Force -Path $_.FullName -ErrorAction Stop
                        $DeletionsPerformed = $true
                    }
                    catch {
                        Write-Error "Failed to delete directory $($_.FullName). You may need to run as Administrator or sudo."
                        Write-Error $_
                        $ErrorsOccurred = $true
                    }
                }
            }
            if (-not $ErrorsOccurred) {
                # Clean up empty folders, if they still exist
                foreach ($AkamaiDirectory in $AkamaiDirectories) {
                    if ((Test-Path $AkamaiDirectory)) {
                        $ChildObjects = Get-ChildItem -Path $AkamaiDirectory
                        if ($null -eq $ChildObjects) {
                            if ($PSCmdlet.ShouldProcess("Removing empty parent directory $($_.FullName)", $_.FullName, "Remove parent directory")) {
                                Write-Warning "Removing empty parent directory $($AkamaiDirectory.FullName)."
                                try {
                                    Remove-Item -Recurse -Force -Path $AkamaiDirectory.FullName -ErrorAction Stop
                                    $DeletionsPerformed = $true
                                }
                                catch {
                                    Write-Error "Failed to delete empty parent directory $($_.FullName). You may need to run as Administrator or sudo."
                                    Write-Error $_
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # Report to the user if nothing was removed
    if ($DeletionsPerformed) {
        # Remove in-memory modules to make sure old config is purged
        Remove-Module Akamai*
    }
    elseif (-not $ErrorsOccurred) {
        Write-Host 'No matching module directories found in any directory under $env:PSModulePath.'
    }
    else {
        Write-Warning "Errors occurred when uninstalling module versions. Please check remaining versions manually."
    }
}

# SIG # Begin signature block
# MIIpmwYJKoZIhvcNAQcCoIIpjDCCKYgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCLmUEDr22QoRyq
# phIF4PhkzHTXgw6ul7yznz0NKKNwRqCCDo4wggawMIIEmKADAgECAhAIrUCyYNKc
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
# yK+p/pQd52MbOoZWeE4wggfWMIIFvqADAgECAhAPqQNIfpKuRHl6VyEAUF/CMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjUwMzA3MDAwMDAwWhcNMjYwMzA3
# MjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEDAOBgNV
# BAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRz
# MRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1haSBUZWNobm9sb2dp
# ZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVzIEluYzCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBANsoarQpG9c+J772YXJn5AR91njV2cZm
# zcrP3A27Qd9ahcUG6PsgQZP/bPqbRpYz/FmQZm5Yy+feRVGovTTE5DBpM+oKL0et
# UDCI2KeJJNZIYleNeRAc5AhS6Rvl172A/cczttku8migVutaEIcwNHSarF/ECWW0
# hRn+StrpRGcNazOxGlu2DgHBZC4BaYneaINzRhOioThATu323GpJ0KVDjvwjlMJa
# og2w1TFc1Y9tWjEWv1/HBhJ+Igl3c/a6jIBZWOA+JXeAa6xIX2qY73YmWM83AUrt
# QjdU0X9MBE6AtrEVGpqkaiB3vjXSeI6MI03waMWyiVN0DSVVS2dMFee47aw/jkn1
# D/8ygmzsZ5oAFYN+qrwhpzblRvYP2RoxumnU1ehmcfwcTFvCNkx/OmRvs/7FC4rc
# eAAUQbNYzI9LD59jfku4Mti9BWyZIT9qhmeZMREHkZYE0XWn3BFo9B/fA5IGAVZF
# NkDyEXBst0KJNYQaCZ3JEFW56O2PaZxGisSlIz6P20M2n6X4HPJKvRmK/JmsmyzB
# jHo7INIyrMKZWqXDQq5mtIUbnuzGhSAUKNJAudUxtWrzjdYuP8gesR7jkeWEXW4j
# SGiUZz9oaVfC2FpgOwotfpIG4wzWGcs3oKjFRL0dy5Fz6QRKljNL2mhbLsrMnwaa
# l8utC3xnk9cRAgMBAAGjggICMIIB/jAfBgNVHSMEGDAWgBRoN+Drtjv4XxGG+/5h
# ewiIZfROQjAdBgNVHQ4EFgQUXJJsGiSblAtbBvAq04u340Zk5mwwPQYDVR0gBDYw
# NDAyBgVngQwBAzApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNv
# bS9DUFMwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMIG1BgNV
# HR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMFOg
# UaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRD
# b2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDCBlAYIKwYBBQUHAQEE
# gYcwgYQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBcBggr
# BgEFBQcwAoZQaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcnQwCQYDVR0T
# BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAVSdbv6a52OI4vbYbdBNMKJnc/f8VLjMn
# BKRGh7p66eQmCZuN16til04U+MIzixe3xECFEK3WYnRP+imbkQLTERFRhIVr3P23
# 6vdRZWoATnl2rfX18CedHqaAzM6zTR62E3oN/Vb836a35LAXeOldyumyFdXE4vYh
# zgjJwFcMzbqRJxAS9t6mN6JL/zDbc+rAIFW2XV9GTvwi0kvrMHhV0we3wNlWuqdR
# gnNXRSKdLWj6I9i2ZhNYcy+ZPqzFPrcC2tYfbZt4MM7HB6ciCYPVVudROIGbesig
# 9gQhDnw7jFpdaupdymJZBN9ywtOTTZJgTPPuElu5MxgSC6ZehOocvUUN5z+TIN6d
# u8RSYVtgbpPcReyDwNLd9TupQ88ky9OF50mkHko26LdlXIu0bijlNRaE5pSBjK5+
# ycDos5E6oIC0mNDB/lzSFjaEPKgrOeu60EugrVAFGp/Rk/uKSva7KN/AdzT31sf3
# JprPNwssciB4ozCEnqf2a/kjqz9vf8xchEgk03syWTL1PZWTOkagg2peVDsUrq3P
# o3W0uI1aNDGa+0MLEYo9XWR/gEjvP2/4qqzxsBSjMnhaLvkzTqE4L0ez0bnqGCbb
# wbiii9lOim5Iugbx6WU6+TYdLjOGpyUcVOFlVoqkWwT1Ykkv4KqXFDpo/iV4OTUk
# MVPcHaArzb8xghpjMIIaXwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2Rl
# IFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEA+pA0h+kq5EeXpXIQBQ
# X8IwDQYJYIZIAWUDBAIBBQCgfDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAv
# BgkqhkiG9w0BCQQxIgQg7EttSkWaqDqkExWRerHyoweWBN79SFxhQn2rymryQc8w
# DQYJKoZIhvcNAQEBBQAEggIAgeYpAnECY3VhRT9/DcQE28kaMbE/qFz1/1o0HdyC
# heqx3tk+PwNbbU7GjLeomT3gpeCj6CEDTq9Q3U+q9sOpYk07f0CkWuAGzEwESqFh
# x4KMncknBK5ATOlKerX6eygVTTbS4ULhPDhAgQuZNO2/4PgHWsr0SS+IyCEHBU0w
# C4EFqzdomN/F7GxWaIf+WJ0K7VsrX6dXIKGV08mQ/zMsjEy+zhE7hcoDKmhKCp6Z
# 3ODU2pXdlA+8uLERKh/N3nBkdJXBvJEkTGeNYfpwn2puQWgX0854iEJuebUQFkda
# n9fux5+y2+AHBQtHh8hSN/UYzuqepTtR5Y2vRTQ8S01XDZ6UfRbtzQNmZpeGdRHV
# LGJzU+6HMU0x5pSLdmlQ7zqfPNPUtCYuH6epAKUWh5+yMsVDaxKlwV9kLTbNmTWl
# EM88tMlw+5CxK8qULyDUEGHZipPVugNHCcQwqB2sFRuAzNGoVIvzmTA2/lRrG+Td
# o5a6gnyYwcNVKaqSKKs8C6nCEB1dMkNa0mZbokX4lvPczoT/+RhcPC+treCMRn8X
# FhlWzd/utli3IesrO8Co88Z2e+MtFn2km6qe3sDrPqmin8bvkupRBTJzROyeDujv
# udM8A4/MQuU8QlhOqIrHsXfhjxBoM2ca7sOimUEsc41RtYa9HGvqHu623EhCUbnR
# NmWhghc5MIIXNQYKKwYBBAGCNwMDATGCFyUwghchBgkqhkiG9w0BBwKgghcSMIIX
# DgIBAzEPMA0GCWCGSAFlAwQCAQUAMHcGCyqGSIb3DQEJEAEEoGgEZjBkAgEBBglg
# hkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgQvY7Y9PO/YAT1M1Qtzf2sSmi4JBI
# o6VfVCMofO1nZ64CEFsCKv/F0Aw4p4nOqsPGbRIYDzIwMjUwNDE1MTgxMTU2WqCC
# EwMwgga8MIIEpKADAgECAhALrma8Wrp/lYfG+ekE4zMEMA0GCSqGSIb3DQEBCwUA
# MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UE
# AxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBp
# bmcgQ0EwHhcNMjQwOTI2MDAwMDAwWhcNMzUxMTI1MjM1OTU5WjBCMQswCQYDVQQG
# EwJVUzERMA8GA1UEChMIRGlnaUNlcnQxIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVz
# dGFtcCAyMDI0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvmpzn/aV
# IauWMLpbbeZZo7Xo/ZEfGMSIO2qZ46XB/QowIEMSvgjEdEZ3v4vrrTHleW1JWGEr
# rjOL0J4L0HqVR1czSzvUQ5xF7z4IQmn7dHY7yijvoQ7ujm0u6yXF2v1CrzZopykD
# 07/9fpAT4BxpT9vJoJqAsP8YuhRvflJ9YeHjes4fduksTHulntq9WelRWY++TFPx
# zZrbILRYynyEy7rS1lHQKFpXvo2GePfsMRhNf1F41nyEg5h7iOXv+vjX0K8RhUis
# fqw3TTLHj1uhS66YX2LZPxS4oaf33rp9HlfqSBePejlYeEdU740GKQM7SaVSH3Tb
# BL8R6HwX9QVpGnXPlKdE4fBIn5BBFnV+KwPxRNUNK6lYk2y1WSKour4hJN0SMkoa
# NV8hyyADiX1xuTxKaXN12HgR+8WulU2d6zhzXomJ2PleI9V2yfmfXSPGYanGgxzq
# I+ShoOGLomMd3mJt92nm7Mheng/TBeSA2z4I78JpwGpTRHiT7yHqBiV2ngUIyCtd
# 0pZ8zg3S7bk4QC4RrcnKJ3FbjyPAGogmoiZ33c1HG93Vp6lJ415ERcC7bFQMRbxq
# rMVANiav1k425zYyFMyLNyE1QulQSgDpW9rtvVcIH7WvG9sqYup9j8z9J1XqbBZP
# J5XLln8mS8wWmdDLnBHXgYly/p1DhoQo5fkCAwEAAaOCAYswggGHMA4GA1UdDwEB
# /wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMCAG
# A1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6Ftlt
# TYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUn1csA3cOKBWQZqVjXu5Pkh92oFsw
# WgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCBkAYI
# KwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNydDAN
# BgkqhkiG9w0BAQsFAAOCAgEAPa0eH3aZW+M4hBJH2UOR9hHbm04IHdEoT8/T3HuB
# SyZeq3jSi5GXeWP7xCKhVireKCnCs+8GZl2uVYFvQe+pPTScVJeCZSsMo1JCoZN2
# mMew/L4tpqVNbSpWO9QGFwfMEy60HofN6V51sMLMXNTLfhVqs+e8haupWiArSozy
# AmGH/6oMQAh078qRh6wvJNU6gnh5OruCP1QUAvVSu4kqVOcJVozZR5RRb/zPd++P
# GE3qF1P3xWvYViUJLsxtvge/mzA75oBfFZSbdakHJe2BVDGIGVNVjOp8sNt70+kE
# oMF+T6tptMUNlehSR7vM+C13v9+9ZOUKzfRUAYSyyEmYtsnpltD/GWX8eM70ls1V
# 6QG/ZOB6b6Yum1HvIiulqJ1Elesj5TMHq8CWT/xrW7twipXTJ5/i5pkU5E16RSBA
# dOp12aw8IQhhA/vEbFkEiF2abhuFixUDobZaA0VhqAsMHOmaT3XThZDNi5U2zHKh
# Us5uHHdG6BoQau75KiNbh0c+hatSF+02kULkftARjsyEpHKsF7u5zKRbt5oK5YGw
# Fvgc4pEVUNytmB3BpIiowOIIuDgP5M9WArHYSAR16gc0dP2XdkMEP5eBsX7bf/MG
# N4K3HP50v/01ZHo/Z5lGLvNwQ7XHBx1yomzLP8lx4Q1zZKDyHcp4VQJLu2kWTsKs
# OqQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUA
# MGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT
# EHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9v
# dCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQg
# VHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdR
# odbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhX
# qAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69Ox
# tXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ
# 3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLF
# uk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD
# 40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpUR
# K1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/S
# TKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfc
# Yd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31f
# I7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a5
# 0g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNV
# HQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM
# 3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNl
# cnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAg
# BgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQAD
# ggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaop
# afxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXON
# ASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9
# nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4m
# wbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4ck
# u0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2
# QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmH
# QXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZ
# ynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+
# v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8
# mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIFjTCCBHWgAwIB
# AgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIw
# ODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Y
# q3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lX
# FllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxe
# TsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbu
# yntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I
# 9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmg
# Z92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse
# 5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKy
# Ebe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwh
# HbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/
# Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwID
# AQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM
# 3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYD
# VR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+
# MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUA
# A4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSI
# d229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7U
# z9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxA
# GTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAID
# yyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW
# /VvRXKwYw02fc7cBqZ9Xql4o4rmUMYIDdjCCA3ICAQEwdzBjMQswCQYDVQQGEwJV
# UzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRy
# dXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhALrma8Wrp/
# lYfG+ekE4zMEMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG
# 9w0BCRABBDAcBgkqhkiG9w0BCQUxDxcNMjUwNDE1MTgxMTU2WjArBgsqhkiG9w0B
# CRACDDEcMBowGDAWBBTb04XuYtvSPnvk9nFIUIck1YZbRTAvBgkqhkiG9w0BCQQx
# IgQg0cmmlusXdvxDbSsHTTqBE6Ofi06kp2eUzLxLv10/H/wwNwYLKoZIhvcNAQkQ
# Ai8xKDAmMCQwIgQgdnafqPJjLx9DCzojMK7WVnX+13PbBdZluQWTmEOPmtswDQYJ
# KoZIhvcNAQEBBQAEggIAuVtGG66ZBn/PwatXsHnMFxDGpc7jANBSI+tY7HS+wLUI
# EjB5wipllI+2qiZO4fcJb52nLK0D+oPIzWDjnQRbv1fGGUc2w316ibeT0DasF+ep
# JHI84Rc8NPYAuyivYDbwR7pslYhbqb/kSPyVJGZ8CnshdYRuW571QnBRO8nOK/kO
# iIvcNAPv7kGfPhdEl8fgrMo/DmSZ6kqJh4pV5RfZyAEF3vYlF1FotQLRZLDOouiJ
# mZkmWcMeTdyynQNx6XN9CiXJPXjyVQqSWDNLLe8q2N/Spqry/k9y9O4vsCqb28sA
# BxxdZmxtOelWrYbWDZIQNIQRIUk0ISGefVI6UkfaLp/lr4mrjJp91smn0EQLDzk+
# rfitYtL+C9M6DjNUI1I4+RcIZeVQxWy2eEmd9XqKx29cLcQ9k5+ELEJXUMeJntZx
# TyGyiic4CefbxggtNMgNcqxkw8UWfQhGZBLYQtfJoIVXmLdekpysuRvTUVv+Y9Yd
# 2OX8s4mJHLTfkXZCopDc8N2zVoNY0IAsdtYiKUaID+CKDhyWMMz+pYc+8uzIbhZ5
# hlrJZoshLBw02pzVRSqd6jDWpn7jE7AEy35QXqvQ2JNXTmn6zCciwdNWXVFUuCiH
# ZcXjxu/cF6WR5PxYSZw5/ErRXyMM/TnKYUjlT4BaZWYE5cqJ9p7OpcA10DlJdrc=
# SIG # End signature block
