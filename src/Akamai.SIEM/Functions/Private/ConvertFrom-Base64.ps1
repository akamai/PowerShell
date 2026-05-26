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
