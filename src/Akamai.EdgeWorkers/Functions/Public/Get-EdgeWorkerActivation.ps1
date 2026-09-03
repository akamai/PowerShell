function Get-EdgeWorkerActivation {
    [CmdletBinding(DefaultParameterSetName = 'Get all by name')]
    param(
        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get all by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [string]
        $ActivationID,

        [Parameter(ParameterSetName = 'Get all by name', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all by ID', ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(ParameterSetName = 'Get all by name')]
        [Parameter(ParameterSetName = 'Get all by ID')]
        [switch]
        $ActiveOnNetwork,

        [Parameter(ParameterSetName = 'Get all by name')]
        [Parameter(ParameterSetName = 'Get all by ID')]
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
            'activeOnNetwork' = $PSBoundParameters.ActiveOnNetwork.IsPresent
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
