function Format-PEM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $PEM
    )

    # Remove any existing line breaks and carriage returns, then reformat with proper line breaks
    $FormattedPEM = $PEM.Replace("\r", "")
    $FormattedPEM = $FormattedPEM.Replace("`r", "")
    $FormattedPEM = $FormattedPEM.Replace("\n", "`n")

    return $FormattedPEM
}
function Get-BodyObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        $Source
    )

    Process {
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
}

function Add-CCMSignedCertificate {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $CertificateID,

        [Parameter()]
        [switch]
        $AcknowledgeWarnings,

        [Parameter(Mandatory)]
        [string]
        $CertificatePEM,

        [Parameter()]
        [string]
        $TrustChainPEM,

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
        $Path = "/ccm/v1/certificates/$CertificateID"
        $QueryParameters = @{ 
            'acknowledgeWarnings' = $PSBoundParameters.AcknowledgeWarnings.IsPresent
        }
        $AdditionalHeaders = @{
            'Content-Type' = 'application/json-patch+json'
        }

        # Sanitize PEMs
        if ($CertificatePEM) {
            $CertificatePEM = Format-PEM -PEM $CertificatePEM
        }
        if ($TrustChainPEM) {
            $TrustChainPEM = Format-PEM -PEM $TrustChainPEM
        }

        $Body = @(
            @{
                'op'    = 'add'
                'path'  = '/signedCertificatePem'
                'value' = $CertificatePEM
            }
            @{
                'op'    = 'add'
                'path'  = '/trustChainPem'
                'value' = $TrustChainPEM
            }
        )
        $RequestParameters = @{
            'Path'              = $Path
            'Method'            = 'PATCH'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'QueryParameters'   = $QueryParameters 
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
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

function Get-CCMBinding {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Single', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $CertificateID,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $Domain,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $ExpiringInDays,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $PageSize = 100,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $Page,

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
        if ($CertificateID) {
            $Path = "/ccm/v1/certificates/$CertificateID/certificate-bindings"
        }
        else {
            $Path = "/ccm/v1/certificate-bindings"
        }
        $QueryParameters = @{ 
            'contractId'     = $ContractID
            'groupId'        = $GroupID
            'domain'         = $Domain
            'network'        = $Network
            'expiringInDays' = $PSBoundParameters.ExpiringInDays
            'pageSize'       = $PageSize
            'page'           = $PSBoundParameters.Page
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
            return $Response.Body.bindings
        }
        catch {
            throw $_
        }
    }
}

function Get-CCMCertificate {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'Single')]
        [string]
        $CertificateID,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $CertificateStatus,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $ExpiringInDays,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $Domain,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $KeyType,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $Issuer,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $IncludeCertificateMaterials,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $PageSize = 100,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'All')]
        [string]
        $Sort,

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
        if ($CertificateID) {
            $Path = "/ccm/v1/certificates/$CertificateID"
        }
        else {
            $Path = "/ccm/v1/certificates"
        }
        $QueryParameters = @{ 
            'contractId'                  = $ContractID
            'groupId'                     = $GroupID
            'certificateStatus'           = $CertificateStatus
            'expiringInDays'              = $PSBoundParameters.ExpiringInDays
            'domain'                      = $Domain
            'certificateName'             = $CertificateName
            'keyType'                     = $KeyType
            'issuer'                      = $Issuer
            'includeCertificateMaterials' = $PSBoundParameters.IncludeCertificateMaterials.IsPresent
            'pageSize'                    = $PageSize
            'page'                        = $PSBoundParameters.Page
            'sort'                        = $Sort
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
            if ($CertificateID) {
                return $Response.Body
            }
            else {
                return $Response.Body.certificates
            }
        }
        catch {
            throw $_
        }
    }
}

function New-CCMCertificate {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $CertificateName,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $CommonName,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Country,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Locality,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Organization,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $State,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('2048', 'P-256')]
        [string]
        $KeySize,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('RSA', 'ECDSA')]
        [string]
        $KeyType,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $SANs = @(),

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('ENHANCED_TLS')]
        [string]
        $SecureNetwork,

        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Request body')]
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
        $Path = "/ccm/v1/certificates"
        $QueryParameters = @{ 
            'contractId' = $ContractID
            'groupId'    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'subject'       = @{
                    'commonName'   = $CommonName
                    'country'      = $Country
                    'locality'     = $Locality
                    'organization' = $Organization
                    'state'        = $State
                }
                'keySize'       = $KeySize
                'keyType'       = $KeyType
                'sans'          = $SANs
                'secureNetwork' = $SecureNetwork
            }
            if ($CertificateName) {
                $Body.certificateName = $CertificateName
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
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}

function Remove-CCMCertificate {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $CertificateID,

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
        $Path = "/ccm/v1/certificates/$CertificateID"
        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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

function Rename-CCMCertificate {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $CertificateID,

        [Parameter()]
        [switch]
        $AcknowledgeWarnings,

        [Parameter()]
        [string]
        $CertificateName,

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
        $Path = "/ccm/v1/certificates/$CertificateID"
        $QueryParameters = @{ 
            'acknowledgeWarnings' = $PSBoundParameters.AcknowledgeWarnings.IsPresent
        }
        $AdditionalHeaders = @{
            'Content-Type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'replace'
                'path'  = '/certificateName'
                'value' = $CertificateName
            }
        )
        $RequestParameters = @{
            'Path'              = $Path
            'Method'            = 'PATCH'
            'QueryParameters'   = $QueryParameters 
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
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

function Set-CCMCertificate {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $CertificateID,

        [Parameter()]
        [switch]
        $AcknowledgeWarnings,

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
        $Path = "/ccm/v1/certificates/$CertificateID"
        $QueryParameters = @{ 
            'acknowledgeWarnings' = $PSBoundParameters.AcknowledgeWarnings.IsPresent
        }

        # Handle \n line breaks as plain text in body
        $Body = Get-BodyObject -Source $Body
        'csrPem', 'signedCertificatePem' | ForEach-Object {
            if ($null -ne $Body.$_) {
                $Body.$_ = Format-PEM -PEM $Body.$_
            }
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCArw7TG1DfLFAeO
# NhgA8UWaL9ELS8BQ5EowEbWY6ykjS6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGzZLGRaqEeXCPnKAgJtzKzJw8VhGUua
# KXSK/hEOmWF/MA0GCSqGSIb3DQEBAQUABIIBgEzSYyYye0zWN+qPqqodieiq6qBy
# BOXiyNArfdQXhR9HLUHUErD1zu9+dSN7GI2rOJlTzfaYGmSZUixr9BM2FMX7t61T
# tqzg3GdyIfpqIt7/EB8qr+JPhdCaFlXK+XOtXqJxRFSjjOZ2EuTBagvvnw/6HF+m
# 4BXjbWHIN+DwCEdBjpT7mSFTH/0b715smtJksyzSHCG1Pq+IUkAiUAfCJOQM6wUI
# HTVz3x9MlPhVKaOFR2jRSWeml1r7GML2c6ykZX314UBfUcepn+zBct8go2FpP/7y
# 6uFQtWceUBkKUmdMk4/WX0sHii8Oy71e3MZZIS8VuDAFGxqB4dRVn9gDPW5dlv30
# vNL00pgaV5dNbUUW/RJb0hkxNQNZi+jGwD5M8BF/HDRV/lM+sIC4eeEbHsZ+/0dA
# cP/nq3V2ZmgzMWW9x8yS+w5jZAzz/EkYO4uG+XLSLDY8X+l7M3RTx8PuK49Zj/Z3
# aE75bMOeWOssCOwbw10iFdjyzzlWRkGcsPSnqA==
# SIG # End signature block
