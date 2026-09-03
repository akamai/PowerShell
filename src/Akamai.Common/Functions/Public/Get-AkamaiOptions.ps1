function Get-AkamaiOptions {
    [CmdletBinding()]
    Param()
    
    $OptionsPath = $Env:AkamaiOptionsPath
    if (-Not $OptionsPath) {
        $OptionsPath = $HOME + "/.akamai-pwsh/options.json"
    }
    
    if ((Test-Path $OptionsPath)) {
        Write-Debug "Get-AkamaiOptions: Retrieving options from $OptionsPath"
        $OptionsContent = Get-Content -Raw $OptionsPath
        if ($null -ne $OptionsContent) {
            try {
                $Global:AkamaiOptions = ConvertFrom-Json -InputObject $OptionsContent
            }
            catch {
                Write-Debug "Get-AkamaiOptions: Failed to convert content from '$OptionsPath'. Resetting to defaults"
                $Global:AkamaiOptions = New-AkamaiOptions
            }
        }
        else {
            Write-Debug "Get-AkamaiOptions: Options file '$OptionsPath' is empty. Setting to default values."
            $Global:AkamaiOptions = New-AkamaiOptions
        }
    }
    else {
        Write-Debug "Get-AkamaiOptions: Loading default options"
        $Global:AkamaiOptions = New-AkamaiOptions
    }

    return $Global:AkamaiOptions
}
