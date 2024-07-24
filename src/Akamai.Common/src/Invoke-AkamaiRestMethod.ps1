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

  .PARAMETER ResponseHeadersVariable
  A variable containing a response headers dictionary. Enter a variable name without the dollar sign `($)` symbol.

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
        [ValidateSet("GET", "PUT", "POST", "DELETE", "PATCH")]
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
        [string]
        $ResponseHeadersVariable,

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
            if ($key -notin $QueryNVCollection.Keys) {
                $QueryNVCollection.Add($key, $QueryParameters.$key)
            }
            else {
                $QueryNVCollection[$key] = $QueryParameters.$key
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

    # Add additional headers if POSTing or PUTing
    If ($Body) {
        # turn off the "Expect: 100 Continue" header
        # as it's not supported on the Akamai side.
        [System.Net.ServicePointManager]::Expect100Continue = $false
    }

    # Set TLS version to 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    $RequestParameters = @{
        Method             = $Method
        Uri                = $Request.Uri
        Headers            = $Headers
        ContentType        = $ContentType
        MaximumRedirection = 0
    }

    if ($null -ne $ENV:https_proxy) { $RequestParameters.Proxy = $ENV:https_proxy }

    if ($Method -in "PUT", "POST", "PATCH") {
        if ($Body) { $RequestParameters.Body = $Body }
        if ($InputFile) { $RequestParameters.InFile = $InputFile }
    }

    # Add -AllowInsecureRedirect if Pwsh 7.4 or higher
    if ($PSVersionTable.PSVersion.Major -gt 7 -or ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -ge 4)) {
        $RequestParameters['AllowInsecureRedirect'] = $true
    }

    # GET requests typically
    else {
        # Differentiate on PS 5 and later as PS 5's Invoke-RestMethod doesn't behave the same as the later versions
        if ($PSVersionTable.PSVersion.Major -le 5) {
            $RequestParameters.ErrorAction = "SilentlyContinue"
        }
        else {
            $RequestParameters.ErrorAction = "Stop"
            $RequestParameters.ResponseHeadersVariable = $ResponseHeadersVariable
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
                $Response = Invoke-AkamaiRestMethod -Method $Method -Path $NewPath -AdditionalHeaders $AdditionalHeaders -EdgeRCFile $EdgeRCFile -Section $Section -ResponseHeadersVariable $ResponseHeadersVariable -AccountSwitchKey $AccountSwitchKey
            }
            catch {
                throw $_
            }
        }
        elseif ($_.Exception.Response.StatusCode.value__ -eq 429) {
            $retryAfter = $_.Exception.Response.Headers | Where-Object { $_.Key -eq 'Retry-After' } | Select-Object -ExpandProperty Value

            if ( -not $retryAfter ) {
                $retryMessage = $_.ErrorDetails.Message | ConvertFrom-Json | Select-Object -ExpandProperty Detail
                $match = [regex]::Match($retryMessage, 'Retry after: (\d+) seconds')
                $retryAfter = $match.Groups[1].Value
            }

            Write-Debug "Rate limited. Waiting $retryAfter seconds"
            Start-Sleep -Seconds $retryAfter

            $Response = Invoke-AkamaiRestMethod @PSBoundParameters
        }
        elseif ($_.Exception.Response.StatusCode.value__ -eq 500) {
            if ( $script:retryOn500 -le 2 ) {

                $script:retryWaitSec = 20
                $script:retryOn500++

                Write-Verbose "Sleeping $retryWaitSec and will try again"
                Start-Sleep -Seconds $retryWaitSec

                $Response = Invoke-AkamaiRestMethod @PSBoundParameters
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

    # Set ResponseHeadersVariable to be passed back to requesting function
    if ($ResponseHeadersVariable) {
        Set-Variable -name $ResponseHeadersVariable -Value (Get-Variable -Name $ResponseHeadersVariable -ValueOnly -ErrorAction SilentlyContinue) -Scope Script
    }
    Return $Response
}
