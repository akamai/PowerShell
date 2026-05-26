
function Get-EDNSTSIGKeyContract {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(Mandatory)]
        [string]
        $TSIGKeyName,
        
        [Parameter(Mandatory)]
        [string]
        $TSIGKeySecret,

        [Parameter()]
        [ValidateSet('inbound', 'outbound', 'proxy')]
        [string]
        $KeyType,

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
        $Path = "/config-dns/v2/keys/used-by/zone-contract-map"
        $QueryParameters = @{ 
            'keyType' = $KeyType
        }
        $Body = @{
            'algorithm' = $TSIGKeyAlgorithm
            'name'      = $TSIGKeyName
            'secret'    = $TSIGKeySecret
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            QueryParameters  = $QueryParameters 
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.contracts
        }
        catch {
            throw $_
        }
    }
}
