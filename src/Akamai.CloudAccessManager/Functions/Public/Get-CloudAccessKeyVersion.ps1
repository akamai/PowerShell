function Get-CloudAccessKeyVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [nullable[int]]
        $AccessKeyUID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int]
        $Version,

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
        if ($Version) {
            $Path = "/cam/v1/access-keys/$AccessKeyUID/versions/$Version"
        }
        else {
            $Path = "/cam/v1/access-keys/$AccessKeyUID/versions"
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
        if ($Version) {
            return $Response.Body
        }
        else {
            return $Response.Body.accessKeyVersions
        }
    }
}
