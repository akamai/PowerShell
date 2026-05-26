BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.MOKS Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'

        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.MOKS'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }

        # Set timestamp for unique asset creation
        $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)

        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContractID = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestCertificateName = "akamaipowershell-thirdparty-$Timestamp"

        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.MOKS"
        # Persistent Data
        $PD = @{}
    }

    AfterAll {
        try {
            Get-MOKSClientCertVersion -CertificateName $TestCertificateName @CommonParams |
                Where-Object status -NE 'DELETE_PENDING' |
                Remove-MOKSClientCertVersion -CertificateName $TestCertificateName @CommonParams
        }
        catch {
            Write-Debug "No versions found for cleanup"
        }

        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 CACert
    #------------------------------------------------

    Context 'Get-MOKSCACert' {
        It 'returns a list of CA certs' {
            $PD.GetMOKSCACert = Get-MOKSCACert @CommonParams
            $PD.GetMOKSCACert[0].id | Should -Not -BeNullOrEmpty
            $PD.GetMOKSCACert[0].accountId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ClientCert
    #------------------------------------------------

    Context 'New-MOKSClientCert' {
        It 'creates a new client cert by attributes' {
            $TestParams = @{
                'CertificateName'    = $TestCertificateName
                'ContractID'         = $TestContractID
                'GroupID'            = $TestGroupID
                'NotificationEmails' = 'mail@example.com'
                'SecureNetwork'      = 'STANDARD_TLS'
                'Signer'             = 'THIRD_PARTY'
                'Geography'          = 'CORE'
                'KeyAlgorithm'       = 'RSA'
            }
            $NewClientCert = New-MOKSClientCert @TestParams @CommonParams
            $NewClientCert.certificateId | Should -Match '[\d]+'
            $NewClientCert.certificateName | Should -Be $TestCertificateName
        }
        It 'creates a new client cert by body' {

        }
    }

    Context 'Get-MOKSClientCert' {
        It 'gets a list of client certs' {
            $PD.ClientCerts = Get-MOKSClientCert @CommonParams
            $PD.ClientCerts[0].certificateId | Should -Not -BeNullOrEmpty
            $PD.ClientCerts[0].certificateName | Should -Not -BeNullOrEmpty
            $PD.ClientCerts[0].certificateName | Should -Not -BeNullOrEmpty
        }
        It 'gets a single client cert by name' {
            $TestParams = @{
                'CertificateName' = $TestCertificateName
            }
            $PD.ClientCert = Get-MOKSClientCert @TestParams @CommonParams
            $PD.ClientCert.certificateName | Should -Be $TestCertificateName
            $PD.ClientCert.certificateId | Should -Match '[\d]+'
        }
        It 'gets a single client cert by ID' {
            $TestParams = @{
                'CertificateID' = $PD.ClientCert.CertificateID
            }
            $PD.ClientCertByID = Get-MOKSClientCert @TestParams @CommonParams
            $PD.ClientCert.certificateName | Should -Be $TestCertificateName
            $PD.ClientCert.certificateId | Should -Be $PD.ClientCert.CertificateID
        }
    }

    Context 'Set-MOKSClientCert' {
        It 'updates by parameter' {
            $PD.ClientCert.CertificateName = $TestCertificateName + "-temp"
            $TestParams = @{
                'Body'          = $PD.ClientCert | ConvertTo-Json -Depth 100
                'CertificateID' = $PD.ClientCert.CertificateID
            }
            Set-MOKSClientCert @TestParams @CommonParams
        }
        It 'updates by attributes' {
            $TestParams = @{
                'CertificateID'      = $PD.ClientCert.certificateId
                'newName'            = $TestCertificateName
                'notificationEmails' = ($PD.ClientCert.notificationEmails -join ', ')
            }
            Set-MOKSClientCert @TestParams @CommonParams
        }
    }

    #------------------------------------------------
    #                 ClientCertVersion
    #------------------------------------------------

    Context 'New-MOKSClientCertVersion' {
        It 'returns the correct data' {
            $TestParams = @{
                'CertificateID' = $PD.ClientCert.CertificateID
            }
            $PD.NewVersion = New-MOKSClientCertVersion @TestParams @CommonParams
            $PD.NewVersion.version | Should -Match '[\d]+'
            $PD.NewVersion.status | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-MOKSClientCertVersion' {
        It 'gets a list of versions' {
            $TestParams = @{
                'CertificateID' = $PD.ClientCert.CertificateID
            }
            $PD.Versions = Get-MOKSClientCertVersion @TestParams @CommonParams
            $PD.Versions[0].Version | Should -Match '[\d]+'
            $PD.Versions[0].status | Should -Not -BeNullOrEmpty
            Should -ActualValue $PD.Versions[0].properties -Be $null
        }
        It 'gets a list of versions, include properties' {
            $TestParams = @{
                'CertificateID'               = $PD.ClientCert.CertificateID
                'IncludeAssociatedProperties' = $true
            }
            $PD.Versions = Get-MOKSClientCertVersion @TestParams @CommonParams
            $PD.Versions[0].Version | Should -Match '[\d]+'
            $PD.Versions[0].status | Should -Not -BeNullOrEmpty
            Should -ActualValue $PD.Versions[0].Properties -BeOfType 'array'
        }
    }

    Context 'Complete-MOKSClientCertVersion' -Skip:($PSVersionTable.PSVersion.Major -lt 6) {
        BeforeAll {
            # Create cert and chain files
            function Get-CertFromCSR($CSR) {
                # Defaults
                $HashAlgo = [System.Security.Cryptography.HashAlgorithmName]::SHA256
                $RSASigPadding = [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
                $ReqOptions = [System.Security.Cryptography.X509Certificates.CertificateRequestLoadOptions]::Default
                $ParentConstraints = [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($true, $false, 0, $false)
                $CertConstraints = [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($false, $false, 0, $false)

                # Create Parent
                $PrivateKey = [System.Security.Cryptography.RSA]::Create()
                $ParentReq = New-Object -TypeName System.Security.Cryptography.X509Certificates.CertificateRequest ("cn = ca.example.com", $PrivateKey, $HashAlgo, $RSASigPadding)
                $ParentReq.CertificateExtensions.Add($ParentConstraints)
                $ParentCert = $ParentReq.CreateSelfSigned((Get-Date), (Get-Date).AddDays(3650))
                $ParentB64Cert = [Convert]::ToBase64String($ParentCert.RawData) -replace '(.{64})', "`$1`n"
                $ParentPEM = "-----BEGIN CERTIFICATE-----`n$($ParentB64Cert)`n-----END CERTIFICATE-----"

                # Sign request
                $Req = [System.Security.Cryptography.X509Certificates.CertificateRequest]::LoadSigningRequestPem($CSR, $HashAlgo, $ReqOptions, $RSASigPadding)
                $Req.CertificateExtensions.Add($CertConstraints)

                $Cert = $Req.Create($ParentCert, (Get-Date), (Get-Date).AddDays(365), [System.Text.Encoding]::UTF8.GetBytes("why so serial?") )
                $B64Cert = [Convert]::ToBase64String($Cert.RawData) -replace '(.{64})', "`$1`n"
                $PEM = "-----BEGIN CERTIFICATE-----`n$($B64Cert)`n-----END CERTIFICATE-----"
                return $PEM, $ParentPEM
            }

            $Cert, $Chain = Get-CertFromCSR -CSR $PD.Versions[0].csrBlock.csr

            $Cert | Out-File 'TestDrive:/cert.pem'
            $Chain | Out-File 'TestDrive:/chain.pem'
        }
        It 'completes successfully by file' {
            $TestParams = @{
                'CertificateID'   = $PD.ClientCert.CertificateID
                'Version'         = $PD.Versions[0].Version
                'CertificateFile' = 'TestDrive:/cert.pem'
                'TrustChainFile'  = 'TestDrive:/chain.pem'
            }
            Complete-MOKSClientCertVersion @TestParams @CommonParams
        }
        It 'completes successfully by body' {
            # Create new version
            $PD.FinalVersion = $PD.ClientCert | New-MOKSClientCertVersion @CommonParams
            $FinalVersionCert, $FinalVersionChain = Get-CertFromCSR -CSR $PD.FinalVersion.csrBlock.csr
            $TestBody = @{
                'certificate' = $FinalVersionCert
                'trustChain'  = $FinalVersionChain
            }
            $TestParams = @{
                'CertificateID' = $PD.ClientCert.CertificateID
                'Version'       = $PD.FinalVersion.Version
            }
            $TestBody | Complete-MOKSClientCertVersion @TestParams @CommonParams
        }
    }

    #------------------------------------------------
    #                 ClientCertDetails
    #------------------------------------------------

    Context 'Expand-MOKSClientCertDetails' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.MOKS/Functions/Private/Expand-MOKSClientCertDetails.ps1

            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = "TestDrive:/options.json"
            # Creat options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache

            if ($null -eq $PD.FinalVersion) {
                $PD.FinalVersion = Get-MOKSClientCertVersion -CertificateID $PD.ClientCert.CertificateID @CommonParams |
                    Sort-Object -Property Version -Descending |
                    Select-Object -First 1
            }
        }
        It 'finds the right client cert' {
            $TestParams = @{
                'CertificateName' = $TestCertificateName
            }
            $CertificateID, $null = Expand-MOKSClientCertDetails @TestParams @CommonParams
            $CertificateID | Should -Be $PD.ClientCert.certificateId
            $AkamaiDataCache.MOKS.ClientCerts.$TestCertificateName.CertificateID | Should -Be $CertificateID
        }
        It 'finds the latest version' {
            $TestParams = @{
                'CertificateName' = $TestCertificateName
                'Version'         = 'latest'
            }
            $CertificateID, $CertificateVersion = Expand-MOKSClientCertDetails @TestParams @CommonParams
            $CertificateID | Should -Be $PD.ClientCert.certificateId
            $CertificateVersion | Should -Be $PD.FinalVersion.version
            $AkamaiDataCache.MOKS.ClientCerts.$TestCertificateName.CertificateID | Should -Be $CertificateID
        }
        It 'throws when there is no deployed version' {
            $TestParams = @{
                'CertificateName' = $TestCertificateName
                'Version'         = 'deployed'
            }
            { Expand-MOKSClientCertDetails @TestParams @CommonParams } | Should -Throw 'No deployed version of client certificate *'
        }
        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache

            Remove-Item -Path Function:/Expand-MOKSClientCertDetails -Force
        }
    }

    Context 'Remove-MOKSClientCertVersion' {
        It 'removes by pipeline' {
            $TestParams = @{
                'CertificateName' = $TestCertificateName
            }
            $PD.FinalVersion | Remove-MOKSClientCertVersion @TestParams @CommonParams
        }
        It 'removes by param' {
            $TestParams = @{
                'CertificateName' = $TestCertificateName
                'Version'         = 'latest'
            }
            Remove-MOKSClientCertVersion @TestParams @CommonParams
        }
    }
}
