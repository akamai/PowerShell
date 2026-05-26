
function Get-EdgeworkerRevisionBom {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RevisionID,

        [Parameter()]
        [switch]
        $IncludeActiveVersions,

        [Parameter()]
        [switch]
        $IncludePinnedRevisions,

        [Parameter()]
        [switch]
        $IncludeCurrentlyPinnedRevisions,

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
        $EdgeWorkerID, $null, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/bom"
        $QueryParameters = @{
            'includeActiveVersions'           = $PSBoundParameters.IncludeActiveVersions.IsPresent
            'includePinnedRevisions'          = $PSBoundParameters.IncludePinnedRevisions.IsPresent
            'includeCurrentlyPinnedRevisions' = $PSBoundParameters.IncludeCurrentlyPinnedRevisions.IsPresent
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
        return $Response.Body
    }
}
