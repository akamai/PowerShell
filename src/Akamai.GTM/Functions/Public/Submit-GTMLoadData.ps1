function Submit-GTMLoadData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $ResourceName,

        [Parameter(Mandatory)]
        [string]
        $DatacenterID,

        [Parameter(ValueFromPipeline, Mandatory)]
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

    Process {
        $Path = "/gtm-load-data/v1/$DomainName/$ResourceName/$DatacenterID"
        $AdditionalHeaders = @{ 
            'Accept' = 'application/problem+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

