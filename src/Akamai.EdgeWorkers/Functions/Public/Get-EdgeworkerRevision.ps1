
function Get-EdgeworkerRevision {
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
        $RevisionID,

        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [int]
        $ActivationID,

        [Parameter()]
        [string]
        $Network,

        [Parameter()]
        [switch]
        $PinnedOnly,

        [Parameter()]
        [switch]
        $CurrentlyPinned,

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
        $EdgeWorkerID, $Version, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($RevisionID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions"
        }
        $QueryParameters = @{
            'version'         = $Version
            'activationId'    = $PSBoundParameters.ActivationID
            'network'         = $Network
            'pinnedOnly'      = $PSBoundParameters.PinnedOnly.IsPresent
            'currentlyPinned' = $PSBoundParameters.CurrentlyPinned.IsPresent
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
        if ($RevisionID) {
            return $Response.Body
        }
        else {
            return $Response.Body.revisions
        }
    }
}
