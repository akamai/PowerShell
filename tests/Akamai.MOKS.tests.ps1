BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.MOKS Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.MOKS/Akamai.MOKS.psm1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestCertificateName = $env:PesterMOKSCertName

        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.MOKS"
        # Persistent Data
        $PD = @{}
    }

    AfterAll {
        
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

    Context 'New-MOKSClientCert, attributes' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MOKS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-MOKSClientCert.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                CertificateName    = 'sample-set'
                CommonName         = 'clients.example.com'
                ContractID         = '1-2AB34C'
                GroupID            = 123456
                NotificationEmails = 'mail@example.com'
                SecureNetwork      = 'STANDARD_TLS'
                Signer             = 'AKAMAI'
            }
            $NewClientCert = New-MOKSClientCert @TestParams @CommonParams
            $NewClientCert.certificateId | Should -Match '[\d]+'
            $NewClientCert.certificateName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-MOKSClientCert, all' {
        It 'returns the correct data' {
            $PD.ClientCerts = Get-MOKSClientCert @CommonParams
            $PD.ClientCerts.Count | Should -BeGreaterThan 1
            $PD.ClientCerts[0].certificateId | Should -Not -BeNullOrEmpty
            $PD.ClientCerts[0].certificateName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-MOKSClientCert, single by name' {
        It 'returns the correct data' {
            $TestParams = @{
                CertificateName = $TestCertificateName
            }
            $PD.ClientCert = Get-MOKSClientCert @TestParams @CommonParams
            $PD.ClientCert.certificateName | Should -Be $TestCertificateName
            $PD.ClientCert.certificateId | Should -Match '[\d]+'
        }
    }
    
    Context 'Get-MOKSClientCert, single by ID' {
        It 'returns the correct data' {
            $TestParams = @{
                CertificateID = $PD.ClientCert.CertificateID
            }
            $PD.ClientCertByID = Get-MOKSClientCert @TestParams @CommonParams
            $PD.ClientCert.certificateName | Should -Be $TestCertificateName
            $PD.ClientCert.certificateId | Should -Be $PD.ClientCert.CertificateID
        }
    }

    Context 'Set-MOKSClientCert, id, by parameter' {
        It 'updates correctly' {
            $PD.ClientCert.CertificateName = $TestCertificateName + "-temp"
            $TestParams = @{
                Body          = $PD.ClientCert | ConvertTo-Json -Depth 100
                CertificateID = $PD.ClientCert.CertificateID
            }
            Set-MOKSClientCert @TestParams @CommonParams
        }
    }
    
    Context 'Set-MOKSClientCert, id, by attributes' {
        It 'updates correctly' {
            $TestParams = @{
                CertificateID      = $PD.ClientCert.certificateId
                newName            = $TestCertificateName
                notificationEmails = ($PD.ClientCert.notificationEmails -join ', ')
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
                CertificateID = $PD.ClientCert.CertificateID
            }
            $PD.NewVersion = New-MOKSClientCertVersion @TestParams @CommonParams
            $PD.NewVersion.version | Should -Match '[\d]+'
            $PD.NewVersion.status | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-MOKSClientCertVersion' {
        It 'returns the correct data' {
            $TestParams = @{
                CertificateID = $PD.ClientCert.CertificateID
            }
            $PD.Versions = Get-MOKSClientCertVersion @TestParams @CommonParams
            $PD.Versions[0].Version | Should -Match '[\d]+'
            $PD.Versions[0].status | Should -Not -BeNullOrEmpty
        }
    }

    # ---- Tests disabled until we can automate cert signing in PS5.1 (7 is fine apparently)
    # Context 'Complete-MOKSClientCertVersion, by pipeline' {
    #     It 'returns the correct data' {
    #         $TestParams = @{
    #             Body    = REPLACEMEWITH_BODY
    #             Version = REPLACEMEWITH_VERSION
    #         }
    #         $PD.CompleteMOKSClientCertVersionIDByParam = Complete-MOKSClientCertVersion @TestParams @CommonParams
    #         $PD.CompleteMOKSClientCertVersionIDByParam.REPLACEME | Should -Not -BeNullOrEmpty
    #     }
    # }

    # Context 'Complete-MOKSClientCertVersion, by file' {
    #     It 'returns the correct data' {
    #         $TestParams = @{
    #             Version = REPLACEMEWITH_VERSION
    #         }
    #         $PD.CompleteMOKSClientCertVersionIDByPipeline = REPLACEMEWITH_Body | Complete-MOKSClientCertVersion @TestParams @CommonParams
    #         $PD.CompleteMOKSClientCertVersionIDByPipeline.REPLACEME | Should -Not -BeNullOrEmpty
    #     }
    # }

    #------------------------------------------------
    #                 ClientCertDetails
    #------------------------------------------------

    Context 'Expand-MOKSClientCertDetails' {
        BeforeAll {
            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = "TestDrive:/options.json"
            # Creat options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache
        }
        It 'finds the right client cert' {
            $TestParams = @{
                CertificateName = $TestCertificateName
                Version         = 'latest'
            }
            $CertificateID, $CertificateVersion = Expand-MOKSClientCertDetails @TestParams @CommonParams
            $CertificateID | Should -Be $PD.ClientCert.certificateId
            $CertificateVersion | Should -Be $PD.NewVersion.version
            $AkamaiDataCache.MOKS.ClientCerts.$TestCertificateName.CertificateID | Should -Be $CertificateID
        }
        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache
        }
    }

    Context 'Remove-MOKSClientCertVersion, by pipeline' {
        It 'returns the correct data' {
            $TestParams = @{
                CertificateName = $TestCertificateName
                Version         = 'latest'
            }
            Remove-MOKSClientCertVersion @TestParams @CommonParams
        }
    }
}
