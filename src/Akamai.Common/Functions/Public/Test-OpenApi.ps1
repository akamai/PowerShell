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
