function New-CloudAccessLookup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $AccessKeyUID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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
        $Path = "/cam/v1/access-keys/$AccessKeyUID/versions/$Version/property-lookup-id"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'Body'             = $Body
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

