function New-EdgeWorkerVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & directory')]
    Param(
        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'Name & bundle', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID & directory', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & bundle', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory)]
        [string]
        $CodeDirectory,

        [Parameter(ParameterSetName = 'Name & bundle', Mandatory)]
        [Parameter(ParameterSetName = 'ID & bundle', Mandatory)]
        [string]
        $CodeBundle,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [system.version]
        $Version,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $Patch,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $Minor,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $Major,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [string]
        $SaveBundleTo,

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
        # Validate version params
        if ($Version -and ($Patch -or $Minor -or $Major)) {
            throw "Cannot use -Version parameter with -Patch, -Minor, or -Major parameters."
        }
        if ($Patch -and ($Minor -or $Major)) {
            throw "Cannot use -Patch parameter with -Minor or -Major parameters."
        }
        if ($Minor -and ($Patch -or $Major)) {
            throw "Cannot use -Minor parameter with -Patch or -Major parameters."
        }
        if ($Major -and ($Patch -or $Minor)) {
            throw "Cannot use -Major parameter with -Patch or -Minor parameters."
        }

        # Check codedirectory exists
        if ($CodeDirectory -and -not (Test-Path $CodeDirectory)) {
            throw "Code directory '$CodeDirectory' not found."
        }


        $EdgeWorkerID, $null = Expand-EdgeWorkerDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('directory')) {
            if ( Get-Command tar -ErrorAction SilentlyContinue) {
                if (-not $EdgeWorkerName) {
                    $EdgeWorker = Get-EdgeWorker -EdgeWorkerID $EdgeWorkerID -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
                    $EdgeWorkerName = $EdgeWorker.Name
                }
                $Directory = Get-Item $CodeDirectory
                $BundleFile = "$($Directory.FullName)/bundle.json"
                $Bundle = ConvertFrom-Json (Get-Content $BundleFile -Raw)

                $CurrentVersion = [system.version]$Bundle.'edgeworker-version'
                if ($Version) {
                    $BundleVersion = $Version
                }
                elseif ($Patch -or $Minor -or $Major) {
                    if ($Patch) {
                        $BundleVersion = [system.version]::new($CurrentVersion.Major, $CurrentVersion.Minor, $CurrentVersion.Build + 1)
                    }
                    elseif ($Minor) {
                        $BundleVersion = [system.version]::new($CurrentVersion.Major, $CurrentVersion.Minor + 1, 0)
                    }
                    elseif ($Major) {
                        $BundleVersion = [system.version]::new($CurrentVersion.Major + 1, 0, 0)
                    }
                }
                else {
                    $BundleVersion = $CurrentVersion
                }
                # Update bundle.json
                $Bundle.'edgeworker-version' = $BundleVersion.ToString()

                # Update description
                if ($Description) {
                    $Bundle.description = $Description
                }

                # Export updated bundle.json
                $Bundle | ConvertTo-Json -Depth 10 | Set-Content $BundleFile

                if ($SaveBundleTo) {
                    $CodeBundle = New-Item $SaveBundleTo | Select-Object -ExpandProperty FullName
                }
                else {
                    $CodeBundle = New-TemporaryFile
                }

                # Create bundle
                Write-Debug "Creating tarball '$CodeBundle' from directory $($Directory.fullName)."
                New-TarArchive -SourceDirectory $Directory.FullName -OutputFile $CodeBundle
            }
            else {
                throw "tar command not found. Please create .tgz file manually and use -CodeBundle parameter."
            }
        }

        elseif ($PSCmdlet.ParameterSetName.Contains('bundle')) {
            if (-not (Test-Path $CodeBundle)) {
                throw "Code Bundle $CodeBundle could not be found."
            }        
        } 
    
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/versions"
        $AdditionalHeaders = @{
            'Content-Type' = 'application/gzip'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'InputFile'         = $CodeBundle
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
