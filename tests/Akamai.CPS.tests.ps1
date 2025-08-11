BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.CPS Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.CPS/Akamai.CPS.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestEnrollmentID = $env:PesterEnrollmentID
        $TestHostname = $env:PesterHostname
        $TestNewHostname = $env:PesterHostname2
        $TestCN = 'akamaipowershell-thirdparty.test.akamai.com'
        $TestNewEnrollmentBody = @"
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
        "cn": "$TestCN",
        "l": "Cambridge",
        "o": "Akamai",
        "ou": "WebEx",
        "sans": [
            "akamaipowershell-thirdparty.test.akamai.com"
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
        $PD = @{}
    }

    AfterAll {
        $Enrollments = Get-CPSEnrollment @CommonParams
        # Remove 3rd party enrollment if it exists
        $Enrollments | Where-Object { $_.csr.cn -eq $TestCN } | ForEach-Object { Remove-CPSEnrollment -EnrollmentID $_.id @CommonParams }
        # If existing enrollment contains $TestNewHostname, remove it and push change
        $EnrollmentToUpdate = $Enrollments | Where-Object { $TestNewHostname -in $_.csr.sans }
        if ($null -ne $EnrollmentToUpdate) {
            $EnrollmentToUpdate.csr.sans = @($Enrollment.csr.sans | Where-Object { $_ -ne $TestNewHostname })
            $EnrollmentToUpdate | Set-CPSEnrollment @CommonParams
        }
    }

    Context 'New-CPSEnrollment' {
        It 'creates an enrollment' {
            $PD.TPEnrollment = New-CPSEnrollment -ContractId $TestContract -Body $TestNewEnrollmentBody @CommonParams
            $PD.TPEnrollment.enrollment | Should -Not -BeNullOrEmpty
            $PD.TPEnrollment.enrollmentId | Should -Match '^[0-9]+$'
            $PD.TPEnrollment.changes | Should -Not -BeNullOrEmpty
            $PD.TPEnrollment.changeIds | Should -Not -BeNullOrEmpty
            $PD.TPEnrollment.changeIds[0] | Should -Match '^[0-9]+$'
        }
    }

    Context 'Get-CPSEnrollment - all' {
        It 'returns a list' {
            $PD.Enrollments = Get-CPSEnrollment -ContractID $TestContract @CommonParams
            $PD.Enrollments[0].id | Should -Match '^[0-9]+$'
            $PD.Enrollments[0].csr | Should -Not -BeNullOrEmpty

            $EnrollmentsPending = $PD.Enrollments | Where-Object { $_.pendingChanges.count -gt 0 }
            Write-Host "Found $($EnrollmentsPending.count) enrollments with pending changes"
            if ($EnrollmentsPending) {
                $EnrollmentsPending[0].pendingChanges[0].changeId | Should -Match '^[0-9]+$'
            }
        }
    }

    Context 'Get-CPSEnrollment - individual' {
        It 'returns an enrollment' {
            $PD.Enrollment = Get-CPSEnrollment -EnrollmentID $TestEnrollmentID @CommonParams
            $PD.Enrollment.id | Should -Be $TestEnrollmentID
            $PD.Enrollment.csr.cn | Should -Be "akamaipowershell-testing.edgesuite.net"
        }
    }

    Context 'Get-CPSEnrollment' {
        It 'lists active certificates' {
            $PD.ActiveCerts = Get-CPSActiveCertificate -ContractID $TestContract @CommonParams
            $PD.ActiveCerts.count | Should -BeGreaterThan 0
            $PD.ActiveCerts[0].id | Should -Not -BeNullOrEmpty
            $PD.ActiveCerts[0].productionSlots | Should -Not -BeNullOrEmpty
            $PD.ActiveCerts[0].stagingSlots | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CPSCertificateHistory' {
        It 'returns history' {
            $PD.CertHistory = Get-CPSCertificateHistory -EnrollmentID $TestEnrollmentID @CommonParams
            $PD.CertHistory[0].deploymentStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CPSChangeHistory' {
        It 'returns history' {
            $PD.ChangeHistory = Get-CPSChangeHistory -EnrollmentID $TestEnrollmentID @CommonParams
            $PD.ChangeHistory.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-CPSDeployment' {
        It 'returns deployments' {
            $PD.Deployments = Get-CPSDeployment -EnrollmentID $TestEnrollmentID @CommonParams
            $PD.Deployments.staging | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CPSProductionDeployment' {
        It 'returns deployments' {
            $PD.ProdDeployments = Get-CPSProductionDeployment -EnrollmentID $TestEnrollmentID @CommonParams
            $PD.ProdDeployments | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CPSStagingDeployment' {
        It 'returns deployments' {
            $PD.StagingDeployments = Get-CPSStagingDeployment -EnrollmentID $TestEnrollmentID @CommonParams
            $PD.StagingDeployments | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-CPSEnrollment' {
        It 'updates correctly' {
            $PD.Enrollment.changeManagement = $true
            $PD.Enrollment.csr.sans += $TestNewHostname
            $PD.UpdateEnrollment = $PD.Enrollment | Set-CPSEnrollment -EnrollmentID $PD.Enrollment.id -AllowCancelPendingChanges @CommonParams
            $PD.UpdateEnrollment.enrollment | Should -Match $PD.Enrollment.id
            $PD.UpdateEnrollment.enrollmentId | Should -Match '^[0-9]+$'
            $PD.UpdateEnrollment.changes | Should -Not -BeNullOrEmpty
            $PD.UpdateEnrollment.changeIds | Should -Not -BeNullOrEmpty
            $PD.UpdateEnrollment.changeIds[0] | Should -Match '^[0-9]+$'
        }

        It 'throws no errors when updating an enrollment with an existing change' {
            $PD.PendingEnrollment = Get-CPSEnrollment -EnrollmentID $TestEnrollmentID @CommonParams
            { $PD.PendingEnrollment | Set-CPSEnrollment -EnrollmentID $PD.Enrollment.id -AllowCancelPendingChanges @CommonParams } | Should -Not -Throw
        }
    }

    Context 'Get-CPSChangeStatus' {
        It 'returns the correct info' {
            $PD.ChangeStatus = Get-CPSChangeStatus -EnrollmentID $TestEnrollmentID -ChangeID $PD.UpdateEnrollment.changeIds[0] @CommonParams
            $PD.ChangeStatus.statusInfo.status | Should -Not -BeNullOrEmpty
            Write-Host -ForegroundColor Yellow 'Taking a break to wait for LE challenges...'
            Start-Sleep -Seconds 120
            Write-Host -ForegroundColor Yellow 'Right then! Off we go...'
        }
    }

    Context 'Get-CPSLetsEncryptChallenges' {
        It 'returns the correct info' {
            $PD.LEChallenges = Get-CPSLetsEncryptChallenges -EnrollmentID $TestEnrollmentID -ChangeID $PD.UpdateEnrollment.changeIds[0] @CommonParams
            $PD.LEChallenges.dv[0].status | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CPSDVHistory' {
        It 'returns history' {
            $PD.DVHistory = Get-CPSDVHistory -EnrollmentID $TestEnrollmentID @CommonParams
            $PD.DVHistory[0].domainHistory | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-CPSDeploymentSchedule' {
        It 'returns history' {
            $Now = Get-Date
            $AWeekFromNow = $Now.AddDays(7)
            $NotBefore = Get-Date $AWeekFromNow -Format 'yyyy-MM-ddT00:00:00Z'
            $PD.SetSchedule = Set-CPSDeploymentSchedule -EnrollmentID $TestEnrollmentID -ChangeID $PD.UpdateEnrollment.changeIds[0] -NotBefore $NotBefore @CommonParams
            $PD.SetSchedule.change | Should -Match $TestEnrollmentID
            $PD.SetSchedule.changeId | Should -Match '^[0-9]+$'
        }
    }

    Context 'Remove-CPSChange' {
        It 'returns the correct info' {
            $PD.ChangeRemoval = Remove-CPSChange -EnrollmentID $TestEnrollmentID -ChangeID $PD.UpdateEnrollment.changeIds[0] @CommonParams
            $PD.ChangeRemoval | Should -Match $TestEnrollmentID
            $PD.ChangeRemoval.changeId | Should -Match '^[0-9]+$'
        }
    }

    Context 'Get-CPSCSR' {
        It 'returns the correct data' {
            $PD.CSR = Get-CPSCSR -EnrollmentID $PD.TPEnrollment.enrollmentID -ChangeID $PD.TPEnrollment.changeIds[0] @CommonParams
            $PD.CSR.csrs[0].csr | Should -Match "BEGIN CERTIFICATE REQUEST"
        }
    }

    Context 'Remove-CPSEnrollment' {
        It 'deletes the enrollment' {
            $PD.RemoveEnrollment = Remove-CPSEnrollment -EnrollmentID $PD.TPEnrollment.enrollmentID -AllowCancelPendingChanges @CommonParams
            $PD.RemoveEnrollment.enrollmentId | Should -Be $PD.TPEnrollment.enrollmentID
        }
    }
}

Describe 'Unsafe Akamai.CPS Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.CPS/Akamai.CPS.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.CPS"
        $PD = @{}
    }
    Context 'Get-CPSPreVerificationWarnings' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CPSPreVerificationWarnings.json"
                return $Response | ConvertFrom-Json
            }
            $PreWarnings = Get-CPSPreVerificationWarnings -EnrollmentID 123456 -ChangeID 123456
            $PreWarnings.warnings | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CPSPostVerificationWarnings' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CPSPostVerificationWarnings.json"
                return $Response | ConvertFrom-Json
            }
            $PostWarnings = Get-CPSPostVerificationWarnings -EnrollmentID 123456 -ChangeID 123456
            $PostWarnings.warnings | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Confirm-CPSPreVerificationWarnings' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CPS -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Confirm-CPSPreVerificationWarnings.json"
                return $Response | ConvertFrom-Json
            }
            $AckPreWarnings = Confirm-CPSPreVerificationWarnings -EnrollmentID 123456 -ChangeID 123456 -Acknowledgement acknowledge
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
            $AckPostWarnings = Confirm-CPSPostVerificationWarnings -EnrollmentID 123456 -ChangeID 123456 -Acknowledgement acknowledge
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
            $UploadCert = Add-CPSThirdPartyCert -EnrollmentID 123456 -ChangeID 123456 -Certificate "--- BEGIN CERTIFICATE ------ END CERTIFICATE ---" -KeyAlgorithm RSA
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
            $CompleteChange = Complete-CPSChange -EnrollmentID 123456 -ChangeID 123456 -Acknowledgement acknowledge
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
            $LEComplete = Confirm-CPSLetsEncryptChallengesCompleted -EnrollmentID 123456 -ChangeID $ChangeID -Acknowledgement acknowledge
            $LEComplete.change | Should -Not -BeNullOrEmpty
            $LEComplete.changeId | Should -Match '^[0-9]+$'
        }
    }
}

