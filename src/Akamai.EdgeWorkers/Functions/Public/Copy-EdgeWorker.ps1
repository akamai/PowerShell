function Copy-EdgeWorker {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Version = 'production',

        [Parameter(Mandatory)]
        [string]
        $NewName,

        [Parameter()]
        [int]
        $GroupID,

        [Parameter()]
        [ValidateSet(100, 200, 400)]
        [int]
        $ResourceTierID,

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
        $AuthParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }

        # 0. Find existing EdgeWorker
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters -Version $Version # Version has a default, which will not be included in PSBoundParameters

        # 1. Get the specified version of the old EdgeWorker
        $Local:VersionFile = New-TemporaryFile
        $GetCodeBundleParams = @{
            'EdgeWorkerID' = $EdgeWorkerID
            'Version'      = $Version
            'OutputFile'   = $Local:VersionFile
        }
        Write-Debug "Copy-EdgeWorker: Downloading code bundle for EdgeWorker ID $EdgeWorkerID, version $Version to temporary file $($Local:VersionFile.FullName)"
        try {
            Get-EdgeWorkerCodeBundle @GetCodeBundleParams @AuthParams | Out-Null
        }
        catch {
            throw $_
        }

        # 2. Get EdgeWorker for group, resource tier & description, if required
        if (-not $GroupID -or -not $ResourceTierID) {
            $ExistingEdgeWorker = Get-EdgeWorker -EdgeWorkerID $EdgeWorkerID @AuthParams

            if (-not $ResourceTierID) {
                $ResourceTierID = $ExistingEdgeWorker.resourceTierId
            }
            if (-not $GroupID) {
                $GroupID = $ExistingEdgeWorker.groupId
            }
            if (-not $Description) {
                $Description = $ExistingEdgeWorker.description
            }
        }

        # 3. Create the new EdgeWorker
        $NewEdgeWorkerParams = @{
            'EdgeWorkerName' = $NewName
            'GroupID'        = $GroupID
            'ResourceTierID' = $ResourceTierID
        }

        if ($Description) {
            $NewEdgeWorkerParams['Description'] = $Description
        }

        Write-Debug "Copy-EdgeWorker: Creating new EdgeWorker with name $NewName, group ID $GroupID, resource tier ID $ResourceTierID & description $Description"
        try {
            $Local:NewEdgeWorker = New-EdgeWorker @NewEdgeWorkerParams @AuthParams
        }
        catch {
            throw $_
        }

        # 4. Apply saved version to new EdgeWorker
        $NewVersionParams = @{
            'EdgeWorkerID' = $Local:NewEdgeWorker.EdgeWorkerID
            'CodeBundle'   = $Local:VersionFile
        }
        Write-Debug "Copy-EdgeWorker: Creating new version $Version for EdgeWorker ID $($Local:NewEdgeWorker.EdgeWorkerID) using code bundle from temporary file $($Local:VersionFile.FullName)"
        try {
            New-EdgeWorkerVersion @NewVersionParams @AuthParams | Out-Null
        }
        catch {
            throw $_
        }

        return $Local:NewEdgeWorker
    }
}
