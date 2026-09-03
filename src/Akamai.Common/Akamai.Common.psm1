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
    try {
        Import-Module "$PSScriptRoot/bin/RecommendedActionsProvider.dll" -ErrorAction Stop
    }
    catch {
        # Parallel runspaces can attempt to register the same feedback provider subsystem implementation.
        if ($_.Exception.Message -match "already registered" -and $_.Exception.Message -match "FeedbackProvider") {
            Write-Debug "Recommended actions provider already registered in this process. Skipping duplicate registration."
        }
        else {
            throw
        }
    }
}

# Optionally create data cache
if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache) {
    Write-Debug "Creating default data cache."
    New-AkamaiDataCache
}

# Load known errors
$Script:KnownErrors = Get-Content -Raw "$PSScriptRoot/data/KnownErrors.json" | ConvertFrom-Json