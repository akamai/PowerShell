function Get-RuleFormatSchema {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [string]
        $ProductID,

        [Parameter(Position = 1, Mandatory, ValueFromPipeline)]
        [string]
        $RuleFormat,

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
        $Path = "/papi/v1/schemas/products/$ProductID/$RuleFormat"
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
