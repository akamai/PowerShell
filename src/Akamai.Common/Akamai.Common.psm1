Get-ChildItem -Path $PSScriptRoot/Functions/ -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }

# Load System.Web assembly
if ($PSVersionTable.PSVersion.Major -lt 6) {
    Add-Type -AssemblyName System.Web
}

# Load options
Get-AkamaiOptions | Out-Null

# Load Recommended actions provider if required
if ($Global:AkamaiOptions.EnableRecommendedActions -and $PSVersionTable.PSVersion -ge '7.4.0') {
    Write-Debug "Loading recommended actions provider."
    Import-Module "$PSScriptRoot/bin/RecommendedActionsProvider.dll"
}

# Optionally create data cache
if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache) {
    Write-Debug "Creating default data cache."
    New-AkamaiDataCache
}

# Load known errors
$Script:KnownErrors = Get-Content -Raw "$PSScriptRoot/data/KnownErrors.json" | ConvertFrom-Json