function Copy-EdgeWorker {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory)]
        [string]
        $NewName,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory)]
        [ValidateSet(100, 200, 400)]
        [int]
        $ResourceTierID,

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
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/clone"
        $Body = @{
            'name'           = $NewName
            'groupId'        = $GroupID
            'resourceTierId' = $ResourceTierID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
