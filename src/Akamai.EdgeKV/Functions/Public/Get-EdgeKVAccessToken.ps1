function Get-EdgeKVAccessToken {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $TokenName,

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
        if ($TokenName) {
            $Path = "/edgekv/v1/tokens/$TokenName"
        }
        else {
            $Path = "/edgekv/v1/tokens"
        }
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
        if ($TokenName) {
            return $Response.Body
        }
        else {
            return $Response.Body.tokens
        }
    }
}

