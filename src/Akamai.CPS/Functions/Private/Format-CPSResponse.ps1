function Format-CPSResponse {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]
        $ResponseBody
    )

    process {
        # Enrollment member
        if ($ResponseBody.enrollment) {
            if ($ResponseBody.enrollment -match '[\d]+$') {
                $ResponseBody | Add-Member -NotePropertyName enrollmentId -NotePropertyValue ([int] $Matches[0])
            }
        }

        # Basic changes
        if ($ResponseBody.change) {
            if ($ResponseBody.change -match '[\d]+$') {
                $ResponseBody | Add-Member -NotePropertyName changeId -NotePropertyValue ([int] $Matches[0])
            }
        }

        # Enrollment pendingChanges
        if ($ResponseBody.pendingChanges) {
            foreach ($PendingChange in $ResponseBody.pendingChanges) {
                if ($PendingChange.location -match '[\d]+$') {
                    $PendingChange | Add-Member -NotePropertyName changeId -NotePropertyValue ([int] $Matches[0])
                }
            }
        }

        # changes array
        if ($ResponseBody.changes) {
            $ChangeIDs = New-Object -TypeName System.Collections.Generic.List[long]
            $ResponseBody.changes | ForEach-Object {
                if ($_ -match '[\d]+$') {
                    $ChangeIDs.Add([int] $Matches[0])
                }
            }
            if ($ChangeIDs.count -gt 0) {
                $ResponseBody | Add-Member -NotePropertyName changeIds -NotePropertyValue $ChangeIDs
            }
        
        }

        return $ResponseBody
    }
}
