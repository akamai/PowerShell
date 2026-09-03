function Remove-BucketHostname {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ValueFromPipeline)]
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
        # Capitalise $Network, API seems to care
        $Network = $Network.ToUpper()
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/hostnames"
        $QueryParameters = @{
            contractId        = $ContractID
            groupId           = $GroupID
            network           = $Network
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }

        $Body = @{
            'network' = $Network
            'remove'  = $CollatedHostnames
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
        return $Response.Body.hostnames

    }
}
