function Get-CloudletPolicyActivation {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Get one')]
        [int]
        $ActivationID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,
        
        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('prod', 'staging', IgnoreCase = $false)]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $PropertyName,

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
        # If activation ID supplied, assume shared
        if ($ActivationID -and $Legacy) {
            $Legacy = $false
        }

        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/activations"
            $QueryParameters = @{
                'network'      = $Network
                'propertyName' = $PropertyName
                'offset'       = $PSBoundParameters.Page
                'pageSize'     = $PSBoundParameters.PageSize
            }
        }
        else {
            if ($ActivationID) {
                $Path = "/cloudlets/v3/policies/$PolicyID/activations/$ActivationID"
            }
            else {
                $Path = "/cloudlets/v3/policies/$PolicyID/activations"
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
        if (-not $Legacy -and -not $ActivationID) {
            return $Response.Body.content
        }
        else {
            return $Response.Body
        }
    }
}

