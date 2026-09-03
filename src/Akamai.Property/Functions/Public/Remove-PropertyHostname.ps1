function Remove-PropertyHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, Mandatory)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Mandatory)]
        [string[]]
        $HostnamesToRemove,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [switch]
        $IncludeCertStatus,

        [Parameter()]
        [switch]
        $ValidateHostnames,

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

    begin {
        $CollatedHostnames = New-Object System.Collections.Generic.List[string]
    }

    process {
        $HostnamesToRemove | ForEach-Object {
            $CollatedHostnames.Add($_)
        }
    }

    end {
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/hostnames"
        $QueryParameters = @{
            contractId        = $ContractID
            groupId           = $GroupID
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }

        $Body = @{
            'remove' = $CollatedHostnames
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Status -lt 300) {
            return $Response.Body.hostnames.items
        }
        else {
            return $Response.Body
        }

    }
}
