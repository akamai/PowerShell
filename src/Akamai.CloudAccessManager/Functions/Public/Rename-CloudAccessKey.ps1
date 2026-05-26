function Rename-CloudAccessKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $AccessKeyUID,

        [Parameter(Mandatory)]
        [string]
        $AccessKeyName,

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
        $Path = "/cam/v1/access-keys/$AccessKeyUID"
        $Body = @{
            'accessKeyName' = $AccessKeyName
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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