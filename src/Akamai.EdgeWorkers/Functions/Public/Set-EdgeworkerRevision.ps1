
function Set-EdgeworkerRevision {
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
        [ValidateSet('pin', 'unpin')]
        [string]
        $Operation,

        [Parameter()]
        [string]
        $Note,

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
        if ($Operation -eq 'pin') {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/pin"
            if ($Note) {
                $Body = @{
                    'pinNote' = $Note
                }
            }
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/revisions/$RevisionID/unpin"
            if ($Note) {
                $Body = @{
                    'unpinNote' = $Note
                }
            }
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
