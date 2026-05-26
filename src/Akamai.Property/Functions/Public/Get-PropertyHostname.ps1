function Get-PropertyHostname {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Get one by name', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get one by ID', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [switch]
        $ValidateHostnames,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [switch]
        $IncludeCertStatus,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Offset,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Limit,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('hostname:a', 'hostname:d')]
        [string]
        $Sort,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CnameTo,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('PRODUCTION', 'STAGING')]
        [string]
        $Network,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

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
        if ($PSCmdlet.ParameterSetName.Contains('one')) {
            $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

            $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/hostnames"
            $QueryParameters = @{
                contractId        = $ContractId
                groupId           = $GroupID
                validateHostnames = $PSBoundParameters.ValidateHostnames
                includeCertStatus = $PSBoundParameters.IncludeCertStatus
            }
        }
        else {
            $Path = '/papi/v1/hostnames'
            $QueryParameters = @{
                contractId = $ContractId
                groupId    = $GroupID
                offset     = $PSBoundParameters.offset
                limit      = $PSBoundParameters.limit
                sort       = $Sort
                hostname   = $Hostname
                cnameTo    = $CnameTo
                network    = $Network
            }
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
        $Hostnames = $Response.Body.hostnames.items
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            if ($null -eq $PSBoundParameters.Limit -and $null -eq $PSBoundParameters.Offset) {
                $Offset = $Limit = $Response.Body.hostnames.items.count
                while ($Hostnames.count -lt $Response.Body.hostnames.totalItems) {
                    $PSBoundParameters.Limit = $Limit
                    $PSBoundParameters.Offset = $Offset
                    $Hostnames += Get-PropertyHostname @PSBoundParameters
                    # Increase offset for potential next iteration
                    $Offset += $Limit
                }
            }
        }
        return $Hostnames
    }
}
