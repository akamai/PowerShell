function Test-EdgeWorkerCodeBundle {
    [CmdletBinding(DefaultParameterSetName = 'Directory')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Directory')]
        [string]
        $CodeDirectory,

        [Parameter(Mandatory, ParameterSetName = 'Bundle')]
        [string]
        $CodeBundle,

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
        if ($PSCmdlet.ParameterSetName -eq 'Directory') {
            if ( Get-Command tar -ErrorAction SilentlyContinue) {
                $Directory = Get-Item $CodeDirectory
                $Bundle = Get-Content "$($Directory.FullName)\bundle.json" | ConvertFrom-Json
                $CodeBundle = New-TemporaryFile
    
                # Create bundle
                Write-Debug "Creating tarball $CodeBundle from directory $($Directory.fullName)."
                New-TarArchive -SourceDirectory $Directory.FullName -OutputFile $CodeBundle
            }
            else {
                throw "tar command not found. Please create .tgz file manually and use -CodeBundle parameter."
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'bundle') {
            if (-not (Test-Path $CodeBundle)) {
                throw "Code Bundle $CodeBundle could not be found."
            }
        }

        $Path = "/edgeworkers/v1/validations"
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
