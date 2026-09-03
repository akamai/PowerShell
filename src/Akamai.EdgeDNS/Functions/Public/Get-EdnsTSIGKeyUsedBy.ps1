function Get-EDNSTSIGKeyUsedBy {
    [CmdletBinding(DefaultParameterSetName = 'Find by key with attributes')]
    param (
        [Parameter(ParameterSetName = 'Find by zone', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Find by key with attributes', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Find by key with attributes', Mandatory)]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Find by key with attributes', Mandatory)]
        [string]
        $TSIGKeySecret,

        [Parameter(ParameterSetName = 'Find by key with body', ValueFromPipeline, Mandatory)]
        $Body,

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
        if ($PSCmdlet.ParameterSetName -eq 'Find by zone') {
            $Method = 'GET'
            $Path = "/config-dns/v2/zones/$Zone/key/used-by"
        }
        else {
            $Method = 'POST'
            $Path = "/config-dns/v2/keys/used-by"

            if ($PSCmdlet.ParameterSetName -ne 'Find by key with body') {
                $Body = @{
                    'algorithm' = $TSIGKeyAlgorithm
                    'name'      = $TSIGKeyName
                    'secret'    = $TSIGKeySecret
                }
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }

        if ($PSCmdlet.ParameterSetName -ne 'Find by zone') {
            $RequestParams['body'] = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.zones
    }
}
