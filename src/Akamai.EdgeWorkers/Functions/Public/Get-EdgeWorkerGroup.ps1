function Get-EdgeWorkerGroup {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [int]
        $GroupID,

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
        if ($GroupID) {
            $Path = "/edgeworkers/v1/groups/$GroupID"
        }
        else {
            $Path = "/edgeworkers/v1/groups"
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
        if ($GroupID) {
            return $Response.Body
        }
        else {
            return $Response.Body.groups
        }
    }
}
