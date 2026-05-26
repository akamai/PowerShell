
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]
    $CSRPem,

    [Parameter(Mandatory, Position = 1)]
    [string]
    $CertFile,

    [Parameter(Mandatory, Position = 2)]
    [string]
    $ChainFile
)
    
# Create CA certificate
$CAPrivateKey = [System.Security.Cryptography.RSA]::Create()
$HashAlgo = [System.Security.Cryptography.HashAlgorithmName]::SHA256
$RSASigPadding = [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
$CAReq = New-Object -TypeName System.Security.Cryptography.X509Certificates.CertificateRequest ("cn = pester-testing", $CAPrivateKey, $HashAlgo, $RSASigPadding)
    
# Mark as CA certificate with path length constraint
$Constraints = [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($true, $false, 0, $true)
$CAReq.CertificateExtensions.Add($Constraints)
    
# Create self-signed CA certificate valid for 10 years
$CACert = $CAReq.CreateSelfSigned((Get-Date), (Get-Date).AddDays(3650))
    
# Convert CA cert to PEM
$B64CACert = [Convert]::ToBase64String($CACert.RawData) -Replace '(.{64})', "`$1`n"
$CAPem = "-----BEGIN CERTIFICATE-----`n$($B64CACert)`n-----END CERTIFICATE-----"
    
# Load the CSR from PEM, including extensions
$CSR = [System.Security.Cryptography.X509Certificates.CertificateRequest]::LoadSigningRequestPem($CSRPem, $HashAlgo, [System.Security.Cryptography.X509Certificates.CertificateRequestLoadOptions]::UnsafeLoadCertificateExtensions)
    
# Create a new CertificateRequest with the CSR's subject and public key
$NewReq = New-Object System.Security.Cryptography.X509Certificates.CertificateRequest ($CSR.SubjectName, $CSR.PublicKey, $HashAlgo)
    
# Copy all extensions from the CSR
foreach ($Extension in $CSR.CertificateExtensions) {
    $NewReq.CertificateExtensions.Add($Extension)
}
    
# Generate random serial number
$SerialNumber = [byte[]]::new(16)
$RNG = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
$RNG.GetBytes($SerialNumber)
$RNG.Dispose()
    
# Create signature generator using CA's private key
$SignatureGenerator = [System.Security.Cryptography.X509Certificates.X509SignatureGenerator]::CreateForRSA($CAPrivateKey, $RSASigPadding)
    
# Sign the certificate with the CA
$SignedCert = $NewReq.Create($CACert.SubjectName, $SignatureGenerator, (Get-Date), (Get-Date).AddDays(46), $SerialNumber)
    
# Convert signed cert to PEM
$B64SignedCert = [Convert]::ToBase64String($SignedCert.RawData) -Replace '(.{64})', "`$1`n"
$SignedPem = "-----BEGIN CERTIFICATE-----`n$($B64SignedCert)`n-----END CERTIFICATE-----"
    
$SignedPem | Out-File -FilePath $CertFile -Encoding utf8
$CAPem | Out-File -FilePath $ChainFile -Encoding utf8
