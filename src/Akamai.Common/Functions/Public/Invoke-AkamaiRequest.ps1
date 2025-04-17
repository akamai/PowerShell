<#
.SYNOPSIS
Sends a HTTPS request to an Akamai RESTful web service.
.DESCRIPTION
The `Invoke-Akamai RestMethod` cmdlet sends a HTTPS request to Akamai RESTful web services and formats the response based on data type.
When the REST endpoint returns multiple objects, the objects are received as an array. If you pipe the output from `Invoke-AkamaiRequest` to another command, it's sent as a single `[Object[]]` object. The contents of that array are not enumerated for the next command on the pipeline.
.PARAMETER Method
Specifies the method used for the web request. Values are `GET`, `HEAD`, `POST`, `PUT`, `DELETE` and `PATCH`.
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
.PARAMETER SkipHttpErrorCheck
Switch to be passed through to Invoke-WebRequest in order to avoid status codes 300+ throwing an error. Note: only compatible with Pwsh7+
.PARAMETER Retry
Retry index. Used when handling error retries
.PARAMETER EdgeRCFile
The path to an edgerc file. Defaults to `~/.edgerc`. 
.PARAMETER Section
The edgerc section name. Defaults to `default`. 
.PARAMETER AccountSwitchKey
A key used to apply changes to an account external to your credentials' account.
.EXAMPLE
Invoke-AkamaiRequest -Method "GET" -Path "/path/to/api"
`GET` without query parameters. 
.EXAMPLE
Invoke-AkamaiRequest -Method "POST" -Path "/path/to/api" -Body @{"key" = @{"key2" = "value"; "key3" = "value"}}
Request: `POST` without query parameters and an inline body.
Response: The data returned is dependent upon the endpoint and varies.
.EXAMPLE
Invoke-AkamaiRequest -Method "POST" -Path "/path/to/api" -InputFile "~./path/to/body.json"
Request: `POST` without query parameters and path to the JSON body containing the body of the call.
Response: The data returned is dependent upon the endpoint and varies.
.EXAMPLE
Invoke-AkamaiRequest -Method "PUT" -Path "/path/to/api?withParams=true" -Body @{"key" = @{"key2" = "value"; "key3" = "value"}
Request: `PUT` with query parameters for an existing item and an inline body.
Response: The data returned is dependent upon the endpoint and varies.
.EXAMPLE
Invoke-AkamaiRequest -Method "PATCH" -Path "/path/to/api?withParams=true" -Body '{"key":{"key3": "value"}}'
Request: `PATCH` with query parameters for an existing item and an inline body.
Response: The data returned is dependent upon the endpoint and varies.
.EXAMPLE
Invoke-AkamaiRequest -Method "DELETE" -Path "/path/to/api?itemId"
Request: `DELETE` with an ID for the item to delete as a query parameter.
Response: The data returned is dependent upon the endpoint and varies.
.LINK
PowerShell overview: https://techdocs.akamai.com/powershell/docs/overview
.LINK
Online version: https://techdocs.akamai.com/powershell/reference/Invoke-AkamaiRequest
#>

function Invoke-AkamaiRequest {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Path,
        
        [Parameter()]
        [ValidateSet("GET", "HEAD", "PUT", "POST", "DELETE", "PATCH")]
        [string] 
        $Method = "GET",

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
        $SkipHttpErrorCheck,
        
        [Parameter()]
        [int]
        $Retry,
        
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

    ## Define shared variables
    $RedirectStatuses = 301, 302, 307, 308
    $RetryStatuses = 500, 502, 503, 504
    $RetryMethods = 'GET', 'HEAD'
    
    # Make sure options are available
    if ($null -eq $Global:AkamaiOptions) {
        New-AkamaiOptions
    }
    
    # Get auth creds from various potential sources
    $Credentials = Get-AkamaiCredentials -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
    if ($Debug) {
        ## Check creds if in Debug mode
        Confirm-Auth -Auth $Credentials
    }

    # Path with QueryString compatibility
    if ($Path.Contains('?')) {
        $PathElements = $Path.Split('?')
        $Path = $PathElements[0]
        $QueryFromPath = $PathElements[1]
    }

    # Build QueryNameValueCollection
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

    # Add account switch key from $Credentials, if present
    if ($Credentials.account_key) {
        $QueryNVCollection.Add('accountSwitchKey', $Credentials.account_key)
    }
    
    # Build Request URL
    [System.UriBuilder]$Request = New-Object -TypeName 'System.UriBuilder'
    $Request.Scheme = 'https'
    $Request.Host = $Credentials.host
    $Request.Path = $Path
    $Request.Query = $QueryNVCollection.ToString()

    # ReqURL Verification
    Write-Debug "Request URL = $($Request.Uri.AbsoluteUri)"
    If (($null -eq $Request.Uri.AbsoluteUri) -or ($Request.Host -notmatch "akamaiapis.net")) {
        throw "Error: Invalid Request URI"
    }

    # Convert Body to string if not already, but only if Content-Type hasn't been overridden
    $ConvertBody = $false
    if ($null -ne $Body -and $Body -isnot 'String') {
        $ConvertBody = $true
    }
    if ($null -ne $AdditionalHeaders -and $null -ne $AdditionalHeaders['content-type'] -and -not $AdditionalHeaders['content-type'].contains('json')) {
        Write-Debug 'Forgoing body conversion due to custom content-type.'
        $ConvertBody = $false
    }
    if ($ConvertBody) {
        try {
            Write-Debug "Converting Body of type $($Body.GetType().Name) to JSON."
            $Body = ConvertTo-Json -InputObject $Body -Depth 100
        }
        catch {
            Write-Error $_
            throw 'Body could not be converted to a JSON string'
        }
    }

    ## Create IDictionary to hold request headers
    $Headers = @{}
    
    ## Generate Auth header and add to dictionary
    $AuthHeaderParams = @{
        Credentials  = $Credentials
        Method       = $Method
        ExpandedPath = ($Request.Path + $Request.Query)
        Body         = $Body
        InputFile    = $InputFile
        ErrorAction  = 'SilentlyContinue'
    }
    $Headers['Authorization'] = Get-AkamaiAuthHeader @AuthHeaderParams
    
    ## Calculate custom UA
    $UserAgent = Get-AkamaiUserAgent
    $Headers.Add('User-Agent', $UserAgent)
    
    # Add headers
    $Headers.Add('Accept', 'application/json')
    $Headers.Add('Content-Type', 'application/json; charset=utf-8')

    # Add additional headers
    if ($AdditionalHeaders) {
        $AdditionalHeaders.Keys | ForEach-Object {
            $Headers[$_] = $AdditionalHeaders[$_]
        }
    }

    # Add PAPI prefix removal header if required
    if ($Global:AkamaiOptions.DisablePapiPrefixes) {
        $Headers['PAPI-Use-Prefixes'] = 'false'
    }

    # Set ContentType param from Content-Type header. This is sent along with bodies to fix string encoding issues in IRM
    $ContentType = $Headers['Content-Type']

    # turn off the "Expect: 100 Continue" header as it's not supported on the Akamai side.
    [System.Net.ServicePointManager]::Expect100Continue = $false

    # Set TLS version to 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    
    $RequestParams = @{
        Method             = $Method
        Uri                = $Request.Uri
        Headers            = $Headers
        ContentType        = $ContentType
        MaximumRedirection = 0
        ErrorAction        = 'Stop'
        OutVariable        = 'Response'
    }
    
    # Add -AllowInsecureRedirect if Pwsh 7.4 or higher
    if ($PSVersionTable.PSVersion -ge '7.4.0') {
        $RequestParams['AllowInsecureRedirect'] = $true
    }

    # Add -SkipHttpErrorCheck if Pwsh 7+
    if ($PSVersionTable.PSVersion -ge '7.0.0') {
        $RequestParams['SkipHttpErrorCheck'] = $SkipHttpErrorCheck
    }

    # Add -UseBasicParsing if Pwsh < 6
    if ($PSVersionTable.PSVersion -lt '6.0.0') {
        $RequestParams['UseBasicParsing'] = $true
    }
    
    # Support proxy as environment variable
    if ($null -ne $ENV:https_proxy) { $RequestParams.Proxy = $ENV:https_proxy }

    # Add body or inputfile, exclusively
    if ($Body) { $RequestParams.Body = $Body }
    elseif ($InputFile) { $RequestParams.InFile = $InputFile }

    # Add outputfile
    if ($OutputFile) {
        $RequestParams.OutFile = $OutputFile
    }

    ## Backup and set ProgressPreference
    $OldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    
    # Reset retry params
    $RetryRequest = $false
    $RetryWaitTime = $null
    if ($null -eq $PSBoundParameters.Retry) {
        $Retry = 0
    }

    ##---- Make request
    try {
        $Response = Invoke-WebRequest @RequestParams
    }
    catch {
        # Expand error to access exception data during evaluation
        $ExpandedError = Expand-AkamaiError -ErrorRecord $_ -Options $Global:AkamaiOptions
        if ([int] $ExpandedError.Exception.Response.StatusCode -eq 302) {
            # Construct fake response object for redirect chasing
            $Response = [PSCustomObject] @{
                StatusCode = 302
                Headers    = [PSCustomObject] @{
                    Location = $ExpandedError.Exception.Response.Headers.Location
                }
            }
        }
        elseif ($ExpandedError.ErrorDetails.Message -and $ExpandedError.ErrorDetails.Message.Contains('The maximum redirection count has been exceeded')) {
            # Do nothing here, this is expected in pwsh 5.1
        }
        else {
            # 429 handling
            # Extract "retry after X seconds", if it exists. Otherwise, retry using the standard exponential backoff logic
            if ($Global:AkamaiOptions.enableRateLimitRetries -and [int] $ExpandedError.Exception.Response.StatusCode -eq 429) {
                if ($ExpandedError.Exception.Data.detail -match '(?<WaitTime>[\d]+) seconds') {
                    $RetryWaitTime = $Matches.WaitTime
                }
                $RetryRequest = $true
            }
            # General error handling
            elseif ($Global:AkamaiOptions.enableErrorRetries -and [int] $ExpandedError.Exception.Response.StatusCode -in $RetryStatuses -and $Method.ToUpper() -in $RetryMethods) {
                $RetryRequest = $true
            }
            # No recourse other than throwing the error. Ah well.
            else {
                $PSCmdlet.ThrowTerminatingError($ExpandedError)
            }
        }

        # Wait for the calculated period, then repeat the request
        if ($RetryRequest) {
            if ($PSBoundParameters.Retry -ge $Global:AkamaiOptions.maxErrorRetries) {
                Write-Warning "Request will not be retried as retries have reached the maximum limit ($($Global:AkamaiOptions.maxErrorRetries))."
                $PSCmdlet.ThrowTerminatingError($ExpandedError)
            }
            else {
                Write-Warning "Received the following error: $([int] $ExpandedError.Exception.Response.StatusCode) $($ExpandedError.Exception.Response.StatusCode)."
                # Ensure retry is set in PSBoundParameters for the next request
                $PSBoundParameters.Retry = ++$Retry
                if ($RetryWaitTime) {
                    Write-Warning "Waiting for $RetryWaitTime seconds before retrying. Wait time determine from API response."
                }
                else {
                    $RetryWaitTime = $Global:AkamaiOptions.initialErrorWait * ([Math]::Pow(2, $PSBoundParameters.Retry - 1))
                    Write-Warning "Waiting for $RetryWaitTime seconds before retrying."
                }
                Start-Sleep -Seconds $RetryWaitTime
                Write-Debug "Retrying request. Attempt = $($PSBoundParameters.Retry)."
                # Retry request
                $Response = Invoke-AkamaiRequest @PSBoundParameters
            }
        }
    }

    ## Reset ProgressPreference
    $ProgressPreference = $OldProgressPreference

    ## Chase redirects, with signature regeneration
    if ($Response.StatusCode -in $RedirectStatuses) {
        if ($null -eq $Response.Headers.Location) {
            throw "Response with status $($Response.statusCode) missing Location header"
        }
        $Location = $Response.Headers.Location | Select-Object -First 1
        $RedirectUrl = [System.UriBuilder]::new($Location)
        $RedirectPath = $RedirectUrl.Path + $RedirectUrl.Query
        Write-Debug "Redirecting to $RedirectPath."
        $RedirectParams = @{
            'Method'            = $Method
            'Path'              = $RedirectPath
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        
        try {
            $Response = Invoke-AkamaiRequest @RedirectParams
        }
        catch {
            # Expand errors for more useful response, then throw
            $PSCmdlet.ThrowTerminatingError((Expand-AkamaiError -ErrorRecord $_ -Options $Global:AkamaiOptions))
        }
        return $Response
    }
    
    ## Parse response
    $ParsedResponseBody = $null
    if ($Response.Content) {
        # Extract content-type
        if ($null -ne $Response.Headers.'Content-Type') {
            $ResponseContentType = $Response.Headers.'Content-Type' | Select-Object -First 1
        }
        else {
            # Assume empty string, purely to avoid issues evaluating it later. Should maybe default to text/plain?
            $ResponseContentType = ''
        }
        if ($ResponseContentType -is 'Array') {
            $ResponseContentType = $ResponseContentType[0]
        }
        Write-Debug "Response content type = $ResponseContentType"

        # Handle response content
        $ParsedResponseBody = $Response.content
        # Handle IWR byte[] response content
        if ($ParsedResponseBody -is 'Byte[]') {
            Write-Debug "Converting response from byte[]."
            $ParsedResponseBody = [System.Text.Encoding]::UTF8.GetString($ParsedResponseBody)
        }
        # Convert json bodies to PSCustomObject. This can happen in addition to the byte array conversion
        if ($ResponseContentType.Contains('json')) {
            try {
                Write-Debug "Converting response body from JSON."
                $ParsedResponseBody = $ParsedResponseBody | ConvertFrom-Json
            }
            catch {
                Write-Debug "JSON conversion failed. Falling back to raw response."
            }
        }
        # Convert XML bodies to PSCustomObject
        elseif ($ResponseContentType -eq 'application/xml') {
            try {
                Write-Debug "Converting response body from XML."
                $ParsedResponseBody = [xml] $ParsedResponseBody
            }
            catch {
                Write-Debug "XML conversion failed. Falling back to raw response."
            }
        }
        # Convert CSV bodies to PSCustomObject
        elseif ($ResponseContentType -eq 'text/csv') {
            try {
                Write-Debug "Converting response body from XML."
                $ParsedResponseBody = $ParsedResponseBody | ConvertFrom-Csv
            }
            catch {
                Write-Debug "XML conversion failed. Falling back to raw response."
            }
        }
    }
    $ParsedResponse = [PSCustomObject] @{
        Status  = $Response.StatusCode
        Headers = $Response.Headers
        Body    = $ParsedResponseBody
    }

    # Report on 429 limits
    if ($Global:AkamaiOptions.EnableRateLimitWarnings) {
        if ($null -ne $ParsedResponse.Headers -and $null -ne $ParsedResponse.Headers['X-RateLimit-Remaining']) {
            if ($ParsedResponse.Headers['X-RateLimit-Limit']) {
                $RateLimitRemaining = [int] ($ParsedResponse.Headers['X-RateLimit-Remaining'] | Select-Object -First 1)
            }
            if ($ParsedResponse.Headers['X-RateLimit-Limit']) {
                $RateLimitTotal = [int] ($ParsedResponse.Headers['X-RateLimit-Limit'] | Select-Object -First 1)
            }
            if ($RateLimitRemaining -and $RateLimitTotal) {
                $RateLimitPercentUsed = (1 - ($RateLimitRemaining / $RateLimitTotal)) * 100
                $RateLimitPercentDisplay = "{0:F2}" -f $RateLimitPercentUsed
                if ($RateLimitPercentUsed -gt $Global:AkamaiOptions.RateLimitWarningPercentage) {
                    Write-Warning "Akamai Rate Limit used = $RateLimitPercentDisplay%. Remaining requests = $RateLimitRemaining."
                }
            }
        }
    }

    return $ParsedResponse
}

# SIG # Begin signature block
# MIIpnAYJKoZIhvcNAQcCoIIpjTCCKYkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHcFFGCqVObY1b
# ooNbKrhy2PFAoHyaDqxQcUZdl65k9aCCDo4wggawMIIEmKADAgECAhAIrUCyYNKc
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
# MVPcHaArzb8xghpkMIIaYAIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2Rl
# IFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEA+pA0h+kq5EeXpXIQBQ
# X8IwDQYJYIZIAWUDBAIBBQCgfDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAv
# BgkqhkiG9w0BCQQxIgQgP7dZgW49i3v47st/Oawgpa18zHVkn9gqc8TRsZ7r+pAw
# DQYJKoZIhvcNAQEBBQAEggIAnHc7CUYqcQqrMjqiVXHuykOeLhYuWTgma+rrrMdX
# 9hMySFsX8/c5HaUOAh6sctM/DGtAuE3BmvvWFwluAcgkDI2zGmddLXEMvnQJOJVT
# nMP+5PfVtt6MBFL0Od0U2frxJFbF2uem9q+G5Ocq781mHP70nT63JIA8QIHS7K+6
# J/PjW8AJIJv/igzmWk2sqHQ6qmU7E5ja4pKIF4333NVvPgXshTsbO0/rrtY3EJU2
# gQntSdW/9+ErpwGAX/tefr3y3Gj/Wd35cFAev6HBzmfE0/B/US7QiLul17mMeLeZ
# a/oZG/08PgfDc/GndnsV28ULfc4wsgCxrJevzlXrailqQw1RefpbcYrM9P8J9EbS
# p5YS8BH1MAI/RXQ6K6T4+BZDp0p80/OGuslIFf3TgQMUhUmU7wtVK5ArdO3qyxgX
# 6NU1e8zpB9gTDDg9YK8UA4j60ptH8rCwaBOQw7zP0ltLPVO9+aiuOP0PjtVHuIs4
# cNY4qY90fASqd+buFCg5EHVr2X7g05sKFEZKpuZy15TD1c8+Nedk2lXuBtlCiQyq
# yPdHgTw3gW7ZZ2JNaIMlotPqsBcitjYQk1E/qwsmpZEjzwiepv3tIzMtwyMwpI37
# nLJ6+1V6l15Go0g7GT66o/vFNUkymWgzChZgDndGMjdiLdT/L96zrDYhSe2HW2yv
# Saihghc6MIIXNgYKKwYBBAGCNwMDATGCFyYwghciBgkqhkiG9w0BBwKgghcTMIIX
# DwIBAzEPMA0GCWCGSAFlAwQCAQUAMHgGCyqGSIb3DQEJEAEEoGkEZzBlAgEBBglg
# hkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQg4wj2No1QMuTX7mk/sZdBcGaOXwo6
# aDFx9Wp10PWuZ+sCEQC3iUsVd3vN0xup6QcdStFtGA8yMDI1MDQxNTE4MTM0Mlqg
# ghMDMIIGvDCCBKSgAwIBAgIQC65mvFq6f5WHxvnpBOMzBDANBgkqhkiG9w0BAQsF
# ADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNV
# BAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1w
# aW5nIENBMB4XDTI0MDkyNjAwMDAwMFoXDTM1MTEyNTIzNTk1OVowQjELMAkGA1UE
# BhMCVVMxETAPBgNVBAoTCERpZ2lDZXJ0MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1l
# c3RhbXAgMjAyNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL5qc5/2
# lSGrljC6W23mWaO16P2RHxjEiDtqmeOlwf0KMCBDEr4IxHRGd7+L660x5XltSVhh
# K64zi9CeC9B6lUdXM0s71EOcRe8+CEJp+3R2O8oo76EO7o5tLuslxdr9Qq82aKcp
# A9O//X6QE+AcaU/byaCagLD/GLoUb35SfWHh43rOH3bpLEx7pZ7avVnpUVmPvkxT
# 8c2a2yC0WMp8hMu60tZR0ChaV76Nhnj37DEYTX9ReNZ8hIOYe4jl7/r419CvEYVI
# rH6sN00yx49boUuumF9i2T8UuKGn9966fR5X6kgXj3o5WHhHVO+NBikDO0mlUh90
# 2wS/Eeh8F/UFaRp1z5SnROHwSJ+QQRZ1fisD8UTVDSupWJNstVkiqLq+ISTdEjJK
# GjVfIcsgA4l9cbk8Smlzddh4EfvFrpVNnes4c16Jidj5XiPVdsn5n10jxmGpxoMc
# 6iPkoaDhi6JjHd5ibfdp5uzIXp4P0wXkgNs+CO/CacBqU0R4k+8h6gYldp4FCMgr
# XdKWfM4N0u25OEAuEa3JyidxW48jwBqIJqImd93NRxvd1aepSeNeREXAu2xUDEW8
# aqzFQDYmr9ZONuc2MhTMizchNULpUEoA6Vva7b1XCB+1rxvbKmLqfY/M/SdV6mwW
# TyeVy5Z/JkvMFpnQy5wR14GJcv6dQ4aEKOX5AgMBAAGjggGLMIIBhzAOBgNVHQ8B
# Af8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAg
# BgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZ
# bU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFJ9XLAN3DigVkGalY17uT5IfdqBb
# MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAG
# CCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQw
# DQYJKoZIhvcNAQELBQADggIBAD2tHh92mVvjOIQSR9lDkfYR25tOCB3RKE/P09x7
# gUsmXqt40ouRl3lj+8QioVYq3igpwrPvBmZdrlWBb0HvqT00nFSXgmUrDKNSQqGT
# dpjHsPy+LaalTW0qVjvUBhcHzBMutB6HzeledbDCzFzUy34VarPnvIWrqVogK0qM
# 8gJhh/+qDEAIdO/KkYesLyTVOoJ4eTq7gj9UFAL1UruJKlTnCVaM2UeUUW/8z3fv
# jxhN6hdT98Vr2FYlCS7Mbb4Hv5swO+aAXxWUm3WpByXtgVQxiBlTVYzqfLDbe9Pp
# BKDBfk+rabTFDZXoUke7zPgtd7/fvWTlCs30VAGEsshJmLbJ6ZbQ/xll/HjO9JbN
# VekBv2Tgem+mLptR7yIrpaidRJXrI+UzB6vAlk/8a1u7cIqV0yef4uaZFORNekUg
# QHTqddmsPCEIYQP7xGxZBIhdmm4bhYsVA6G2WgNFYagLDBzpmk9104WQzYuVNsxy
# oVLObhx3RugaEGru+SojW4dHPoWrUhftNpFC5H7QEY7MhKRyrBe7ucykW7eaCuWB
# sBb4HOKRFVDcrZgdwaSIqMDiCLg4D+TPVgKx2EgEdeoHNHT9l3ZDBD+XgbF+23/z
# BjeCtxz+dL/9NWR6P2eZRi7zcEO1xwcdcqJsyz/JceENc2Sg8h3KeFUCS7tpFk7C
# rDqkMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsF
# ADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJv
# b3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0
# IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mX
# UaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34
# V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevT
# sbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GD
# Gd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8By
# xbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcg
# Q+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKV
# EStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP
# 0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj3
# 3GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9
# XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2
# udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYD
# VR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1k
# TN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcD
# CDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
# ZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0
# cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmww
# IAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUA
# A4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2q
# KWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVz
# jQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2yS
# vZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQe
# JsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeH
# JLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1P
# tkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5
# h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZ
# Wcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT
# /r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP
# /JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBY0wggR1oAMC
# AQICEA6bGI750C3n79tQ4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIy
# MDgwMTAwMDAwMFoXDTMxMTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8G
# A1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAv+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9
# WKt2ms2uexuEDcQwH/MbpDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+p
# VxZZVXKvaJNwwrK6dZlqczKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7s
# Xk7Ik/ghYZs06wXGXuxbGrzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW
# 7sp7XeOtyU9e5TXnMcvak17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9
# iPWCPhCRcKtVgkEy19sEcypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuap
# oGfdpCe8oU85tRFYF/ckXEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5L
# HucOY67m1O+SkjqePdwA5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGy
# shG3u3/y1YxwLEFgqrFjGESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QM
# IR2yVCkliWzlDlJRR3S+Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1
# P2PsIV/EIFFrb7GrhotPwtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsC
# AwEAAaOCATowggE2MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1k
# TN8uZz/nupiuHA9PMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4G
# A1UdDwEB/wQEAwIBhjB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8E
# PjA8MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwF
# AAOCAQEAcKC/Q1xV5zhfoKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2k
# iHdtvRoU9BNKei8ttzjv9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je
# 1M/RQ0SbQyHrlnKhSLSZy51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJM
# QBk1RmppVLC4oVaO7KTVPeix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwC
# A8sgsKxYoA5AY8WYIsGyWfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaH
# lv1b0VysGMNNn3O3AamfV6peKOK5lDGCA3YwggNyAgEBMHcwYzELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBU
# cnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQQIQC65mvFq6
# f5WHxvnpBOMzBDANBglghkgBZQMEAgEFAKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZI
# hvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTI1MDQxNTE4MTM0MlowKwYLKoZIhvcN
# AQkQAgwxHDAaMBgwFgQU29OF7mLb0j575PZxSFCHJNWGW0UwLwYJKoZIhvcNAQkE
# MSIEINtofptf/x5NEZ54Lhi7Gtybq0+k5WqlzlN9aU5l3TUmMDcGCyqGSIb3DQEJ
# EAIvMSgwJjAkMCIEIHZ2n6jyYy8fQws6IzCu1lZ1/tdz2wXWZbkFk5hDj5rbMA0G
# CSqGSIb3DQEBAQUABIICAH2tb+ZGg5FD8LGlXiiSDTdHxs15hkFB8jY59LG2wFMh
# WVEJKi5vJ5WvLHR/ZsgmUUKE21yCC341dyJEg3NXQ6N3TVpz3L7vt45OsfuAIjFw
# X9RdSdP+lo1T/tvmHp1HPLqMdIw54+5ABHLHCl2U883u/ytN45UpJJKUnGwY95C2
# esb2xlO+fDH2qwEp4bJfQouXqsApy/bO3S056iPP/sfsNE8T8F8rD/o3VyDCEzMG
# Gn3rfva9pN7RHyJ6/7z4xL1+cF8MjNXrGCmIJJpSDj3NhvKzgcQVhGJM2o5jfbTh
# 1sh684msTfixUYP6dI6C1+WHLeYRGeLKMouYL2pyUYjEjqBMVYAPECuzbNVy9LFJ
# opxlINyvdOsoDVn9g+BaWcbKSS7nasV+J/rMmM0hFmXdD7cWDy69Su/QkGTeXia3
# i19G7V/KnWGrv/8QggJHqmV3OeLTSsk/A+63XW7SOU/YREnblaIZtIG6kRbCqOsn
# kaAS5PqGXoGepoB3eizuruMyzQh+NjRm9OXl80wa/bS8Rc5FnUKM7JXBO4S8bgmj
# I/IuHJ73KwWDVrpuF3GTVn6jTv3nPXwiYZ+hIJ2JrwOKhpgphNJcqGseBoOcMPxC
# E7YS/1q80D8TbKtYVblzuqdSwcOeCXQUTi9AODPw+V8qAATiR/Vubz3fmAoYR1IN
# SIG # End signature block
