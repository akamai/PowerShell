function Get-EdgegridAuthHeader {
    [CmdletBinding()]
    param(
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
    $TimeStamp = [DateTime]::UtcNow.ToString('yyyyMMddTHH:mm:sszz00')

    # GUID for request signing
    $Nonce = [GUID]::NewGuid()

    # Build data string for signature generation
    $SignatureData = $Method + "`thttps`t"
    $SignatureData += $Credentials.Host + "`t" + $ExpandedPath

    #Sanitize body to remove NO-BREAK SPACE Unicode character, which breaks PAPI
    $Body = $Body -replace '[\u00a0]', ''

    # Add body to signature. Truncate if body is greater than max-body (Akamai default is 131072). PUT Method does not require adding to signature.
    if ($Method -eq 'POST') {
        if ($Body) {
            $Body_SHA256 = [System.Security.Cryptography.SHA256]::Create()
            if ($Body.Length -gt $MaxBody) {
                $Body_Hash = [System.Convert]::ToBase64String($Body_SHA256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Body.Substring(0, $MaxBody))))
            }
            else {
                $Body_Hash = [System.Convert]::ToBase64String($Body_SHA256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Body)))
            }

            $SignatureData += "`t`t$Body_Hash`t"
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

            $SignatureData += "`t`t$Body_Hash`t"
            Write-Debug "Signature generated from input file $InputFile"
        }
        else {
            $SignatureData += "`t`t`t"
        }
    }
    else {
        $SignatureData += "`t`t`t"
    }

    $AuthHeaderBase = 'EG1-HMAC-SHA256 '
    $AuthHeaderBase += 'client_token=' + $Credentials.ClientToken + ';'
    $AuthHeaderBase += 'access_token=' + $Credentials.AccessToken + ';'
    $AuthHeaderBase += 'timestamp=' + $TimeStamp + ';'
    $AuthHeaderBase += 'nonce=' + $Nonce + ';'

    # Add auth header base to signature data
    $SignatureData += $AuthHeaderBase
    Write-Debug "SignatureData = $SignatureData"

    # Generate SigningKey
    $SigningKey = Get-EncryptedMessage -secret $Credentials.ClientSecret -message $TimeStamp

    # Generate Auth Signature
    $Signature = Get-EncryptedMessage -secret $SigningKey -message $SignatureData

    # Create AuthHeader
    $AuthorizationHeader = $AuthHeaderBase + 'signature=' + $Signature

    return $AuthorizationHeader
}
