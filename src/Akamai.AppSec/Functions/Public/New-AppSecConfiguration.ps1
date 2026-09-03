function New-AppSecConfiguration {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $Description,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
        [string]
        $ContractId,

        [Parameter(Mandatory)]
        [string[]]
        $Hostnames,

        [Parameter()]
        [int]
        $CloneConfigID,

        [Parameter()]
        [int]
        $CloneConfigVersion,

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
        $Path = "/appsec/v1/configs"
        $Body = @{
            name        = $Name
            description = $Description
            contractId  = $ContractID
            groupId     = $GroupID
            hostnames   = $Hostnames
        }
    
        if ($CloneConfigID -and $CloneConfigVersion) {
            $Body['createFrom'] = @{
                configId = $CloneConfigID
                version  = $CloneConfigVersion
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
        
            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                Set-AkamaiDataCache -AppSecConfigName $Response.Body.name -AppSecConfigID $Response.Body.configId
            }
        
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
