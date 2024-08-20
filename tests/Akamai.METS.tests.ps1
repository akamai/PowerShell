Describe 'Safe Akamai.METS Tests' {
    BeforeAll {
        function Get-CAPem($CN) {
            $PrivateKey = [System.Security.Cryptography.RSA]::Create()
            $HashAlgo = [System.Security.Cryptography.HashAlgorithmName]::SHA256
            $RSASigPadding = [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
            $Req = New-Object -TypeName System.Security.Cryptography.X509Certificates.CertificateRequest ("cn = $CN", $PrivateKey, $HashAlgo, $RSASigPadding)
            $Constraints = [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($true, $false, 0, $false)
            $Req.CertificateExtensions.Add($Constraints)
            $Cert = $Req.CreateSelfSigned((Get-Date), (Get-Date).AddDays(3650))
            $B64Cert = [Convert]::ToBase64String($Cert.RawData) -Replace '(.{64})', "`$1`n"
            $PEM = "-----BEGIN CERTIFICATE-----`n$($B64Cert)`n-----END CERTIFICATE-----"
            return $PEM
        }


        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.METS/Akamai.METS.psm1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestCASetName = 'AkamaiPowershell'


        # Set up test data
        $TestDirName = 'metsdata'
        $TestCertsFile = "$TestDirName/chain.pem"
        $TestCertsDir = "$TestDirName/certs"
        New-Item -ItemType directory -Path $TestDirName | Out-Null
        New-Item -ItemType Directory -Path $TestCertsDir | Out-Null

        # Create self signed certs
        $TestPEM1 = Get-CAPem
        $TestPEM2 = Get-CAPem
        $TestPEM3 = Get-CAPem
        $TestPEM4 = Get-CAPem
        $TestPEM5 = Get-CAPem
        $TestPEM6 = Get-CAPem

        $TestPEM1 | Out-File $TestCertsDir/cert1.pem
        $TestPEM2 | Out-File $TestCertsDir/cert2.pem
        "$TestPEM3`n$TestPEM4" | Out-File $TestCertsFile
        $TestNewVersionComments = "Pester testing on $(Get-Date)"
        $TestNewVersionBody = @{
            allowInsecureSha1 = $false
            comments          = $TestNewVersionComments
            certificates      = @(
                @{
                    certificatePem = $TestPEM5
                },
                @{
                    certificatePem = $TestPEM6
                }
            )
        }

        # Persistent Data
        $PD = @{}
    }

    AfterAll {
        Remove-Item -Force -Recurse $TestDirName
    }

    #------------------------------------------------
    #                   CA Set
    #------------------------------------------------

    Context 'Get-METSCASet - all' {
        It 'returns a list' {
            $PD.CASets = Get-METSCASet @CommonParams
            $PD.CASets[0].caSetId | Should -Not -BeNullOrEmpty
            $PD.CASets[0].caSetName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-METSCASet - single, by name' {
        It 'returns the correct set' {
            $TestParams = @{
                CASetName = $TestCASetName
            }
            $PD.CASetByName = Get-METSCASet @TestParams @CommonParams | Where-Object isDeleted -eq $false
            $PD.CASetByName.caSetName | Should -Be $TestCASetName
        }
    }
    
    Context 'Get-METSCASet - single, by ID' {
        It 'returns the correct set' {
            $TestParams = @{
                CASetID = $PD.CASetByName.caSetId
            }
            $PD.CASet = Get-METSCASet @TestParams @CommonParams
            $PD.CASet.caSetId | Should -Be $PD.CASetByName.caSetId
            $PD.CASet.caSetName | Should -Be $TestCASetName
        }
    }

    Context 'Get-METSCASetActivities' {
        It 'returns the correct data' {
            $TestParams = @{
                CASetID = $PD.CASet.caSetId
            }
            $PD.Activities = Get-METSCASetActivities @TestParams @CommonParams
            $PD.Activities[0].activityBy | Should -Not -BeNullOrEmpty
            $PD.Activities[0].activityDate | Should -Not -BeNullOrEmpty
        }
    }
    
    

    #------------------------------------------------
    #                 Private Functions
    #------------------------------------------------
    
    Context 'Expand-METSCASetDetails' {
        It 'reports the correct data' {
            $TestParams = @{
                CASetName = $TestCASetName
            }
            $PD.ExpandCASetID = Expand-METSCASetDetails @TestParams @CommonParams
            $PD.ExpandCASetID | Should -Be $PD.CASet.caSetId
        }
    }

    #------------------------------------------------
    #                 Activations                  
    #------------------------------------------------


    Context 'Get-METSCASetActivation - all' {
        It 'returns the correct data' {
            $TestParams = @{
                CASetID = $PD.CASet.caSetId
            }
            $PD.Activations = Get-METSCASetActivation @TestParams @CommonParams
            $PD.Activations[0].activationId | Should -Not -BeNullOrEmpty
            $PD.Activations[0].caSetId | Should -Be $PD.CASet.caSetId
        }
    }

    Context 'Get-METSCASetActivation - single' {
        It 'returns the correct data' {
            $TestParams = @{
                CASetID      = $PD.CASet.caSetId
                VersionID    = $PD.Activations[0].versionId
                ActivationId = $PD.Activations[0].activationId
            }
            $PD.Activation = Get-METSCASetActivation @TestParams @CommonParams
            $PD.Activation.ActivationID | Should -Be $PD.Activations[0].activationId
            $PD.Activation.caSetId | Should -Be $PD.CASet.caSetId
        }
    }

    
    #------------------------------------------------
    #                 Versions                  
    #------------------------------------------------

    Context 'Get-METSCASetVersion - all' {
        It 'gets a list of versions' {
            $TestParams = @{
                CASetID             = $PD.CASet.caSetId
                IncludeCertificates = $true
            }
            $PD.Versions = Get-METSCASetVersion @TestParams @CommonParams
            $PD.Versions.count | Should -BeGreaterThan 0
            $PD.Versions[0].certificates.count | Should -BeGreaterThan 0
            $PD.Versions[0].versionId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-METSCASetVersion - single' {
        It 'returns the correct data' {
            $LatestVersion = $PD.Versions | Sort-Object -Property versionNumber -Descending | Select-Object -First 1
            $TestParams = @{
                CASetID   = $PD.CASet.caSetId
                VersionID = $LatestVersion.versionId
            }
            $PD.Version = Get-METSCASetVersion @TestParams @CommonParams
            $PD.Version.VersionId | Should -Be $LatestVersion.versionId
        }
    }

    Context 'New-METSCASetVersion - body' {
        It 'updates correctly' {
            $TestParams = @{
                CASetID = $PD.CASet.caSetId
            }
            $PD.NewVersionBody = $TestNewVersionBody | New-METSCASetVersion @TestParams @CommonParams
            $PD.NewVersionBody.versionId | Should -Not -BeNullOrEmpty
            $PD.NewVersionBody.versionNumber | Should -BeGreaterThan $LatestVersion.VersionNumber
        }
    }

    Context 'New-METSCASetVersion - file' {
        It 'updates correctly' {
            $TestParams = @{
                CASetID          = $PD.CASet.caSetId
                CertificatesFile = $TestCertsFile
                Comments         = 'Pester updates by file'
            }
            $PD.NewVersionFile = New-METSCASetVersion @TestParams @CommonParams
            $PD.NewVersionFile.versionId | Should -Not -BeNullOrEmpty
            $PD.NewVersionFile.versionNumber | Should -BeGreaterThan $PD.NewVersionBody.VersionNumber
        }
    }

    Context 'New-METSCASetVersion - directory' {
        It 'updates correctly' {
            $TestParams = @{
                CASetID               = $PD.CASet.caSetId
                CertificatesDirectory = $TestCertsDir
                Comments              = 'Pester updates by directory'
            }
            $PD.NewVersionDirectory = New-METSCASetVersion @TestParams @CommonParams
            $PD.NewVersionDirectory.versionId | Should -Not -BeNullOrEmpty
            $PD.NewVersionDirectory.versionNumber | Should -BeGreaterThan $PD.NewVersionFile.VersionNumber
        }
    }


    Context 'Set-METSCASetVersion - body' {
        It 'updates correctly' {
            $TestParams = @{
                CASetID = $PD.CASet.caSetId
            }
            $PD.SetVersionBody = $PD.NewVersionDirectory | Set-METSCASetVersion @TestParams @CommonParams
            $PD.SetVersionBody.versionId | Should -Not -BeNullOrEmpty
            $PD.SetVersionBody.versionNumber | Should -BeGreaterThan $LatestVersion.VersionNumber
        }
    }

    Context 'Set-METSCASetVersion - file' {
        It 'updates correctly' {
            $TestParams = @{
                CASetID          = $PD.CASet.caSetId
                VersionID        = $PD.NewVersionDirectory.VersionID
                CertificatesFile = $TestCertsFile
                Comments         = 'Pester updates by file'
            }
            $PD.SetVersionFile = Set-METSCASetVersion @TestParams @CommonParams
            $PD.SetVersionFile.versionId | Should -Not -BeNullOrEmpty
            $PD.SetVersionFile.versionNumber | Should -BeGreaterThan $PD.NewVersionBody.VersionNumber
        }
    }

    Context 'Set-METSCASetVersion - directory' {
        It 'updates correctly' {
            $TestParams = @{
                CASetID               = $PD.CASet.caSetId
                VersionID             = $PD.NewVersionDirectory.VersionID
                CertificatesDirectory = $TestCertsDir
                Comments              = 'Pester updates by directory'
            }
            $PD.SetVersionDirectory = Set-METSCASetVersion @TestParams @CommonParams
            $PD.SetVersionDirectory.versionId | Should -Not -BeNullOrEmpty
            $PD.SetVersionDirectory.versionNumber | Should -BeGreaterThan $PD.NewVersionFile.VersionNumber
        }
    }


    Context 'Copy-METSCASetVersion' {
        It 'returns the correct data' {
            $TestParams = @{
                CASetID   = $PD.CASet.caSetId
                VersionID = $PD.NewVersionDirectory.VersionID
            }
            $PD.CopyVersion = Copy-METSCASetVersion @TestParams @CommonParams
            ($PD.CopyVersion.Certificates.certificateId | Sort-Object) | Should -Be ($PD.NewVersionDirectory.Certificates.certificateId | Sort-Object)
        }
    }

    #------------------------------------------------
    #                 CASet Version Certificate                  
    #------------------------------------------------

    Context 'Get-METSCASetVersionCertificate' {
        It 'returns the correct data' {
            $TestParams = @{
                CASetID   = $PD.CASet.caSetId
                VersionID = $PD.NewVersionDirectory.VersionID
            }
            $PD.VersionCerts = Get-METSCASetVersionCertificate @TestParams @CommonParams
            ($PD.VersionCerts.certificateId | Sort-Object) | Should -Be ($PD.NewVersionDirectory.Certificates.certificateId | Sort-Object)
        }
    }
}


Describe 'Unsafe METS Tests' {
    
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.METS/Akamai.METS.psm1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterSafeEdgeRCFile
            Section    = 'default'
        }
        $TestContract = '1-2AB34C'
        $TestGroup = 123456
        $TestCASet = @"
{
    "caSetName": "akamaipowershell",
    "description": "Testing"
}
"@
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.METS"
        $PD = @{}
    }

    AfterAll {
        
    }

    #-------------------------------------------------
    #                   CA Set
    #-------------------------------------------------
    
    Context 'New-METSCASet by parameters' {
        It 'creates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-METSCASet.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                CASetName   = 'akamaipowershell'
                Description = 'Testing'
            }
            $NewSet = New-METSCASet @TestParams
            $NewSet.caSetId | Should -Not -BeNullOrEmpty
            $NewSet.caSetName | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'New-METSCASet by pipeline' {
        It 'creates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-METSCASet.json"
                return $Response | ConvertFrom-Json
            }
            $NewSet = $TestCASet | New-METSCASet
            $NewSet.caSetId | Should -Not -BeNullOrEmpty
            $NewSet.caSetName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-METSCASet' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-METSCASet.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                CASetID = 123456
            }
            Remove-METSCASet @TestParams
        }
    }

    Context 'Get-METSRemoval - All' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-METSRemoval_1.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                CASetID = $PD.CASet.caSetId
            }
            $PD.Removals = Get-METSRemoval @TestParams
            $PD.Removals.count | Should -BeGreaterThan 1
            $PD.Removals[0].caSetId | Should -Not -BeNullOrEmpty
            $PD.Removals[0].deletionId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-METSRemoval - Single' {
        It 'returns a single deletion' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-METSRemoval.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                CASetID    = $PD.CASet.caSetId
                DeletionID = 2
            }
            $PD.Removal = Get-METSRemoval @TestParams
            $PD.Removal.caSetId | Should -Not -BeNullOrEmpty
            $PD.Removal.deletionId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Deactivation                  
    #------------------------------------------------

    Context 'New-METSCASetDeactivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-METSCASetDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                CASetID   = 123456
                Network   = 'STAGING'
                VersionID = 1
            }
            $Deactivation = New-METSCASetDeactivation @TestParams
            $Deactivation.activationId | Should -Not -BeNullOrEmpty
            $Deactivation.caSetId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Activation                  
    #------------------------------------------------

    Context 'New-METSCASetActivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-METSCASetActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                CASetID   = 123456
                Network   = 'STAGING'
                VersionID = 1
            }
            $PD.Activate = New-METSCASetActivation @TestParams
            $PD.Activate.versionId | Should -Not -BeNullOrEmpty
            $PD.Activate.activationId | Should -Not -BeNullOrEmpty
        }
    }
}
