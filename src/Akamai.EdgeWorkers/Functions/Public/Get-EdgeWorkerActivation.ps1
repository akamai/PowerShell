function Get-EdgeWorkerActivation {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter()]
        [string]
        $ActivationID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $ActiveOnNetwork,

        [Parameter()]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

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
        $EdgeWorkerID, $Version, $ActivationID, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($ActivationID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/activations/$ActivationID"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/activations"
        }
        $QueryParameters = @{
            'version'         = $Version
            'activeOnNetwork' = $PSBoundParamters.ActiveOnNetwork.IsPresent
            'network'         = $Network
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
        if ($ActivationID) {
            return $Response.Body
        }
        else {
            return $Response.Body.activations
        }
    }
}
