function Test-PropertyIncludeRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, Mandatory)]
        [string]
        $IncludeVersion,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

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
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $RequestPath = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion/rules"
        $QueryParameters = @{
            'validateRules' = $PSBoundParameters.ValidateRules
            'validateMode'  = $ValidateMode
            'dryRun'        = $PSBoundParameters.DryRun
            'contractId'    = $ContractId
            'groupId'       = $GroupID
            'upgradeRules'  = $PSBoundParameters.UpgradeRules
            'originalInput' = $PSBoundParameters.OriginalInput
        }
        $AdditionalHeaders = @{
            'content-type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'test'
                'path'  = $Path
                'value' = (Get-BodyObject -Source $Value)
            }
        )
        $RequestParams = @{
            'Method'            = 'PATCH'
            'Path'              = $RequestPath
            'QueryParameters'   = $QueryParameters
            'AdditionalHeaders' = $AdditionalHeaders
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