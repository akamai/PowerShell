function Expand-MOKSClientCertDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $CertificateName,
        
        [Parameter()]
        $CertificateID,

        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    $CommonParams = @{
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }

    if ($CertificateName -ne '') {
        # Check cache if enabled
        if ($Global:AkamaiOptions.EnableDataCache) {
            $CertificateID = $Global:AkamaiDataCache.MOKS.ClientCerts.$CertificateName.CertificateID
        }

        if (-not $CertificateID) {
            Write-Debug "Expand-MOKSClientCertDetails: '$CertificateName' - Retrieving Client Certificate details."
            $ClientCerts = Get-MOKSClientCert @CommonParams
            $ClientCert = $ClientCerts | Where-Object certificateName -eq $CertificateName
            if ($null -eq $ClientCert) {
                throw "Client certificate '$CertificateName' not found."
            }
            $CertificateID = $ClientCert.certificateId
        }

        # Add to data cache
        if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.MOKS.ClientCerts.$CertificateName) {
            $Global:AkamaiDataCache.MOKS.ClientCerts.$CertificateName = @{
                'CertificateID' = $CertificateID
            }
        }
        Write-Debug "Expand-MOKSClientCertDetails: CertificateID = $CertificateID."
    }

    if ($Version -and $Version.ToLower() -in 'latest', 'deployed') {
        Write-Debug "Expand-MOKSClientCertDetails: '$CertificateID' - Retrieving Client Certificate versions."
        $Versions = Get-MOKSClientCertVersion -CertificateID $CertificateID @CommonParams | Sort-Object -property Version -Descending
        if ($Version.ToLower() -eq 'latest') {
            $Version = $Versions[0].version
        }
        elseif ($Version.ToLower() -eq 'deployed') {
            $DeployedVersion = $Versions | Where-Object status -eq 'DEPLOYED'
            if ($null -eq $DeployedVersion) {
                Throw "No deployed version of client certificate '$CertificateID'."
            }
            $Version = $DeployedVersion.version
        }
        Write-Debug "Expand-MOKSClientCertDetails: Version = $Version."
    }

    return $CertificateID, $Version
}
