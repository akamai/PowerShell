function Get-GTMLoadData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $ResourceName,

        [Parameter(Mandatory)]
        [int]
        $DatacenterID,

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
        return $Response.Body
    }
}

