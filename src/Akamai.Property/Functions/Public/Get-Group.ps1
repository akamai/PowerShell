function Get-Group {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0)]
        [string]
        $GroupName,

        [Parameter(ParameterSetName = 'ID', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

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
        $Path = "/papi/v1/groups"
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
        if ($GroupName) {
            return $Response.Body.groups.items | Where-Object { $_.groupName -eq $GroupName }

        }
        elseif ($GroupID) {
            return $Response.Body.groups.items | Where-Object { $_.groupId -eq $GroupID }

        }
        else {
            return $Response.Body.groups.items
        }
    }
}
