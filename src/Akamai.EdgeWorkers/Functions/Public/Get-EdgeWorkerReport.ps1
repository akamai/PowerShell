function Get-EdgeWorkerReport {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [int]
        $ReportID,

        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [string]
        $Start,

        [Parameter(ParameterSetName = 'Get one by name', Mandatory)]
        [Parameter(ParameterSetName = 'Get one by ID', Mandatory)]
        [string]
        $End,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [ValidateSet('onClientRequest', 'onOriginRequest', 'onOriginResponse', 'onClientResponse', 'responseProvider')]
        [string]
        $EventHandler,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [ValidateSet('success', 'genericError', 'unknownEdgeWorkerId', 'unimplementedEventHandler', 'runtimeError', 'executionError', 'timeoutError', 'resourceLimitHit')]
        [string]
        $Status,

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

    if ($null -ne $PSBoundParameters.ReportID) {
        # Expand to get EdgeWorkerID
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/reports/$ReportID"
        $QueryParameters = @{
            'start'        = $Start
            'end'          = $End
            'edgeWorker'   = $EdgeWorkerID
            'status'       = $Status
            'eventHandler' = $EventHandler
        }
    }
    else {
        $Path = "/edgeworkers/v1/reports"
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
    if ($null -ne $PSBoundParameters.ReportID) {
        return $Response.Body
    }
    else {
        return $Response.Body.reports
    }
}
