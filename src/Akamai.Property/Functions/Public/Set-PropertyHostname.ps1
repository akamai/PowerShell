function Set-PropertyHostname {
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

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter()]
        [switch]
        $ValidateHostnames,

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

    begin {
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion/hostnames"
        $QueryParameters = @{
            contractId        = $ContractId
            groupId           = $GroupID
            validateHostnames = $PSBoundParameters.ValidateHostnames
            includeCertStatus = $PSBoundParameters.IncludeCertStatus
        }
        if ($MyInvocation.ExpectingInput) {
            $PipedHostnames = New-Object -TypeName System.Collections.Generic.List[Object]
        }
    }

    process {
        if ($MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $PipedHostnames.Add($Body)
        }
    }

    end {
        if ($MyInvocation.ExpectingInput -and $PipedHostnames.count -gt 0) {
            $Body = $PipedHostnames
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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

