function Get-ProductsPerReportingGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ReportingGroupID,

        [Parameter()]
        [string]
        $From,

        [Parameter()]
        [string]
        $To,

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
        $DateMatch = '[\d]{4}-[\d]{2}-[\d]{2}'
        if (($From -or $To) -and ($From -notmatch $DateMatch -or $To -notmatch $DateMatch)) {
            throw "ERROR: From & To must be in the format 'YYYY-MM-DD'"
        }
    
        $Path = "/contract-api/v1/reportingGroups/$ReportingGroupID/products/summaries"
        $QueryParameters = @{
            'from' = $From
            'to'   = $To
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.products.'marketing-products'  
    }
}

