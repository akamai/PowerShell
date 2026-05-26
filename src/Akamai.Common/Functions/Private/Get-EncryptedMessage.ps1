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
