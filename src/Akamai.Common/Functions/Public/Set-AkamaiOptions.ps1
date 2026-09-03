function Set-AkamaiOptions {
    [CmdletBinding(DefaultParameterSetName = 'Set options')]
    Param (
        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableErrorRetries,

        [Parameter(ParameterSetName = 'Set options')]
        [int]
        $InitialErrorWait,

        [Parameter(ParameterSetName = 'Set options')]
        [int]
        $MaxErrorRetries,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableRateLimitRetries,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableRateLimitWarnings,

        [Parameter(ParameterSetName = 'Set options')]
        [int]
        $RateLimitWarningPercentage,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $DisablePAPIPrefixes,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableRecommendedActions,

        [Parameter(ParameterSetName = 'Set options')]
        [bool]
        $EnableDataCache,

        [Parameter(ParameterSetName = 'Default')]
        [switch]
        $RestoreDefaults
    )

    $OptionsPath = $Env:AkamaiOptionsPath
    if (-Not $OptionsPath) {
        $OptionsPath = $HOME + "/.akamai-pwsh/options.json"
    }
    if ($PSCmdlet.ParameterSetName -eq 'Set options') {
        if ($null -eq $Global:AkamaiOptions) {
            Get-AkamaiOptions | Out-Null
        }
        $PSBoundParameters.Keys | ForEach-Object {
            if ($_ -notin 'Debug', 'Verbose') {
                Write-Debug "Updating option $_."
                if ($_ -in $Global:AkamaiOptions.PSObject.Properties.Name) {
                    $Global:AkamaiOptions.$_ = $PSBoundParameters.$_
                }
                else {
                    # This option only included in case new options have been introduced since the creation of the options object
                    $Global:AkamaiOptions | Add-Member -NotePropertyName $_ -NotePropertyValue $PSBoundParameters.$_ -Force
                }
            }
        }
        Write-Debug "Set-AkamaiOptions: writing updated options to $OptionsPath"
        ConvertTo-Json -InputObject $Global:AkamaiOptions | Out-File -FilePath $OptionsPath -Encoding utf8

        # Create data cache
        if ($EnableDataCache -and -not $Global:AkamaiDataCache) {
            New-AkamaiDataCache
        }
        # Clear data cache
        if ($PSBoundParameters.EnableDataCache -eq $false) {
            Clear-AkamaiDataCache
        }
    }
    elseif ($RestoreDefaults) {
        # Restore Defaults
        Write-Debug "Set-AkamaiOptions: Restoring options to default"
        $Global:AkamaiOptions = New-AkamaiOptions
    }
    return $Global:AkamaiOptions
}
