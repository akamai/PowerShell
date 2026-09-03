function Find-APIOperation {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('ACTIVE_IN_PRODUCTION', 'ACTIVE_IN_STAGING', 'ACTIVE_WITHIN_DATE_RANGE')]
        [string]
        $QueryType,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $APIEndPointHosts,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $ResourcePaths,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $ActiveStartTime,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $ActiveEndTime,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $IncludeDetails,

        [Parameter(Mandatory, ParameterSetName = 'Body', ValueFromPipeline)]
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
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{}
            if ($ActiveEndTime) {
                $Body.activeEndTime = $ActiveEndTime
            }
            if ($ActiveEndTime) {
                $Body.activeStartTime = $ActiveStartTime
            }
            if ($APIEndPointHosts) {
                $Body.apiEndPointHosts = $APIEndPointHosts
            }
            if ($IncludeDetails) {
                $Body.includeDetails = $IncludeDetails.IsPresent
            }
            if ($QueryType) {
                $Body.queryType = $QueryType
            }
            if ($ResourcePaths) {
                $Body.resourcePaths = $ResourcePaths
            }
        }

        $Path = "/api-definitions/v2/search-operations"
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