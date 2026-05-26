
function Complete-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]
        $DomainName,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('HOST', 'WILDCARD', 'DOMAIN')]
        [string[]]
        $ValidationScope,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('DNS_CNAME', 'DNS_TXT', 'HTTP')]
        [string[]]
        $ValidationMethod,

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
        $Path = "/domain-validation/v1/domains/validate-now"
        $Body = @{
            'domains' = New-Object -TypeName System.Collections.Generic.List[Object]
        }
        for ($i = 0; $i -lt $DomainName.count; $i++) {
            $DomainObject = @{
                'domainName'       = $DomainName[$i]
                'validationScope'  = $ValidationScope[$i]
                'validationMethod' = $ValidationMethod[$i]
            }
            $Body.domains.Add($DomainObject)
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters 
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.domains
        }
        catch {
            throw $_
        }
    }
}

function Disable-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]
        $ValidationScope,

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
        $Path = "/domain-validation/v1/domains/invalidate"
        $Body = @{
            'domains' = New-Object -TypeName System.Collections.Generic.List[Object]
        }
        for ($i = 0; $i -lt $DomainName.Count; $i++) {
            $DomainObject = @{
                'domainName'      = $DomainName[$i]
                'validationScope' = $ValidationScope[$i]
            }
            $Body.domains.Add($DomainObject)
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters 
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.domains
        }
        catch {
            throw $_
        }
    }
}


function Find-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'attributes', ValueFromPipelineByPropertyName)]
        [string[]]
        $DomainName,

        [Parameter(Mandatory, ParameterSetName = 'attributes', ValueFromPipelineByPropertyName)]
        [ValidateSet('HOST', 'WILDCARD', 'DOMAIN')]
        [string[]]
        $ValidationScope,

        [Parameter()]
        [switch]
        $IncludeAll,

        [Parameter(Mandatory, ParameterSetName = 'body')]
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
        $Path = "/domain-validation/v1/domains/search"
        $QueryParameters = @{ 
            'includeAll' = $PSBoundParameters.IncludeAll.IsPresent
        }
        if ($PSCmdlet.ParameterSetName -eq 'attributes') {
            $Body = @{
                'domains' = New-Object -TypeName System.Collections.Generic.List[Object]
            }
            for ($i = 0; $i -lt $DomainName.Count; $i++) {
                $DomainObject = @{
                    'domainName'      = $DomainName[$i]
                    'validationScope' = $ValidationScope[$i]
                }
                $Body.domains.Add($DomainObject)
            }
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters 
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.domains
        }
        catch {
            throw $_
        }
    }
}


function Get-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'single', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ParameterSetName = 'single')]
        [ValidateSet('HOST', 'WILDCARD', 'DOMAIN')]
        [string]
        $ValidationScope,

        [Parameter(ParameterSetName = 'single')]
        [switch]
        $IncludeDomainStatusHistory,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $Paginate,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'All')]
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

    process {
        if ($DomainName) {
            $Path = "/domain-validation/v1/domains/$DomainName"
            $QueryParameters = @{ 
                'validationScope'            = $ValidationScope
                'includeDomainStatusHistory' = $PSBoundParameters.IncludeDomainStatusHistory.IsPresent
            }
        }
        else {
            $Path = "/domain-validation/v1/domains"
            $QueryParameters = @{ 
                'paginate' = $PSBoundParameters.Paginate.IsPresent
                'page'     = $PSBoundParameters.Page
                'pageSize' = $PageSize
            }
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters 
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($DomainName) {
                return $Response.Body
            }
            else {
                return $Response.Body.domains
            }
        }
        catch {
            throw $_
        }
    }
}


function New-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [string[]]
        $DomainName,

        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [ValidateSet('HOST', 'WILDCARD', 'DOMAIN')]
        [string[]]
        $ValidationScope,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'body')]
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
        $Path = "/domain-validation/v1/domains"
        if ($PSCmdlet.ParameterSetName -eq 'attributes') {
            $Body = @{
                domains = New-Object -TypeName System.Collections.Generic.List[Object]
            }
            for ($i = 0; $i -lt $DomainName.Count; $i++) {
                $DomainObject = @{
                    'domainName'      = $DomainName[$i]
                    'validationScope' = $ValidationScope[$i]
                }
                $Body.domains.Add($DomainObject)
            }
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function Remove-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $ValidationScope,

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
        $Path = "/domain-validation/v1/domains"
        $Body = @{
            'domains' = New-Object -TypeName System.Collections.Generic.List[Object]
        }
        for ($i = 0; $i -lt 1; $i++) {
            $DomainObject = @{
                'domainName'      = $DomainName[$i]
                'validationScope' = $ValidationScope[$i]
            }
            $Body.domains.Add($DomainObject)
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters 
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAAUdLOIpKyH2Jm
# 9tlWP+Uz4+lG//Aub9QZeVCFMiwGO6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII83HRFdm0HWt1DE0CbR5Dx6wkhbu78s
# DKF8c0vN2RxYMA0GCSqGSIb3DQEBAQUABIIBgAl8cSFQQeu4H0x1eB8XQ0tZeIBd
# 1Ns3XRVmpG0FmFmolD3n/4F81etc272ibAOPbgqfB3lg0kLaGTypn6QkIqpFicno
# azEVMzZvduIi5gh9c+qIzBHyehW9o/JElyUQcZujToG4mzFx0YWINsMGqMdroF17
# vgO/sK03nlxIrwgxfsj2MLz6Gr+Jpic8y4BqinXxGo8rFxzYJKNo+Dv8dBtHjoh0
# 9RJ8+pyOKFMi3odCwRxHp8HSlw4+mGrGEhjYbZKzpy6/65Pwme3HJCWyfOhrDQdp
# ur+mH5fKrviOdE+WXwj/y7/1y5/u1COQwJG3p8vmtAXZG0Lz3N5Zuf91Iz8ct0gR
# UQsNZ1yqufJlKZ4Ms/fopt2lhe9lFSFMPdq17cVQg7pnCTUNAX4U+rDKRkN47j8J
# kM3aWdnco5yn6fuIF8tE6amOtybwdjOvVetBzg7tw1ueM+4BgtiI4ZdMHghS212j
# 26mUpHoZ4clonUH2CindCNpM8ksJuc1mqZ5eGg==
# SIG # End signature block
