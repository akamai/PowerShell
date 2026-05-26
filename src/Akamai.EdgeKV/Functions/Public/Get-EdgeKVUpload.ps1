
function Get-EdgeKVUpload {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [string]
        $BulkUploadID,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $IncludeErrors,

        [Parameter(ParameterSetName = 'Get one')]
        [int]
        $MaxItems,

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
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/jobs/$BulkUploadID"
            $QueryParameters = @{
                'includeErrors' = $PSBoundParameters.IncludeErrors.IsPresent
                'maxItems'      = $PSBoundParameters.MaxItems
            }
        }
        else {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/upload"
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($BulkUploadID) {
                return $Response.Body
            }
            else {
                return $Response.Body.jobs
            }
        }
        catch {
            throw $_
        }
    }

}
