function Invoke-AkamaiRequest {
    [Alias('iar')]
    [CmdletBinding()]
    param(
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
        [switch]
        $SkipHeaderValidation,

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
        Get-AkamaiOptions | Out-Null
    }

    # Get auth creds from various potential sources
    $Credentials = Get-EdgegridCredentials -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey

    # Validate credentials
    $CredentialsStatus = $Credentials | Test-EdgegridCredentials
    if ($CredentialsStatus.Count -gt 0) {
        $CredentialsStatus | ForEach-Object { Write-Debug $_ }
        throw "One or more Edgegrid credentials appear to be invalid. See debug output for details."
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
    if ($Credentials.AccountKey) {
        $QueryNVCollection.Add('accountSwitchKey', $Credentials.AccountKey)
    }

    # Build Request URL
    [System.UriBuilder]$Request = New-Object -TypeName 'System.UriBuilder'
    $Request.Scheme = 'https'
    $Request.Host = $Credentials.Host
    $Request.Path = $Path
    $Request.Query = $QueryNVCollection.ToString()

    # ReqURL Verification
    Write-Debug "Request URL = $($Request.Uri.AbsoluteUri)"
    if (($null -eq $Request.Uri.AbsoluteUri) -or ($Request.Host -notmatch "akamaiapis.net")) {
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
    $Headers['Authorization'] = Get-EdgegridAuthHeader @AuthHeaderParams

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

    # Add -SkipHeaderValidation if Pwsh 6+
    if ($PSVersionTable.PSVersion -ge '6.0.0') {
        $RequestParams['SkipHeaderValidation'] = $SkipHeaderValidation
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
    # Include credentials
    if ($null -ne $ENV:proxy_use_default_credentials) { $params.ProxyUseDefaultCredentials = $true }

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
        if ($_.Exception.Response) {
            $ExpandedError = Expand-AkamaiError -ErrorRecord $_ -Options $Global:AkamaiOptions
        }
        else {
            $ExpandedError = $_
        }
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
                else {
                    # Extract X-RateLimit-Next header, if present
                    if ($PSVersionTable.PSVersion.Major -ge 6) {
                        if ($ExpandedError.Exception.Response.Headers.Contains('x-ratelimit-next')) {
                            $RateLimitNextHeader = $ExpandedError.Exception.Response.Headers.GetValues('x-ratelimit-next') | Select-Object -First 1
                        }
                    }
                    else {
                        if ('x-ratelimit-next' -in $ExpandedError.Exception.Response.Headers.Keys) {
                            $RateLimitNextHeader = $ExpandedError.Exception.Response.Headers['x-ratelimit-next']
                        }
                    }

                    if ($RateLimitNextHeader) {
                        $RetryDateTime = Get-Date $RateLimitNextHeader
                        $RetryWaitTime = [Math]::Ceiling(($RetryDateTime - (Get-Date)).TotalSeconds) + 1 # Add an extra second for safety
                    }
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
                return Invoke-AkamaiRequest @PSBoundParameters
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
