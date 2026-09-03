function Add-BucketHostname {
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
        $CombinedHostnameArray = New-Object -TypeName System.Collections.Generic.List[Object]
    }

    process {
        foreach ($Hostname in $NewHostnames) {
            $CombinedHostnameArray.Add($Hostname) | Out-Null
        }
    }

    end {
        $Body = @{
            network = $Network
            add     = $CombinedHostnameArray
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
