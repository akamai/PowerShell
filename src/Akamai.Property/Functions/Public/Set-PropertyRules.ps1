Function Set-PropertyRules {
    [CmdletBinding(DefaultParameterSetName = 'Name & body')]
    Param(
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & file', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & snippets', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & file', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & snippets', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [string]
        $InputFile,

        [Parameter(ParameterSetName = 'Name & snippets', Mandatory)]
        [Parameter(ParameterSetName = 'ID & snippets', Mandatory)]
        [string]
        $InputDirectory,

        [Parameter(ParameterSetName = 'Name & snippets')]
        [Parameter(ParameterSetName = 'ID & snippets')]
        [string]
        $DefaultRuleFilename = 'main.json',

        [Parameter(ParameterSetName = 'Name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $VersionNotes,

        [Parameter()]
        [string]
        $RuleFormat,

        [Parameter()]
        [switch]
        $UpgradeRules,

        [Parameter()]
        [switch]
        $OriginalInput,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [ValidateSet('fast', 'full')]
        [string]
        $ValidateMode,

        [Parameter()]
        [switch]
        $ValidateRules,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        if ($InputFile) {
            if (!(Test-Path $InputFile)) {
                throw "Input file $Inputfile does not exist."
            }
            $Body = Get-Content $InputFile -Raw
        }
        elseif ($InputDirectory) {
            if (-not (Test-Path $InputDirectory)) {
                throw "Input directory $Inputfile does not exist."
            }
            if (-not (Test-Path "$InputDirectory/$DefaultRuleFilename")) {
                throw "Default rule filename '$DefaultRuleFilename' does not exist in input directory '$InputDirectory'."
            }
            $Body = Merge-PropertyRules -SourceDirectory $InputDirectory -DefaultRuleFilename $DefaultRuleFilename
        }

        # Add notes if required
        $Body = Get-BodyObject -Source $Body
        if ($VersionNotes) {
            $Body | Add-Member -MemberType NoteProperty -Name 'comments' -Value $VersionNotes -Force
        }

        # Set ruleformat in headers and body
        if ($RuleFormat) {
            $AdditionalHeaders = @{
                'Content-Type' = "application/vnd.akamai.papirules.$RuleFormat+json"
            }
            $Body.ruleFormat = $RuleFormat
        }

        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}

