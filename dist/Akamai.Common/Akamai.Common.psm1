function ConvertFrom-Base64 {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $EncodedString
    )

    Write-Debug "Decoding '$EncodedString'"
    try {
        $DecodedString = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedString))
        return $DecodedString
    }
    catch {
        Write-Debug "Error decoding '$EncodedString'"
        Write-Debug $_
        return $EncodedString
    }
}

function ConvertTo-Base64 {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UnencodedString
    )

    Write-Debug "Encoding '$UnencodedString'"
    try {
        $DecodedString = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($UnencodedString))
        return $DecodedString
    }
    catch {
        Write-Debug "Error encoding '$UnencodedString'"
        Write-Debug $_
        return $UnencodedString
    }
}

function Expand-AkamaiError {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord,
        
        [Parameter()]
        [PSCustomObject]
        $Options
    )

    # Extract response content type
    Write-Debug "Extracting content type"
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        if ('Content-Type' -in $ErrorRecord.Exception.Response.Headers.Keys) {
            $ResponseContentType = $ErrorRecord.Exception.Response.Headers.GetValues('Content-Type') -join ','
        }
    }
    else {
        if ($null -ne $ErrorRecord.Exception.Response.Content.Headers -and $ErrorRecord.Exception.Response.Content.Headers.Contains('Content-Type')) {
            $ResponseContentType = $ErrorRecord.Exception.Response.Content.Headers.GetValues('Content-Type') -join ','
        }
    }
    Write-Debug "ResponseContentType = $ResponseContentType"
    
    # If json, convert to object to extract useful info
    $ErrorData = $null
    if ($ResponseContentType -and $ResponseContentType.Contains('json')) {
        if ($ErrorRecord.ErrorDetails.Message) {
            try {
                Write-Debug "Extracting error data."
                $ErrorData = ConvertFrom-Json -InputObject $ErrorRecord.ErrorDetails.Message
            }
            catch {
                Write-Debug "Failed to convert error response body from JSON."
                Write-Debug $_
            }
    
            if ($ErrorData) {
                try {
                    # Remove closing full stops for printing
                    'title', 'errors', 'detail' | ForEach-Object {
                        if ($ErrorData.$_ -and $ErrorData.$_ -is 'String' -and $ErrorData.$_.EndsWith('.')) {
                            $ErrorData.$_ = $ErrorData.$_.SubString(0, $ErrorData.$_.Length - 1)
                        }
                    }
                }
                catch {
                    Write-Debug "Failed to clean up error data"
                    Write-Debug $_
                }
            }
        }
        else {
            Write-Debug "Thrown error has no Message element."
        }
    }

    # Add status if missing
    if ($null -ne $ErrorData -and $null -eq $ErrorData.status -and $null -ne $ErrorRecord.Exception.Response.StatusCode) {
        $ErrorData | Add-Member -NotePropertyName status -NotePropertyValue ([int] $ErrorRecord.Exception.Response.StatusCode)
    }
    Write-Debug "Status = $($ErrorData.Status)"

    # Override error details
    $ErrorMessage = $ErrorRecord.ErrorDetails.Message
    if ($null -ne $ErrorData.status -and $null -ne $ErrorData.detail) {
        Write-Debug "Setting errormessage from title and detail."
        $ErrorMessage = "HTTP $($ErrorData.status) - $($ErrorData.title) - $($ErrorData.detail). See `$Error[0].exception.data for more information."
    }
    elseif ($null -ne $ErrorData.status -and $ErrorData.errors -is 'String') {
        Write-Debug "Setting errormessage from title ($($ErrorData.title)) and errors ($($ErrorData.errors))."
        $ErrorMessage = "HTTP $($ErrorData.status) - $($ErrorData.title) - $($ErrorData.errors). See `$Error[0].exception.data for more information."
    }
    elseif ($null -ne $ErrorData.status -and $ErrorData.errors -isnot 'String') {
        Write-Debug "Setting errormessage from title only."
        $ErrorMessage = "HTTP $($ErrorData.status) - $($ErrorData.title). See `$Error[0].exception.data for more information."
    }
    elseif ($null -ne $ErrorData.code -and $null -ne $ErrorData.title) {
        Write-Debug "Setting errormessage from title only."
        $ErrorMessage = "$($ErrorData.code) - $($ErrorData.title). See `$Error[0].exception.data for more information."
    }
    elseif ($ErrorRecord.Exception -is [InvalidOperationException]) {
        Write-Debug "Invalid operation. Using original message."
    }
    # Use default error message if API data is not available
    else {
        Write-Debug "Defaulting to original error message."
        $ErrorMessage = $ErrorRecord.Exception.Message
    }

    # Create new error
    $ExpandedError = [System.Management.Automation.ErrorRecord]::new(
        [System.InvalidOperationException]::new($ErrorMessage, $ErrorRecord.Exception),
        $ErrorRecord.FullyQualifiedErrorId,
        $ErrorRecord.CategoryInfo.Category,
        $ErrorRecord.TargetObject)
    # Copy items which aren't replicated
    'Response', 'HttpRequestError', 'StatusCode' | ForEach-Object {
        $ExpandedError.Exception | Add-Member -MemberType NoteProperty -Name $_ -Value $ErrorRecord.Exception.$_
    }
        
    # Evaluate known errors and add recommended actions if found
    if ($null -ne $ErrorMessage) {
        $ExpandedError.ErrorDetails = $ErrorMessage
        # Set recommendedAction, if found
        $KnownError = $Script:KnownErrors | Where-Object { $ErrorData.Detail -like "*$($_.Error)*" }
        if ($KnownError) {
            if ($Options.EnableRecommendedActions -and $KnownError.recommendedAction) {
                $ExpandedError.ErrorDetails.RecommendedAction = $KnownError.recommendedAction
            }
        }
    }
    
    # Rerun loop to copy data to target exception
    if ($null -ne $ErrorData) {
        $ErrorData.PSObject.Properties.Name | foreach-object {
            $ExpandedError.Exception.Data.Add($_, $ErrorData.$_)
        }
    }

    return $ExpandedError
}

function Format-FileName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Filename
    )
    
    $BadCharacters = @(
        '\',
        '/',
        ':',
        '*',
        '?',
        '"',
        '<',
        '>',
        '|'
    )

    $SanitizedFilename = $Filename
    foreach ($BadCharacter in $BadCharacters) {
        $SanitizedFilename = $SanitizedFilename.Replace($BadCharacter, [System.Web.HttpUtility]::UrlEncode($BadCharacter))
    }

    # Special Handling for asterisk, which the HttpUtility doesn't encode
    $SanitizedFilename = $SanitizedFilename.Replace('*', '%2A')

    # Trim whitespace
    $SanitizedFilename = $SanitizedFilename.Trim()
    
    return $SanitizedFilename
}








# Will remove null query parameters and encode invalid characters
function Format-QueryString {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $QueryString
    )
    
    $ValidParameters = New-Object -TypeName System.Collections.ArrayList

    # Remove invalid characters
    $QueryString = $QueryString.Replace(" ", "%20")
    
    # Parse Elements
    if ($QueryString.Contains("&")) {
        $Parameters = $QueryString.Split("&")
    }
    else {
        $Parameters = $QueryString
    }

    foreach ($Parameter in $Parameters) {
        if (!$Parameter.Contains("=")) {
            Write-Host -ForegroundColor Red "ERROR: '$Parameter' has no value."
            return $QueryString
        }
        else {
            if ($Parameter.Length -gt $Parameter.IndexOf("=") + 1) {
                $ValidParameters.Add($Parameter) | Out-Null
            }
        }
    }

    if ($ValidParameters.Count -eq 0) {
        return $null
    }
    else {
        $JoinedParameters = $ValidParameters -join "&"
        return $JoinedParameters
    }
}

function Get-AkamaiUserAgent {
    # Extract Version from loaded module
    $Module = Get-Module Akamai.Common
    if ($Module) {
        $ModuleVersion = $Module.Version
    }
    else {
        $ModuleVersion = 'Unknown'
    }
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        #< 6 is missing the OS member of PSVersionTable, so we use env variables
        $OS = $PSVersionTable.OS
    }
    else {
        $OS = $Env:OS
    }
    
    $UserAgent = "AkamaiPowershell/$ModuleVersion (Powershell $PSEdition $($PSVersionTable.PSVersion) $PSCulture, $OS)"
    return $UserAgent
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
        throw "Source param is of an unhandled type '$($Source.GetType().Name)'"
    }

    return $BodyObject
}

function Get-EdgegridAuthHeader {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Credentials,

        [Parameter(Mandatory)]
        [string] 
        $Method,
        
        [Parameter(Mandatory)]
        [string]
        $ExpandedPath,

        [Parameter()]
        [string]
        $Body,
        
        [Parameter()]
        [string] 
        $InputFile,

        [Parameter()]
        [string] 
        $MaxBody = 131072
    )

    # Sanitize Method param
    $Method = $Method.ToUpper()

    # Timestamp for request signing
    $TimeStamp = [DateTime]::UtcNow.ToString("yyyyMMddTHH:mm:sszz00")

    # GUID for request signing
    $Nonce = [GUID]::NewGuid()

    # Build data string for signature generation
    $SignatureData = $Method + "`thttps`t"
    $SignatureData += $Credentials.Host + "`t" + $ExpandedPath

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
            if ($PSVersionTable.PSVersion.Major -lt 6) {
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
    $SignatureData += "client_token=" + $Credentials.ClientToken + ";"
    $SignatureData += "access_token=" + $Credentials.AccessToken + ";"
    $SignatureData += "timestamp=" + $TimeStamp + ";"
    $SignatureData += "nonce=" + $Nonce + ";"

    Write-Debug "SignatureData = $SignatureData"

    # Generate SigningKey
    $SigningKey = Get-EncryptedMessage -secret $Credentials.ClientSecret -message $TimeStamp

    # Generate Auth Signature
    $Signature = Get-EncryptedMessage -secret $SigningKey -message $SignatureData

    # Create AuthHeader
    $AuthorizationHeader = "EG1-HMAC-SHA256 "
    $AuthorizationHeader += "client_token=" + $Credentials.ClientToken + ";"
    $AuthorizationHeader += "access_token=" + $Credentials.AccessToken + ";"
    $AuthorizationHeader += "timestamp=" + $TimeStamp + ";"
    $AuthorizationHeader += "nonce=" + $Nonce + ";"
    $AuthorizationHeader += "signature=" + $Signature

    return $AuthorizationHeader
}
function Get-EncryptedMessage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Secret,

        [Parameter(Mandatory)]
        [string]
        $Message
    )

    [byte[]] $KeyByte = [System.Text.Encoding]::UTF8.GetBytes($Secret)
    [byte[]] $MessageBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $HMAC = new-object System.Security.Cryptography.HMACSHA256((, $keyByte))
    [byte[]] $HashMessage = $HMAC.ComputeHash($MessageBytes)
    $EncryptedMessage = [System.Convert]::ToBase64String($HashMessage)

    return $EncryptedMessage
}

function Get-RandomString {
    [CmdletBinding(DefaultParameterSetName = 'Alphabetical')]
    Param(
        [Parameter()]
        [int]
        $Length = 16,

        [Parameter(Mandatory, ParameterSetName = 'Alphabetical')]
        [switch]
        $Alphabetical,

        [Parameter(Mandatory, ParameterSetName = 'AlphaNumeric')]
        [switch]
        $AlphaNumeric,

        [Parameter(Mandatory, ParameterSetName = 'Numerical')]
        [switch]
        $Numerical,

        [Parameter(Mandatory, ParameterSetName = 'Hex')]
        [switch]
        $Hex
    )

    $Multiplier = 120
    $AlphabetRange = (97..122)
    $AtoFRange = (97..102)
    $NumberRange = (48..57)

    Switch ($PSCmdlet.ParameterSetName) {
        'Alphabetical' { $CharRange = $AlphabetRange }
        'AlphaNumeric' { $CharRange = $AlphabetRange + $NumberRange }
        'Numerical' { $CharRange = $NumberRange }
        'Hex' { $CharRange = $AtoFRange + $NumberRange }
    }

    $Response = -join ( $CharRange * $Multiplier | Get-Random -Count $Length | ForEach-Object { [char]$_ })
    return $Response
}

function Set-NetstorageAuthHeaders {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Hashtable]
        $Headers,

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Credentials
    )

    #GUID for request signing
    $Nonce = Get-RandomString -Length 20 -Hex

    # Generate X-Akamai-ACS-Auth-Data variable
    $Version = 5
    $EpochTime = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
    $AuthDataHeader = "$Version, 0.0.0.0, 0.0.0.0, $EpochTime, $Nonce, $($Credentials.id)"
    $Headers['X-Akamai-ACS-Auth-Data'] = $AuthDataHeader

    # Create sign-string for encrypting, reuse shared Get-EncryptedMessage
    $SignString = "$Path`nx-akamai-acs-action:$ActionHeader`n"
    $EncryptMessage = $AuthDataHeader + $SignString
    $Signature = Get-EncryptedMessage -secret $Credentials.key -message $EncryptMessage
    $Headers['X-Akamai-ACS-Auth-Sign'] = $Signature

    return $Headers
}
function Test-ISO8601 {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $DateTime,
        
        [Parameter()]
        [switch]
        $RequireTime
    )

    $ISO8601General = '^[\d]{4}-[\d]{2}-[\d]{2}(T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?)?$'
    $ISO8601TimeRequired = '^[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?$'

    if ($RequireTime) {
        if ($DateTime -notmatch $ISO8601TimeRequired) {
            throw "'$DateTime' is not a valid ISO 8601 datetime. Please ensure that the parameter is of the format 'YYYY-MM-DDThh:mm:ss(Z|+-HH)'"
        }
    }
    else {
        if ($DateTime -notmatch $ISO8601General) {
            throw "'$DateTime' is not a valid ISO 8601 datetime. Please ensure that the parameter is of the format 'YYYY-MM-DDThh:mm:ss(Z|+-HH)'"
        }
    }
}

function Clear-AkamaiDataCache {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(ParameterSetName = 'API endpoint name')]
        [string]
        $APIEndpointName,

        [Parameter(ParameterSetName = 'API endpoint ID')]
        [string]
        $APIEndpointID,

        [Parameter(ParameterSetName = 'AppSec config name')]
        [string]
        $AppSecConfigName,

        [Parameter(ParameterSetName = 'AppSec config ID')]
        [string]
        $AppSecConfigID,

        [Parameter(ParameterSetName = 'AppSec config name')]
        [Parameter(ParameterSetName = 'AppSec config ID')]
        [string]
        $AppSecPolicyName,

        [Parameter(ParameterSetName = 'AppSec config name')]
        [Parameter(ParameterSetName = 'AppSec config ID')]
        [string]
        $AppSecPolicyID,

        [Parameter(ParameterSetName = 'Client List name')]
        [string]
        $ClientListName,

        [Parameter(ParameterSetName = 'Client List ID')]
        [string]
        $ClientListID,

        [Parameter(ParameterSetName = 'EdgeWorker name')]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'EdgeWorker ID')]
        [string]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'METS CaSet name')]
        [string]
        $METSCaSetName,

        [Parameter(ParameterSetName = 'METS CaSet ID')]
        [string]
        $METSCaSetID,

        [Parameter(ParameterSetName = 'MOKS client cert name')]
        [string]
        $MOKSClientCertName,

        [Parameter(ParameterSetName = 'MOKS client cert ID')]
        [string]
        $MOKSClientCertID,

        [Parameter(ParameterSetName = 'Property name')]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Property ID')]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Include name')]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'Include ID')]
        [string]
        $IncludeID
    )

    if (-not $AkamaiOptions.EnableDataCache) {
        Write-Debug "Data cache not enabled. No cache to clear."
        return
    }

    # Handle input combo
    if (($AppSecPolicyName -or $AppSecPolicyID) -and -not $AppSecConfigName -and -not $AppSecConfigID) {
        throw "To remove an AppSec policy by name or ID you must also provide -AppSecConfigName or -AppSecConfigID."
    }

    # Remove entire cache with no other prompts
    if ($PSCmdlet.ParameterSetName -eq '__AllParameterSets') {
        Write-Debug "Clearing Akamai Data Cache."
        $Global:AkamaiDataCache = $null
        New-AkamaiDataCache
    }

    # Otherwise, remove individual elements
    # ---- API Endpoints
    if ($APIEndpointID) {
        foreach ($Key in $AkamaiDataCache.APIDefinitions.APIEndpoints.Keys) {
            if ($AkamaiDataCache.APIDefinitions.APIEndpoints.$Key.APIEndpointID -eq $APIEndpointID) {
                $APIEndpointName = $Key
                break
            }
        }
    }
    if ($APIEndpointName) {
        if ($null -ne $AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName) {
            Write-Debug "Removing APIEndpoint '$APIEndpointName' from data cache."
            $AkamaiDataCache.APIDefinitions.APIEndpoints.Remove($APIEndpointName)
        }
    }

    # ---- AppSec
    if ($AppSecConfigID) {
        foreach ($Key in $AkamaiDataCache.AppSec.Configs.Keys) {
            if ($AkamaiDataCache.AppSec.Configs.$Key.ConfigId -eq $AppSecConfigID) {
                $AppSecConfigName = $Key
                break
            }
        }
    }
    if ($AppSecConfigName) {
        # Check for policy info, as if present we only delete that, not the whole config key
        if ($AppSecPolicyID -or $AppSecPolicyName) {
            if ($AppSecPolicyID) {
                foreach ($Key in $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.Keys) {
                    if ($AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.$Key.PolicyID -eq $AppSecPolicyID) {
                        $AppSecPolicyName = $Key
                        break
                    }
                }
            }
            if ($AppSecPolicyName) {
                if ($null -ne $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.$AppSecPolicyName) {
                    Write-Debug "Removing AppSec policy '$AppSecPolicyName' from data cache."
                    $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.Remove($AppSecPolicyName)
                }
            }
        }
        else {
            if ($null -ne $AkamaiDataCache.AppSec.Configs.$AppSecConfigName) {
                Write-Debug "Removing AppSec config '$AppSecConfigName' from data cache."
                $AkamaiDataCache.AppSec.Configs.Remove($AppSecConfigName)
            }
        }
    }

    # ---- Client Lists
    if ($ClientListID) {
        foreach ($Key in $AkamaiDataCache.ClientLists.Lists.Keys) {
            if ($AkamaiDataCache.ClientLists.Lists.$Key.ListID -eq $ClientListID) {
                $ClientListName = $Key
                break
            }
        }
    }
    if ($ClientListName) {
        if ($null -ne $AkamaiDataCache.ClientLists.Lists.$ClientListName) {
            Write-Debug "Removing client list '$ClientListName' from data cache."
            $AkamaiDataCache.ClientLists.Lists.Remove($ClientListName)
        }
    }

    # ---- EdgeWorkers
    if ($EdgeWorkerID) {
        foreach ($Key in $AkamaiDataCache.EdgeWorkers.EdgeWorkers.Keys) {
            if ($AkamaiDataCache.EdgeWorkers.EdgeWorkers.$Key.EdgeWorkerID -eq $EdgeWorkerID) {
                $EdgeWorkerName = $Key
                break
            }
        }
    }
    if ($EdgeWorkerName) {
        if ($null -ne $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName) {
            Write-Debug "Removing EdgeWorker '$EdgeWorkerName' from data cache."
            $AkamaiDataCache.EdgeWorkers.EdgeWorkers.Remove($EdgeWorkerName)
        }
    }

    # ---- METS
    if ($METSCaSetID) {
        foreach ($Key in $AkamaiDataCache.METS.CASets.Keys) {
            if ($AkamaiDataCache.METS.CASets.$Key.CASetID -eq $METSCaSetID) {
                $METSCaSetName = $Key
                break
            }
        }
    }
    if ($METSCaSetName) {
        if ($null -ne $AkamaiDataCache.METS.CASets.$METSCaSetName) {
            Write-Debug "Removing METS CA Set '$METSCaSetName' from data cache."
            $AkamaiDataCache.METS.CASets.Remove($METSCaSetName)
        }
    }

    # ---- MOKS
    if ($MOKSClientCertID) {
        foreach ($Key in $AkamaiDataCache.MOKS.ClientCerts.Keys) {
            if ($AkamaiDataCache.MOKS.ClientCerts.$Key.CertificateID -eq $MOKSClientCertID) {
                $MOKSClientCertName = $Key
                break
            }
        }
    }
    if ($MOKSClientCertName) {
        if ($null -ne $AkamaiDataCache.MOKS.ClientCerts.$MOKSClientCertName) {
            Write-Debug "Removing MOKS Client Certificate '$MOKSClientCertName' from data cache."
            $AkamaiDataCache.MOKS.ClientCerts.Remove($MOKSClientCertName)
        }
    }

    # ---- Property
    if ($PropertyID) {
        foreach ($Key in $AkamaiDataCache.Property.Properties.Keys) {
            if ($AkamaiDataCache.Property.Properties.$Key.PropertyID -eq $PropertyID) {
                $PropertyName = $Key
                break
            }
        }
    }
    if ($PropertyName) {
        if ($null -ne $AkamaiDataCache.Property.Properties.$PropertyName) {
            Write-Debug "Removing property '$PropertyName' from data cache."
            $AkamaiDataCache.Property.Properties.Remove($PropertyName)
        }
    }

    if ($IncludeID) {
        foreach ($Key in $AkamaiDataCache.Property.Includes.Keys) {
            if ($AkamaiDataCache.Property.Includes.$Key.IncludeID -eq $IncludeID) {
                $IncludeName = $Key
                break
            }
        }
    }
    if ($IncludeName) {
        if ($null -ne $AkamaiDataCache.Property.Includes.$IncludeName) {
            Write-Debug "Removing include '$IncludeName' from data cache."
            $AkamaiDataCache.Property.Includes.Remove($IncludeName)
        }
    }
}

function Clear-AkamaiOptions {
    if ($env:AkamaiOptionsPath) {
        $OptionsPath = $env:AkamaiOptionsPath
    }
    else {
        $OptionsPath = '~/.akamai-pwsh/options.json'
    }
    if ((Test-Path $OptionsPath)) {
        Remove-Item -Path $OptionsPath
    }
}

function Clear-EdgegridCredentials {
    [CmdletBinding()]
    Param()

    process {
        $Keys = 'ACCESS_TOKEN', 'CLIENT_TOKEN', 'CLIENT_SECRET', 'HOST', 'ACCOUNT_KEY'
        foreach ($Key in $Keys) {
            Get-ChildItem -Path "Env:\AKAMAI_*$Key" | ForEach-Object {
                Write-Debug "Removing environment variable: $($_.Name)"
                $_ | Remove-Item
            }
        }
    }
}
function Clear-NetstorageCredentials {
    [CmdletBinding()]
    Param()

    process {
        $Keys = 'CPCODE', 'GROUP', 'HOST', 'ID', 'KEY'
        foreach ($Key in $Keys) {
            Get-ChildItem -Path "Env:\NETSTORAGE_*$Key" | ForEach-Object {
                Write-Debug "Removing environment variable: $($_.Name)"
                $_ | Remove-Item
            }
        }
    }
}
function Export-EdgegridCredentials {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $EdgeRCFile = '~/.edgerc',

        [Parameter()]
        [string]
        $Section = 'default',

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('account_key')]
        [Alias('AccountKey')]
        [string]
        $AccountSwitchKey,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $HostName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('client_token')]
        [string]
        $ClientToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('access_token')]
        [string]
        $AccessToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('client_secret')]
        [string]
        $ClientSecret,

        [Parameter()]
        [switch]
        $Force
    )

    process {
        # Define new credentials
        $NewSection = @(
            "[$Section]"
            "access_token = $AccessToken"
            "client_secret = $ClientSecret"
            "client_token = $ClientToken"
            "host = $HostName"
        ) -join "`n"
        if ($AccountSwitchKey) {
            $NewSection += "`naccount_key = $AccountSwitchKey"
        }

        # Check for existing file
        if (Test-Path -Path $EdgeRCFile) {
            # Get file contents
            $EdgeRCContents = Get-Content -Path $EdgeRCFile -Raw

            $AppendNewEntry = $false

            # Retrieve existing credentials for section, if any
            try {
                $ExistingCredentials = Get-EdgegridCredentials -Section $Section -EdgeRCFile $EdgeRCFile
            }
            catch {
                Write-Debug "Export-EdgegridCredentials: No existing credentials found in $EdgeRCFile for section $Section"
                $AppendNewEntry = $true
            }

            if ($ExistingCredentials) {
                if (-not $Force) {
                    throw "Credentials for section '$Section' already exist in '$EdgeRCFile'. Use -Force to overwrite."
                }

                # Extract entire entry
                $SectionPattern = "(?s)(\[$Section\].*?)(\[|$)"
                $SectionMatch = $EdgeRCContents | Select-String -Pattern $SectionPattern

                if ($SectionMatch -and $SectionMatch.Matches[0].Groups[1].Value) {
                    $ExistingSection = $SectionMatch.Matches[0].Groups[1].Value.Trim()

                    # Sanitize existing client secret for regex replacement
                    $EscapedExistingClientSecret = [Regex]::Escape($ExistingCredentials.ClientSecret)

                    $UpdatedSection = $ExistingSection -replace "(\r?\n)client_token[ ]*=[ ]*$($ExistingCredentials.ClientToken)", "`$1client_token = $ClientToken"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)access_token[ ]*=[ ]*$($ExistingCredentials.AccessToken)", "`$1access_token = $AccessToken"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)client_secret[ ]*=[ ]*$EscapedExistingClientSecret", "`$1client_secret = $ClientSecret"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)host[ ]*=[ ]*$($ExistingCredentials.Host)", "`$1host = $HostName"
                    if ($ExistingCredentials.AccountKey) {
                        if ($AccountSwitchKey) {
                            Write-Debug 'Export-EdgegridCredentials: Replacing account_key in existing section'
                            $UpdatedSection = $UpdatedSection -replace "(\r?\n)account_key[ ]*=[ ]*$($ExistingCredentials.AccountKey)", "`$1account_key = $AccountSwitchKey"
                        }
                        else {
                            Write-Debug 'Export-EdgegridCredentials: Removing account_key from existing section'
                            $UpdatedSection = $UpdatedSection -replace "(\r?\n)account_key[ ]*=[ ]*$($ExistingCredentials.AccountKey)[^\r\n]*", ''
                        }
                    }
                    else {
                        if ($AccountSwitchKey) {
                            Write-Debug 'Export-EdgegridCredentials: Adding account_key to existing section'
                            $UpdatedSection += "`naccount_key = $AccountSwitchKey"
                        }
                    }

                    # Update file
                    Write-Debug "Export-EdgegridCredentials: Replacing existing entry:`n$ExistingSection`nwith updated entry:`n$UpdatedSection"
                    $UpdatedFileContents = $EdgeRCContents.Replace($ExistingSection, $UpdatedSection)
                    Write-Host "Updating section '" -NoNewline
                    Write-Host -ForegroundColor Cyan $Section -NoNewline
                    Write-Host "' in '" -NoNewline
                    Write-Host -ForegroundColor Cyan $EdgeRCFile -NoNewline
                    Write-Host "' with new credentials."
                    $UpdatedFileContents | Set-Content -Path $EdgeRCFile -NoNewline
                }
            }
            else {
                $AppendNewEntry = $true
            }

            if ($AppendNewEntry) {
                # Append new entry
                Write-Debug "Export-EdgegridCredentials: Appending new entry:`n$NewSection"
                $LineBreak = "`n"
                if ($EdgeRCContents.Contains("`r`n")) {
                    Write-Debug 'Export-EdgegridCredentials: Detected Windows line endings in existing file'
                    $LineBreak = "`r`n"
                }

                if (!$EdgeRCContents.EndsWith($LineBreak)) {
                    Write-Debug 'Export-EdgegridCredentials: Adding line break before new entry'
                    Add-Content -Path $EdgeRCFile -Value $LineBreak -NoNewline
                }

                Write-Host "Added new section '" -NoNewline
                Write-Host -ForegroundColor Cyan $Section -NoNewline
                Write-Host "' to '" -NoNewline
                Write-Host -ForegroundColor Cyan $EdgeRCFile -NoNewline
                Write-Host "' with new credentials."
                Add-Content -Path $EdgeRCFile -Value "$LineBreak$NewSection"
                return
            }
        }
        else {
            # Create new file with entry
            Write-Host "Creating new .edgerc file at '" -NoNewline
            Write-Host -ForegroundColor Cyan $EdgeRCFile -NoNewline
            Write-Host "' with section '" -NoNewline
            Write-Host -ForegroundColor Cyan $Section -NoNewline
            Write-Host "'."
            Write-Debug "Export-EdgegridCredentials: Creating new file with entry:`n$NewSection"
            $NewSection | Set-Content -Path $EdgeRCFile
        }
    }

}
function Export-NetstorageCredentials {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $NSRCFile = '~/.nsrc',

        [Parameter()]
        [string]
        $Section = 'default',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Key,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Group,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $Hostname,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $CPCode,

        [Parameter()]
        [switch]
        $Force
    )

    process {
        $NewSection = @(
            "[$Section]"
            "cpcode = $CPCode"
            "group = $Group"
            "host = $Hostname"
            "id = $ID"
            "key = $Key"
        ) -Join "`n"
    
        # Check for existing file
        if (Test-Path -Path $NSRCFile) {
            # Get file contents
            $AuthFileContents = Get-Content -Path $NSRCFile -Raw

            $AppendNewEntry = $false

            # Retrieve existing credentials for section, if any
            try {
                $ExistingCredentials = Get-NetstorageCredentials -Section $Section -NSRCFile $NSRCFile
            }
            catch {
                Write-Debug "Export-NetstorageCredentials: No existing credentials found in $NSRCFile for section $Section"
                $AppendNewEntry = $true
            }
    
            if ($ExistingCredentials) {
                if (-not $Force) {
                    throw "Credentials for section '$Section' already exist in '$NSRCFile'. Use -Force to overwrite."
                }

                # Extract entire entry
                $SectionPattern = "(?s)(\[$Section\].*?)(\[|$)"
                $SectionMatch = $AuthFileContents | Select-String -Pattern $SectionPattern

                if ($SectionMatch -and $SectionMatch.Matches[0].Groups[1].Value) {
                    $ExistingSection = $SectionMatch.Matches[0].Groups[1].Value.Trim()

                    $UpdatedSection = $ExistingSection -replace "(\r?\n)key[ ]*=[ ]*$($ExistingCredentials.key)", "`$1key = $Key"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)id[ ]*=[ ]*$($ExistingCredentials.id)", "`$1id = $ID"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)group[ ]*=[ ]*$($ExistingCredentials.group)", "`$1group = $Group"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)host[ ]*=[ ]*$($ExistingCredentials.Host)", "`$1host = $HostName"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)cpcode[ ]*=[ ]*$($ExistingCredentials.cpcode)", "`$1cpcode = $CPCode"
                    
                    # Update file
                    Write-Debug "Export-NetstorageCredentials: Replacing existing entry:`n$ExistingSection`nwith updated entry:`n$UpdatedSection"
                    $UpdatedFileContents = $AuthFileContents.Replace($ExistingSection, $UpdatedSection)
                    Write-Host "Updating section '" -NoNewline
                    Write-Host -ForegroundColor Cyan $Section -NoNewline
                    Write-Host "' in '" -NoNewline
                    Write-Host -ForegroundColor Cyan $NSRCFile -NoNewline
                    Write-Host "' with new credentials."
                    $UpdatedFileContents | Set-Content -Path $NSRCFile -NoNewLine
                }
            }
            else {
                $AppendNewEntry = $true
            }

            if ($AppendNewEntry) {
                # Append new entry
                Write-Debug "Export-NetstorageCredentials: Appending new entry:`n$NewSection"
                $LineBreak = "`n"
                if ($AuthFileContents.Contains("`r`n")) {
                    Write-Debug "Export-NetstorageCredentials: Detected Windows line endings in existing file"
                    $LineBreak = "`r`n"
                }
                
                if (!$AuthFileContents.EndsWith($LineBreak)) {
                    Write-Debug "Export-NetstorageCredentials: Adding line break before new entry"
                    Add-Content -Path $NSRCFile -Value $LineBreak -NoNewline
                }

                Write-Host "Added new section '" -NoNewline
                Write-Host -ForegroundColor Cyan $Section -NoNewline
                Write-Host "' to '" -NoNewline
                Write-Host -ForegroundColor Cyan $NSRCFile -NoNewline
                Write-Host "' with new credentials."
                Add-Content -Path $NSRCFile -Value "$LineBreak$NewSection"
                return
            }
        }
        else {
            # Create new file with entry
            Write-Host "Creating new .nsrc file at '" -NoNewline
            Write-Host -ForegroundColor Cyan $NSRCFile -NoNewline
            Write-Host "' with section '" -NoNewline
            Write-Host -ForegroundColor Cyan $Section -NoNewline
            Write-Host "'."
            Write-Debug "Export-NetstorageCredentials: Creating new file with entry:`n$NewSection"
            $NewSection | Set-Content -Path $NSRCFile
        }
    }
}

function Get-AkamaiOptions {
    [CmdletBinding()]
    Param()
    
    $OptionsPath = $Env:AkamaiOptionsPath
    if (-Not $OptionsPath) {
        $OptionsPath = $HOME + "/.akamai-pwsh/options.json"
    }
    
    if ((Test-Path $OptionsPath)) {
        Write-Debug "Get-AkamaiOptions: Retrieving options from $OptionsPath"
        $OptionsContent = Get-Content -Raw $OptionsPath
        if ($null -ne $OptionsContent) {
            try {
                $Global:AkamaiOptions = ConvertFrom-Json -InputObject $OptionsContent
            }
            catch {
                Write-Debug "Get-AkamaiOptions: Failed to convert content from '$OptionsPath'. Resetting to defaults"
                $Global:AkamaiOptions = New-AkamaiOptions
            }
        }
        else {
            Write-Debug "Get-AkamaiOptions: Options file '$OptionsPath' is empty. Setting to default values."
            $Global:AkamaiOptions = New-AkamaiOptions
        }
    }
    else {
        Write-Debug "Get-AkamaiOptions: Loading default options"
        $Global:AkamaiOptions = New-AkamaiOptions
    }

    return $Global:AkamaiOptions
}

function Get-AuthGrants {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [switch]
        $ReturnObject,

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

    $Path = "/-/client-api/active-grants/implicit"

    try {
        $Response = Invoke-AkamaiRequest -Method GET -Path $Path -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        if ($ReturnObject) {
            return $Response.Body
        }
        Write-Host "Credential Name: '$($Response.Body.name)'."
        Write-Host "---------------------------------"
        Write-Host "Created $($Response.Body.Created) by '$($Response.Body.CreatedBy)'."
        Write-Host "Updated $($Response.Body.Updated) by '$($Response.Body.UpdatedBy)'."
        Write-Host "Activated $($Response.Body.Activated) by '$($Response.Body.ActivatedBy)'."
        Write-Host "Grants:"
        
        $Scope = $Response.Body.Scope.Split(" ")
        $Grants = New-Object System.Collections.ArrayList
        foreach ($Grant in $Scope) {
            $Grant = $Grant.Replace("https://luna.akamaiapis.net/-/scope/", "")
            $Grant = $Grant.Replace("/-/", ": ")
            $Grants.Add("    $Grant") | Out-Null
        }
        $Grants
    }
    catch {
        throw $_
    }
}

function Get-EdgegridCredentials {
    [CmdletBinding()]
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

    ## Assign defaults if values not provided
    if ($EdgeRCFile -eq '') {
        $EdgeRCFile = '~/.edgerc'
    }
    else {
        ## If EdgeRCFile is provided we use that, regardless of other auth types being available
        $Mode = 'edgerc'
    }
    if ($Section -eq '') {
        $Section = 'default'
    }   


    #----------------------------------------------------------------------------------------------
    #                             1. Set up auth object
    #----------------------------------------------------------------------------------------------

    ## Instantiate auth object
    $Credentials = [PSCustomObject] @{
        Host         = $null
        ClientToken  = $null
        AccessToken  = $null
        ClientSecret = $null
        AccountKey   = $null
    }

    #----------------------------------------------------------------------------------------------
    #                              2. Check for environment variables
    #----------------------------------------------------------------------------------------------
    
    ## 'default' section is implicit. Otherwise env variable starts with section prefix
    if ($Mode -ne 'edgerc') {
        if ($Section.ToLower() -eq 'default') {
            $EnvPrefix = 'AKAMAI'
        }
        else {
            $EnvPrefix = "AKAMAI_$Section".ToUpper()
        }
    
        if (Test-Path "env:\$EnvPrefix`_HOST") {
            $Credentials.Host = (Get-Item -Path "env:\$EnvPrefix`_HOST").Value
        }
        if (Test-Path "env:\$EnvPrefix`_CLIENT_TOKEN") {
            $Credentials.ClientToken = (Get-Item -Path "env:\$EnvPrefix`_CLIENT_TOKEN").Value
        }
        if (Test-Path "env:\$EnvPrefix`_ACCESS_TOKEN") {
            $Credentials.AccessToken = (Get-Item -Path "env:\$EnvPrefix`_ACCESS_TOKEN").Value
        }
        if (Test-Path "env:\$EnvPrefix`_CLIENT_SECRET") {
            $Credentials.ClientSecret = (Get-Item -Path "env:\$EnvPrefix`_CLIENT_SECRET").Value
        }
        if (Test-Path "env:\$EnvPrefix`_ACCOUNT_KEY") {
            $Credentials.AccountKey = (Get-Item -Path "env:\$EnvPrefix`_ACCOUNT_KEY").Value
        }

        ## Explicit ASK wins over env variable
        if ($AccountSwitchKey) {
            $Credentials.AccountKey = $AccountSwitchKey
        }

        ## Remove ASK if value is "none"
        if ($AccountSwitchKey -eq "none") {
            $Credentials.AccountKey = $null
        }

        ## Check essential elements and return
        if ($null -ne $Credentials.Host -and $null -ne $Credentials.ClientToken -and $null -ne $Credentials.AccessToken -and $null -ne $Credentials.ClientSecret) {
            ## Env creds valid
            Write-Debug "Obtained credentials from environment variables in section '$Section'"
            return $Credentials
        }
    }

    #----------------------------------------------------------------------------------------------
    #                              3. Read from .edgerc file
    #----------------------------------------------------------------------------------------------

    # Get credentials from EdgeRC
    if (Test-Path $EdgeRCFile) {
        $EdgeRCContent = Get-Content $EdgeRCFile -Raw
        $SectionPattern = "(?s)(\[$Section\].*?)(\[|$)"
        $SectionMatch = $EdgeRCContent | Select-String -Pattern $SectionPattern

        if ($SectionMatch -and $SectionMatch.Matches[0].Groups[1].Value) {
            $SectionContent = $SectionMatch.Matches[0].Groups[1].Value

            $HostMatch = $SectionContent | Select-String -Pattern "\r?\nhost[ ]*=[ ]*([^\s#]+)"
            if ($HostMatch) {
                $Credentials.host = $HostMatch.Matches[0].Groups[1].Value
            }
            $ClientTokenMatch = $SectionContent | Select-String -Pattern "\r?\nclient_token[ ]*=[ ]*([^\s#]+)"
            if ($ClientTokenMatch) {
                $Credentials.ClientToken = $ClientTokenMatch.Matches[0].Groups[1].Value
            }
            $AccessTokenMatch = $SectionContent | Select-String -Pattern "\r?\naccess_token[ ]*=[ ]*([^\s#]+)"
            if ($AccessTokenMatch) {
                $Credentials.AccessToken = $AccessTokenMatch.Matches[0].Groups[1].Value
            }
            $ClientSecretMatch = $SectionContent | Select-String -Pattern "\r?\nclient_secret[ ]*=[ ]*([^\s#]+)"
            if ($ClientSecretMatch) {
                $Credentials.ClientSecret = $ClientSecretMatch.Matches[0].Groups[1].Value
            }
            $AccountKeyMatch = $SectionContent | Select-String -Pattern "\r?\naccount_key[ ]*=[ ]*([^\s#]+)"
            if ($AccountKeyMatch) {
                $Credentials.AccountKey = $AccountKeyMatch.Matches[0].Groups[1].Value
            }
        }
        else {
            throw "Error: Section '$Section' not found in edgerc file '$EdgeRCFile'"
        }

        ## Explicit ASK wins over edgerc file entry
        if ($AccountSwitchKey) {
            $Credentials.AccountKey = $AccountSwitchKey
        }

        ## Remove ASK if value is "none"
        if ($AccountSwitchKey -eq "none") {
            $Credentials.AccountKey = $null
        }

        ## Check essential elements and return
        if ($null -ne $Credentials.host -and $null -ne $Credentials.ClientToken -and $null -ne $Credentials.AccessToken -and $null -ne $Credentials.ClientSecret) {
            Write-Debug "Obtained credentials from edgerc file '$EdgeRCFile' in section '$Section'"
            return $Credentials
        }
    }
    
    #----------------------------------------------------------------------------------------------
    #                                     4. Panic!
    #----------------------------------------------------------------------------------------------

    ## Under normal circumstances you should not get this far...    
    throw "Error: Credentials could not be loaded from either; session, environment variables or edgerc file '$EdgeRCFile'"

}
function Get-NetstorageCredentials {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    ## Assign defaults if values not provided
    if ($NSRCFile -eq '') {
        $NSRCFile = '~/.nsrc'
    }
    if ($Section -eq '') {
        $Section = 'default'
    }


    #----------------------------------------------------------------------------------------------
    #                             1. Set up auth object
    #----------------------------------------------------------------------------------------------

    ## Instantiate auth object
    $CredentialElements = @(
        'Key',
        'ID',
        'Group',
        'Host',
        'CPCode'
    )

    $Credentials = New-Object -TypeName PSCustomObject
    $CredentialElements | ForEach-Object {
        $Credentials | Add-Member -MemberType NoteProperty -Name $_ -Value $null
    }

    #----------------------------------------------------------------------------------------------
    #                              2. Check for environment variables
    #----------------------------------------------------------------------------------------------
    
    ## 'default' section is implicit. Otherwise env variable starts with section prefix
    if ($Section.ToLower() -eq 'default') {
        $EnvPrefix = 'NETSTORAGE_'
    }
    else {
        $EnvPrefix = "NETSTORAGE_$Section`_".ToUpper()
    }

    $CredentialElements | ForEach-Object {
        $UpperEnv = "$EnvPrefix$_".ToUpper()
        if (Test-Path Env:\$UpperEnv) {
            $Credentials.$_ = (Get-Item -Path Env:\$UpperEnv).Value
        }
    }

    ## Check essential elements and return
    if ($null -ne $Credentials.Key -and $null -ne $Credentials.ID -and $null -ne $Credentials.Group -and $null -ne $Credentials.Host -and $null -ne $Credentials.CPCode) {
        ## Env creds valid
        Write-Debug "Obtained credentials from environment variables in section '$Section'"
        return $Credentials
    }

    #----------------------------------------------------------------------------------------------
    #                              3. Read from .nsrc file
    #----------------------------------------------------------------------------------------------

    # Get credentials from Auth file
    if (Test-Path $NSRCFile) {
        $AuthFileContent = Get-Content $NSRCFile
        for ($i = 0; $i -lt $AuthFileContent.length; $i++) {
            $line = $AuthFileContent[$i]
            $SanitizedLine = $line.Replace(" ", "")

            if ($line.contains("[") -and $line.contains("]")) {
                $SectionHeader = $SanitizedLine.Substring($Line.indexOf('[') + 1)
                $SectionHeader = $SectionHeader.SubString(0, $SectionHeader.IndexOf(']'))
            }

            ## Skip sections other than desired one
            if ($SectionHeader -ne $Section) { continue }

            if ($SanitizedLine.ToLower().StartsWith('key')) { $Credentials.Key = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
            if ($SanitizedLine.ToLower().StartsWith('id')) { $Credentials.ID = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
            if ($SanitizedLine.ToLower().StartsWith('group')) { $Credentials.Group = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
            if ($SanitizedLine.ToLower().StartsWith('host')) { $Credentials.Host = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
            if ($SanitizedLine.ToLower().StartsWith('cpcode')) { $Credentials.CPCode = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
        }

        ## Check essential elements and return
        if ($null -ne $Credentials.Key -and $null -ne $Credentials.ID -and $null -ne $Credentials.Group -and $null -ne $Credentials.Host -and $null -ne $Credentials.CPCode) {
            Write-Debug "Obtained credentials from auth file '$NSRCFile' in section '$Section'"
            return $Credentials
        }
    }
    
    #----------------------------------------------------------------------------------------------
    #                                     4. Panic!
    #----------------------------------------------------------------------------------------------

    ## Under normal circumstances you should not get this far...    
    throw "Error: Credentials could not be loaded from either; session, environment variables or auth file '$NSRCFile'"
}
function Import-EdgegridCredentials {
    [CmdletBinding(DefaultParameterSetName = 'EdgeRC file')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('host')]
        [string]
        $HostName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('client_token')]
        [string]
        $ClientToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('access_token')]
        [string]
        $AccessToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('client_secret')]
        [string]
        $ClientSecret,

        [Parameter(ParameterSetName = 'EdgeRC file')]
        [string]
        $EdgeRCFile,

        [Parameter(ParameterSetName = 'EdgeRC file')]
        [string]
        $Section,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('account_key')]
        [Alias('AccountKey')]
        [string]
        $AccountSwitchKey,

        [Parameter()]
        [string]
        $EnvironmentPrefix
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Credentials') {
            $Credentials = [PSCustomObject]@{
                'Host'         = $HostName
                'ClientToken'  = $ClientToken
                'AccessToken'  = $AccessToken
                'ClientSecret' = $ClientSecret
            }
            if ($AccountSwitchKey) {
                $Credentials | Add-Member -MemberType NoteProperty -Name 'AccountKey' -Value $AccountSwitchKey
            }
        }
        else {
            # Retrieve credentials from edgerc file
            $CommonParams = @{
                'EdgeRCFile'       = $EdgeRCFile
                'Section'          = $Section
                'AccountSwitchKey' = $AccountSwitchKey
            }
            $Credentials = Get-EdgegridCredentials @CommonParams
        }

        $EnvPrefix = if ($EnvironmentPrefix) { "_$($EnvironmentPrefix.ToUpper())" } else { "" }

        # Set environment variables
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_CLIENT_TOKEN" -Value $Credentials.ClientToken
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_CLIENT_SECRET" -Value $Credentials.ClientSecret
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_ACCESS_TOKEN" -Value $Credentials.AccessToken
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_HOST" -Value $Credentials.Host
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_ACCOUNT_KEY" -Value $Credentials.AccountKey
    }

}
function Import-NetstorageCredentials {
    [CmdletBinding(DefaultParameterSetName = 'Auth file')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [string]
        $Key,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [string]
        $ID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [string]
        $Group,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('host')]
        [string]
        $Hostname,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [string]
        $CPCode,

        [Parameter(ParameterSetName = 'Auth file')]
        [string]
        $NSRCFile,

        [Parameter(ParameterSetName = 'Auth file')]
        [string]
        $Section,

        [Parameter()]
        [string]
        $EnvironmentPrefix
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Credentials') {
            # Set environment variables directly from parameters
            $Credentials = [PSCustomObject] @{
                key    = $Key
                id     = $ID
                group  = $Group
                host   = $Hostname
                cpcode = $CPCode
            }
        }
        else {
            $CommonParams = @{
                'NSRCFile' = $NSRCFile
                'Section'  = $Section
            }
            $Credentials = Get-NetstorageCredentials @CommonParams
        }

        $EnvPrefix = ''
        if ($EnvironmentPrefix) {
            $EnvPrefix = '_' + $EnvironmentPrefix.ToUpper()
        }

        # Set environment variables
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_KEY" -Value $Credentials.key
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_ID" -Value $Credentials.id
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_GROUP" -Value $Credentials.group
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_HOST" -Value $Credentials.host
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_CPCODE" -Value $Credentials.cpcode
    }
}
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

function Invoke-AkamaiRestMethod {
    [Alias('iarm')]
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
            if ($PSVersionTable.PSVersion.Major -lt 6) {
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
    $SignatureData += "client_token=" + $Credentials.client_token + ";"
    $SignatureData += "access_token=" + $Credentials.access_token + ";"
    $SignatureData += "timestamp=" + $TimeStamp + ";"
    $SignatureData += "nonce=" + $Nonce + ";"

    Write-Debug "SignatureData = $SignatureData"

    # Generate SigningKey
    $SigningKey = Get-EncryptedMessage -secret $Credentials.client_secret -message $TimeStamp

    # Generate Auth Signature
    $Signature = Get-EncryptedMessage -secret $SigningKey -message $SignatureData

    # Create AuthHeader
    $AuthorizationHeader = "EG1-HMAC-SHA256 "
    $AuthorizationHeader += "client_token=" + $Credentials.client_token + ";"
    $AuthorizationHeader += "access_token=" + $Credentials.access_token + ";"
    $AuthorizationHeader += "timestamp=" + $TimeStamp + ";"
    $AuthorizationHeader += "nonce=" + $Nonce + ";"
    $AuthorizationHeader += "signature=" + $Signature

    # Create IDictionary to hold request headers
    $Headers = @{}

    ## Calculate custom UA
    $UserAgent = Get-AkamaiUserAgent
    
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
    
    $RequestParams = @{
        Method             = $Method
        Uri                = $Request.Uri
        Headers            = $Headers
        ContentType        = $ContentType
        MaximumRedirection = 0
    }
    
    # Add -AllowInsecureRedirect if Pwsh 7.4 or higher
    if ($PSVersionTable.PSVersion -ge '7.4.0') {
        $RequestParams['AllowInsecureRedirect'] = $true
    }
    
    # Support proxy as environment variable
    if ($null -ne $ENV:https_proxy) { $RequestParams.Proxy = $ENV:https_proxy }
    # Include credentials
    if ($null -ne $ENV:proxy_use_default_credentials) { $params.ProxyUseDefaultCredentials = $true }

    if ($Method -in "PUT", "POST", "PATCH") {
        if ($Body) { $RequestParams.Body = $Body }
        if ($InputFile) { $RequestParams.InFile = $InputFile }
    }
    # GET requests typically
    else { 
        # Differentiate on PS 5 and later as PS 5's Invoke-RestMethod doesn't behave the same as the later versions
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            $RequestParams.ErrorAction = "SilentlyContinue"
        }
        else {
            $RequestParams.ErrorAction = "Stop"
            $RequestParams.ResponseHeadersVariable = 'ResponseHeaders'
        }
    }

    if ($OutputFile) {
        $RequestParams.OutFile = $OutputFile
    }

    Write-Verbose "$($Request.Uri.AbsoluteUri)"

    try {
        $Response = Invoke-RestMethod @RequestParams
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

function New-AkamaiDataCache {
    $Global:AkamaiDataCache = [ordered] @{
        'APIDefinitions' = @{
            'APIEndpoints' = @{}
        }
        'AppSec'         = @{
            'Configs' = @{}
        }
        'ClientLists'    = @{
            'Lists' = @{}
        }
        'EdgeWorkers' = @{
            'EdgeWorkers' = @{}
        }
        'METS'           = @{
            'CASets' = @{}
        }
        'MOKS'           = @{
            'ClientCerts' = @{}
        }
        'Property'       = [ordered] @{
            'Properties' = @{}
            'Includes'   = @{}
        }
    }
}

function New-AkamaiOptions {
    [CmdletBinding()]
    Param(

    )

    $OptionsPath = $Env:AkamaiOptionsPath
    if (-Not $OptionsPath) {
        $OptionsPath = $HOME + "/.akamai-pwsh/options.json"
    }
    
    if (-not (Test-Path $OptionsPath)) {
        New-Item -ItemType File -Path $OptionsPath -Force | Out-Null
    }

    $Options = [PSCustomObject] @{
        'EnableErrorRetries'         = $false
        'InitialErrorWait'           = 1
        'MaxErrorRetries'            = 5
        'EnableRateLimitRetries'     = $false
        'DisablePapiPrefixes'        = $false
        'EnableRateLimitWarnings'    = $false
        'RateLimitWarningPercentage' = 90
        'EnableRecommendedActions'   = $false
        'EnableDataCache'            = $false
    }
    Write-Debug "New-AkamaiOptions: Writing default options to $OptionsPath"
    $Options | ConvertTo-Json | Out-File $OptionsPath -Encoding utf8 -Force
    return $Options
}

function New-EdgeAuthToken {
    [CmdletBinding(DefaultParameterSetName = 'URL')]
    Param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-fA-F0-9]+$')]
        [string]
        $Secret,

        [Parameter()]
        [int]
        $StartTime,

        [Parameter()]
        [int]
        $EndTime,

        [Parameter()]
        [int]
        $DurationInSeconds,

        [Parameter()]
        [int]
        $DurationInMinutes,

        [Parameter()]
        [int]
        $DurationInHours,

        [Parameter(ParameterSetName = 'ACL')]
        [string]
        $ACL,

        [Parameter(ParameterSetName = 'URL')]
        [string]
        $URL,

        [Parameter()]
        [switch]
        $EscapeInputs,

        [Parameter()]
        [string]
        $IP,

        [Parameter()]
        [string]
        $Data,

        [Parameter()]
        [string]
        $ID,

        [Parameter()]
        [string]
        $Salt,

        [Parameter()]
        [string]
        $Delimiter = '~',

        [Parameter()]
        [string]
        [ValidateSet('sha256', 'sha1', 'md5')]
        $Algorithm = 'sha256'
    )

    # Validate secret
    if ($Secret.length % 2 -ne 0 -or $Secret -notmatch '^[a-fA-F0-9]+$') {
        throw "Secret must have an even number of hexadecimal characters"
    }

    $DefaultDuration = 900 # Set 15m in the absence of actual setting
    $TokenArray = @()

    ### ip
    if ($IP) {
        $TokenArray += "ip=$IP"
    }

    ### st
    if ($StartTime) {
        $Start = $StartTime
        $TokenArray += "st=$Start"
    }
    else {
        $Start = [long] (Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s)
    }


    ### exp
    if ($EndTime) {
        $End = $EndTime
    }
    else {
        if ($DurationInSeconds) {
            $End = $Start + $DurationInSeconds
        }
        elseif ($DurationInMinutes) {
            $End = $Start + ($DurationInMinutes * 60)
        }
        elseif ($DurationInHours) {
            $End = $Start + ($DurationInHours * 3600)
        }
        else {
            Write-Warning "Neither EndTime nor Duration specified. Setting token duration to 15m."
            $End = $Start + $DefaultDuration
        }
    }

    $TokenArray += "exp=$End"

    ### acl
    if ($ACL) {
        $TokenArray += "acl=$ACL"
    }

    ### id
    if ($ID) {
        $TokenArray += "id=$ID"
    }

    ### data
    if ($Data) {
        $TokenArray += "data=$Data"
    }

    $HashArray = $TokenArray.PSObject.Copy()

    ### url (hash only)
    if ($URL) {
        if ($EscapeInputs) {
            $URL = [System.Web.HttpUtility]::UrlEncode($URL)
            $URL = $URL.replace('*', '%2a')
        }
        $HashArray += "url=$URL"
    }

    ### salt (hash only)
    if ($Salt) {
        $HashArray += "salt=$Salt"
    }

    $SigningString = $HashArray -join $Delimiter
    Write-Debug "Signing string = $Signingstring"

    # Generate HMAC
    switch ($Algorithm) {
        "sha1" { $HMAC = New-Object System.Security.Cryptography.HMACSHA1 }
        "sha256" { $HMAC = New-Object System.Security.Cryptography.HMACSHA256 }
        "md5" { $HMAC = New-Object System.Security.Cryptography.HMACMD5 }
    }

    $HMAC = New-Object System.Security.Cryptography.HMACSHA256
    $HMAC.key = [byte[]] -split ($Secret -replace '..', '0x$& ') # Secret is presented as string, but we need to treat each pair of characters as Hex before getting their byte value
    $Hash = $HMAC.ComputeHash([Text.Encoding]::UTF8.GetBytes($SigningString))
    $Signature = ($Hash | ForEach-Object ToString x2) -join ''

    $TokenArray += "hmac=$Signature"
    $Token = $TokenArray -join $Delimiter

    return $Token
}
function Set-AkamaiDataCache {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(ParameterSetName = 'API Definitions', Mandatory)]
        [string]
        $APIEndpointName,

        [Parameter(ParameterSetName = 'API Definitions', Mandatory)]
        [string]
        $APIEndpointID,

        [Parameter(ParameterSetName = 'AppSec config', Mandatory)]
        [Parameter(ParameterSetName = 'AppSec policy', Mandatory)]
        [string]
        $AppSecConfigName,

        [Parameter(ParameterSetName = 'AppSec config', Mandatory)]
        [string]
        $AppSecConfigID,

        [Parameter(ParameterSetName = 'AppSec policy', Mandatory)]
        [string]
        $AppSecPolicyName,

        [Parameter(ParameterSetName = 'AppSec policy', Mandatory)]
        [string]
        $AppSecPolicyID,

        [Parameter(ParameterSetName = 'Client Lists', Mandatory)]
        [string]
        $ClientListName,

        [Parameter(ParameterSetName = 'Client Lists', Mandatory)]
        [string]
        $ClientListID,

        [Parameter(ParameterSetName = 'EdgeWorkers', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'EdgeWorkers', Mandatory)]
        [string]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'METS', Mandatory)]
        [string]
        $METSCaSetName,

        [Parameter(ParameterSetName = 'METS', Mandatory)]
        [string]
        $METSCaSetID,

        [Parameter(ParameterSetName = 'MOKS', Mandatory)]
        [string]
        $MOKSClientCertName,

        [Parameter(ParameterSetName = 'MOKS', Mandatory)]
        [string]
        $MOKSClientCertID,

        [Parameter(ParameterSetName = 'Property', Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Property', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Include', Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'Include', Mandatory)]
        [string]
        $IncludeID
    )

    # ---- API Endpoints
    if ($PSCmdlet.ParameterSetName -eq 'API Definitions') {
        if ($AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName) {
            Write-Debug "Setting existing cache entry for API Endpoint '$APIEndpointName' to '$APIEndpointID'."
            $AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName.APIEndpointID = $APIEndpointID
        }
        else {
            Write-Debug "Setting new cache entry for API Endpoint '$APIEndpointName' to '$APIEndpointID'."
            $AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName = @{ 'APIEndpointID' = $APIEndpointID }
        }
    }

    # ---- AppSec
    if ($PSCmdlet.ParameterSetName.StartsWith('AppSec')) {
        # Config mode
        if (-not $AppSecPolicyName -and -not $AppSecPolicyID) {
            if ($AkamaiDataCache.AppSec.Configs.$AppSecConfigName) {
                Write-Debug "Setting existing cache entry for AppSec config '$AppSecConfigName' to '$AppSecConfigID'."
                $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.ConfigID = $AppSecConfigID
            }
            else {
                Write-Debug "Setting new cache entry for AppSec config '$AppSecConfigName' to '$AppSecConfigID'."
                $AkamaiDataCache.AppSec.Configs.$AppSecConfigName = @{
                    'ConfigID' = $AppSecConfigID
                    'Policies' = @{}
                }
            }
        }
        # Policy Mode
        else {
            if (($AppSecPolicyName -and -not $AppSecPolicyID) -or ($AppSecPolicyID -and -not $AppSecPolicyName)) {
                throw "To add a policy to the data cache you require -AppSecPolicyName AND -AppSecPolicyID"
            }
            if ($AkamaiDataCache.AppSec.Configs.$AppSecConfigName) {
                Write-Debug "Setting existing cache entry for AppSec config '$APIEndpointName ($APIEndpointID)'. Policy '$AppSecPolicyName' set to '$AppSecPolicyID'."
                $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.$AppSecPolicyName = @{ 'PolicyID' = $AppSecPolicyID }
            }
            else {
                Write-Debug "Setting new cache entry for AppSec config '$APIEndpointName ($APIEndpointID)'. Policy '$AppSecPolicyName' set to '$AppSecPolicyID'."
                $AkamaiDataCache.AppSec.Configs.$AppSecConfigName = @{
                    'ConfigID' = $AppSecConfigID
                    'Policies' = @{
                        $AppSecPolicyName = @{
                            'PolicyID' = $AppSecPolicyID
                        }
                    }
                }
            }
        }
    }

    # ---- Client Lists
    if ($PSCmdlet.ParameterSetName -eq 'Client Lists') {
        if ($AkamaiDataCache.ClientLists.Lists.$ClientListName) {
            Write-Debug "Setting existing cache entry for Client List '$ClientListName' to '$ClientListID'."
            $AkamaiDataCache.ClientLists.Lists.$ClientListName.ListID = $ClientListID
        }
        else {
            Write-Debug "Setting new cache entry for Client List '$ClientListName' to '$ClientListID'."
            $AkamaiDataCache.ClientLists.Lists.$ClientListName = @{ 'ListID' = $ClientListID }
        }
    }

    # ---- EdgeWorkers
    if ($PSCmdlet.ParameterSetName -eq 'EdgeWorkers') {
        if ($AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName) {
            Write-Debug "Setting existing cache entry for EdgeWorker '$EdgeWorkerName' to '$EdgeWorkerID'."
            $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName.EdgeWorkerID = $EdgeWorkerID
        }
        else {
            Write-Debug "Setting new cache entry for EdgeWorker '$EdgeWorkerName' to '$EdgeWorkerID'."
            $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName = @{ 'EdgeWorkerID' = $EdgeWorkerID }
        }
    }

    # ---- METS
    if ($PSCmdlet.ParameterSetName -eq 'METS') {
        if ($AkamaiDataCache.METS.CASets.$METSCaSetName) {
            $AkamaiDataCache.METS.CASets.$METSCaSetName.CASetID = $METSCaSetID
        }
        else {
            Write-Debug "Setting new cache entry for METS CA Set '$METSCaSetName' to '$METSCaSetID'."
            $AkamaiDataCache.METS.CASets.$METSCaSetName = @{ 'CASetID' = $METSCaSetID }
        }
    }

    # ---- MOKS
    if ($PSCmdlet.ParameterSetName -eq 'MOKS') {
        if ($AkamaiDataCache.MOKS.ClientCerts.$MOKSClientCertName) {
            Write-Debug "Setting existing cache entry for MOKS Client Cert '$MOKSClientCertName' to '$MOKSClientCertID'."
            $AkamaiDataCache.MOKS.ClientCerts.$MOKSClientCertName.CertificateID = $MOKSClientCertID
        }
        else {
            Write-Debug "Setting new cache entry for MOKS Client Cert '$MOKSClientCertName' to '$MOKSClientCertID'."
            $AkamaiDataCache.MOKS.ClientCerts.$MOKSClientCertName = @{ 'CertificateID' = $MOKSClientCertID }
        }
    }

    # ---- Property
    if ($PSCmdlet.ParameterSetName -eq 'Property') {
        if ($AkamaiDataCache.Property.Properties.$PropertyName) {
            Write-Debug "Setting existing cache entry for Property '$PropertyName' to '$PropertyID'."
            $AkamaiDataCache.Property.Properties.$PropertyName.PropertyID = $PropertyID
        }
        else {
            Write-Debug "Setting new cache entry for Property '$PropertyName' to '$PropertyID'."
            $AkamaiDataCache.Property.Properties.$PropertyName = @{ 'PropertyID' = $PropertyID }
        }
    }

    # ---- Include
    if ($PSCmdlet.ParameterSetName -eq 'Include') {
        if ($AkamaiDataCache.Property.Includes.$IncludeName) {
            Write-Debug "Setting existing cache entry for Include '$IncludeName' to '$IncludeID'."
            $AkamaiDataCache.Property.Includes.$IncludeName.IncludeID = $IncludeID
        }
        else {
            Write-Debug "Setting new cache entry for Include '$IncludeName' to '$IncludeID'."
            $AkamaiDataCache.Property.Includes.$IncludeName = @{ 'IncludeID' = $IncludeID }
        }
    }
}

function Set-AkamaiOptions {
    [CmdletBinding(DefaultParameterSetName = 'Set options')]
    Param (
        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableErrorRetries,

        [Parameter(ParameterSetName = 'Set options')]
        [int]
        $InitialErrorWait,

        [Parameter(ParameterSetName = 'Set options')]
        [int]
        $MaxErrorRetries,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableRateLimitRetries,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableRateLimitWarnings,

        [Parameter(ParameterSetName = 'Set options')]
        [int]
        $RateLimitWarningPercentage,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $DisablePAPIPrefixes,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableRecommendedActions,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableDataCache,

        [Parameter(ParameterSetName = 'Default')]
        [switch]
        $RestoreDefaults
    )

    $OptionsPath = $Env:AkamaiOptionsPath
    if (-Not $OptionsPath) {
        $OptionsPath = $HOME + "/.akamai-pwsh/options.json"
    }
    if ($PSCmdlet.ParameterSetName -eq 'Set options') {
        if ($null -eq $Global:AkamaiOptions) {
            Get-AkamaiOptions | Out-Null
        }
        $PSBoundParameters.Keys | ForEach-Object {
            if ($_ -notin 'Debug', 'Verbose') {
                Write-Debug "Updating option $_."
                if ($_ -in $Global:AkamaiOptions.PSObject.Properties.Name) {
                    $Global:AkamaiOptions.$_ = $PSBoundParameters.$_
                }
                else {
                    # This option only included in case new options have been introduced since the creation of the options object
                    $Global:AkamaiOptions | Add-Member -NotePropertyName $_ -NotePropertyValue $PSBoundParameters.$_ -Force
                }
            }
        }
        Write-Debug "Set-AkamaiOptions: writing updated options to $OptionsPath"
        ConvertTo-Json -InputObject $Global:AkamaiOptions | Out-File -FilePath $OptionsPath -Encoding utf8

        # Create data cache
        if ($EnableDataCache -and -not $Global:AkamaiDataCache) {
            New-AkamaiDataCache
        }
        # Clear data cache
        if ($PSBoundParameters.EnableDataCache -eq $false) {
            Clear-AkamaiDataCache
        }
    }
    elseif ($RestoreDefaults) {
        # Restore Defaults
        Write-Debug "Set-AkamaiOptions: Restoring options to default"
        $Global:AkamaiOptions = New-AkamaiOptions
    }
    return $Global:AkamaiOptions
}

function Test-EdgegridCredentials {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $HostName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ClientToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $AccessToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ClientSecret

    )

    $EdgegridCredentialMatch = '^aka[ab]-[a-z0-9]{16}-[a-z0-9]{16}'
    $SecretMatch = '[a-zA-Z0-9\+\/=]{44}'
    $Status = New-Object -Typename System.Collections.Generic.List[string]

    if ($HostName -notmatch $EdgegridCredentialMatch) {
        $Status.Add("The 'Host' attribute of your credentials appears to be invalid")
    }
    if ($ClientToken -notmatch $EdgegridCredentialMatch) {
        $Status.Add("The 'ClientToken' attribute of your credentials appears to be invalid")
    }
    if ($AccessToken -notmatch $EdgegridCredentialMatch) {
        $Status.Add("The 'AccessToken' attribute of your credentials appears to be invalid")
    }
    if ($ClientSecret -notmatch $SecretMatch) {
        $Status.Add("The 'ClientSecret' attribute of your credentials appears to be invalid")
    }

    return $Status
}

function Test-OpenAPI {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter()]
        [string]
        $Method = 'GET',

        [Parameter()]
        $Body,

        [Parameter()]
        [string]
        $Accept,

        [Parameter()]
        [string]
        $ContentType,

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

    $AdditionalHeaders = @{}

    if ($Accept) {
        $AdditionalHeaders['Accept'] = $Accept
    }

    if ($ContentType) {
        $AdditionalHeaders['Content-Type'] = $ContentType
    }

    try {
        $Response = Invoke-AkamaiRequest -Method $Method -Path $Path -Body $Body -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey -AdditionalHeaders $AdditionalHeaders
    }
    catch {
        throw $_
    }

    return $Response.Body
}


# Load System.Web assembly
if ($PSVersionTable.PSVersion.Major -lt 6) {
    Add-Type -AssemblyName System.Web
}

# Load options
Get-AkamaiOptions | Out-Null

# Load Recommended actions provider if required
if ($Global:AkamaiOptions.EnableRecommendedActions -and $PSVersionTable.PSVersion -ge '7.4.0') {
    Write-Debug "Loading recommended actions provider."
    Import-Module "$PSScriptRoot/bin/RecommendedActionsProvider.dll"
}

# Optionally create data cache
if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache) {
    Write-Debug "Creating default data cache."
    New-AkamaiDataCache
}

# Load known errors
$Script:KnownErrors = Get-Content -Raw "$PSScriptRoot/data/KnownErrors.json" | ConvertFrom-Json
# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB9nWSaYokyLUyC
# UwqBvKJhwNktxWny/czFe4f5xUrmw6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHFOp3LFDWajoiCLl1cs5dox2X24CH3Q
# 43MrJAWCW8BoMA0GCSqGSIb3DQEBAQUABIIBgArZ5P8jhKyheVc7zlkmNB/bj89Z
# cugFUCl19aSvY7WMwqKAdA0x4kYarFIHtPQKKEtyIvcTQU/W2sQnjsZmTqEjeTyw
# dkvJsHUCwyLjKiXoL0nYrPlSZG3TnmjlMGQilHM4Dvyjw5sc2bu66dSNUutZkzSp
# UZpfe5mOIZeM85+2JYEMlWH+E9aVEsb1XOgMyAZ42PneQkH+tLaIfScX3Z9e4+bN
# UsFHtHP4/WaQ4XhCU+n0EmMjLi/YUax9Zr8dTIBdKTNcRGRPN6PvYp/2U4eRzl2V
# LZO2i18CqSf5D9m0h+CXLWENgL8oB+Jp0szl2UXhxwOVPXfvC0VTeiwCQ8MV47lT
# HnsK60P4ocWYdUU30rSDClwBtksPfbD5IzKypsms4n3UPc6feoyM/2OSY+3v9plN
# cfiGR3HsHPOcXNpKUHIQpmHCLdLF8HFHT8zeEHZnVYxtnYxIudU6awN0csJp/1xf
# d5Gy/v23IVSlMVkOF7pceeHHzH+hjPI3GMs/zA==
# SIG # End signature block
