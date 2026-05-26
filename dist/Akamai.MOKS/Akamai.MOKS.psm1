function Expand-MOKSClientCertDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $CertificateName,
        
        [Parameter()]
        $CertificateID,

        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    $CommonParams = @{
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }

    if ($CertificateName -ne '') {
        # Check cache if enabled
        if ($Global:AkamaiOptions.EnableDataCache) {
            $CertificateID = $Global:AkamaiDataCache.MOKS.ClientCerts.$CertificateName.CertificateID
        }

        if (-not $CertificateID) {
            Write-Debug "Expand-MOKSClientCertDetails: '$CertificateName' - Retrieving Client Certificate details."
            $ClientCerts = Get-MOKSClientCert @CommonParams
            $ClientCert = $ClientCerts | Where-Object certificateName -eq $CertificateName
            if ($null -eq $ClientCert) {
                throw "Client certificate '$CertificateName' not found."
            }
            $CertificateID = $ClientCert.certificateId
        }

        # Add to data cache
        if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.MOKS.ClientCerts.$CertificateName) {
            $Global:AkamaiDataCache.MOKS.ClientCerts.$CertificateName = @{
                'CertificateID' = $CertificateID
            }
        }
        Write-Debug "Expand-MOKSClientCertDetails: CertificateID = $CertificateID."
    }

    if ($Version -and $Version.ToLower() -in 'latest', 'deployed') {
        Write-Debug "Expand-MOKSClientCertDetails: '$CertificateID' - Retrieving Client Certificate versions."
        $Versions = Get-MOKSClientCertVersion -CertificateID $CertificateID @CommonParams | Sort-Object -property Version -Descending
        if ($Version.ToLower() -eq 'latest') {
            $Version = $Versions[0].version
        }
        elseif ($Version.ToLower() -eq 'deployed') {
            $DeployedVersion = $Versions | Where-Object status -eq 'DEPLOYED'
            if ($null -eq $DeployedVersion) {
                Throw "No deployed version of client certificate '$CertificateID'."
            }
            $Version = $DeployedVersion.version
        }
        Write-Debug "Expand-MOKSClientCertDetails: Version = $Version."
    }

    return $CertificateID, $Version
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
        throw "Source param is of an unhandled type '$($Source.GetType().Name)'."
    }

    return $BodyObject
}


function Complete-MOKSClientCertVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & file')]
    Param(
        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'Name & body')]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID & file')]
        [Parameter(ParameterSetName = 'ID & body')]
        [int]
        $CertificateID,

        [Parameter(Mandatory)]
        [ValidatePattern('^(latest|deployed|[0-9]+)$')]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $AcknowledgeAllWarnings,

        [Parameter(Mandatory, ParameterSetName = 'Name & file')]
        [Parameter(Mandatory, ParameterSetName = 'ID & file')]
        [string]
        $CertificateFile,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [string]
        $TrustChainFile,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name & body')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ID & body')]
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
        $CertificateID, $Version = Expand-MOKSClientCertDetails @PSBoundParameters
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID/versions/$Version/certificate-block"
        $QueryParameters = @{
            'acknowledgeAllWarnings' = $PSBoundParameters.AcknowledgeAllWarnings.IsPresent
        }
        if ($PSCmdlet.ParameterSetName.Contains('file')) {
            if (-not (Test-Path $CertificateFile)) {
                throw "Certificate file '$CertificateFile' not found."
            }
            $CertData = Get-Content -Raw $CertificateFile
            $Body = @{
                'certificate' = $CertData
            }
            if ($TrustChainFile) {
                if (-not (Test-Path $TrustChainFile)) {
                    throw "Trust chain file '$TrustChainFile' not found."
                }
                $TrustData = Get-Content -Raw $TrustChainFile
                $Body.trustChain = $TrustData
            }
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
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


function Get-MOKSCACert {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
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
        $Path = "/mtls-origin-keystore/v1/ca-certificates"
        $QueryParameters = @{
            'status' = $Status
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
        return $Response.Body.certificates
    }
}


function Get-MOKSClientCert {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets__')]
    Param(
        [Parameter(ParameterSetName = 'Name')]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID', ValueFromPipeline)]
        [int]
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
        if ($PSCmdlet.ParameterSetName -eq 'Name' -or $PSCmdlet.ParameterSetName -eq 'ID') {
            $CertificateID, $null = Expand-MOKSClientCertDetails @PSBoundParameters
            $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID"
        }
        else {
            $Path = "/mtls-origin-keystore/v1/client-certificates"
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                if ($CertificateID) {
                    Set-AkamaiDataCache -MOKSClientCertName $Response.Body.certificateName -MOKSClientCertID $Response.Body.certificateId
                }
                else {
                    foreach ($ClientCert in $Response.Body.certificates) {
                        Set-AkamaiDataCache -MOKSClientCertName $ClientCert.certificateName -MOKSClientCertID $ClientCert.certificateId
                    }
                }
            }

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


function Get-MOKSClientCertVersion {
    [CmdletBinding(DefaultParameterSetName = 'ID')]
    Param(
        [Parameter(ParameterSetName = 'name', Mandatory)]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CertificateID,

        [Parameter()]
        [switch]
        $IncludeAssociatedProperties,

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
        $CertificateID, $null = Expand-MOKSClientCertDetails @PSBoundParameters
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID/versions"
        $QueryParameters = @{
            'includeAssociatedProperties' = $PSBoundParameters.IncludeAssociatedProperties.IsPresent
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
        return $Response.Body.versions
    }
}

function New-MOKSClientCert {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $CertificateName,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $ContractID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('CORE', 'RUSSIAN_AND_CORE', 'CHINA_AND_CORE')]
        [string]
        $Geography = 'CORE',

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('STANDARD_TLS', 'ENHANCED_TLS')]
        [string]
        $SecureNetwork,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('AKAMAI', 'THIRD_PARTY')]
        [string]
        $Signer,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $NotificationEmails,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $PreferredCA,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('RSA', 'ECDSA')]
        [string]
        $KeyAlgorithm,

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
        $Path = "/mtls-origin-keystore/v1/client-certificates"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'certificateName'    = $CertificateName
                'contractId'         = $ContractID
                'groupId'            = $GroupID
                'geography'          = $Geography
                'notificationEmails' = ($NotificationEmails.Replace(' ', '') -split ',')
                'secureNetwork'      = $SecureNetwork
                'signer'             = $Signer
            }
            if ($PreferredCA) { $Body.preferredCa = $PreferredCA }
            if ($KeyAlgorithm) { $Body.keyAlgorithm = $KeyAlgorithm }
            if ($Subject) { $Body.subject = $Subject }
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                Set-AkamaiDataCache -MOKSClientCertName $Response.Body.certificateName -MOKSClientCertID $Response.Body.certificateId
            }

            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}


function New-MOKSClientCertVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
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
        $CertificateID, $null = Expand-MOKSClientCertDetails @PSBoundParameters
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID/versions"

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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

function Remove-MOKSClientCertVersion {
    [CmdletBinding(DefaultParameterSetName = 'ID')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [int]
        $CertificateID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|deployed|[0-9]+)$')]
        [string]
        $Version,

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
        $CertificateID, $Version = Expand-MOKSClientCertDetails @PSBoundParameters
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID/versions/$Version"

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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


function Set-MOKSClientCert {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID &attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CertificateID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID &attributes', Mandatory)]
        [string]
        $NewName,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID &attributes', Mandatory)]
        [string]
        $NotificationEmails,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name & body')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ID & body')]
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
        $CertificateID, $null = Expand-MOKSClientCertDetails @PSBoundParameters
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'certificateName'    = $NewName
                'notificationEmails' = ($NotificationEmails.Replace(' ', '') -split ',')
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
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


# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBS8IYiiG8m5CWM
# Gkx4bAc9kDmYQ2xCaAMaNQNXoR13/KCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBfPHYr+DOloEdOEVJM9vvKYWS91EV98
# WPlnuAMZuTNZMA0GCSqGSIb3DQEBAQUABIIBgCcP0cW1bPpo8y0VWqNZndX8kG1Z
# yiu4xbtOYCN8ljobgW5E2C/8y/cFpTaa1lEcMB/V7zX5dl7QUcdgfiXa8QlmNNEJ
# ADkJ+ybe8U/jC2PaFQuebNCjovExbW+NYBbp5xDZY8RSBk2uL7vhM6byQkJZ6SnQ
# KpAVLLzA9QGACEhRUPfNjjJmVureXbEC6BAYMWhv8/NcAFsgZcb4CMQ1F0D8cp8i
# cn0DctQZg9DQy1k/fxEQ0hY4aBTSu5KfdJwUSbOXzIMJDzoHdzFeSX4s476aUYmA
# eIIenGZ0SenHLlXy2iWKINRnl9wk+GDpZ1UBa2QXBuO2DXKRk0iHsmnAHT9CmFVx
# pnWxRASalBzB6qPJryPbuKPr+HIvdu3j9nh4sxSAbXXysMq87ytneGnf5FPUwM2U
# jaUCQPly4iockHZf8XwhHWXOqxaTo8umLrAYIFeKM+DrOqArZ4ApQ89Edl7sVErO
# J5JPj8Tq4F4VzrV682MtfeV2ciCXo7NfunYqjQ==
# SIG # End signature block
