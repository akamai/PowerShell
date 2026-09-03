function Expand-ChildRuleSnippet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Include,

        [Parameter(Mandatory)]
        [string]
        $Path,
        
        [Parameter(Mandatory)]
        [string]
        $DefaultRuleDirectory
    )

    process {
        $IncludePath = $Path + '/' + $Include.Replace("#include:", "")
        $IncludeDir = [System.IO.Path]::GetDirectoryName($IncludePath)
        $IncludePathFromMain = $DefaultRuleDirectory + '/' + $Include.Replace("#include:", "")
        if ((Test-Path $IncludePath)) {
            Write-Debug "Expanding include $IncludePath."
            $Child = Get-Content $IncludePath -Raw | ConvertFrom-Json
        }
        elseif ((Test-Path $IncludePathFromMain)) {
            Write-Debug "Expanding include from main path $IncludePathFromMain."
            $Child = Get-Content $IncludePathFromMain -Raw | ConvertFrom-Json
        }
        else {
            throw "Could not find include path in the following locations: $IncludePath, $IncludePathFromMain."
        }
    
        for ($i = 0; $i -lt $Child.children.count; $i++) {
            if ($Child.children[$i].GetType().Name -eq 'String' -and $Child.children[$i].StartsWith('#include:')) {
                $Child.children[$i] = Expand-ChildRuleSnippet -Include $Child.children[$i] -Path $IncludeDir -DefaultRuleDirectory $DefaultRuleDirectory
            }
        }
    
        return $Child
    }
}
