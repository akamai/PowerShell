function Set-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Name & items')]
    Param(
        [Parameter(ParameterSetName = 'Name & items', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & items', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & items', ValueFromPipeline, Mandatory)]
        [Parameter(ParameterSetName = 'ID & items', ValueFromPipeline, Mandatory)]
        [Object[]]
        $Items,

        [Parameter(ParameterSetName = 'Name & items', Mandatory)]
        [Parameter(ParameterSetName = 'ID & items', Mandatory)]
        [ValidateSet('update', 'append', 'delete')]
        [String]
        $Operation,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
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

    begin {
        $CollatedItems = New-Object -TypeName System.Collections.Generic.List['object']
    }

    process {
        $Items | ForEach-Object {
            if ($_ -is 'String') {
                $CollatedItems.Add( @{ 'value' = $_ })
            }
            else {
                $CollatedItems.Add($_)
            }
        }
    }

    end {
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/items"
        if ($PSCmdlet.ParameterSetName.Contains('items')) {
            $Body = @{
                $Operation = $CollatedItems
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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
