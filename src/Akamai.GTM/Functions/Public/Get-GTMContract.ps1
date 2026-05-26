function Get-GTMContract {
    [CmdletBinding()]
    Param(
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

    Process {
        $Path = "/config-gtm/v1/identity/contracts"

        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }

        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.contracts
    }
}