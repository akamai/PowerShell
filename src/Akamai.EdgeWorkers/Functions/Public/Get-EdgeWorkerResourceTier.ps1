function Get-EdgeWorkerResourceTier {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name')]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Get all', Mandatory)]
        [string]
        $ContractID,

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
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $Path = "/edgeworkers/v1/resource-tiers"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/resource-tier"
        }
        $QueryParameters = @{
            'contractId' = $ContractID
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
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            return $Response.Body.resourceTiers
        }
        else {
            return $Response.Body
        }
    }
}
