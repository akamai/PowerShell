function Format-SIEMEvent {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [object]
        $SIEMEvent
    )

    $AttackDataAttributes = @(
        'rules',
        'ruleVersions',
        'ruleMessages',
        'ruleTags',
        'ruleData',
        'ruleSelectors',
        'ruleActions'
    )

    $httpMessageAttributes = @(
        'query',
        'requestHeaders',
        'responseHeaders'
    )

    $AttackDataAttributes | ForEach-Object {
        Write-Debug "Parsing $_"
        ### Encoded data sometimes contains pluses (+) which should not be decoded
        $PlusSafeString = $SIEMEvent.attackData.$_.Replace("+", "%2b")
        $URLdecodedString = [System.Net.WebUtility]::UrlDecode($PlusSafeString)
        $Entries = $URLdecodedString -split ";"
        foreach ($Entry in $Entries) {
            if ($Entry -ne '') {
                $DecodedEntry = ConvertFrom-Base64 -EncodedString $Entry
                $URLdecodedString = $URLdecodedString.Replace($Entry, $DecodedEntry)
            }
        }
        $SIEMEvent.attackData.$_ = $URLdecodedString
    }

    $httpMessageAttributes | ForEach-Object {
        if ($SIEMEvent.httpMessage.$_) {
            Write-Debug "Parsing $_"
            $URLdecodedString = [System.Net.WebUtility]::UrlDecode($SIEMEvent.httpMessage.$_)
            $SIEMEvent.httpMessage.$_ = $URLdecodedString -split "`n" | Where-Object { $_ -ne '' }
        }
    }

    return $SIEMEvent
}


