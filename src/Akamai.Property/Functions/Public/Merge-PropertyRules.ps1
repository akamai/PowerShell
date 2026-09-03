function Merge-PropertyRules {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [string]
        $SourceDirectory,

        [Parameter()]
        [string]
        $DefaultRuleFilename = 'main.json',

        [Parameter()]
        [switch]
        $OutputToFile,

        [Parameter()]
        [string]
        $OutputFileName
    )

    process {
        if (!(Test-Path "$SourceDirectory/$DefaultRuleFilename")) {
            throw "Default rule file '$SourceDirectory/$DefaultRuleFilename' not found."
        }
        else {
            $Source = Get-Item $SourceDirectory
        }
    
        $DefaultRulePath = "$($Source.FullName)/$DefaultRuleFilename"
        $Rules = Get-Content -Raw $DefaultRulePath | ConvertFrom-Json
    
        ## Get Variables
        if ($null -ne $Rules.variables) {
            $VariablesFileName = $Rules.variables.Replace("#include:", "")
            $Rules.variables = @()
            $Variables = Get-Content -Raw "$($Source.FullName)/$VariablesFileName" | ConvertFrom-Json
            $Rules.variables += $Variables
        }
        
    
        for ($i = 0; $i -lt $Rules.children.count; $i++) {
            if ($Rules.children[$i].GetType().Name -eq 'String' -and $Rules.children[$i].StartsWith('#include:')) {
                $Rules.children[$i] = Expand-ChildRuleSnippet -Include $Rules.children[$i] -Path $Source.FullName -DefaultRuleDirectory $Source.FullName
            }
        }
    
        $Output = New-Object -TypeName PSCustomObject
        $Output | Add-Member -MemberType NoteProperty -Name rules -Value $Rules
    
        if ($OutputToFile) {
            if ($OutputFileName -eq '') {
                $OutputFileName = $Source.Name + '.json'
            }
            Write-Host 'Combined contents of ' -NoNewline
            Write-Host -ForegroundColor Green $SourceDirectory -NoNewline
            Write-Host ' into ' -NoNewline
            Write-Host -ForegroundColor Green $OutputFileName -NoNewline
            Write-Host '.'
            $Output | ConvertTo-Json -Depth 100 | Set-Content $OutputFileName
        }
        else {
            return $Output
        }
    }
}
