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

function Get-ChinaCDNDeprovisionPolicy {
    Param(
        [Parameter(Mandatory)]
        [string]
        $EdgeHostname,

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

    $Path = "/chinacdn/v1/edge-hostnames/$EdgeHostname/deprovision-policy"
    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.deprovision-policy.v1+json'
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


function Get-ChinaCDNEdgeHostnames {
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

    $Path = "/chinacdn/v1/edge-hostnames"
    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.edge-hostnames.v2+json'
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
    return $Response.Body.edgeHostnames
}


function Get-ChinaCDNGroups {
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

    $Path = "/chinacdn/v1/groups"
    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.groups.v1+json'
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
    return $Response.Body.groups
}


function Get-ChinaCDNHoldingEntities {
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

    $Path = "/chinacdn/v1/icp-holding-entities"
    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.icp-holding-entities.v1+json'
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
    return $Response.Body.icpHoldingEntities
}


function Get-ChinaCDNICPNumbers {
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

    $Path = "/chinacdn/v1/icp-numbers"

    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.icp-numbers.v1+json'
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
    return $Response.Body.icpNumbers
}


function Get-ChinaCDNPropertyHostname {
    Param(
        [Parameter()]
        [string]
        $Hostname,

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

    if ($Hostname) {
        $Path = "/chinacdn/v1/property-hostnames/$Hostname"
        $AdditionalHeaders = @{
            Accept = 'application/vnd.akamai.chinacdn.property-hostname.v1+json'
        }
    }
    else {
        $Path = "/chinacdn/v1/property-hostnames"
        $AdditionalHeaders = @{
            Accept = 'application/vnd.akamai.chinacdn.property-hostnames.v1+json'
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
    if ($Hostname) {
        return $Response.Body
    }
    else {
        $Response.Body.propertyHostnames
    }
}


function Get-ChinaCDNProvisionStateChange {
    Param(
        [Parameter(Mandatory)]
        [string]
        $Hostname,

        [Parameter()]
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

    if ($ChangeID) {
        $Path = "/chinacdn/v1/property-hostnames/$Hostname/provision-state-changes/$ChangeID"
        $AdditionalHeaders = @{
            Accept = 'application/vnd.akamai.chinacdn.provision-state-change.v1+json'
        }
    }
    else {
        $Path = "/chinacdn/v1/property-hostnames/$Hostname/provision-state-changes/current"
        $AdditionalHeaders = @{
            Accept = 'application/vnd.akamai.chinacdn.provision-state-changes.v1+json'
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
    if ($ChangeID) {
        return $Response.Body
    }
    else {
        return $Response.Body.provisionStateChanges
    }
}


function Get-ChinaCDNProvisionStates {
    Param(
        [Parameter()]
        [string]
        $ProvisionState,

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

    $Path = "/chinacdn/v1/current-provision-states"
    $QueryParameters = @{
        'provisionState' = $ProvisionState
    }

    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.provision-states.v1+json'
    }
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
    return $Response.Body.provisionStates
}


function New-ChinaCDNPropertyHostname {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    [Alias('Set-ChinaCDNPropertyHostname')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Hostname,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Comments,

        [Parameter(, ParameterSetName = 'Attributes')]
        [int]
        $ICPNumberID,

        [Parameter(, ParameterSetName = 'Attributes')]
        [int]
        $ServiceCategory,

        [Parameter(Mandatory, ParameterSetName = 'Body', ValueFromPipeline)]
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
        $Path = "/chinacdn/v1/property-hostnames/$Hostname"
        $QueryParameters = @{
            'groupId' = $GroupID
        }
        $AdditionalHeaders = @{
            'Accept'       = 'application/vnd.akamai.chinacdn.property-hostname.v1+json'
            'Content-Type' = 'application/vnd.akamai.chinacdn.property-hostname.v1+json'
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                hostname = $Hostname
            }
            if ($ICPNumberID) {
                $Body['icpNumberId'] = $ICPNumberID
            }
            if ($ServiceCategory) {
                $Body['serviceCategory'] = $ServiceCategory
            }
            if ($Comments) {
                $Body['comments'] = $Comments
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
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

    end {}
}


function New-ChinaCDNProvisionStateChange {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Hostname,

        [Parameter()]
        [switch]
        $ForceDeprovision,

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
        $Path = "/chinacdn/v1/property-hostnames/$Hostname/provision-state-changes"
        $AdditionalHeaders = @{
            'Accept'       = 'application/vnd.akamai.chinacdn.provision-state-change.v1+json'
            'Content-Type' = 'application/vnd.akamai.chinacdn.provision-state-change.v1+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

    end {}

    
}


function Set-ChinaCDNDeprovisionPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory)]
        [string]
        $EdgeHostname,

        [Parameter(ParameterSetName = 'Attributes')]
        [bool]
        $UnmapSharedEdgeHostname,

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

    begin {}

    process {
        $Path = "/chinacdn/v1/edge-hostnames/$EdgeHostname/deprovision-policy"
        $AdditionalHeaders = @{
            'Accept'       = 'application/vnd.akamai.chinacdn.deprovision-policy.v1+json'
            'Content-Type' = 'application/vnd.akamai.chinacdn.deprovision-policy.v1+json'
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'unmapSharedEdgeHostname' = $UnmapSharedEdgeHostname
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

    end {}
}



# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDf3yWNjukpJ1pV
# LVT6fUgyu6Yco18j3uNvXxzrTK5Yp6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL0U9jfp4r1XS2TR3aWPJl3f8zd4pH/r
# aFbwnikxuQJxMA0GCSqGSIb3DQEBAQUABIIBgBPotv6tTu3ET21mF5fJFR0AswE2
# AC212VDXY9+OwkLx4q+IDgNMABe1ZnEHExy528TedaourFo/Mp4k9bQvSQ/Hom7V
# vfLNn4c6demQp045PnVFAg6xS7dHEIlZ8tC+Lwy+9Wmol4BtlzwdMgB4XufBaen3
# QPK2QA6hOcBVAZ8NVXBgjKyAO4Lc2RhRzqSsGZY16//252QC3dUHXCTAswDB1CyT
# eICtWHAWXUh1tj+9h5mkus+jzimpZxmgzYGmez+G/kVs5DyxpKOicIRalRP4AKWr
# 9xTA38CuGZdim9q5NsG8gXqdXkq2JUyc3hs60PN6I+VD0sog1EfWmLeoy1kDdgx7
# J+GO5G+ROSXDSdCBMFKmV7PO3bqkRIc9L1TODNGxUQ2of5IxiUEh62tiOPk1Y2Zz
# b2XInDGZBedr/nEkyYVMuGgJywH25gZLHo8PktLT3+qQ+2nx4oF9TyDu6DBwxyIM
# OYH0THG9HRVf6Q/JNNMxQg/zz74mP0XCl76Adg==
# SIG # End signature block
