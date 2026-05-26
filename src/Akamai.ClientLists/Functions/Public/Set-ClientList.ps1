function Set-ClientList {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & attributes', ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $NewName,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Notes,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string[]]
        $Tags,

        [Parameter(ParameterSetName = 'Name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipeline)]
        $Body,

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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'name' = $NewName
            }
            if ($Notes) { $Body['notes'] = $Notes }
            if ($Tags) { $Body['tags'] = $Tags }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}