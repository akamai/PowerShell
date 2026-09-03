
function Get-CloudWrapperProperty {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [switch]
        $Unused,

        [Parameter()]
        [string[]]
        $ContractIds,

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
        $Path = "/cloud-wrapper/v1/properties"
        $QueryParameters = @{ 
            'unused'      = $PSBoundParameters.Unused.IsPresent
            'contractIds' = $ContractIds
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
        return $Response.Body.properties
    }

}
