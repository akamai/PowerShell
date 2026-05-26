function Get-IAMAllowedAPIs {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('uiUserName')]
        [string]
        $Username,

        [Parameter()]
        [ValidateSet('CLIENT', 'USER_CLIENT', 'SERVICE_ACCOUNT')]
        [string]
        $ClientType,

        [Parameter()]
        [switch]
        $AllowAccountSwitch,

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
        $Path = "/identity-management/v3/users/$Username/allowed-apis"
        $QueryParameters = @{
            'clientType'         = $ClientType
            'allowAccountSwitch' = $PSBoundParameters.AllowAccountSwitch.IsPresent
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
        return $Response.Body
    }
}
