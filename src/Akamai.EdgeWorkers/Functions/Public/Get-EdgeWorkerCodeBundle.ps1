function Get-EdgeWorkerCodeBundle {
    [CmdletBinding(DefaultParameterSetName = 'Name & file')]
    Param(
        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID & file', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [string]
        $OutputFile,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [string]
        $OutputDirectory,

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
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/versions/$Version/content"
        $AdditionalHeaders = @{
            accept = 'application/gzip'
        }

        # Set output file name
        if (-not $OutputFile) {
            if ($EdgeWorkerName) {
                $OutputFile = "$EdgeWorkerName-$Version.tgz"
            }
            else {
                $OutputFile = "$EdgeWorkerID-$Version.tgz"
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'OutputFile'        = $OutputFile
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSCmdlet.ParameterSetName.contains('directory')) {
            if (-not (Test-Path $OutputFile)) {
                throw "Could not find output file $OutputFile to decompress."
            }
            if (-not (Test-Path $OutputDirectory)) {
                New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
            }
            else {
                $ExistingFiles = Get-ChildItem -Path $OutputDirectory
                if ($ExistingFiles.count -gt 0) {
                    Write-Warning "Output directory '$OutputDirectory' is not empty and existing files will not be overwritten. Command may produce unexpected results."
                }
            }
            tar -xvf $OutputFile -C $OutputDirectory/
            Remove-Item -Force $OutputFile
        }
        return $Response.Body
    }
}
