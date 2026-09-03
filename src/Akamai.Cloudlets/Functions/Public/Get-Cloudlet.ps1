function Get-Cloudlet {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(ParameterSetName = 'Non-shared policy', Position = 0)]
        [int]
        $CloudletID,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [switch]
        $Legacy,

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
            if ($CloudletID) {
                $Path = "/cloudlets/api/v2/cloudlet-info/$CloudletID"
            }
            else {
                $Path = "/cloudlets/api/v2/cloudlet-info"
            }
        }
        else {
            $Path = "/cloudlets/v3/cloudlet-info"
        }
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

