function Clear-AkamaiOptions {
    if ($env:AkamaiOptionsPath) {
        $OptionsPath = $env:AkamaiOptionsPath
    }
    else {
        $OptionsPath = '~/.akamai-pwsh/options.json'
    }
    if ((Test-Path $OptionsPath)) {
        Remove-Item -Path $OptionsPath
    }
}
