function Get-PurgeLimit {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('cpcode', 'url', 'tag')]
        [string]
        $PurgeType,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Path = "/ccu/v3/rate-limit-status/$PurgeType"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Add headers to body
        $RateLimitHeaders = $Response.Headers.Keys | Where-Object { $_ -match '^x-ratelimit' }
        foreach ($Header in $RateLimitHeaders) {
            $HeaderName = $Header -replace '^x-ratelimit-', ''
            $HeaderName = $HeaderName.Replace('-', '')
            $Response.Body | Add-Member -NotePropertyName $HeaderName -NotePropertyValue $Response.Headers[$Header][0]
        }
        return $Response.Body
    }
}