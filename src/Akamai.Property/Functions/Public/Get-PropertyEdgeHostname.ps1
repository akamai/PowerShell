function Get-PropertyEdgeHostname {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $EdgeHostnameID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $Options,

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
        if ($EdgeHostnameID) {
            $Path = "/papi/v1/edgehostnames/$EdgeHostnameID"
        }
        else {
            $Path = "/papi/v1/edgehostnames"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
            options    = $Options
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
        return $Response.Body.edgehostnames.items
    }
}
