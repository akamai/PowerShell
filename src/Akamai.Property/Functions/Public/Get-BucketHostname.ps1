function Get-BucketHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $OffSet,

        [Parameter()]
        [string]
        $Limit,

        [Parameter()]
        [string]
        $Sort,

        [Parameter()]
        [string]
        $HostnameFilter,

        [Parameter()]
        [string]
        $CNAMEToFilter,

        [Parameter()]
        [switch]
        $IncludeCertStatus,

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
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        # Capitalise $Network, API seems to care
        $Network = $Network.ToUpper()

        $Path = "/papi/v1/properties/$PropertyID/hostnames"
        $QueryParameters = @{
            contractId        = $ContractId
            groupId           = $GroupID
            network           = $Network
            offset            = $OffSet
            limit             = $Limit
            sort              = $Sort
            hostname          = $HostnameFilter
            cnameTo           = $CNAMEToFilter
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
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
        return $Response.Body.hostnames.items
    }
}
