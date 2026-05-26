function Get-CPReportingGroup {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0, ValueFromPipeline)]
        [int]
        $ReportingGroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CPCodeID,

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

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/cprg/v1/reporting-groups/$ReportingGroupID"
        }
        else {
            $Path = "/cprg/v1/reporting-groups"
        }
        $QueryParameters = @{
            'contractId'         = $ContractID
            'groupId'            = $GroupID
            'cpcodeId'           = $CPCodeID
            'reportingGroupName' = $Name
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($ReportingGroupID) {
            return $Response.Body
        }
        else {
            return $Response.Body.groups
        }
    }
}

