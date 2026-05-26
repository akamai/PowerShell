function Get-AkamaiUserAgent {
    # Extract Version from loaded module
    $Module = Get-Module Akamai.Common
    if ($Module) {
        $ModuleVersion = $Module.Version
    }
    else {
        $ModuleVersion = 'Unknown'
    }
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        #< 6 is missing the OS member of PSVersionTable, so we use env variables
        $OS = $PSVersionTable.OS
    }
    else {
        $OS = $Env:OS
    }
    
    $UserAgent = "AkamaiPowershell/$ModuleVersion (Powershell $PSEdition $($PSVersionTable.PSVersion) $PSCulture, $OS)"
    return $UserAgent
}
