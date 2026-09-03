function Get-DatastreamGroups {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm')]
        [string]
        $LogType = 'cdn', # Defaulting to CDN for backward compatibility
        
        [Parameter()]
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

    $Path = "/datastream-config-api/v3/log/$LogType/groups"
    $QueryParameters = @{
        'contractId' = $ContractID
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
    return $Response.Body.groups
}

