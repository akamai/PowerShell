function Get-PropertyVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

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
        if ($PropertyVersion) {
            $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
            $Path = "/papi/v1/properties/$PropertyID/versions/$PropertyVersion"
        }
        else {
            $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
            $Path = "/papi/v1/properties/$PropertyID/versions"
        }
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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

        # Add elements to output for better pipelining
        foreach ($Item in $Response.Body.versions.items) {
            $Item | Add-Member -NotePropertyName PropertyID -NotePropertyValue $Response.Body.PropertyID -Force
            $Item | Add-Member -NotePropertyName ContractID -NotePropertyValue $Response.Body.ContractID -Force
            $Item | Add-Member -NotePropertyName GroupID -NotePropertyValue $Response.Body.GroupID -Force
        }

        return $Response.Body.versions.items
    }
}
