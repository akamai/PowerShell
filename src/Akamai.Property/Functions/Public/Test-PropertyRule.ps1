function Test-PropertyRule {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $RequestPath = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/rules"
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