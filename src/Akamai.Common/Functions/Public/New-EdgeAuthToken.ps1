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