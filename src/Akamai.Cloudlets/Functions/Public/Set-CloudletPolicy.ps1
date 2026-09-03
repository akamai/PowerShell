function Set-CloudletPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Non-shared policy')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(ParameterSetName = 'Shared policy')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Shared policy')]
        [Parameter(Mandatory, ParameterSetName = 'Non-shared policy')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Shared policy')]
        [Parameter(ParameterSetName = 'Non-shared policy')]
        [string]
        $Description,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
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
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID"
        }

        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            $Body = @{}
            if ($Name) { $Body['name'] = $Name }
            if ($GroupID) { $Body['groupId'] = $GroupID }
            if ($Description) { $Body.description = $Description }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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

