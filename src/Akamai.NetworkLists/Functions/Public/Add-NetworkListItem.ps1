function Add-NetworkListItem {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('uniqueId')]
        [string]
        $NetworkListID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Items,

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
        $Path = "/network-list/v2/network-lists/$NetworkListID/append"
        $Body = @{
            'list' = $CollatedItems
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