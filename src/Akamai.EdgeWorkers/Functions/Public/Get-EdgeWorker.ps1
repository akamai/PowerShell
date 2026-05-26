function Get-EdgeWorker {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name')]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $GroupID,

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
        if ($EdgeWorkerID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID"
        }
        else {
            $Path = "/edgeworkers/v1/ids"
        }
        $QueryParameters = @{
            'groupId' = $PSBoundParameters.GroupID
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
    
            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                if ($EdgeWorkerID) {
                    Set-AkamaiDataCache -EdgeWorkerName $Response.Body.name -EdgeWorkerID $Response.Body.edgeWorkerId
                }
                else {
                    foreach ($EdgeWorker in $Response.Body.edgeworkerIds) {
                        Set-AkamaiDataCache -EdgeWorkerName $EdgeWorker.name -EdgeWorkerID $EdgeWorker.edgeWorkerId
                    }
                }
            }
    
            if ($PSCmdlet.ParameterSetName -eq 'Get all') {
                return $Response.Body.edgeWorkerIds
            }
            elseif ($PSCmdlet.ParameterSetName.contains('name')) {
                return $Response.Body.edgeworkerIds | Where-Object name -eq $EdgeWorkerName
            }
            else {
                return $Response.Body
            }
        }
        catch {
            throw $_
        }
    }
}
