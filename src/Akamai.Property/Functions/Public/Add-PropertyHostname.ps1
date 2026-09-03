function Add-PropertyHostname {
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

        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [object[]]
        $NewHostnames,

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
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/hostnames"
        $QueryParameters = @{
            contractId        = $ContractID
            groupId           = $GroupID
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }
        $CombinedHostnameArray = New-Object -TypeName System.Collections.Generic.List[Object]
    }

    process {
        foreach ($Hostname in $NewHostnames) {
            $CombinedHostnameArray.Add($Hostname) | Out-Null
        }
    }

    end {
        $Body = @{ add = $CombinedHostnameArray }
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
        return $Response.Body.hostnames.items
    }


}

