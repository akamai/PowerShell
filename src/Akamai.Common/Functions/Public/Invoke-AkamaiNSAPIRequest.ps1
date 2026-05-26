function Invoke-AkamaiNSAPIRequest {
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
        [string]
        $AuthFile,

        [Parameter()]
        [string]
        $Section
    )

    $Auth = Get-NetstorageCredentials -AuthFile $AuthFile -Section $Section

    # Correct Windows backslash paths before signature calculation
    $Path = $Path.Replace('\', '/')
    #Prepend path with / and add CP Code
    $CPCode = $Auth.cpcode
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

    #GUID for request signing
    $Nonce = Get-RandomString -Length 20 -Hex

    # Generate X-Akamai-ACS-Auth-Data variable
    $Version = 5
    $EpochTime = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
    $AuthDataHeader = "$Version, 0.0.0.0, 0.0.0.0, $EpochTime, $Nonce, $($Auth.id)"
    $Headers['X-Akamai-ACS-Auth-Data'] = $AuthDataHeader

    # Create sign-string for encrypting, reuse shared Get-EncryptedMessage
    $SignString = "$Path`nx-akamai-acs-action:$ActionHeader`n"
    $EncryptMessage = $AuthDataHeader + $SignString
    $Signature = Get-EncryptedMessage -secret $Auth.key -message $EncryptMessage
    $Headers['X-Akamai-ACS-Auth-Sign'] = $Signature

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
    $ReqURL = "https://$($Auth.host)" + $Path

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

    ## Do It.
    $Response = Invoke-RestMethod @Params
    
    return $Response
}
