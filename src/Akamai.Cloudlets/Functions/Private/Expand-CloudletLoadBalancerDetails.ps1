function Expand-CloudletLoadBalancerDetails {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $OriginID,

        [Parameter()]
        [string]
        $Version,

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
        $Versions = Get-CloudletLoadBalancerVersion -OriginID $OriginID -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey | Sort-Object -Property Version -Descending
        $Version = $Versions[0].version
    }

    return $Version
}
