function New-GTMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $ContractID,

        [Parameter()]
        [string]
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

    begin {}

    process {
        $Path = "/config-gtm/v1/domains"
        $QueryParameters = @{
            'contractId' = $ContractID
            'gid'        = $GroupID
        }
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.resource  
    }

    end {}

}

