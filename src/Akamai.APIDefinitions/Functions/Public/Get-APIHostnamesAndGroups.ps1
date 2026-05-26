function Get-APIHostnamesAndGroups {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $GroupID,
        
        [Parameter(Mandatory)]
        [string]
        $ContractID,
        
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

    $Path = "/api-definitions/v2/contracts/$ContractID/groups/$GroupID/hostsAcgs"
    $RequestParams = @{
        'Path'             = $Path
        'Method'           = 'GET'
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body
}

