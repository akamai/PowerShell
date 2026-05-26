
function Get-PropertyIncludeParent {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter()]
        [int]
        $Offset,

        [Parameter()]
        [int]
        $Limit,

        [Parameter()]
        [string]
        $ContractID,

        [Parameter()]
        [string]
        $GroupID,

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
        $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        $Path = "/papi/v1/includes/$IncludeID/parents"
        $QueryParameters = @{
            'offset'     = $PSBoundParameters.Offset
            'limit'      = $PSBoundParameters.Limit
            'contractId' = $ContractID
            'groupId'    = $GroupID
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.properties.items
        }
        catch {
            throw $_
        }
    }
}
