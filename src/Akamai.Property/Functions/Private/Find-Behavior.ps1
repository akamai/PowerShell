function Find-Behavior {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $BehaviorName,

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Rule
    )

    $Results = New-Object System.Collections.Generic.List[PSCustomObject]
    foreach ($Behavior in $Rule.behaviors) {
        if ($Behavior.name -eq $BehaviorName) {
            $Results.Add($Behavior)
        }
    }

    foreach ($Child in $Rule.children) {
        $ChildResults = Find-Behavior -BehaviorName $BehaviorName -Rule $Child
        if ($ChildResults.Count -gt 0) {
            $Results.AddRange($ChildResults)
        }
    }
    return $Results
}