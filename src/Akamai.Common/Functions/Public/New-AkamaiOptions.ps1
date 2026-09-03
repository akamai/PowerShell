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
