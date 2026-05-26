function Get-PropertyIncludeRules {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $IncludeVersion,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $OutputToFile,

        [Parameter()]
        [string]
        $OutputFileName,

        [Parameter()]
        [switch]
        $OutputSnippets,

        [Parameter()]
        [string]
        $OutputDirectory,

        [Parameter()]
        [int]
        $MaxDepth = 100,

        [Parameter()]
        [ValidateSet('Windows', 'Unix', IgnoreCase)]
        [string]
        $ForceSlashStyle,

        [Parameter()]
        [switch]
        $PathFromMainJson,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $PassThru,

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

    process {
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $Path = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'originalInput' = $PSBoundParameters.OriginalInput
        }

        if ($RuleFormat) {
            $AdditionalHeaders = @{
                Accept = "application/vnd.akamai.papirules.$RuleFormat+json"
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        if ($OutputToFile -or $OutputFileName) {
            if (!$OutputFileName) {
                $OutputFileName = $Response.Body.includeName + "_" + $Response.Body.includeVersion + ".json"
            }
            elseif (!($OutputFileName.EndsWith(".json"))) {
                $OutputFileName += ".json"
            }

            if ( (Test-Path $OutputFileName) -and !$Force) {
                Write-Host -ForegroundColor Yellow "Failed to write file. $OutputFileName exists and -Force not specified."
            }
            else {
                $Response.Body | ConvertTo-Json -Depth 100 | Set-Content $OutputFileName -Force
                Write-Host 'Wrote version ' -NoNewline
                Write-Host -ForegroundColor Green $Response.Body.includeVersion -NoNewline
                Write-Host ' of include ' -NoNewline
                Write-Host -ForegroundColor Green $Response.Body.includeName -NoNewline
                Write-Host ' to ' -NoNewline
                Write-Host -ForegroundColor Green $OutputFileName -NoNewline
                Write-Host '.'
            }
        }
        if ($OutputSnippets -or $OutputDirectory) {
            if ($OutputDirectory -eq '') {
                $OutputDirectory = $Response.Body.includeName
            }

            # Make Include Directory if required
            if (!(Test-Path $OutputDirectory)) {
                Write-Host "Creating new property include directory " -NoNewLine
                Write-Host -ForegroundColor Cyan $OutputDirectory -NoNewline
                Write-Host "."
                New-Item -Path $OutputDirectory -ItemType Directory | Out-Null
            }
            else {
                $ExistingFiles = Get-ChildItem $OutputDirectory
                if ($ExistingFiles.count -gt 0) {
                    if ($Force) {
                        Write-Debug "Get-PropertyRules: Deleting contents of $OutputDirectory."
                        Remove-Item -Path $OutputDirectory/* -Force -Recurse
                    }
                    else {
                        throw "Output directory $OutputDirectory already exists. To use this directory and overwrite its contents, use -Force."
                    }
                }
            }

            for ($i = 0; $i -lt $Response.Body.rules.children.count; $i++) {
                $ChildRuleSnippetParams = @{
                    Rules        = $Response.Body.rules.children[$i]
                    Path         = $OutputDirectory
                    CurrentDepth = 0
                    MaxDepth     = $MaxDepth
                }
                if ($ForceSlashStyle) { $ChildRuleSnippetParams['ForceSlashStyle'] = $ForceSlashStyle }
                if ($PathFromMainJson) { $ChildRuleSnippetParams['PathFromMainJson'] = $PathFromMainJson }
                Get-ChildRuleSnippet @ChildRuleSnippetParams
                $SafeName = Format-Filename -FileName $Response.Body.rules.children[$i].Name
                $Response.Body.rules.children[$i] = "#include:$SafeName.json"
            }

            ### Split variables out to its own file
            if ($null -ne $Response.Body.rules.variables) {
                ConvertTo-Json -depth 100 $Response.Body.rules.variables | Set-Content "$OutputDirectory\pmVariables.json" -Force
                $Response.Body.rules.variables = "#include:pmVariables.json"
            }

            ### Write default rule to main file
            $Response.Body.rules | ConvertTo-Json -depth 100 | Set-Content "$OutputDirectory\main.json" -Force

            Write-Host 'Wrote version ' -NoNewLine
            Write-Host -ForegroundColor Cyan $Response.Body.includeVersion -NoNewline
            Write-Host ' of include ' -NoNewline
            Write-Host  -ForegroundColor Cyan $Response.Body.includeName -NoNewline
            Write-Host ' to ' -NoNewline
            Write-Host  -ForegroundColor Cyan $OutputDirectory -NoNewline
            Write-Host '.'
        }
        # Return object if other options not specified, or user has supplied -PassThru
        if ( (-not $OutputToFile -and -not $OutputFileName -and -not $OutputSnippets -and -not $OutputDirectory) -or $PassThru) {
            return $Response.Body
        }
    }
}
