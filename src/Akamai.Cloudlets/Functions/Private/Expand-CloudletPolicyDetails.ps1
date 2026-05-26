function Expand-CloudletPolicyDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [int]
        $PolicyID,
        
        [Parameter()]
        [string]
        $Version,
        
        [Parameter()]
        [switch]
        $Legacy,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    if ($Version -eq 'latest') {
        $Versions = @(Get-CloudletPolicyVersion -PolicyID $PolicyID -PageSize 10 -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey)
        if ($Versions.count -gt 0) {
            $Version = $Versions[0].Version
        }
    }

    return $Version
}
