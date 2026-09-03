function Get-TopLevelGroup {
    [CmdletBinding()]
    Param(
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

    try {
        $Groups = Get-Group -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey | Where-Object { $null -eq $_.parentGroupId }
        return $Groups 
    }
    catch {
        throw $_
    }
}
