function Read-NetstorageDirectory {
    [CmdletBinding(DefaultParameterSetName = 'Directory')]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(ParameterSetName = 'Directory')]
        [string]
        $Prefix,

        [Parameter(ParameterSetName = 'List')]
        [switch]
        $Recurse,

        [Parameter(Mandatory)]
        [string]
        $OutputDirectory,

        [Parameter()]
        [string]
        $StartPath,

        [Parameter()]
        [string]
        $EndPath,

        [Parameter()]
        [int]
        $MaxEntries,

        [Parameter()]
        [string]
        $Encoding,

        [Parameter()]
        [switch]
        $SlashBoth,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        # Set common params for Read calls
        $CommonParams = @{
            NSRCFile = $NSRCFile
            Section  = $Section
        }

        if (-not (Test-Path $OutputDirectory)) {
            Write-Host 'Creating output directory ' -NoNewline
            Write-Host -ForegroundColor Cyan $OutputDirectory -NoNewline
            Write-Host '.'
            New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
        }

        # Get list of files
        $GetParams = $PSBoundParameters.PSObject.Copy()
        $GetParams.Remove('OutputDirectory') | Out-Null
        $NetstorageFiles = Get-NetstorageDirectory @GetParams

        $Files = $NetstorageFiles | Where-Object type -eq file
        Write-Debug "Retrieving $($Files.count) files"
        $Files | ForEach-Object {
            $LocalPath = "$OutputDirectory/$($_.name)"
            Read-NetstorageObject -RemotePath $_.name -LocalPath $LocalPath @CommonParams
        }
    }
}
