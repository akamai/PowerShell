function New-NetworkList {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('IP', 'GEO')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $ContractId,

        [Parameter(ParameterSetName = 'Attributes')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes', ValueFromPipeline)]
        [string[]]
        $Items,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
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
        $CollatedItems = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        foreach ($Item in $Items) {
            $CollatedItems.Add($Item)
        }
    }

    end {
        $Path = "/network-list/v2/network-lists"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'name' = $Name
                'type' = $Type
            }
            if ($Description -ne '') {
                $Body['description'] = $Description
            }
            if ($ContractID -ne '') {
                $Body['contractId'] = $ContractID
            }
            if ($GroupID -ne '') {
                $Body['groupId'] = $GroupID
            }
            if ($CollatedItems.Count -gt 0) {
                $Body['list'] = $CollatedItems
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

