function Get-EdgeHostnameChangeRequest {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipeline)]
        [string]
        $ChangeID,

        [Parameter(ParameterSetName = 'Get one by components', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RecordName,

        [Parameter(ParameterSetName = 'Get one by components', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $DNSZone,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        [ValidateSet('PENDING')]
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

    process {
        if ($ChangeID) {
            $Path = "/hapi/v1/change-requests/$ChangeID"
        }
        else {
            $Path = "/hapi/v1/change-requests"
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters = @{
                'status' = $Status
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Get one by components') {
            $Path = "/hapi/v1/dns-zones/$DNSZone/edge-hostnames/$RecordName/change-requests"
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
        if ($ChangeID) {
            return $Response.Body
        }
        else {
            return $Response.Body.changeRequests
        }
    }
}
