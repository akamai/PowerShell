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







