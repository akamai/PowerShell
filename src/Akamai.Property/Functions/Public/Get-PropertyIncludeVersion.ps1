function Get-PropertyIncludeVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $IncludeVersion,

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
        if ($IncludeVersion) {
            $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
            $Path = "/papi/v1/includes/$IncludeID/versions/$IncludeVersion"
        }
        else {
            $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
            $Path = "/papi/v1/includes/$IncludeID/versions"
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
            $Item | Add-Member -NotePropertyName IncludeID -NotePropertyValue $Response.Body.IncludeID -Force
            $Item | Add-Member -NotePropertyName ContractID -NotePropertyValue $Response.Body.ContractID -Force
            $Item | Add-Member -NotePropertyName GroupID -NotePropertyValue $Response.Body.GroupID -Force
        }

        return $Response.Body.versions.items
    }
}
