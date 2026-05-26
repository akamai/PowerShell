function Get-CloudletPolicyProperty {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(ParameterSetName = 'Shared policy')]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Shared policy')]
        [int]
        $Page,
        
        [Parameter(ParameterSetName = 'Shared policy')]
        [int]
        $PageSize,

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
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/properties"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID/properties"
        }

        $QueryParameters = @{
            'page' = $PSBoundParameters.Page
            'size' = $PSBoundParameters.PageSize
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
        if (-not $Legacy) {
            return $Response.Body.content
        }
        else {
            return $Response.Body
        }
    }
}

