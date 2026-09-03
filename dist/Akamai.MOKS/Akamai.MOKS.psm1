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
        [ValidateSet('CORE', 'RUSSIA_AND_CORE', 'CHINA_AND_CORE')]
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

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Subject,

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
# MIIo2QYJKoZIhvcNAQcCoIIoyjCCKMYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAU/Ik1plRJQV4z
# bfhGkDd1oFfxZkg9/Q0lsqEwUQsfd6CCDg4wggawMIIEmKADAgECAhAIrUCyYNKc
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
# yK+p/pQd52MbOoZWeE4wggdWMIIFPqADAgECAhAGRzH371ShX6hjGl1wSSyYMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjYwMjI1MDAwMDAwWhcNMjcwMzEw
# MjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEDAOBgNV
# BAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRz
# MRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1haSBUZWNobm9sb2dp
# ZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVzIEluYzCCAaIwDQYJ
# KoZIhvcNAQEBBQADggGPADCCAYoCggGBAJeMKuhiUI5WSRdGIPhNWLpaVPlXbSaz
# hGuvzZxTi623Ht46hiPejDtWB8F8dT2pd+nOWsx5NVgkv7x/Tz35cZcWVMDxq/K7
# wYe9R2GndGgfEL02/j5rslwHr8e6qFzy1axuL/xaGXuBTVrSQw25019l1KalUHwI
# nKLIP7Hw1HLPTacyJNNTsYmOpZNqKIiQe9ivzBd7SuPU0cGi1YHUk4ZQh6Ig5tBx
# 8XZYjTmzbiQr2WWwk/CufaoIPME5zAvmW99S05rAtOqvoUr7eoLUQ/TcMMA6eOli
# AbO5m0w/pv5YDgzhzt9hQez189zZNOkMO6AcHNitJzzsEvCg7fhPHxoXvasRJ0Ea
# CEze0nuVakLPf+mGCLoZYGRctayOn4HP6LEEOGmAnQBZkwFR6zxk0hzAMOkK/p7M
# V9V6QwOuk9q7WKnIdzS/4RjRtXNxXb2fMNyBEwrwJhdmEhWF0eS0Wd6Uz3IbSr0+
# XH8FHLflQXFCkPcZKiGPgSCp8rTP3KHr6wIDAQABo4ICAjCCAf4wHwYDVR0jBBgw
# FoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFKT3RICOlmcsnPu7KwUf
# 9HL4YegLMD0GA1UdIAQ2MDQwMgYFZ4EMAQMwKTAnBggrBgEFBQcCARYbaHR0cDov
# L3d3dy5kaWdpY2VydC5jb20vQ1BTMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAK
# BggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEz
# ODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5j
# cmwwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIw
# MjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQADggIBAGSBrSnUReHU
# zGTy9VC6hy2oDSpu2QNu5j3o/uoaaAy2CgI0hVJRL/OfYinLR4hJofuNNKORp2MW
# Xpy52L5PCGtD6/Hf92bMkDl1AP6nXuplt5HvkFPh5kVDbQ7oHfI1Pup2IOpKxb00
# UNwjtKy+38ZCX0dgkASP2vQFamBCG0eTaGUh/9ZH9rz11Nkr9p83Snz/3eW3vOeK
# AFL3S5RDEMkTvv09540mnzA4J5lKGES2eje/FhwCCQUQBvqCvoNFNZHyXvW9v8Kq
# X/3CcN1LAtGCy4XnkFjQRPyn+o/OJv5M5yX2Rm5kq9dYpWnDU2xgxMR1BZaDf+uD
# oqGsLo4OqbPV4Dftp2FDs8DHMD8xP6i/k4htaWShkdyjdijr9TBOi+pS9vNlcCKj
# wLq6aibcbkUk7ef3wxR5imhajsX22vy8Zd9ByAk07BJrccggJGczCtiKcD6LZtP3
# VjnqhYPSQ4jk6wCruqcTCTwwO7FrIROVrWb2Ro+ph+/a5Llj5ryLyp+6NAgtNwyr
# kp2WxZviLbh5AXnmg9Pnwrz64UE93LEjI23AWBJsLFdJTbisZ/tTgozdVdPZf2Dy
# 2k8xfYZoIq6V1oWiAoQCzb5B9nETV5NGjiMPskJ4GwnlzOvz+4IgLQjl0V5I08Qw
# +3uvPQ8rHHMLbKgncTqSxqtZ73kItOztMYIaITCCGh0CAQEwfTBpMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0
# IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0Ex
# AhAGRzH371ShX6hjGl1wSSyYMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEvr3rkmflHGa8zk393sPLj0
# uJFUm3fdENvFLsrWJVhaMA0GCSqGSIb3DQEBAQUABIIBgFe28vzvkv0H6HzHz8hj
# /lG643YoEHMSCWvnzVopk+LukoV3ewUw8n0m4B6wqRYv7YBt7hTeUijfIBVnLNrH
# qn5zEQ5yqoTiCjud0JA6MFsPqsYfN7iI2y8KSKy4TRuJpHEGJNhSMEX7sNRn6Xve
# iDo+LTILs4OSfcdZnOfLSlrNwhM1sbePUo9nLWBUh0GD47ahGyNyj9k7mzETS731
# hV4+PkvGiwfc0rEPM8Imsk/YZj4cODNxhtNJdhZ+CmTX2Zd+Ht03jypM4UlKNqXi
# xOydWVMqQhjbrH+9ufcETjZSKJSn3o4j3Fa9CMB2H9vLIYx+bIYH0tYw4U74CCfq
# i4JA2FRWYE2MEdOjBARVSX7mQaVHlKlv8oc3iXCWf5DT1xxn8o73OKFaBkT0uiRB
# zcnsBx1TE2x4hAChUMGtOTF6ShvFLK/SuTWLMJ+qeYjzTuY0gNr5EAXqmE9naZQy
# IRGYLxkKXCSIXKHsQoQBWRPHbtzao12zLBQPziJXUpmm8aGCF3cwghdzBgorBgEE
# AYI3AwMBMYIXYzCCF18GCSqGSIb3DQEHAqCCF1AwghdMAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAweAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCBDerF5Ktkg96tAUKQEp+p5qg1MAefuRTsKSVslHmTCMgIRANO4
# dQKuC31ztb6r6KNUVSMYDzIwMjYwODI1MjI0MTIzWqCCEzowggbtMIIE1aADAgEC
# AhAKgO8YS43xBYLRxHanlXRoMA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1
# c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwHhcN
# MjUwNjA0MDAwMDAwWhcNMzYwOTAzMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFNIQTI1NiBS
# U0E0MDk2IFRpbWVzdGFtcCBSZXNwb25kZXIgMjAyNSAxMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEA0EasLRLGntDqrmBWsytXum9R/4ZwCgHfyjfMGUIw
# YzKomd8U1nH7C8Dr0cVMF3BsfAFI54um8+dnxk36+jx0Tb+k+87H9WPxNyFPJIDZ
# HhAqlUPt281mHrBbZHqRK71Em3/hCGC5KyyneqiZ7syvFXJ9A72wzHpkBaMUNg7M
# OLxI6E9RaUueHTQKWXymOtRwJXcrcTTPPT2V1D/+cFllESviH8YjoPFvZSjKs3SK
# O1QNUdFd2adw44wDcKgH+JRJE5Qg0NP3yiSyi5MxgU6cehGHr7zou1znOM8odbkq
# oK+lJ25LCHBSai25CFyD23DZgPfDrJJJK77epTwMP6eKA0kWa3osAe8fcpK40uhk
# tzUd/Yk0xUvhDU6lvJukx7jphx40DQt82yepyekl4i0r8OEps/FNO4ahfvAk12hE
# 5FVs9HVVWcO5J4dVmVzix4A77p3awLbr89A90/nWGjXMGn7FQhmSlIUDy9Z2hSgc
# taepZTd0ILIUbWuhKuAeNIeWrzHKYueMJtItnj2Q+aTyLLKLM0MheP/9w6CtjuuV
# HJOVoIJ/DtpJRE7Ce7vMRHoRon4CWIvuiNN1Lk9Y+xZ66lazs2kKFSTnnkrT3pXW
# ETTJkhd76CIDBbTRofOsNyEhzZtCGmnQigpFHti58CSmvEyJcAlDVcKacJ+A9/z7
# eacCAwEAAaOCAZUwggGRMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFOQ7/PIx7f39
# 1/ORcWMZUEPPYYzoMB8GA1UdIwQYMBaAFO9vU0rp5AZ8esrikFb2L9RJ7MtOMA4G
# A1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCBlQYIKwYBBQUH
# AQEEgYgwgYUwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBd
# BggrBgEFBQcwAoZRaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3J0MF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNybDAg
# BgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQAD
# ggIBAGUqrfEcJwS5rmBB7NEIRJ5jQHIh+OT2Ik/bNYulCrVvhREafBYF0RkP2AGr
# 181o2YWPoSHz9iZEN/FPsLSTwVQWo2H62yGBvg7ouCODwrx6ULj6hYKqdT8wv2UV
# +Kbz/3ImZlJ7YXwBD9R0oU62PtgxOao872bOySCILdBghQ/ZLcdC8cbUUO75ZSpb
# h1oipOhcUT8lD8QAGB9lctZTTOJM3pHfKBAEcxQFoHlt2s9sXoxFizTeHihsQyfF
# g5fxUFEp7W42fNBVN4ueLaceRf9Cq9ec1v5iQMWTFQa0xNqItH3CPFTG7aEQJmmr
# JTV3Qhtfparz+BW60OiMEgV5GWoBy4RVPRwqxv7Mk0Sy4QHs7v9y69NBqycz0BZw
# hB9WOfOu/CIJnzkQTwtSSpGGhLdjnQ4eBpjtP+XB3pQCtv4E5UCSDag6+iX8MmB1
# 0nfldPF9SVD7weCC3yXZi/uuhqdwkgVxuiMFzGVFwYbQsiGnoa9F5AaAyBjFBtXV
# LcKtapnMG3VH3EmAp/jsJ3FVF3+d1SVDTmjFjLbNFZUWMXuZyvgLfgyPehwJVxwC
# +UpX2MSey2ueIu9THFVkT+um1vshETaWyQo8gmBto/m3acaP9QsuLj3FNwFlTxq2
# 5+T4QwX9xa6ILs84ZPvmpovq90K8eWyG2N01c4IhSOxqt81nMIIGtDCCBJygAwIB
# AgIQDcesVwX/IZkuQEMiDDpJhjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3
# MDAwMDAwWhcNMzgwMTE0MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMO
# RGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGlt
# ZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAtHgx0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1
# mZaDLFTtQ2oRjzUXMmxCqvkbsDpz4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJa
# DNs1+JH7Z+QdSKWM06qchUP+AbdJgMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6A
# o+xh/AS7sQRuQL37QXbDhAktVJMQbzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M98
# 0EpLtlrNyHw0Xm+nt5pnYJU3Gmq6bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC
# 2ZQ8BbfnFRQVESYOszFI2Wv82wnJRfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+Kd
# PvMvaB0WkE/2qHxJ0ucS638ZxqU14lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHk
# ccpL6uoG8pbF0LJAQQZxst7VvwDDjAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8
# hjj/q8d6ylgxCZSKi17yVp2NL+cnT6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDK
# iDEb1AQ8es9Xr/u6bDTnYCTKIsDq1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCB
# ZtVFJfVZ3j7OgWmnhFr4yUozZtqgPrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsg
# Y1MCAwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9v
# U0rp5AZ8esrikFb2L9RJ7MtOMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiu
# HA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEF
# BQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBB
# BggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkw
# FzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsW
# gBz+Bz0RdnEwvb4LyLU0pn/N0IfFiBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j0
# 0DNqhCT3t+s8G0iP5kvN2n7Jd2E4/iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywF
# LerycvZTAz40y8S4F3/a+Z1jEMK/DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2
# e26MHvVY9gCDA/JYsq7pGdogP8HRtrYfctSLANEBfHU16r3J05qX3kId+ZOczgj5
# kjatVB+NdADVZKON/gnZruMvNYY2o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXu
# vTPSegOOzr4EWj7PtspIHBldNE2K9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25
# xUbI7GIN/TpVfHIqQ6Ku/qjTY6hc3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZ
# jE4YtL8Pbzg0c1ugMZyZZd/BdHLiRu7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeq
# GkH/wyW4N7OigizwJWeukcyIPbAvjSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQ
# sfch28bZeUz2rtY/9TCA6TD8dC3JE3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS
# 9/wQD7yFylIz0scmbKvFoW2jNrbM1pD2T7m3XDCCBY0wggR1oAMCAQICEA6bGI75
# 0C3n79tQ4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAw
# MFoXDTMxMTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGln
# aUNlcnQgVHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAv+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuE
# DcQwH/MbpDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNw
# wrK6dZlqczKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs0
# 6wXGXuxbGrzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e
# 5TXnMcvak17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtV
# gkEy19sEcypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85
# tRFYF/ckXEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+S
# kjqePdwA5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1Yxw
# LEFgqrFjGESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzl
# DlJRR3S+Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFr
# b7GrhotPwtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATow
# ggE2MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiu
# HA9PMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQE
# AwIBhjB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2
# hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290
# Q0EuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/
# Q1xV5zhfoKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNK
# ei8ttzjv9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHr
# lnKhSLSZy51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4
# oVaO7KTVPeix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5A
# Y8WYIsGyWfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNN
# n3O3AamfV6peKOK5lDGCA3wwggN4AgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0
# IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMQIQCoDvGEuN8QWC
# 0cR2p5V0aDANBglghkgBZQMEAgEFAKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcN
# AQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTI2MDgyNTIyNDEyM1owKwYLKoZIhvcNAQkQ
# AgwxHDAaMBgwFgQU3WIwrIYKLTBr2jixaHlSMAf7QX4wLwYJKoZIhvcNAQkEMSIE
# IOiYUZFQ9Ku0tku3BnNJ4FXpPuO7php0XBzOzpGCkQlsMDcGCyqGSIb3DQEJEAIv
# MSgwJjAkMCIEIEqgP6Is11yExVyTj4KOZ2ucrsqzP+NtJpqjNPFGEQozMA0GCSqG
# SIb3DQEBAQUABIICAIeGx+U/Ox16sFMkwu+IhOYJOme17sZxLRemzEHoZ35+X2SU
# wN/KaWIh1RRMV8sAGHoJzzKm3bcAEqpMmlIu75reN+vlXr1jqEzKuSUM2bVeqwyU
# ZrsxXM45x5bv5/2crKw5TaPmMKJhfmlOYYwpN3ASlRus7KLseXvMs5ngAxgHh0uv
# +YKx+ZkH4zZNLaTWnBqbzuxVsTPKAN757zauVvh5QNRIRuXXIRkeBMlGz50eTek0
# eeRgqaT8M444dzTKundq9aG9BUd8tXQSAIKEY6HUEMzGw4RqNAQq7/Oz3bW2qrhv
# HyczbXT9y4z5xgSs8aHCHxM1sXc6kzDzYyCBgfyHpR8x0yHl1DXkQNoUkevrjpTO
# PHzmqt8tPLUAV8Do315JKfyDg64VLn/Ixv9DcIPAyMUnwKuvV093zJ6+DGd6I6Tg
# gtNwE4lASGT9IRxy1en58qPisYVa3dvF+6ZQkc+hquaL1QIoBnL3O4TljvGkHsUo
# b9YYTrPOwElXwrtxKI5ScqViRsthBMA+7o8fVOXy8zsK4fOIKhII8NcCb6EB6qvi
# T1CVPg/W1pXK7IOnCVGCBM5CXzcfUyAM0JP1Wuy0Ehyq2QKmjiV6C7wqb5spe4/7
# Cy6t7OPTOseQRgWs8b3EHPSZIku1Zod3JdutDoYNB3evPgguGiX7U7oJBmtj
# SIG # End signature block
