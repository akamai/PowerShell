function Import-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Name & file')]
    Param(
        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'Name & items', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & items', Mandatory)]
        [string]
        $ListID,

        [Parameter(Mandatory)]
        [ValidatePattern('[\d]+|latest')]
        [string]
        $Version,

        [Parameter(Mandatory, ParameterSetName = 'Name & file')]
        [Parameter(Mandatory, ParameterSetName = 'ID & file')]
        [string]
        $File,

        [Parameter(Mandatory, ParameterSetName = 'Name & items')]
        [Parameter(Mandatory, ParameterSetName = 'ID & items')]
        [string[]]
        $Items,

        [Parameter(Mandatory)]
        [ValidateSet('MERGE', 'REPLACE')]
        [string]
        $Action,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [switch]
        $IncludeStatus,

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
        $CollatedItems = New-Object -TypeName System.Collections.Generic.List['string']
    }

    process {
        $Items | ForEach-Object {
            $CollatedItems.Add($_)
        }
    }

    end {
        $ListID, $Version = Expand-ClientListDetails @PSBoundParameters
        if ($PSCMDlet.ParameterSetName.Contains('items')) {
            $Path = "/client-list/v1/lists/$ListID/items/import"
            $Body = @{
                'items'   = $CollatedItems
                'action'  = $Action
                'version' = $Version
            }
        }
        else {
            $Path = "/client-list/v1/lists/$ListID/items/import-file"
            $FileContent = Get-Content -Raw $File
            $FileName = (Get-Item $File).Name
            $Boundary = "AKAMAIPOWERSHELL"
            $Body = @"
--$Boundary
Content-Disposition: form-data; name="file"; filename="$FileName"

$FileContent
--$Boundary
Content-Disposition: form-data; name="action"

$Action
--$Boundary
Content-Disposition: form-data; name="version"

$Version
--$Boundary--
"@

            $AdditionalHeaders = @{ 'Content-Type' = "multipart/form-data; boundary=$Boundary" }
        }
        $QueryParameters = @{
            'dryRun' = $PSBoundParameters.DryRun.IsPresent
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.result
        }
    }
}