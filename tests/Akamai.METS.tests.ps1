BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.METS Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.METS'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
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
        
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContractID = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestCASetName = 'pester'


        # Set up test data
        $TestDirName = 'TestDrive:/metsdata'
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
        $TestNewVersionDescription = "Pester testing on $(Get-Date)"
        $TestNewVersionBody = @{
            allowInsecureSha1 = $false
            description       = $TestNewVersionDescription
            certificates      = @(
                @{
                    'certificatePem' = $TestPEM5
                },
                @{
                    'certificatePem' = $TestPEM6
                }
            )
        }

        $TestCASet = @"
{
    "caSetName": "akamaipowershell",
    "description": "Testing"
}
"@

        # Clear cache
        Clear-AkamaiDataCache

        # Persistent Data
        $PD = @{}

        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.METS"
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                   CA Set
    #------------------------------------------------

    Context 'Get-METSCASet' -Tag 'Get-METSCASet' {
        It 'returns a list' {
            $PD.CASets = Get-METSCASet @CommonParams
            $PD.CASets[0].caSetId | Should -Not -BeNullOrEmpty
            $PD.CASets[0].caSetName | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct set by name' {
            $TestParams = @{
                'CASetName' = $TestCASetName
            }
            $PD.CASetByName = Get-METSCASet @TestParams @CommonParams | Where-Object caSetStatus -ne 'DELETED'
            $PD.CASetByName.caSetName | Should -Be $TestCASetName
        }
        It 'returns the correct set by ID' {
            $TestParams = @{
                'CASetID' = $PD.CASetByName.caSetId
            }
            $PD.CASet = Get-METSCASet @TestParams @CommonParams
            $PD.CASet.caSetId | Should -Be $PD.CASetByName.caSetId
            $PD.CASet.caSetName | Should -Be $TestCASetName
        }
    }

    Context 'Get-METSCASetActivities' {
        It 'returns the correct data' {
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
            }
            $PD.Activities = Get-METSCASetActivities @TestParams @CommonParams
            $PD.Activities[0].activityBy | Should -Not -BeNullOrEmpty
            $PD.Activities[0].activityDate | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-METSCASetAssociation' {
        It 'checks for correct properties' {
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
            }
            $PD.Associations = Get-METSCASetAssociation @TestParams @CommonParams
            $PD.Associations.PSObject.Properties.Name | Should -Contain 'enrollments'
            $PD.Associations.PSObject.Properties.Name | Should -Contain 'properties'
        }
    }

    #------------------------------------------------
    #                 Private Functions
    #------------------------------------------------
    
    Context 'Expand-METSCASetDetails' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.METS/Functions/Private/Expand-METSCASetDetails.ps1

            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = "TestDrive:/options.json"
            # Create options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache
        }
        It 'finds the right CA set' {
            $TestParams = @{
                'CASetName' = $TestCASetName
            }
            $PD.ExpandedCASetID = Expand-METSCASetDetails @TestParams @CommonParams
            $PD.ExpandedCASetID | Should -Be $PD.CASet.caSetId
            $AkamaiDataCache.METS.CASets.$TestCASetName.CASetID | Should -Be $PD.ExpandedCASetID
        }
        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache

            Remove-Item -Path Function:/Expand-METSCASetDetails -Force
        }
    }

    #------------------------------------------------
    #                 Versions                  
    #------------------------------------------------

    Context 'Get-METSCASetVersion' {
        It 'gets a list of versions' {
            $TestParams = @{
                'CASetID'             = $PD.CASet.caSetId
                'IncludeCertificates' = $true
            }
            $PD.Versions = Get-METSCASetVersion @TestParams @CommonParams
            $PD.Versions.count | Should -BeGreaterThan 0
            $PD.Versions[0].certificates.count | Should -BeGreaterThan 0
            $PD.Versions[0].Version | Should -Not -BeNullOrEmpty
        }
        It 'gets a single version by ID' {
            $LatestVersion = $PD.Versions | Sort-Object -Property version -Descending | Select-Object -First 1
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
                'Version' = $LatestVersion.Version
            }
            $PD.Version = Get-METSCASetVersion @TestParams @CommonParams
            $PD.Version.Version | Should -Be $LatestVersion.Version
        }
    }

    Context 'New-METSCASetVersion' {
        It 'creates a new version by pipeline' {
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
            }
            $PD.NewVersionBody = $TestNewVersionBody | New-METSCASetVersion @TestParams @CommonParams
            $PD.NewVersionBody.version | Should -BeGreaterThan $PD.Version.Version
        }
        It 'creates a new version by file' {
            $TestParams = @{
                'CASetID'          = $PD.CASet.caSetId
                'CertificatesFile' = $TestCertsFile
                'Comments'         = 'Pester updates by file'
            }
            $PD.NewVersionFile = New-METSCASetVersion @TestParams @CommonParams
            $PD.NewVersionFile.version | Should -Be ($PD.NewVersionBody.version + 1)
        }
        It 'creates a new version by directory' {
            $TestParams = @{
                'CASetID'               = $PD.CASet.caSetId
                'CertificatesDirectory' = $TestCertsDir
                'Comments'              = 'Pester updates by directory'
            }
            $PD.NewVersionDirectory = New-METSCASetVersion @TestParams @CommonParams
            $PD.NewVersionDirectory.version | Should -Be ($PD.NewVersionFile.version + 1)
        }
    }

    Context 'Set-METSCASetVersion' {
        It 'updates by body' {
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
            }
            $PD.SetVersionBody = $PD.NewVersionBody | Set-METSCASetVersion @TestParams @CommonParams
            $PD.SetVersionBody.version | Should -BeGreaterThan $LatestVersion.version
        }
        It 'updates by file' {
            $TestParams = @{
                'CASetID'          = $PD.CASet.caSetId
                'Version'          = $PD.NewVersionFile.Version
                'CertificatesFile' = $TestCertsFile
                'Comments'         = 'Pester updates by file'
            }
            $PD.SetVersionFile = Set-METSCASetVersion @TestParams @CommonParams
            $PD.SetVersionFile.version | Should -Be $PD.NewVersionFile.version
        }
        It 'updates by directory' {
            $TestParams = @{
                'CASetID'               = $PD.CASet.caSetId
                'Version'               = $PD.NewVersionDirectory.Version
                'CertificatesDirectory' = $TestCertsDir
                'Comments'              = 'Pester updates by directory'
            }
            $PD.SetVersionDirectory = Set-METSCASetVersion @TestParams @CommonParams
            $PD.SetVersionDirectory.version | Should -Be $PD.NewVersionDirectory.version
        }
    }

    Context 'Copy-METSCASetVersion' {
        It 'creates a new version' {
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
                'Version' = $PD.NewVersionDirectory.Version
            }
            $PD.CopyVersion = Copy-METSCASetVersion @TestParams @CommonParams
            ($PD.CopyVersion.Certificates.certificateId | Sort-Object) | Should -Be ($PD.NewVersionDirectory.Certificates.certificateId | Sort-Object)
        }
    }

    Context 'Test-METSCASetVersion' {
        It 'test by body' {
            $TestParams = @{
                'Body' = @{
                    'allowInsecureSha1' = $false
                    'certificates'      = @(
                        @{
                            'certificatePem' = $TestPEM1
                        },
                        @{
                            'certificatePem' = $TestPEM2
                        }
                    )
                }
            }
            $PD.CertBody = Test-METSCASetVersion @TestParams @CommonParams
            $PD.CertBody | Should -Not -BeNullOrEmpty
            $PD.CertBody.certificates.count | Should -BeGreaterThan 0
            $PD.CertBody.validation | Should -Not -BeNullOrEmpty
        }
        It 'test by file' {
            $TestParams = @{
                'CertificatesFile' = $TestCertsFile
            }
            $PD.CertFile = Test-METSCASetVersion @TestParams @CommonParams
            $PD.CertFile | Should -Not -BeNullOrEmpty
            $PD.CertFile.certificates.count | Should -BeGreaterThan 0
            $PD.CertFile.validation | Should -Not -BeNullOrEmpty
        }
        It 'test by directory' {
            $TestParams = @{
                'CertificatesDirectory' = $TestCertsDir
            }
            $PD.CertDirectory = Test-METSCASetVersion @TestParams @CommonParams
            $PD.CertDirectory | Should -Not -BeNullOrEmpty
            $PD.CertDirectory.certificates.count | Should -BeGreaterThan 0
            $PD.CertDirectory.validation | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-METSCASetVersion' {
        It 'removes a version by parameters' {
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
                'Version' = $PD.SetVersionBody.version
            }
            Remove-METSCASetVersion @TestParams @CommonParams
        }
        It 'removes a version by pipeline' {
            $PD.SetVersionFile, $PD.SetVersionDirectory, $PD.CopyVersion | Remove-METSCASetVersion @CommonParams
        }
    }

    #------------------------------------------------
    #                 Activations                  
    #------------------------------------------------


    Context 'Get-METSCASetActivation' {
        It 'gets a list of activations' {
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
                'Version' = 1
            }
            $PD.Activations = Get-METSCASetActivation @TestParams @CommonParams
            $PD.Activations[0].activationId | Should -Not -BeNullOrEmpty
            $PD.Activations[0].caSetId | Should -Be $PD.CASet.caSetId
            $PD.Activations[0].version | Should -Be 1
        }
        It 'gets a single activation by ID' {
            $TestParams = @{
                'CASetID'      = $PD.CASet.caSetId
                'Version'      = 1
                'ActivationId' = $PD.Activations[0].activationId
            }
            $PD.Activation = Get-METSCASetActivation @TestParams @CommonParams
            $PD.Activation.ActivationID | Should -Be $PD.Activations[0].activationId
            $PD.Activation.caSetId | Should -Be $PD.CASet.caSetId
            $PD.Activation.version | Should -Be 1
        }
    }

    #------------------------------------------------
    #                 CASet Version Certificate                  
    #------------------------------------------------

    Context 'Get-METSCASetVersionCertificate' {
        It 'returns the correct data' {
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
                'Version' = $PD.NewVersionDirectory.Version
            }
            $PD.VersionCerts = Get-METSCASetVersionCertificate @TestParams @CommonParams
            ($PD.VersionCerts.certificateId | Sort-Object) | Should -Be ($PD.NewVersionDirectory.Certificates.certificateId | Sort-Object)
        }
    }

    #-------------------------------------------------
    #                   CA Set
    #-------------------------------------------------
    
    Context 'New-METSCASet' {
        It 'creates by parameters' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-METSCASet.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CASetName'   = 'akamaipowershell'
                'Description' = 'Testing'
            }
            $NewSet = New-METSCASet @TestParams
            $NewSet.caSetId | Should -Not -BeNullOrEmpty
            $NewSet.caSetName | Should -Not -BeNullOrEmpty
        }
        It 'creates by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-METSCASet.json"
                return $Response | ConvertFrom-Json
            }
            $NewSet = $TestCASet | New-METSCASet
            $NewSet.caSetId | Should -Not -BeNullOrEmpty
            $NewSet.caSetName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Copy-METSCASet' -Tag 'Copy-METSCASet' {
        It 'clones a CA set' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Copy-METSCASet.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CASetID'      = 123456
                'NewCASetName' = 'akamaipowershell-clone'
                'Description'  = 'Clone test'
            }
            $PD.CopyCASet = Copy-METSCASet @TestParams @CommonParams
            $PD.CopyCASet.caSetName | Should -Not -BeNullOrEmpty
            $PD.CopyCASet.caSetId | Should -Not -BeNullOrEmpty
            $PD.CopyCASet.caSetLink | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-METSCASet' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-METSCASet.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'throws no errors by parameters' {
            $TestParams = @{
                'CASetID' = 123456
            }
            Remove-METSCASet @TestParams
        }
        It 'throws no errors by pipeline' {
            $PD.CASet | Remove-METSCASet
        }
    }

    Context 'Get-METSRemoval' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-METSRemoval.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CASetID' = $PD.CASet.caSetId
            }
            $PD.Removals = Get-METSRemoval @TestParams
            $PD.Removals.deletions.count | Should -BeGreaterThan 1
            $PD.Removals.caSetId | Should -Not -BeNullOrEmpty
            $PD.Removals.caSetName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Deactivation                  
    #------------------------------------------------

    Context 'New-METSCASetDeactivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-METSCASetDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CASetID' = 123456
                'Network' = 'STAGING'
                'Version' = 1
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
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.METS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-METSCASetActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CASetID' = 123456
                'Network' = 'STAGING'
                'Version' = 1
            }
            $PD.Activate = New-METSCASetActivation @TestParams
            $PD.Activate.Version | Should -Not -BeNullOrEmpty
            $PD.Activate.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #            Empty Input Tests
    #------------------------------------------------

    Context 'Empty Input' -Tag 'Empty Input' {
        $EmptyInputFunctions = @(
            'Get-METSCASetActivities'
            'Get-METSCASetAssociation'
            'Get-METSCASetVersion'
            'Get-METSCASetVersionCertificate'
            'Remove-METSCASet'
            'Get-METSRemoval'

        )
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.METS -MockWith {
                return "IAR executed"
            }
        }
        It '<_> handles empty input correctly' -ForEach $EmptyInputFunctions {
            & {} | & $_ | Should -Not -Be "IAR executed"
        }
    }
}
