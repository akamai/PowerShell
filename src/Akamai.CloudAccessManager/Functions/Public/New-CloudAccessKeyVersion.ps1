function New-CloudAccessKeyVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $AccessKeyUID,

        [Parameter(Mandatory)]
        [string]
        $CloudAccessKeyID,

        [Parameter(Mandatory)]
        [string]
        $CloudSecretAccessKey,

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
        $Path = "/cam/v1/access-keys/$AccessKeyUID/versions"
    
        $Body = @{
            'cloudAccessKeyId'     = $CloudAccessKeyID
            'cloudSecretAccessKey' = $CloudSecretAccessKey
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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
