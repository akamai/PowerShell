function Get-IAMGroup {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $GroupID,

        [Parameter()]
        [switch]
        $Actions,
        
        [Parameter()]
        [switch]
        $Flatten,

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
        function flatten($Group) {
            $Output = New-Object -TypeName System.Collections.Generic.List[Object]
            $Output.Add($Group)
            $Group.SubGroups | ForEach-Object {
                $SubGroups = flatten($_)
                foreach ($SubGroup in $SubGroups) {
                    $Output.Add($SubGroup)
                }
            }
            return $Output
        }
    
        if ($GroupID) {
            $Path = "/identity-management/v3/user-admin/groups/$GroupID"
        }
        else {
            $Path = "/identity-management/v3/user-admin/groups"
        }
        $QueryParameters = @{
            'actions' = $PSBoundParameters.Actions.IsPresent
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
        if ($Flatten) {
            $FlattenedGroups = New-Object -TypeName System.Collections.Generic.List[Object]
            foreach ($Group in $Response.Body) {
                $FlattenedGroup = flatten($Group)
                if ($FlattenedGroup.count -eq 1) {
                    $FlattenedGroups.Add($FlattenedGroup)
                }
                elseif ($FlattenedGroup.count -gt 1) {
                    $FlattenedGroups.AddRange($FlattenedGroup)
                }
            }
            return $FlattenedGroups
        }
        else {
            return $Response.Body
        }
    }
}
