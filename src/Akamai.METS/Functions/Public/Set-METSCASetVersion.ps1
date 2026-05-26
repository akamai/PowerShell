function Set-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & body')]
    Param(
        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [int]
        $CASetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $Version,

        [Parameter(ParameterSetName = 'Name & file', Mandatory)]
        [Parameter(ParameterSetName = 'ID & file', Mandatory)]
        [string]
        $CertificatesFile,

        [Parameter(ParameterSetName = 'Name & directory', Mandatory)]
        [Parameter(ParameterSetName = 'ID & directory', Mandatory)]
        [string]
        $CertificatesDirectory,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [Alias('Comments')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [Parameter(ParameterSetName = 'Name & directory')]
        [Parameter(ParameterSetName = 'ID & directory')]
        [switch]
        $AllowInsecureSha1,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name & body')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ID & body')]
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

    process {
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/versions/$Version"

        if (-not $PSCmdlet.ParameterSetName.Contains('body')) {
            $PEMMatch = '-----BEGIN CERTIFICATE-----[a-zA-Z0-9\/\+\r\n=]+-----END CERTIFICATE-----'
            $CertFiles = @()
            $Certificates = @()
            if ($PSCmdlet.ParameterSetName.Contains('file')) {
                if (-not (Test-Path $CertificatesFile)) {
                    throw "Certificates file '$CertificatesFile' does not exist"
                }
                $CertFiles += Get-Item $CertificatesFile
            }
            else {
                if (-not (Test-Path $CertificatesDirectory)) {
                    throw "Certificates directory '$CertificatesDirectory' does not exist"
                }
                $CertFiles += Get-ChildItem $CertificatesDirectory
            }
            foreach ($CertFile in $CertFiles) {
                $FileContent = Get-Content -Raw $CertFile.FullName
                $CertMatches = Select-String -InputObject $FileContent -Pattern $PEMMatch -AllMatches
                foreach ($CertMatch in $CertMatches.matches) {
                    $Certificates += ($CertMatch.value -replace '[\r\n]*', '')
                }
            }
            # De-duplicate certs
            $Certificates = $Certificates | Select-Object -Unique

            $Body = @{
                'certificates' = @()
            }
            $Certificates | ForEach-Object {
                $Body['certificates'] += @{ 'certificatePem' = $_ }
            }
            if ($Description) {
                $Body['description'] = $Description
            }
            if ($AllowInsecureSha1) {
                $Body['allowInsecureSha1'] = $true
            }
        }

        $Body = Format-CASetVersion -Version $Body

        $RequestParams = @{
            'Method'           = 'PUT'
            'Path'             = $Path
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
