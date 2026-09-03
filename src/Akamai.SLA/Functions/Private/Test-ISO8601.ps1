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
