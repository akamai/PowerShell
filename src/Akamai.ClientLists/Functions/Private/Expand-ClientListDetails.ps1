function Expand-ClientListDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $Name,
        
        [Parameter()]
        $ListID,
        
        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    $CommonParams = @{
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    if ($Name -ne '') {
        # Check cache if enabled
        if ($Global:AkamaiOptions.EnableDataCache) {
            $ListID = $Global:AkamaiDataCache.ClientLists.Lists.$Name.ListID
        }

        if (-not $ListID) {
            Write-Debug "Expand-ClientListDetails: '$Name' - Retrieving list details."
            $ClientList = Get-ClientList -Name $Name @CommonParams
            if ($ClientList.count -gt 1) {
                throw "There are multiple client lists with the name '$Name'. Please use -ListID instead."
            }
            elseif ($null -ne $ClientList.listId) {
                # Single item array has been enumerated
                $ListID = $ClientList.listId
            }
            else {
                throw "Client List '$Name' not found."
            }
        }

        # Add to data cache
        if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.ClientLists.Lists.$Name) {
            $Global:AkamaiDataCache.ClientLists.Lists.$Name = @{
                'ListID' = $ListID
            }
        }
        Write-Debug "Expand-ClientListDetails: ListID = $ListID."
    }

    if ($Version -and $Version -notmatch '^[0-9]+$') {
        Write-Debug "Expand-ClientListDetails: '$ListID' - Retrieving list versions."
        if ($null -eq $ClientList) {
            $ClientList = Get-ClientList -ListID $ListID @CommonParams
        }

        if ($Version -eq 'latest') {
            $Version = $ClientList.version
        }
        elseif ($Version -eq 'production') {
            if ($null -eq $ClientList.productionActiveVersion) {
                throw "No production-active version of client list '$($ClientList.name)'."
            }
            else {
                $Version = $ClientList.productionActiveVersion
            }
        }
        elseif ($Version -eq 'staging') {
            if ($null -eq $ClientList.stagingActiveVersion) {
                throw "No staging-active version of client list '$($ClientList.name)'."
            }
            else {
                $Version = $ClientList.stagingActiveVersion
            }
        }
        Write-Debug "Expand-ClientListDetails: Version = $Version."
    }

    return $ListID, $Version
}
