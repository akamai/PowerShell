function Test-METSCASetVersion {
    [CmdletBinding(DefaultParameterSetName = 'body')]
    Param(
        [Parameter(ParameterSetName = 'File', Mandatory)]
        [string]
        $CertificatesFile,

        [Parameter(ParameterSetName = 'Directory', Mandatory)]
        [string]
        $CertificatesDirectory,

        [Parameter()]
        [switch]
        $AllowInsecureSha1,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
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
        $Path = "/mtls-edge-truststore/v2/certificates/validate"
        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            $PEMMatch = '-----BEGIN CERTIFICATE-----[a-zA-Z0-9\/\+\r\n=]+-----END CERTIFICATE-----'
            $CertFiles = @()
            $Certificates = @()
            if ($PSCmdlet.ParameterSetName -eq 'File') {
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
            if ($AllowInsecureSha1) {
                $Body['allowInsecureSha1'] = $true
            }
        }

        $RequestParams = @{
            'Method'           = 'POST'
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
