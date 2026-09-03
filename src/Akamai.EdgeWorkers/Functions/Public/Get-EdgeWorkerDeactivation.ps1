function Get-EdgeWorkerDeactivation {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $DeactivationID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Version,

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
        $EdgeWorkerID, $Version, $null, $DeactivationID = Expand-EdgeWorkerDetails @PSBoundParameters

        if ($DeactivationID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/deactivations/$DeactivationID"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/deactivations"
        }
        $QueryParameters = @{
            'version' = $Version
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
        if ($DeactivationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.deactivations
        }
    }
}
