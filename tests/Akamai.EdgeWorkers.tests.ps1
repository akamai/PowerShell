Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.EdgeWorkers/Akamai.EdgeWorkers.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestGroupID = $env:PesterGroupID
$Script:TestContract = $env:PesterContractID
$Script:TestEdgeworkerName = 'akamaipowershell-testing'
$Script:TestEdgeworkerVersion = '0.0.1'
$script:TestNextEdgeWorkerVersion = '0.0.2'
$Script:BundleJson = @"
{ "edgeworker-version": "0.0.1", "description": "Pester testing"}
"@
$Script:MainJS = 'export function onClientRequest(request){}'
$Script:BigFileLocation = 'https://raw.githubusercontent.com/adamdehaven/Brackets-BTTF-Ipsum/master/src/script.txt'
$Script:TestBundleDirectory = 'bundledirectory'

# Prepare files
$Script:TestEdgeWorkerDirectory = New-Item -ItemType Directory -Name $TestEdgeworkerName
$BundleJson | Set-Content -Path "$TestEdgeworkerName/bundle.json"
$MainJS | Set-Content -Path "$TestEdgeworkerName/main.js"
Invoke-RestMethod -Uri $BigFileLocation -OutFile "$TestEdgeworkerName/data.txt" | Out-Null

# Create TGZ of first version
$CurrentDir = Get-Location
Set-Location $TestEdgeworkerName
tar -czf "$TestEdgeWorkerName-$TestEdgeWorkerVersion.tgz" --exclude=*.tgz * #| Out-Null
Set-Location $CurrentDir

# Update JSON for higher version with directory option
$Bundle = ConvertFrom-Json $BundleJson
$Bundle.'edgeworker-version' = $TestNextEdgeWorkerVersion
$Bundle | ConvertTo-Json -Compress | Set-Content "$TestEdgeworkerName/bundle.json" -Force

Describe 'Safe Edgeworker Tests' {

    BeforeAll {
        it 'EW should not already exist' {
            { Get-EdgeWorker -EdgeWorkerName $TestEdgeworkerName -EdgeRCFile $EdgeRCFile -Section $Section } | Should -BeNullOrEmpty
        }
    }

    ### New-EdgeWorker
    $Script:NewEdgeWorker = New-EdgeWorker -EdgeWorkerName $TestEdgeworkerName -GroupID $TestGroupID -ResourceTierID 100 -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-Edgeworker completes successfully' {
        $NewEdgeWorker.name | Should -Be $TestEdgeworkerName
    }

    ### Get-Edgeworker, all
    $Script:EdgeWorkers = Get-EdgeWorker -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-Edgeworkers returns a list' {
        $EdgeWorkers[0].edgeWorkerId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorker by name
    $Script:GetEdgeWorkerByName = Get-EdgeWorker -EdgeWorkerName $TestEdgeworkerName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorker by name returns the correct EW' {
        $GetEdgeWorkerByName.edgeWorkerId | Should -Be $NewEdgeWorker.edgeWorkerId
    }

    ### Get-EdgeWorker by ID
    $Script:GetEdgeWorkerByID = Get-EdgeWorker -EdgeWorkerID $NewEdgeWorker.edgeWorkerId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorker by ID returns the correct EW' {
        $GetEdgeWorkerByID.edgeWorkerId | Should -Be $NewEdgeWorker.edgeWorkerId
    }

    ### Get-EdgeworkerContract
    $Script:EdgeWorkerContracts = Get-EdgeworkerContract -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeworkerContract returns a list of contracts' {
        $EdgeWorkerContracts | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeworkerGroup, all
    $Script:EdgeWorkerGroups = Get-EdgeWorkerGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeworkerGroup, all, returns a list of groups' {
        $EdgeWorkerGroups[0].groupId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeworkerGroup, single
    $Script:Group = Get-EdgeWorkerGroup -GroupID $TestGroupId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeworkerGroup, single returns the correct group' {
        $Group.groupId | Should -Be $TestGroupId
    }

    ### Get-EdgeworkerLimit
    $Script:EdgeWorkerLimits = Get-EdgeworkerLimit -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeworkerLimit returns a list of contracts' {
        $EdgeWorkerLimits[0].limitId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerReport
    $Script:Reports = Get-EdgeWorkerReport -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerGroupReport returns a list' {
        $Reports[0].reportId | Should -Not -BeNullOrEmpty
    }

    ### Set-EdgeWorker by Name
    $Script:SetEdgeWorkerByName = Set-EdgeWorker -EdgeWorkerName $TestEdgeWorkerName -NewName $TestEdgeWorkerName -GroupID $TestGroupId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-EdgeWorker by name updates correctly' {
        $SetEdgeWorkerByName.edgeWorkerId | Should -Be $NewEdgeWorker.edgeWorkerId
    }
    
    ### Set-EdgeWorker by ID
    $Script:SetEdgeWorkerByID = Set-EdgeWorker -EdgeWorkerID $NewEdgeWorker.edgeWorkerId -NewName $TestEdgeWorkerName -GroupID $TestGroupId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-EdgeWorker by ID updates correctly' {
        $SetEdgeWorkerByID.name | Should -Be $TestEdgeWorkerName
    }

    ### Get-EdgeWorkerResourceTier, all
    $Script:Tiers = Get-EdgeWorkerResourceTier -ContractId $TestContract -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerResourceTier returns tiers' {
        $Tiers[0].resourceTierId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerResourceTier, single
    $Script:EdgeWorkerTier = Get-EdgeWorkerResourceTier -EdgeWorkerID $NewEdgeWorker.edgeWorkerId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerResourceTier returns the correct data' {
        $EdgeWorkerTier.resourceTierId | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeWorkerVersion with codebundle
    $Script:NewVersionByBundle = New-EdgeWorkerVersion -EdgeWorkerName $TestEdgeworkerName -CodeBundle "$($TestEdgeworkerDirectory.FullName)\$TestEdgeWorkerName-$TestEdgeWorkerVersion.tgz" -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeWorkerVersion by codebundle completes successfully' {
        $NewVersionByBundle.edgeWorkerId | Should -Be $NewEdgeWorker.edgeWorkerId
    }

    ### New-EdgeWorkerVersion with directory
    $Script:NewVersionByDirectory = New-EdgeWorkerVersion -EdgeWorkerID $NewEdgeWorker.edgeWorkerId -CodeDirectory $TestEdgeworkerName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeWorkerVersion by directory creates a new version' {
        "$TestEdgeworkerName\$TestEdgeWorkerName-$TestNextEdgeWorkerVersion.tgz" | Should -Exist
        $NewVersionByDirectory.edgeWorkerId | Should -Be $NewEdgeWorker.edgeWorkerId
    }

    ### Get-EdgeWorkerCodeBundle, file
    Get-EdgeWorkerCodeBundle -EdgeWorkerName $TestEdgeWorkerName -Version latest -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerCodeBundle should download a file' {
        "$TestEdgeWorkerName-$TestNextEdgeWorkerVersion.tgz" | Should -Exist
    }

    ### Get-EdgeWorkerCodeBundle, directory
    Get-EdgeWorkerCodeBundle -EdgeWorkerName $TestEdgeWorkerName -Version latest -OutputDirectory $TestBundleDirectory -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerCodeBundle should download a bundle and extract it into a directory' {
        "$TestBundleDirectory/bundle.json" | Should -Exist
    }

    ### Remove-EdgeWorkerVersion
    it 'Remove-EdgeWorkerVersion completes successfully' {
        { Remove-EdgeWorkerVersion -EdgeWorkerName $TestEdgeworkerName -Version $TestEdgeworkerVersion -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    # Allow remove command to finish
    Start-Sleep -Seconds 10

    ### Get-EdgeWorkerVersion, all by name
    $Script:VersionsByName = Get-EdgeWorkerVersion -EdgeWorkerName $TestEdgeworkerName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerVersions returns at least 1 version' {
        $VersionsByName[0].edgeWorkerId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerVersion, all by ID
    $Script:VersionsByID = Get-EdgeWorkerVersion -EdgeWorkerID $NewEdgeWorker.edgeWorkerId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerVersions returns at least 1 version' {
        $VersionsByID[0].edgeWorkerId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerVersion, single by name
    $Script:VersionByName = Get-EdgeWorkerVersion -EdgeWorkerName $TestEdgeworkerName -Version $TestEdgeWorkerVersion -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerVersion returns the version' {
        $VersionByName.edgeWorkerId | Should -Be $NewEdgeWorker.edgeWorkerId
    }
    
    ### Get-EdgeWorkerVersion, single by ID
    $Script:VersionByID = Get-EdgeWorkerVersion -EdgeWorkerID $NewEdgeWorker.edgeWorkerId -Version $TestEdgeWorkerVersion -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeWorkerVersion returns the version' {
        $VersionByID.edgeWorkerId | Should -Be $NewEdgeWorker.edgeWorkerId
    }

    ### Remove-EdgeWorker
    it 'Remove-EdgeWorker completes successfully' {
        { Remove-EdgeWorker -EdgeWorkerID $NewEdgeWorker.edgeWorkerId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    AfterAll {
        Remove-Item -Recurse $TestEdgeworkerName
        Remove-Item -Recurse $TestBundleDirectory
        Remove-Item "$TestEdgeWorkerName-$TestNextEdgeWorkerVersion.tgz"
    }
    
}

Describe 'Unsafe Edgeworker Tests' {
    ### New-EdgeWorkerActivation
    $Script:ActivationResult = New-EdgeWorkerActivation -EdgeWorkerID 12345 -Version 0.0.1 -Network STAGING -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-EdgeWorkerActivation returns valid response' {
        $ActivationResult.edgeWorkerId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerActivation, all
    $Script:Activations = Get-EdgeWorkerActivation -EdgeWorkerID 12345 -Version 0.0.1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerActivations returns valid response' {
        $Activations[0].activationId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerActivation, single
    $Script:Activation = Get-EdgeWorkerActivation -EdgeWorkerID 12345 -ActivationID 1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerActivation returns valid response' {
        $Activation.edgeWorkerId | Should -Not -BeNullOrEmpty
    }

    ### Remove-EdgeworkerActivation
    $Script:ActivationCancellation = Remove-EdgeWorkerActivation -EdgeWorkerID 12345 -ActivationID 1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerDeactivation returns valid response' {
        $ActivationCancellation.edgeWorkerId | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeWorkerDeactivation
    $Script:DeactivationResult = New-EdgeWorkerDeactivation -EdgeWorkerID 12345 -Version 0.0.1 -Network STAGING -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'DeNew-EdgeWorkerActivation returns valid response' {
        $DeactivationResult.edgeWorkerId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerDeactivation, all
    $Script:Deactivations = Get-EdgeWorkerDeactivation -EdgeWorkerID 12345 -Version 0.0.1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerDeactivation, all returns valid response' {
        $Deactivations[0].deactivationId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerDeactivation
    $Script:Deactivation = Get-EdgeWorkerDeactivation -EdgeWorkerID 12345 -DeactivationID 1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerDeactivation, single returns valid response' {
        $Deactivation.edgeWorkerId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerProperties
    $Script:Properties = Get-EdgeWorkerProperties -EdgeWorkerID 12345 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerDeactivation returns valid response' {
        $Properties.count | Should -Not -Be 0
    }

    ### New-EdgeWorkerAuthToken
    $Script:NewToken = New-EdgeWorkerAuthToken -Hostnames www.example.com -Expiry 60 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-EdgeWorkerAuthToken returns valid response' {
        $NewToken | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeWorkerRevision, all
    $Script:Revisions = Get-EdgeWorkerRevision -EdgeWorkerID 12345 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerRevision returns a list of revisions' {
        $Revisions[1].revisionId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-EdgeWorkerRevision, single
    $Script:Revision = Get-EdgeWorkerRevision -EdgeWorkerID 12345 -RevisionID 1-1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerRevision returns the correct object' {
        $Revision.revisionId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-EdgeWorkerRevisionBom
    $Script:Bom = Get-EdgeWorkerRevisionBom -EdgeWorkerID 12345 -RevisionID 1-1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeWorkerRevisionBom returns the correct object' {
        $Bom.edgeWorkerId | Should -Be 42
        $Bom.dependencies.'redirect-geo-query'.edgeWorkerId | Should -Be 23
    }
    
    ### Compare-EdgeWorkerRevision
    $Script:Comparison = Compare-EdgeWorkerRevision -EdgeWorkerID 12345 -RevisionID 1-1 -ComparisonRevisionID 1-2 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Compare-EdgeWorkerRevision returns the correct object' {
        $Comparison.dependencies.'redirect-geo-query'.diff | Should -Not -BeNullOrEmpty
    }
    
    ### Set-EdgeWorkerRevision, pin
    $Script:Pin = Set-EdgeWorkerRevision -EdgeWorkerID 12345 -RevisionID 1-1 -Operation pin -Note 'Pin!' -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-EdgeWorkerRevision pins correctly' {
        $Pin.pinNote | Should -Not -BeNullOrEmpty
    }
    
    ### Set-EdgeWorkerRevision, unpin
    $Script:Pin = Set-EdgeWorkerRevision -EdgeWorkerID 12345 -RevisionID 1-1 -Operation unpin -Note 'Unpin!' -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-EdgeWorkerRevision unpins correctly' {
        $Pin.unpinNote | Should -Not -BeNullOrEmpty
    }
    
    ### New-EdgeWorkerRevisionActivation
    $Script:RevisionActivation = New-EdgeWorkerRevisionActivation -EdgeWorkerID 12345 -RevisionID 1-1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-EdgeWorkerRevisionActivation activates correctly' {
        $RevisionActivation.activationId | Should -Not -BeNullOrEmpty
    }
}