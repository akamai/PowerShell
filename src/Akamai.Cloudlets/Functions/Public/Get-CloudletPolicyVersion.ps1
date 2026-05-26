function Get-CloudletPolicyVersion {
    [CmdletBinding(DefaultParameterSetName = 'Get one')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(ParameterSetName = 'Get one', Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $OmitRules,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,
        
        [Parameter(ParameterSetName = 'Get all')]
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
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        if ($Legacy) {
            if ($Version) {
                $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version"
            }
            else {
                $Path = "/cloudlets/api/v2/policies/$PolicyID/versions"
            }
            $QueryParameters = @{
                'omitRules' = $PSBoundParameters.OmitRules
                'offset'    = $PSBoundParameters.Page
                'pageSize'  = $PSBoundParameters.PageSize
            }
        }
        else {
            if ($Version) {
                $Path = "/cloudlets/v3/policies/$PolicyID/versions/$Version"
            }
            else {
                $Path = "/cloudlets/v3/policies/$PolicyID/versions"
            }
            $QueryParameters = @{
                'page' = $PSBoundParameters.Page
                'size' = $PSBoundParameters.PageSize
            }
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
        if (-not $Legacy -and ($Version -eq "" -or $null -eq $Version)) {
            return $Response.Body.content
        }
        else {
            return $Response.Body
        }
    }
}

