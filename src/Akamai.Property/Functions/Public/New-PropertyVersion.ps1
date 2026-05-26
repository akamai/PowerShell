function New-PropertyVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Name & attributes', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PropertyVersion')]
        [string]
        $CreateFromVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CreateFromVersionEtag,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        $Body,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
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
        $PropertyID, $CreateFromVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{'createFromVersion' = $CreateFromVersion }
            if ($CreateFromVersionEtag) {
                $Body['createFromVersionEtag'] = $CreateFromVersionEtag
            }
        }

        $Path = "/papi/v1/properties/$PropertyID/versions"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Add additional response data
        $Response.Body | Add-Member -NotePropertyName 'propertyId' -NotePropertyValue $PropertyID
        if ($Response.Body.versionLink -Match '\/versions\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'propertyVersion' -NotePropertyValue ([int] $matches[1])
        }
        if ($ContractID) {
            $Response.Body | Add-Member -NotePropertyName 'contractId' -NotePropertyValue $ContractID
        }
        if ($GroupID) {
            $Response.Body | Add-Member -NotePropertyName 'groupId' -NotePropertyValue $GroupID
        }

        return $Response.Body
    }
}
