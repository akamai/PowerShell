function Invoke-NetstorageRequest {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [ValidateSet('delete', 'dir', 'download', 'du', 'list', 'mkdir', 'mtime', 'quick-delete', 'rename', 'rmdir', 'stat', 'symlink', 'upload')]
        [string]
        $Action,

        [Parameter()]
        [Hashtable]
        $AdditionalOptions,

        [Parameter()]
        [string]
        $Body,

        [Parameter()]
        [string]
        $InputFile,

        [Parameter()]
        [string]
        $OutputFile,

        [Parameter()]
        [int]
        $Retry,

        [Parameter()]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    $Credentials = Get-NetstorageCredentials -NSRCFile $NSRCFile -Section $Section

    # Correct Windows backslash paths before signature calculation
    $Path = $Path.Replace('\', '/')
    #Prepend path with / and add CP Code
    $CPCode = $Credentials.cpcode
    if (!($Path.StartsWith("/"))) {
        $Path = "/$Path"
    }
    if (!($Path.StartsWith("/$CPCode"))) {
        $Path = "/$CPCode/$Path"
        $Path = $Path.Replace('//', '/')
    }
    # Handle spaces in filenames
    $Path = $Path.Replace(' ', '%20')
    # Do the same for any additional options that might be missing the CP Code prefix
    $PathFixAttributes = @( 
        'destination'
        'target'
    )
    $PathFixAttributes | ForEach-Object {
        if ($AdditionalOptions -and $AdditionalOptions[$_] -and !($AdditionalOptions[$_].StartsWith("%2F$CPCode"))) {
            $AdditionalOptions[$_] = "%2F$CPCode$($AdditionalOptions[$_])"
        }
    }
    # Special fix for end
    if ($Action -eq 'list' -and $AdditionalOptions -and $AdditionalOptions['end']) {
        $End = $AdditionalOptions['end']
        if ($End.StartsWith('/')) {
            $End = $End.SubString(1)
        }
        if (-not ($End.StartsWith("$CPCode"))) {
            $End = "$CPCode/$End"
        }
        if ($End.EndsWith('/')) {
            $End = $End -replace '\/$', '0'
        }
        if (-not $End.EndsWith('0')) {
            $End = $End + '0'
        }
        if ($End -eq $CPCode -or $End -eq ($CPCode + '0')) {
            $AdditionalOptions.Remove('end') | Out-Null
        }
        else {
            $AdditionalOptions['end'] = $End
        }
    }

    $Headers = @{}
    
    # Action Header
    $Options = @{
        'version' = '1'
        'action'  = $Action
    }
    if ($AdditionalOptions) {
        $Options += $AdditionalOptions
    }

    $Options.Keys | ForEach-Object {
        $ActionHeader += "$_=$($Options[$_])&"
    }

    if ($ActionHeader.EndsWith("&")) {
        $ActionHeader = $ActionHeader.Substring(0, $ActionHeader.LastIndexOf("&"))
    }
    # Remove null options
    $ActionHeader = Format-QueryString -QueryString $ActionHeader
    $Headers['X-Akamai-ACS-Action'] = $ActionHeader

    # Set X-Akamai-ACS-Auth-Data and X-Akamai-ACS-Auth-Sign headers
    $Headers = Set-NetstorageAuthHeaders -Headers $Headers -Credentials $Credentials

    # Determine HTTP Method from Action
    Switch ($Action) {
        'delete' { $Method = "PUT" }
        'dir' { $Method = "GET" }
        'download' { $Method = "GET" }
        'du' { $Method = "GET" }
        'list' { $Method = "GET" }
        'mkdir' { $Method = "PUT" }
        'mtime' { $Method = "POST" }
        'quick-delete' { $Method = "POST" }
        'rename' { $Method = "POST" }
        'rmdir' { $Method = "POST" }
        'stat' { $Method = "GET" }
        'symlink' { $Method = "POST" }
        'upload' { $Method = "PUT" }
    }

    # Set ReqURL from NSAPI hostname and supplied path
    $ReqURL = "https://$($Credentials.host)" + $Path

    $Params = @{
        method             = $Method
        Uri                = $ReqURL
        Headers            = $Headers
        MaximumRedirection = 0
        ErrorAction        = 'Stop'
    }

    ## Request Body
    if ($Body -ne '') {
        $Params.Body = $Body
    }

    ## InputFile
    if ($InputFile -ne '') {
        $Params.InFile = $InputFile
    }

    ## OutputFile
    if ($OutputFile -ne '') {
        $Params.OutFile = $OutputFile
    }

    ## Proxy
    if ($ENV:https_proxy) {
        $Params.Proxy = $ENV:https_proxy
    }

    # Include credentials
    if ($null -ne $ENV:proxy_use_default_credentials) {
        $Params.ProxyUseDefaultCredentials = $true 
    }

    # Reset retry params
    $RetryRequest = $false
    $RetryWaitTime = $null
    if ($null -eq $PSBoundParameters.Retry) {
        $Retry = 0
    }

    ## Do It.
    try {
        $Response = Invoke-RestMethod @Params
    }
    catch {
        if ($null -ne $_.Exception.Response) {
            # Expand error to access exception data during evaluation
            $ExpandedError = Expand-AkamaiError -ErrorRecord $_ -Options $Global:AkamaiOptions
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
            # No recourse other than throwing the error.
            else {
                $PSCmdlet.ThrowTerminatingError($ExpandedError)
            }

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
                    $Response = Invoke-NetstorageRequest @PSBoundParameters
                }
            }
        }
        else {
            throw $_
        }
    }
    
    return $Response
}
