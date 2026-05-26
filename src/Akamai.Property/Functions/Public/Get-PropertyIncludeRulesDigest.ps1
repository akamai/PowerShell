function Get-PropertyIncludeRulesDigest {
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
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'HEAD'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.status -eq 204) {
            $ETag = $Response.Headers['ETag']
            if ($ETag.Count -gt 1) {
                $ETag = $ETag[0]
            }
            return $ETag
        }
    }
}
