BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.CPS Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.CPS'
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
        $TestEnrollmentID = $env:PesterEnrollmentID
        $TestDVCN = "pester-$Timestamp-dv.test.akamai.com"
        $TestNewHostname = $TestDVCN.Replace('-dv.', '-dv2.')
        $TestTPCN = "pester-$Timestamp-thirdparty.test.akamai.com"

        $TestDVEnrollmentBody = @"
{
    "adminContact": {
        "email": "r2d2@akamai.com",
        "firstName": "R2",
        "lastName": "D2",
        "phone": "617-555-0111"
    },
    "certificateType": "san",
    "certificateChainType": "default",
    "changeManagement": true,
    "csr": {
        "c": "US",
        "cn": "$TestDVCN",
        "l": "Cambridge",
        "o": "Akamai",
        "ou": "WebEx",
        "sans": [
            "$TestDVCN"
        ],
        "st": "MA"
    },
    "enableMultiStackedCertificates": false,
    "networkConfiguration": {
        "quicEnabled": true,
        "secureNetwork": "standard-tls",
        "sniOnly": true,
        "geography": "core",
        "dnsNameSettings": {
            "cloneDnsNames": true
        }
    },
    "org": {
        "addressLineOne": "150 Broadway",
        "addressLineTwo": null,
        "city": "Cambridge",
        "country": "US",
        "name": "Akamai Technologies",
        "phone": "617-555-0111",
        "postalCode": "02142",
        "region": "MA"
    },
    "ra": "lets-encrypt",
    "signatureAlgorithm": "SHA-256",
    "techContact": {
        "email": "bd1@akamai.com",
        "firstName": "BD",
        "lastName": "1",
        "phone": "617-555-0111"
    },
    "thirdParty": null,
    "validationType": "dv"
}
"@

        $TestTPEnrollmentBody = @"
{
    "adminContact": {
        "email": "r2d2@akamai.com",
        "firstName": "R2",
        "lastName": "D2",
        "phone": "617-555-0111"
    },
    "certificateType": "third-party",
    "changeManagement": true,
    "csr": {
        "c": "US",
        "cn": "$TestTPCN",
        "l": "Cambridge",
        "o": "Akamai",
        "ou": "WebEx",
        "sans": [
            "$TestTPCN"
        ],
        "st": "MA"
    },
    "enableMultiStackedCertificates": false,
    "networkConfiguration": {
        "quicEnabled": true,
        "secureNetwork": "standard-tls",
        "sniOnly": true,
        "geography": "core",
        "dnsNameSettings": {
            "cloneDnsNames": true
        }
    },
    "org": {
        "addressLineOne": "150 Broadway",
        "addressLineTwo": null,
        "city": "Cambridge",
        "country": "US",
        "name": "Akamai Technologies",
        "phone": "617-555-0111",
        "postalCode": "02142",
        "region": "MA"
    },
    "ra": "third-party",
    "signatureAlgorithm": "SHA-256",
    "techContact": {
        "email": "bd1@akamai.com",
        "firstName": "BD",
        "lastName": "1",
        "phone": "617-555-0111"
    },
    "thirdParty": {
        "excludeSans": false
    },
    "validationType": "third-party"
}
"@
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.CPS"
        $PD = @{}
    }

    AfterAll {
        $Enrollments = Get-CPSEnrollment @CommonParams
        $Enrollments | Where-Object { $_.csr.cn -in $TestDVCN, $TestTPCN } | Remove-CPSEnrollment -AllowCancelPendingChanges @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'New-CPSEnrollment' {
        It 'creates a DV enrollment' {
            $TestParams = @{
                'ContractId' = $TestContractID
                'Body'       = $TestDVEnrollmentBody
            }
            $PD.NewDVEnrollment = New-CPSEnrollment @TestParams @CommonParams
            $PD.NewDVEnrollment.enrollment | Should -Not -BeNullOrEmpty
            $PD.NewDVEnrollment.enrollmentId | Should -Match '^[0-9]+$'
            $PD.NewDVEnrollment.changes | Should -Not -BeNullOrEmpty
            $PD.NewDVEnrollment.changeIds | Should -Not -BeNullOrEmpty
            $PD.NewDVEnrollment.changeIds[0] | Should -Match '^[0-9]+$'
        }

        It 'creates a third party enrollment' {
            $TestParams = @{
                'ContractId' = $TestContractID
                'Body'       = $TestTPEnrollmentBody
            }
            $PD.NewTPEnrollment = New-CPSEnrollment @TestParams @CommonParams
            $PD.NewTPEnrollment.enrollment | Should -Not -BeNullOrEmpty
            $PD.NewTPEnrollment.enrollmentId | Should -Match '^[0-9]+$'
            $PD.NewTPEnrollment.changes | Should -Not -BeNullOrEmpty
            $PD.NewTPEnrollment.changeIds | Should -Not -BeNullOrEmpty
            $PD.NewTPEnrollment.changeIds[0] | Should -Match '^[0-9]+$'
        }
    }

    Context 'Get-CPSEnrollment' {
        It 'returns a list' {
            $TestParams = @{
                'ContractID' = $TestContractID
            }
            $PD.Enrollments = Get-CPSEnrollment @TestParams @CommonParams
            $PD.Enrollments[0].id | Should -Match '^[0-9]+$'
            $PD.Enrollments[0].csr | Should -Not -BeNullOrEmpty

            $EnrollmentsPending = $PD.Enrollments | Where-Object { $_.pendingChanges.count -gt 0 }
            if ($EnrollmentsPending) {
                $EnrollmentsPending[0].pendingChanges[0].changeId | Should -Match '^[0-9]+$'
            }
        }
        It 'returns an enrollment' {
            $PD.Enrollment = $PD.NewDVEnrollment.EnrollmentId | Get-CPSEnrollment @CommonParams
            $PD.Enrollment.id | Should -Be $PD.NewDVEnrollment.EnrollmentId
            $PD.Enrollment.csr.cn | Should -Be $TestDVCN
        }
    }

    Context 'Get-CPSActiveCertificate' {
        It 'lists active certificates' {
            $TestParams = @{
                'ContractID' = $TestContractID
            }
            $PD.ActiveCerts = Get-CPSActiveCertificate @TestParams @CommonParams
            $PD.ActiveCerts.count | Should -BeGreaterThan 0
            $PD.ActiveCerts[0].id | Should -Not -BeNullOrEmpty
            $PD.ActiveCerts[0].productionSlots | Should -Not -BeNullOrEmpty
            $PD.ActiveCerts[0].stagingSlots | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CPSCertificateHistory' {
        It 'returns history' {
            $PD.CertHistory = $TestEnrollmentID | Get-CPSCertificateHistory @CommonParams
            $PD.CertHistory[0].deploymentStatus | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSCertificateHistory @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CPSChangeHistory' {
        It 'returns history' {
            $PD.ChangeHistory = $TestEnrollmentID | Get-CPSChangeHistory @CommonParams
            $PD.ChangeHistory.count | Should -BeGreaterThan 0
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSChangeHistory @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CPSDeployment' {
        It 'returns deployments' {
            $PD.Deployments = $TestEnrollmentID | Get-CPSDeployment @CommonParams
            $PD.Deployments.staging | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSDeployment @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CPSProductionDeployment' {
        It 'returns deployments' {
            $PD.ProdDeployments = $TestEnrollmentID | Get-CPSProductionDeployment @CommonParams
            $PD.ProdDeployments | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSProductionDeployment @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CPSStagingDeployment' {
        It 'returns deployments' {
            $PD.StagingDeployments = $TestEnrollmentID | Get-CPSStagingDeployment @CommonParams
            $PD.StagingDeployments | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSStagingDeployment @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-CPSEnrollment' {
        It 'updates correctly' {
            $PD.Enrollment.changeManagement = $true
            $PD.Enrollment.csr.sans += $TestNewHostname
            $PD.UpdateEnrollment = $PD.Enrollment | Set-CPSEnrollment -AllowCancelPendingChanges @CommonParams
            $PD.UpdateEnrollment.enrollmentId | Should -Match '^[0-9]+$'
            $PD.UpdateEnrollment.changes | Should -Not -BeNullOrEmpty
            $PD.UpdateEnrollment.changeIds[0] | Should -Match '^[0-9]+$'
        }

        It 'throws no errors when updating an enrollment with an existing change' {
            $TestParams = @{
                'EnrollmentID' = $PD.Enrollment.id
            }
            $PD.PendingEnrollment = Get-CPSEnrollment @TestParams @CommonParams
            { $PD.PendingEnrollment | Set-CPSEnrollment -AllowCancelPendingChanges @CommonParams } | Should -Not -Throw
        }
    }

    Context 'Get-CPSChangeStatus' {
        It 'returns the correct info' {
            $TestParams = @{
                'EnrollmentID' = $PD.Enrollment.id
                'ChangeID'     = $PD.UpdateEnrollment.changeIds[0]
            }
            $PD.ChangeStatus = Get-CPSChangeStatus @TestParams @CommonParams
            $PD.ChangeStatus.statusInfo.status | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSChangeStatus -EnrollmentID 123456 @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Break time!' {
        It 'waits 5m for LE challenges to be ready' {
            Start-Sleep -Seconds 300
        }
    }

    Context 'Get-CPSChangeStagingStatus' {
        It 'fails when there are no changes' {
            { Get-CPSChangeStagingStatus -EnrollmentID $PD.Enrollment.id -ChangeID $PD.UpdateEnrollment.changeIds[0] @CommonParams } | Should -Throw
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSChangeStagingStatus -EnrollmentID 123456 @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CPSLetsEncryptChallenges' {
        It 'returns the correct info' {
            $TestParams = @{
                'EnrollmentID' = $PD.Enrollment.id
                'ChangeID'     = $PD.UpdateEnrollment.changeIds[0]
            }
            $PD.LEChallenges = Get-CPSLetsEncryptChallenges @TestParams @CommonParams
            $PD.LEChallenges.dv[0].status | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSLetsEncryptChallenges -EnrollmentID 123456 @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CPSDVHistory' {
        It 'returns history' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CPSDVHistory.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'EnrollmentID' = 123456
            }
            $DVHistory = Get-CPSDVHistory @TestParams @CommonParams
            $DVHistory[0].domainHistory | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSDVHistory @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-CPSDeploymentSchedule' {
        It 'returns history' {
            $Now = Get-Date
            $AWeekFromNow = $Now.AddDays(7)
            $NotBefore = Get-Date $AWeekFromNow -Format 'yyyy-MM-ddT00:00:00Z'
            $TestParams = @{
                'EnrollmentID' = $PD.Enrollment.id
                'ChangeID'     = $PD.UpdateEnrollment.changeIds[0]
                'NotBefore'    = $NotBefore
            }
            $PD.SetSchedule = Set-CPSDeploymentSchedule @TestParams @CommonParams
            $PD.SetSchedule.change | Should -BeLike "/cps/v2/enrollments/$($PD.Enrollment.id)/changes/*"
            $PD.SetSchedule.changeId | Should -Match '^[0-9]+$'
        }
    }

    Context 'Get-CPSDeploymentSchedule' {
        It 'returns the correct info' {
            $TestParams = @{
                'EnrollmentID' = $PD.Enrollment.id
                'ChangeID'     = $PD.UpdateEnrollment.changeIds[0]
            }
            $PD.DeploymentSchedule = Get-CPSDeploymentSchedule @TestParams @CommonParams
            $PD.DeploymentSchedule | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSDeploymentSchedule -EnrollmentID 123456 @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-CPSChange' {
        It 'returns the correct info' {
            $TestParams = @{
                'EnrollmentID' = $PD.Enrollment.id
                'ChangeID'     = $PD.UpdateEnrollment.changeIds[0]
            }
            $PD.ChangeRemoval = Remove-CPSChange @TestParams @CommonParams
            $PD.ChangeRemoval.change | Should -BeLike "/cps/v2/enrollments/$($PD.Enrollment.id)/changes/*"
            $PD.ChangeRemoval.changeId | Should -Match '^[0-9]+$'
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-CPSChange -EnrollmentID 123456 @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CPSCSR' {
        It 'returns the correct data' {
            $TestParams = @{
                'EnrollmentID' = $PD.NewTPEnrollment.enrollmentID
                'ChangeID'     = $PD.NewTPEnrollment.changeIds[0]
            }
            $PD.CSR = Get-CPSCSR @TestParams @CommonParams
            $PD.CSR.csrs[0].csr | Should -Match "BEGIN CERTIFICATE REQUEST"
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSCSR -EnrollmentID 123456 @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-CPSEnrollment' {
        It 'deletes the third-party enrollment' {
            $PD.RemoveTPEnrollment = $PD.NewTPEnrollment | Remove-CPSEnrollment -AllowCancelPendingChanges @CommonParams
            $PD.RemoveTPEnrollment.enrollmentId | Should -Be $PD.NewTPEnrollment.enrollmentID
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-CPSEnrollment @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }


    # ---- Mocked tests
    Context 'Get-CPSPreVerificationWarnings' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CPSPreVerificationWarnings.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ChangeID'     = 123456
                'EnrollmentID' = 123456
            }
            $PreWarnings = Get-CPSPreVerificationWarnings @TestParams
            $PreWarnings.warnings | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSPreVerificationWarnings -EnrollmentID 123456 @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CPSPostVerificationWarnings' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CPSPostVerificationWarnings.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ChangeID'     = 123456
                'EnrollmentID' = 123456
            }
            $PostWarnings = Get-CPSPostVerificationWarnings @TestParams
            $PostWarnings.warnings | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-CPSPostVerificationWarnings -EnrollmentID 123456 @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Confirm-CPSPreVerificationWarnings' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Confirm-CPSPreVerificationWarnings.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Acknowledgement' = 'acknowledge'
                'ChangeID'        = 123456
                'EnrollmentID'    = 123456
            }
            $AckPreWarnings = Confirm-CPSPreVerificationWarnings @TestParams
            $AckPreWarnings.change | Should -Not -BeNullOrEmpty
            $AckPreWarnings.changeId | Should -Match '^[0-9]+$'
        }
    }

    Context 'Confirm-CPSPostVerificationWarnings' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Confirm-CPSPostVerificationWarnings.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Acknowledgement' = 'acknowledge'
                'ChangeID'        = 123456
                'EnrollmentID'    = 123456
            }
            $AckPostWarnings = Confirm-CPSPostVerificationWarnings @TestParams
            $AckPostWarnings.change | Should -Not -BeNullOrEmpty
            $AckPostWarnings.changeId | Should -Match '^[0-9]+$'
        }
    }

    Context 'Add-CPSThirdPartyCert' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Add-CPSThirdPartyCert.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Certificate'  = "--- BEGIN CERTIFICATE ------ END CERTIFICATE ---"
                'ChangeID'     = 123456
                'EnrollmentID' = 123456
                'KeyAlgorithm' = 'RSA'
            }
            $UploadCert = Add-CPSThirdPartyCert @TestParams
            $UploadCert.change | Should -Not -BeNullOrEmpty
            $UploadCert.changeId | Should -Match '^[0-9]+$'
        }
    }

    Context 'Complete-CPSChange' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Complete-CPSChange.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Acknowledgement' = 'acknowledge'
                'ChangeID'        = 123456
                'EnrollmentID'    = 123456
            }
            $CompleteChange = Complete-CPSChange @TestParams
            $CompleteChange.change | Should -Not -BeNullOrEmpty
            $CompleteChange.changeId | Should -Match '^[0-9]+$'
        }
    }

    Context 'Confirm-CPSLetsEncryptChallengesCompleted' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Confirm-CPSLetsEncryptChallengesCompleted.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Acknowledgement' = 'acknowledge'
                'ChangeID'        = $ChangeID
                'EnrollmentID'    = 123456
            }
            $LEComplete = Confirm-CPSLetsEncryptChallengesCompleted @TestParams
            $LEComplete.change | Should -Not -BeNullOrEmpty
            $LEComplete.changeId | Should -Match '^[0-9]+$'
        }
    }

}
