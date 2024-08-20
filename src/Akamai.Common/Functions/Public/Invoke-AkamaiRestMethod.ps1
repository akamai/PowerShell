<#
  .SYNOPSIS
  Sends a HTTPS request to an Akamai RESTful web service.

  .DESCRIPTION
  The `Invoke-Akamai RestMethod` cmdlet sends a HTTPS request to Akamai RESTful web services and formats the response based on data type.
  
  When the REST endpoint returns multiple objects, the objects are received as an array. If you pipe the output from `Invoke-AkamaiRestMethod` to another command, it's sent as a single `[Object[]]` object. The contents of that array are not enumerated for the next command on the pipeline.

  .PARAMETER Method
  Specifies the method used for the web request. Values are `GET`, `POST`, `PUT`, `DELETE` and `PATCH`.

  .PARAMETER Path
  A resource's path minus the host.

  .PARAMETER QueryParameters
  A hashtable of request query parameters to add to request. If the same key is found in `Path` and `QueryParameters`, the `QueryParameters` value persists.

  .PARAMETER AdditionalHeaders
  A hashtable of any additional request headers.

  .PARAMETER Body
  The data sent to the endpoint. Value is a hashtable that includes values for each parameter.

  > Important: Because `Body` is a free field, our PowerShell module doesn't validate the data you include, the API does.

  .PARAMETER InputFile
  If needed by an endpoint, an input file's location.

  .PARAMETER OutputFile
  If provided by an endpoint, where to place an output file.

  .PARAMETER MaxBody
  The maximum message body size. Default is `2048` bytes. Increase as needed up to `131072` bytes.

  .PARAMETER IncludeResponseHeaders
  Flag to include headers in the function response

  .PARAMETER EdgeRCFile
  The path to an edgerc file. Defaults to `~/.edgerc`. 

  .PARAMETER Section
  The edgerc section name. Defaults to `default`. 

  .PARAMETER AccountSwitchKey
  A key used to apply changes to an account external to your credentials' account.

  .EXAMPLE
  Invoke-AkamaiRestMethod -Method "GET" -Path "/path/to/api"

  `GET` without query parameters. 

  .EXAMPLE
  Invoke-AkamaiRestMethod -Method "POST" -Path "/path/to/api" -Body '{@{"key":{"key2": "value", "key3":"value"}}'

  Request: `POST` without query parameters and an inline body.

  Response: The data returned is dependent upon the endpoint and varies.

  .EXAMPLE
  Invoke-AkamaiRestMethod -Method "POST" -Path "/path/to/api" -InputFile "~./path/to/body.json"

  Request: `POST` without query parameters and path to the JSON body containing the body of the call.

  Response: The data returned is dependent upon the endpoint and varies.

  .EXAMPLE
  Invoke-AkamaiRestMethod -Method "PUT" -Path "/path/to/api?withParams=true" -Body '{@{"key":{"key2": "value", "key3":"value"}}'

  Request: `PUT` with query parameters for an existing item and an inline body.

  Response: The data returned is dependent upon the endpoint and varies.

  .EXAMPLE
  Invoke-AkamaiRestMethod -Method "PATCH" -Path "/path/to/api?withParams=true" -Body '{@{"key":{"key3": "value"}}'

  Request: `PATCH` with query parameters for an existing item and an inline body.

  Response: The data returned is dependent upon the endpoint and varies.

  .EXAMPLE
  Invoke-AkamaiRestMethod -Method "DELETE" -Path "/path/to/api?itemId"

  Request: `DELETE` with an ID for the item to delete as a query parameter.

  Response: The data returned is dependent upon the endpoint and varies.

  .LINK
  PowerShell overview: https://techdocs.akamai.com/powershell/docs/overview

  .LINK
  Online version: https://techdocs.akamai.com/powershell/reference/invoke-akamairestmethod
#>

function Invoke-AkamaiRestMethod {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet("GET", "HEAD", "PUT", "POST", "DELETE", "PATCH")]
        [string] 
        $Method = "GET",
        
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter()]
        [hashtable] 
        $QueryParameters,
        
        [Parameter()]
        [hashtable] 
        $AdditionalHeaders,

        [Parameter()]
        $Body,
        
        [Parameter()]
        [string] 
        $InputFile,

        [Parameter()]
        [string] 
        $OutputFile,

        [Parameter()]
        [string] 
        $MaxBody = 131072,

        [Parameter()]
        [switch]
        $IncludeResponseHeaders,

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
    
    # Get auth creds from various potential sources
    $Auth = Get-AkamaiCredentials -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
    if ($Debug) {
        ## Check creds if in Debug mode
        Confirm-Auth -Auth $Auth
    }
    
    # Path with QueryString compatibility
    if ($Path.Contains('?')) {
        $PathElements = $Path.Split('?')
        $Path = $PathElements[0]
        $QueryFromPath = $PathElements[1]
    }

    # Build QueryNameValueCollection
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        Add-Type -AssemblyName System.Web
    }
    $QueryNVCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

    # Sanitize QueryFromPath (for compatibility)
    if ($QueryFromPath) {
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($QueryFromPath)
        foreach ($key in $QueryString.Keys) {
            if (@($null, '') -notcontains $key -and @($null, '') -notcontains $QueryString[$key]) { 
                $QueryNVCollection.Add($key, $QueryString[$key]) 
            }
        }
    }

    # Merge QueryParameters Hashtable (if same keys, hashtable values win over values from path)
    foreach ($key in $QueryParameters.Keys) {
        if (@($null, '') -notcontains $key -and @($null, '') -notcontains $QueryParameters[$key]) {
            # Lower case boolean params
            $SanitizedValue = $QueryParameters.$key
            if ($SanitizedValue -imatch 'true|false') {
                $SanitizedValue = $SanitizedValue.ToString().ToLower()
            }
            if ($key -notin $QueryNVCollection.Keys) {
                $QueryNVCollection.Add($key, $SanitizedValue)
            }
            else {
                $QueryNVCollection[$key] = $SanitizedValue
            }
        }
    }

    # Add account switch key from $Auth, if present
    if ($Auth.account_key) {
        $QueryNVCollection.Add('accountSwitchKey', $Auth.account_key)
    }
    
    # Build Request URL
    [System.UriBuilder]$Request = New-Object -TypeName 'System.UriBuilder'
    $Request.Scheme = 'https'
    $Request.Host = $Auth.host
    $Request.Path = $Path
    $Request.Query = $QueryNVCollection.ToString()

    # ReqURL Verification
    Write-Debug "Request URL = $($Request.Uri.AbsoluteUri)"
    If (($null -eq $Request.Uri.AbsoluteUri) -or ($Request.Host -notmatch "akamaiapis.net")) {
        throw "Error: Invalid Request URI"
    }

    # Sanitize Method param
    $Method = $Method.ToUpper()

    # Timestamp for request signing
    $TimeStamp = [DateTime]::UtcNow.ToString("yyyyMMddTHH:mm:sszz00")

    # GUID for request signing
    $Nonce = [GUID]::NewGuid()

    # Build data string for signature generation
    $SignatureData = $Method + "`t" + $Request.Scheme + "`t"
    $SignatureData += $Request.Host + "`t" + $Request.Uri.PathAndQuery

    # Convert Body to string if not already, but only if Content-Type hasn't been overridden
    $ConvertBody = $false
    if ($null -ne $Body -and $Body -isnot 'String') {
        $ConvertBody = $true
    }
    if ($null -ne $AdditionalHeaders -and $null -ne $AdditionalHeaders['content-type'] -and -not $AdditionalHeaders['content-type'].contains('json')) {
        Write-Debug 'Forgoing body conversion due to custom content-type'
        $ConvertBody = $false
    }
    if ($ConvertBody) {
        try {
            Write-Debug "Converting Body of type $($Body.GetType().Name) to JSON"
            $Body = ConvertTo-Json -InputObject $Body -Depth 100
        }
        catch {
            Write-Error $_
            throw 'Body could not be converted to a JSON string'
        }
    }

    #Sanitize body to remove NO-BREAK SPACE Unicode character, which breaks PAPI
    $Body = $Body -replace "[\u00a0]", ""

    # Add body to signature. Truncate if body is greater than max-body (Akamai default is 131072). PUT Method does not require adding to signature.
    if ($Method -eq "POST") {
        if ($Body) {
            $Body_SHA256 = [System.Security.Cryptography.SHA256]::Create()
            if ($Body.Length -gt $MaxBody) {
                $Body_Hash = [System.Convert]::ToBase64String($Body_SHA256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Body.Substring(0, $MaxBody))))
            }
            else {
                $Body_Hash = [System.Convert]::ToBase64String($Body_SHA256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Body)))
            }

            $SignatureData += "`t`t" + $Body_Hash + "`t"
        }
        elseif ($InputFile) {
            $Body_SHA256 = [System.Security.Cryptography.SHA256]::Create()
            if ($PSVersionTable.PSVersion.Major -le 5) {
                $Bytes = Get-Content $InputFile -Encoding Byte
            }
            else {
                $Bytes = Get-Content $InputFile -AsByteStream
            }

            if ($Bytes.Length -gt $MaxBody) {
                $Body_Hash = [System.Convert]::ToBase64String($Body_SHA256.ComputeHash($Bytes[0..($MaxBody - 1)]))
            }
            else {
                $Body_Hash = [System.Convert]::ToBase64String($Body_SHA256.ComputeHash($Bytes))
            }

            $SignatureData += "`t`t" + $Body_Hash + "`t"
            Write-Debug "Signature generated from input file $InputFile"
        }
        else {
            $SignatureData += "`t`t`t"
        }
    }
    else {
        $SignatureData += "`t`t`t"
    }

    $SignatureData += "EG1-HMAC-SHA256 "
    $SignatureData += "client_token=" + $Auth.client_token + ";"
    $SignatureData += "access_token=" + $Auth.access_token + ";"
    $SignatureData += "timestamp=" + $TimeStamp + ";"
    $SignatureData += "nonce=" + $Nonce + ";"

    Write-Debug "SignatureData = $SignatureData"

    # Generate SigningKey
    $SigningKey = Get-Crypto -secret $Auth.client_secret -message $TimeStamp

    # Generate Auth Signature
    $Signature = Get-Crypto -secret $SigningKey -message $SignatureData

    # Create AuthHeader
    $AuthorizationHeader = "EG1-HMAC-SHA256 "
    $AuthorizationHeader += "client_token=" + $Auth.client_token + ";"
    $AuthorizationHeader += "access_token=" + $Auth.access_token + ";"
    $AuthorizationHeader += "timestamp=" + $TimeStamp + ";"
    $AuthorizationHeader += "nonce=" + $Nonce + ";"
    $AuthorizationHeader += "signature=" + $Signature

    # Create IDictionary to hold request headers
    $Headers = @{}

    ## Calculate custom UA
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        #< 6 is missing the OS member of PSVersionTable, so we use env variables
        $UserAgent = "AkamaiPowershell/$($Env:AkamaiPowershellVersion) (Powershell $PSEdition $($PSVersionTable.PSVersion) $PSCulture, $($PSVersionTable.OS))"
    }
    else {
        $UserAgent = "AkamaiPowershell/$($Env:AkamaiPowershellVersion) (Powershell $PSEdition $($PSVersionTable.PSVersion) $PSCulture, $($Env:OS))"
    }
    
    # Add headers
    $Headers.Add('Authorization', $AuthorizationHeader)
    $Headers.Add('Accept', 'application/json')
    $Headers.Add('Content-Type', 'application/json; charset=utf-8')
    $Headers.Add('User-Agent', $UserAgent)

    # Add additional headers
    if ($AdditionalHeaders) {
        $AdditionalHeaders.Keys | ForEach-Object {
            $Headers[$_] = $AdditionalHeaders[$_]
        }
    }

    # Set ContentType param from Content-Type header. This is sent along with bodies to fix string encoding issues in IRM
    $ContentType = $Headers['Content-Type']

    # turn off the "Expect: 100 Continue" header as it's not supported on the Akamai side.
    [System.Net.ServicePointManager]::Expect100Continue = $false

    # Set TLS version to 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    
    $RequestParameters = @{
        Method             = $Method
        Uri                = $Request.Uri
        Headers            = $Headers
        ContentType        = $ContentType
        MaximumRedirection = 0
    }
    
    # Add -AllowInsecureRedirect if Pwsh 7.4 or higher
    if ($PSVersionTable.PSVersion.Major -gt 7 -or ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -ge 4)) {
        $RequestParameters['AllowInsecureRedirect'] = $true
    }
    
    if ($null -ne $ENV:https_proxy) { $RequestParameters.Proxy = $ENV:https_proxy }

    if ($Method -in "PUT", "POST", "PATCH") {
        if ($Body) { $RequestParameters.Body = $Body }
        if ($InputFile) { $RequestParameters.InFile = $InputFile }
    }
    # GET requests typically
    else { 
        # Differentiate on PS 5 and later as PS 5's Invoke-RestMethod doesn't behave the same as the later versions
        if ($PSVersionTable.PSVersion.Major -le 5) {
            $RequestParameters.ErrorAction = "SilentlyContinue"
        }
        else {
            $RequestParameters.ErrorAction = "Stop"
            $RequestParameters.ResponseHeadersVariable = 'ResponseHeaders'
        }
    }

    if ($OutputFile) {
        $RequestParameters.OutFile = $OutputFile
    }

    Write-Verbose "$($Request.Uri.AbsoluteUri)"

    try {
        $Response = Invoke-RestMethod @RequestParameters
    }
    catch {
        # PS >=6 handling
        # Redirects aren't well handled due to signatures needing regenerated
        if ($_.Exception.Response.StatusCode.value__ -eq 301 -or $_.Exception.Response.StatusCode.value__ -eq 302) {
            try {
                $NewPath = $_.Exception.Response.Headers.Location.PathAndQuery
                Write-Debug "Redirecting to $NewPath"
                $RedirectParams = @{
                    Method            = $Method
                    Path              = $NewPath
                    AdditionalHeaders = $AdditionalHeaders
                    EdgeRCFile        = $EdgeRCFile
                    Section           = $Section
                    AccountSwitchKey  = $AccountSwitchKey
                }
                if ($IncludeResponseHeaders) {
                    $Response, $ResponseHeaders = Invoke-AkamaiRestMethod -IncludeResponseHeaders @RedirectParams
                }
                else {
                    $Response = Invoke-AkamaiRestMethod @RedirectParams
                }
            }
            catch {
                throw $_
            }
        }
        else {
            throw $_
        }
    }
    
    # PS <5 handling
    if ($null -ne ($Response.PSObject.members | Where-Object { $_.Name -eq "redirectLink" }) -and $method -notin "PUT", "POST", "PATCH") {
        try {
            Write-Debug "Redirecting to $($Response.redirectLink)"
            $Response = Invoke-AkamaiRestMethod -Method $Method -Path $Response.redirectLink -AdditionalHeaders $AdditionalHeaders -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        }
        catch {
            throw $_
        }
    }
    
    # Include response headers in return if required
    if ($IncludeResponseHeaders) {
        return $Response, $ResponseHeaders
    }
    else {
        Return $Response
    }
}
# SIG # Begin signature block
# MIIpoQYJKoZIhvcNAQcCoIIpkjCCKY4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDTESIJAZ1Hvl37
# HkJCASHYeQa0z3ZkvHF/3wxaHEI22qCCDo4wggawMIIEmKADAgECAhAIrUCyYNKc
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
# yK+p/pQd52MbOoZWeE4wggfWMIIFvqADAgECAhAPdHYvm0RfSrL6EenUiisxMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjQwMzE1MDAwMDAwWhcNMjUwMzAy
# MjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEDAOBgNV
# BAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRz
# MRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1haSBUZWNobm9sb2dp
# ZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVzIEluYzCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAMKT63Qf7DusoLBOT9oEXEoDEvodyW3S
# +cpx3iPUcL06mhVej3PzKO/O+cFRHIoM3VAWbU/68bsIBJJPQR7E40v5OIBaEM/H
# NCKMzSzdsOajaKS88f6KOD4FJlgqhpHXx0qPCOlDsbal8260KYbg/9rR1elhP90L
# xjcq6S7Ns2NnPXj4RrEf7XV+S7jbsbX0pR4BvzYilmiavYrbu0u357+mJPddDp+I
# /yZSmVEJAcXwqXqO1YbwwWY6B1QL34Qd2gmcb3dRjC7MFVNIDREAawsPDFztmoyE
# FveD4TNwD3klQcC//tzHELCCN6cQN2w3+NrxAgCJOpcdqgdAWiPkHtp5DJttPMLq
# 8OUoCC0352Sj74JyaHbu8Znm4M0M1haQEogItbD4xU+ceNwFJJcOa2vAXP0CEMNI
# STLDLUEFWrhYWbu0RBsN1l5NWUhrlhRWjPkf8tWxLicmpF7YpkzWKSiPCyURmx4B
# kj1xHnMDWx9jjDqznUGzHgNtm8bE53DayRtEeYAp9NvyKSgmCSWwHrjMxI537WPs
# YHnjanskm0o0Dt/RyeHCoF+im+nKrnukAjIexWUGFnzDL2Pe9OPNBFGSwfzWwrUp
# WBwXq/mJe+aqb2vb1jMYTi3YiqfFBi1YKYtUYlQjrdjMoF/hLw87Yqf+Zx74xYOx
# 8e7DUgFCE+klAgMBAAGjggICMIIB/jAfBgNVHSMEGDAWgBRoN+Drtjv4XxGG+/5h
# ewiIZfROQjAdBgNVHQ4EFgQU97GBfkNk6mU8S+SGvccldFp0jxUwPQYDVR0gBDYw
# NDAyBgVngQwBAzApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNv
# bS9DUFMwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMIG1BgNV
# HR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMFOg
# UaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRD
# b2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDCBlAYIKwYBBQUHAQEE
# gYcwgYQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBcBggr
# BgEFBQcwAoZQaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcnQwCQYDVR0T
# BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAsrjp8fupvxd4TgwbABuZJzP7nXHNcI9E
# eoz/Oqx+00AqTs8grcueY3bLcg2Za7HwqTZVy45758027dK32Uoz98TWKg2e4OM0
# OKoDolbJI8Akx91Qi6+f4ayziNrdcxm0SIdsYNo4lR4jhrQojCHgNA+e/5x94ltE
# k0kS8PLLN1NiuFFtkMBP+2X3HCnaA2tt2XR6lbuUXq8B+8OZzlSuyjviT7EhTYcb
# 9B3frETSZ0MwyhQG3HqxIZLvvWF8n3gwfITkQ0B4NRkVW8spKPn2apHkvLM53mJr
# UMXGhDeJySEm009xeZ61HZ1kGZbL3XlqdrzCcLVFZBmpqtw9FSbmomhBAstBWgpA
# B3MpM3Btj1McKyU1846ZboDiWmsd/urHXU7I5v3xAYvqTL7CN5oWfZnHaBFJUFMo
# Zc325j1pLqcJUkszLDPI1IOW7LQAdIjGhfYcpLwkjFgxkmWmRKzR8ONIQRQI8cIU
# uisYDKWvYyipHVLeVxinH6rCoCrZx9FSPwvKpxK9CYWkw4Jd0Hhf/u+j3xBJIusd
# JzgyKhAt/DHa9UG1/IpJsUkx9eb1I+aRASX/oBXGQtKPyDSUPOMThZc9j55Z4wp0
# g/7WqD4KbJQ04xFBEE/gGstFej2+onuZ6cD9v7/drgX4IjbDlgrzHiWJaZojJhF3
# RJ9rC09tn8QxghppMIIaZQIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2Rl
# IFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEA90di+bRF9KsvoR6dSK
# KzEwDQYJYIZIAWUDBAIBBQCgfDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAv
# BgkqhkiG9w0BCQQxIgQgexVZLg7MK5K8x7lnHl2K54zt2Yb4d+2izc9gwE9JnLMw
# DQYJKoZIhvcNAQEBBQAEggIAiK24sMvOlHWYhx4cBZTh3ZiHvj4K8fhrn2R8ogDG
# 489GkpvUWXuGo+skRIL3gaSOHjEQEebWJJzJ/TWWvXC6eWmJRdmBEMkKRvKdnwkJ
# ddmslkkehq0BpgjBAKBx8p7VRot1x+clN0xi456EIeQMK8Jyir20sQEiX5m/egOi
# YIew8oNbvOzJvJo7ZbcBshbH5HrjFCIJq1Lexa/9o55Cxn0YjMUYLH1192mgS29W
# sYsbWocwZhttvC4QDD5W0qFgnYq1R0yIlTEgRVDTX2i2FB28O3WbO7WbF0LxRdSO
# 6RbkcL0yqgcqPfpAI8/WDEYdeA5+j1//uLEGhiiGjFBueC/xrT+zpS20rJwLGYvS
# IJMgMX0qu8mWfHUY51SzTL+3HNXMGk9TCb+6OJ1FW2hvLtpS+hNy7cso011Zg3yn
# cRlY4eSBLZ1UBIuhgrYecFijLG+rAG84H0fwXjRxqrqhyPPRHQQ+QEPpVj9n8fZE
# ng/pX1eEmvnsh0q7+sgHkInPTnST6pbL0vx71mG0UtIntL/WK9yks2KjBFyoHxbX
# /GxF9TGRdi3qswYxBa3GXECoTxy9w9gXN6YvRUIwTLYDA0sl/cjQz13gN3yuzv9f
# aZp0awI392bXlXDLzu1ZTHliXJtlwnQlZerCbWpLrEsvFVkkSehirwlh7IcOT232
# qZGhghc/MIIXOwYKKwYBBAGCNwMDATGCFyswghcnBgkqhkiG9w0BBwKgghcYMIIX
# FAIBAzEPMA0GCWCGSAFlAwQCAQUAMHcGCyqGSIb3DQEJEAEEoGgEZjBkAgEBBglg
# hkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgAOqwmaDgZHBbiMcN2RALjOHRO8om
# 0magDMK6ojyJpUACEFkrlUZSS4FScixsRPU9r4sYDzIwMjQwODE1MTgwNjAxWqCC
# EwkwggbCMIIEqqADAgECAhAFRK/zlJ0IOaa/2z9f5WEWMA0GCSqGSIb3DQEBCwUA
# MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UE
# AxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBp
# bmcgQ0EwHhcNMjMwNzE0MDAwMDAwWhcNMzQxMDEzMjM1OTU5WjBIMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xIDAeBgNVBAMTF0RpZ2lDZXJ0
# IFRpbWVzdGFtcCAyMDIzMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# o1NFhx2DjlusPlSzI+DPn9fl0uddoQ4J3C9Io5d6OyqcZ9xiFVjBqZMRp82qsmrd
# ECmKHmJjadNYnDVxvzqX65RQjxwg6seaOy+WZuNp52n+W8PWKyAcwZeUtKVQgfLP
# ywemMGjKg0La/H8JJJSkghraarrYO8pd3hkYhftF6g1hbJ3+cV7EBpo88MUueQ8b
# ZlLjyNY+X9pD04T10Mf2SC1eRXWWdf7dEKEbg8G45lKVtUfXeCk5a+B4WZfjRCtK
# 1ZXO7wgX6oJkTf8j48qG7rSkIWRw69XloNpjsy7pBe6q9iT1HbybHLK3X9/w7nZ9
# MZllR1WdSiQvrCuXvp/k/XtzPjLuUjT71Lvr1KAsNJvj3m5kGQc3AZEPHLVRzapM
# ZoOIaGK7vEEbeBlt5NkP4FhB+9ixLOFRr7StFQYU6mIIE9NpHnxkTZ0P387RXoyq
# q1AVybPKvNfEO2hEo6U7Qv1zfe7dCv95NBB+plwKWEwAPoVpdceDZNZ1zY8Sdlal
# JPrXxGshuugfNJgvOuprAbD3+yqG7HtSOKmYCaFxsmxxrz64b5bV4RAT/mFHCoz+
# 8LbH1cfebCTwv0KCyqBxPZySkwS0aXAnDU+3tTbRyV8IpHCj7ArxES5k4MsiK8rx
# KBMhSVF+BmbTO77665E42FEHypS34lCh8zrTioPLQHsCAwEAAaOCAYswggGHMA4G
# A1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAW
# gBS6FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUpbbvE+fvzdBkodVWqWUx
# o97V40kwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNy
# bDCBkAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAgEAgRrW3qCptZgXvHCNT4o8aJzYJf/LLOTN
# 6l0ikuyMIgKpuM+AqNnn48XtJoKKcS8Y3U623mzX4WCcK+3tPUiOuGu6fF29wmE3
# aEl3o+uQqhLXJ4Xzjh6S2sJAOJ9dyKAuJXglnSoFeoQpmLZXeY/bJlYrsPOnvTcM
# 2Jh2T1a5UsK2nTipgedtQVyMadG5K8TGe8+c+njikxp2oml101DkRBK+IA2eqUTQ
# +OVJdwhaIcW0z5iVGlS6ubzBaRm6zxbygzc0brBBJt3eWpdPM43UjXd9dUWhpVgm
# agNF3tlQtVCMr1a9TMXhRsUo063nQwBw3syYnhmJA+rUkTfvTVLzyWAhxFZH7doR
# S4wyw4jmWOK22z75X7BC1o/jF5HRqsBV44a/rCcsQdCaM0qoNtS5cpZ+l3k4SF/K
# wtw9Mt911jZnWon49qfH5U81PAC9vpwqbHkB3NpE5jreODsHXjlY9HxzMVWggBHL
# FAx+rrz+pOt5Zapo1iLKO+uagjVXKBbLafIymrLS2Dq4sUaGa7oX/cR3bBVsrquv
# czroSUa31X/MtjjA2Owc9bahuEMs305MfR5ocMB3CtQC4Fxguyj/OOVSWtasFyIj
# TvTs0xf7UGv/B3cfcZdEQcm4RtNsMnxYL2dHZeUbc7aZ+WssBkbvQR7w8F/g29mt
# kIBEr4AQQYowggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3
# DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0
# ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGln
# aUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0Ew
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE
# 8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBML
# JnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU
# 5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLy
# dkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFk
# dECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgm
# f6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9a
# bJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwY
# SH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80Vg
# vCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5
# FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9
# Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsG
# AQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# ZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0
# hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0
# LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcN
# AQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp
# +3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9
# qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8
# ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6Z
# JxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnE
# tp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fx
# ZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV7
# 7QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT
# 1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkP
# Cr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvm
# fxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIFjTCC
# BHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZ
# wuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4V
# pX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAd
# YyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3
# T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjU
# N6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNda
# SaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtm
# mnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyV
# w4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3
# AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYi
# Cd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmp
# sh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNt
# yA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUG
# A1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3
# DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+Ica
# aVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096ww
# epqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcD
# x4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsg
# jTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37Y
# OtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMYIDdjCCA3ICAQEwdzBjMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lD
# ZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAF
# RK/zlJ0IOaa/2z9f5WEWMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzEN
# BgsqhkiG9w0BCRABBDAcBgkqhkiG9w0BCQUxDxcNMjQwODE1MTgwNjAxWjArBgsq
# hkiG9w0BCRACDDEcMBowGDAWBBRm8CsywsLJD4JdzqqKycZPGZzPQDAvBgkqhkiG
# 9w0BCQQxIgQgn6gy1BsuDn+SrbAwpWOiqNzKLyyxeBgNw57AnD5fnsEwNwYLKoZI
# hvcNAQkQAi8xKDAmMCQwIgQg0vbkbe10IszR1EBXaEE2b4KK2lWarjMWr00amtQM
# eCgwDQYJKoZIhvcNAQEBBQAEggIAe/1Wz5sNiDtWnHoXssQVE4YzFT4i+xCpAHku
# ymTNtJZ8YdR2fXqnngDQKfiXozmyHvr+j2v7ckAJMPXU6Nh5746ubr2LFKmPNMnd
# XwsPfoVx99rgEqGhMlr13KC6R6QHNmZOQREGHwnw+kAqWMOxpFMETT/CMnwBf4zx
# jucSWE+C7jhNDuCwH5FRbaLFQUpGsXb7BhjF7KHrULuqKK9fevzZkah7JOb3mPRk
# FwgrzIDJQzrZ/tkmc91flAPLztTySGCjgNJnMdmesKgMj07qrQ3zYBMOu7tXaYVj
# Co5+6ZmanYuhgaFKhCfT+B7glTyqBxN+Ndgv11k3oTFPMQvKqrROGmz5cScMi31Y
# cfITc94qANq0pwcz4Kkk8eDsfIhLKJM3i41epc3+jgBwnLisGCBkvrv7fN1eGS9q
# lq7lFN/u6vbQaUfdnJr+OyGVpFf0YewoN1FYgoi7M5GRrxutb37dUZlZpXi6YWi/
# DLQRznW00kQm03hVF1XOGHVENA2EVBPRWAOHtxgiK9Gy9tPRMR2dGmsfp28hZJmj
# j53QAOhlg6Q9KRnWPoSDotCi3xcbZJMhEnlDAE2p2DTATEtoBuV2ljVg12bMBcxT
# BJ0bjQwHGrm7i1IEM2LWJBV0ac1K4KctsbRJMOcDjGpaStWfbPBXAyQH1LItJf1O
# sHz5Kgk=
# SIG # End signature block
