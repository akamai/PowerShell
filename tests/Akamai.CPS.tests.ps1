Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.CPS/Akamai.CPS.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestEnrollmentID = $env:PesterEnrollmentID
$Script:NewHostname = $env:PesterHostname2
$Script:NewEnrollmentBody = '{
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
        "cn": "akamaipowershell-thirdparty.test.akamai.com",
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
}'

Describe 'Safe CPS Tests' {

    BeforeDiscovery {
        
    }

    ### New-CPSEnrollment
    $Script:3PEnrollment = New-CPSEnrollment -ContractId $TestContract -Body $NewEnrollmentBody -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CPSEnrollment creates an enrollment' {
        $3PEnrollment.enrollment | Should -Not -BeNullOrEmpty
    }
    $Script:3PEnrollmentID = $3PEnrollment.enrollment.replace("/cps/v2/enrollments/", "")
    $Script:3PChangeID = $3PEnrollment.changes.substring($3PEnrollment.changes.LastIndexOf('/') + 1)

    ### Get-CPSEnrollment - all
    $Script:Enrollments = Get-CPSEnrollment -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSEnrollment returns a list' {
        $Enrollments.count | Should -Not -BeNullOrEmpty
    }

    ### Get-CPSEnrollment - individual
    $Script:Enrollment = Get-CPSEnrollment -EnrollmentID $TestEnrollmentID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSEnrollment with ID returns an enrollment' {
        $Enrollment.id | Should -Be $TestEnrollmentID
    }

    ### Get-CPSCertificateHistory
    $Script:CertHistory = Get-CPSCertificateHistory -EnrollmentID $TestEnrollmentID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSCertificateHistory returns history' {
        $CertHistory[0].deploymentStatus | Should -Not -BeNullOrEmpty
    }

    ### Get-CPSChangeHistory
    $Script:ChangeHistory = Get-CPSChangeHistory -EnrollmentID $TestEnrollmentID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSChangeHistory returns history' {
        $ChangeHistory.count | Should -BeGreaterThan 0
    }

    ### Get-CPSDeployment
    $Script:Deployments = Get-CPSDeployment -EnrollmentID $TestEnrollmentID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSDeployment returns deployments' {
        $Deployments.staging | Should -Not -BeNullOrEmpty
    }

    ### Get-CPSProductionDeployment
    $Script:ProdDeployments = Get-CPSProductionDeployment -EnrollmentID $TestEnrollmentID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSProductionDeployment returns deployments' {
        $ProdDeployments | Should -Not -BeNullOrEmpty
    }

    ### Get-CPSStagingDeployment
    $Script:StagingDeployments = Get-CPSStagingDeployment -EnrollmentID $TestEnrollmentID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSStagingDeployment returns deployments' {
        $StagingDeployments | Should -Not -BeNullOrEmpty
    }

    ### Set-CPSEnrollment
    $Enrollment.csr.sans += $NewHostname
    $Enrollment.changeManagement = $true
    $Script:UpdateEnrollment = $Enrollment | Set-CPSEnrollment -EnrollmentID $Enrollment.id -AllowCancelPendingChanges -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CPSEnrollment updates correctly' {
        $UpdateEnrollment.enrollment | Should -Match $Enrollment.id
    }
    $ChangeID = $UpdateEnrollment.changes[0].SubString($UpdateEnrollment.changes[0].LastIndexOf('/') + 1)

    ### Get-CPSChangeStatus
    $Script:ChangeStatus = Get-CPSChangeStatus -EnrollmentID $TestEnrollmentID -ChangeID $ChangeID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSChangeStatus returns the correct info' {
        $ChangeStatus.statusInfo.status | Should -Not -BeNullOrEmpty
    }

    Write-Host -ForegroundColor Yellow 'Taking a break to wait for LE challenges...'
    Start-Sleep -Seconds 120
    Write-Host -ForegroundColor Yellow 'Right then! Off we go...'

    ### Get-CPSLetsEncryptChallenges
    $Script:LEChallenges = Get-CPSLetsEncryptChallenges -EnrollmentID $TestEnrollmentID -ChangeID $ChangeID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSLetsEncryptChallenges returns the correct info' {
        $LEChallenges.dv[0].status | Should -Not -BeNullOrEmpty
    }

    ### Get-CPSDVHistory
    $Script:DVHistory = Get-CPSDVHistory -EnrollmentID $TestEnrollmentID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSDVHistory returns history' {
        $DVHistory[0].domainHistory | Should -Not -BeNullOrEmpty
    }

    ### Set-CPSDeploymentSchedule
    $Now = Get-Date
    $AWeekFromNow = $Now.AddDays(7)
    $NotBefore = Get-Date $AWeekFromNow -Format 'yyyy-MM-ddT00:00:00Z'
    $Script:SetSchedule = Set-CPSDeploymentSchedule -EnrollmentID $TestEnrollmentID -ChangeID $ChangeID -NotBefore $NotBefore -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CPSDeploymentSchedule returns history' {
        $SetSchedule.change | Should -Match $TestEnrollmentID
    }

    ### Remove-CPSChange
    $Script:ChangeRemoval = Remove-CPSChange -EnrollmentID $TestEnrollmentID -ChangeID $ChangeID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-CPSChange returns the correct info' {
        $ChangeRemoval | Should -Match $TestEnrollmentID
    }

    ### Get-CPSCSR
    $Script:CSR = Get-CPSCSR -EnrollmentID $3PEnrollmentID -ChangeID $3PChangeID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CPSCSR returns the correct data' {
        $CSR.csrs[0].csr | Should -Match "BEGIN CERTIFICATE REQUEST"
    }

    ### Remove-CPSEnrollment
    $Script:RemoveEnrollment = Remove-CPSEnrollment -EnrollmentID $3PEnrollmentID -AllowCancelPendingChanges -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-CPSEnrollment creates an enrollment' {
        $RemoveEnrollment.enrollment | Should -Be "/cps/v2/enrollments/$3PEnrollmentID"
    }

    AfterAll {
        
    }
    
}

Describe 'Unsafe CPS Tests' {
    ### Get-CPSPreVerificationWarnings
    $Script:PreWarnings = Get-CPSPreVerificationWarnings -EnrollmentID 123456 -ChangeID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CPSPreVerificationWarnings returns the correct info' {
        $PreWarnings.warnings | Should -Not -BeNullOrEmpty
    }

    ### Get-CPSPostVerificationWarnings
    $Script:PostWarnings = Get-CPSPostVerificationWarnings -EnrollmentID 123456 -ChangeID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CPSPostVerificationWarnings returns the correct info' {
        $PostWarnings.warnings | Should -Not -BeNullOrEmpty
    }

    ### Confirm-CPSPreVerificationWarnings
    $Script:AckPreWarnings = Confirm-CPSPreVerificationWarnings -EnrollmentID 123456 -ChangeID 123456 -Acknowledgement acknowledge -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Confirm-CPSPreVerificationWarnings returns the correct info' {
        $AckPreWarnings.change | Should -Not -BeNullOrEmpty
    }

    ### Confirm-CPSPostVerificationWarnings
    $Script:AckPostWarnings = Confirm-CPSPostVerificationWarnings -EnrollmentID 123456 -ChangeID 123456 -Acknowledgement acknowledge -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Confirm-CPSPostVerificationWarnings returns the correct info' {
        $AckPostWarnings.change | Should -Not -BeNullOrEmpty
    }

    ### Add-CPSThirdPartyCert
    $Script:UploadCert = Add-CPSThirdPartyCert -EnrollmentID 123456 -ChangeID 123456 -Certificate "--- BEGIN CERTIFICATE ------ END CERTIFICATE ---" -KeyAlgorithm RSA -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Add-CPSThirdPartyCert returns the correct info' {
        $UploadCert.change | Should -Not -BeNullOrEmpty
    }

    ### Complete-CPSChange
    $Script:CompleteChange = Complete-CPSChange -EnrollmentID 123456 -ChangeID 123456 -Acknowledgement acknowledge -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Complete-CPSChange returns the correct info' {
        $CompleteChange.change | Should -Not -BeNullOrEmpty
    }

    ### Confirm-CPSLetsEncryptChallengesCompleted
    it 'Confirm-CPSLetsEncryptChallengesCompleted throws no errors' {
        { Confirm-CPSLetsEncryptChallengesCompleted -EnrollmentID $TestEnrollmentID -ChangeID $ChangeID -Acknowledgement acknowledge -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }
}