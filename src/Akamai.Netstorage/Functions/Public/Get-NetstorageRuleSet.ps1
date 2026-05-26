function Get-NetstorageRuleSet {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RuleSetID,

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
        if ($RuleSetID) {
            $Path = "/storage/v1/rule-sets/$RuleSetID"
        }
        else {
            $Path = "/storage/v1/rule-sets"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($RuleSetID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}
