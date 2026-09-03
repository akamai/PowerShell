
function Get-CloudWrapperConfiguration {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [int64]
        $ConfigID,

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
        if ($ConfigID) {
            $Path = "/cloud-wrapper/v1/configurations/$ConfigID"
        }
        else {
            $Path = "/cloud-wrapper/v1/configurations"
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
        if ($ConfigID) {
            return $Response.Body
        }
        else {
            return $Response.Body.configurations
        }
    }

}
