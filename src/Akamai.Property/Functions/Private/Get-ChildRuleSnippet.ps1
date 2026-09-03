function Get-ChildRuleSnippet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [object]
        $Rules,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [int]
        $CurrentDepth,

        [Parameter(Mandatory)]
        [int]
        $MaxDepth,
        
        [Parameter()]
        [switch]
        $PathFromMainJson
    )
    
    process {
        $SafeName = Format-Filename -FileName $Rules.Name
        $ChildPath = "$Path/$SafeName"
        $NewDepth = $CurrentDepth + 1
    
        if ($NewDepth -lt $MaxDepth) {
            if ($Rules.children.count -gt 0) {
                if (!(Test-Path $ChildPath)) {
                    New-Item -Path $ChildPath -ItemType Directory | Out-Null
                }
            }
            for ($i = 0; $i -lt $Rules.children.count; $i++) {
                $ChildRuleSnippetParams = @{
                    Rules        = $Rules.children[$i]
                    Path         = $ChildPath
                    CurrentDepth = $NewDepth
                    MaxDepth     = $MaxDepth
                }
                if ($ForceSlashStyle) { $ChildRuleSnippetParams['ForceSlashStype'] = $ForceSlashStyle }
                if ($PathFromMainJson) { $ChildRuleSnippetParams['PathFromMainJson'] = $PathFromMainJson }
                Get-ChildRuleSnippet @ChildRuleSnippetParams
                $SafeChildName = Format-Filename -FileName $Rules.children[$i].Name
                if ($PathFromMainJson) {
                    # Remove the first element from the path (the parent folder) in order to base from main json path
                    $Rules.children[$i] = "#include:$($ChildPath.SubString($ChildPath.IndexOf('/') + 1))/$SafeChildName.json"
                }
                else {
                    $Rules.children[$i] = "#include:$SafeName/$SafeChildName.json"
                }
            }
        }
    
        $Rules | ConvertTo-Json -Depth 100 | Set-Content "$Path/$SafeName.json"
    }
}
