
function Compare-EdgeworkerRevision {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RevisionID,

        [Parameter(Mandatory)]
        [string]
        $ComparisonRevisionID,

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
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/compare"
        $Body = @{
            'revisionId' = $ComparisonRevisionID
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
