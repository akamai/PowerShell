
function Get-CloudWrapperAuthKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter(Mandatory)]
        [string]
        $CdnCode,

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
        $Path = "/cloud-wrapper/v1/multi-cdn/auth-keys"
        $QueryParameters = @{ 
            'contractId' = $ContractID
            'cdnCode'    = $CdnCode
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
        return $Response.Body.cdnAuthKeys
    }
}
