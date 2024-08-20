Describe 'Safe Akamai.Edgeworkers Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeWorkers/Akamai.EdgeWorkers.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestGroupID = $env:PesterGroupID
        $TestContract = $env:PesterContractID
        $TestEdgeworkerName = 'akamaipowershell-testing'
        $TestEdgeworkerVersion = '0.0.1'
        $TestNextEdgeWorkerVersion = '0.0.2'
        $TestBundleJson = @"
{ "edgeworker-version": "0.0.1", "description": "Pester testing"}
"@
        $TestMainJS = 'export function onClientRequest(request){}'
        $BigFileLocation = 'https://raw.githubusercontent.com/adamdehaven/Brackets-BTTF-Ipsum/master/src/script.txt'
        $TestBundleDirectory = 'bundledirectory'
        
        # Prepare files
        $TestEdgeWorkerDirectory = New-Item -ItemType Directory -Name $TestEdgeworkerName
        $TestBundleJson | Set-Content -Path "$TestEdgeworkerName/bundle.json"
        $TestMainJS | Set-Content -Path "$TestEdgeworkerName/main.js"
        Invoke-RestMethod -Uri $BigFileLocation -OutFile "$TestEdgeworkerName/data.txt" | Out-Null
        
        # Create TGZ of first version
        $CurrentDir = Get-Location
        Set-Location $TestEdgeworkerName
        tar -czf "$TestEdgeWorkerName-$TestEdgeWorkerVersion.tgz" --exclude=*.tgz * #| Out-Null
        Set-Location $CurrentDir
        
        # Update JSON for higher version with directory option
        $TestBundle = ConvertFrom-Json $TestBundleJson
        $TestBundle.'edgeworker-version' = $TestNextEdgeWorkerVersion
        $TestBundle | ConvertTo-Json -Compress | Set-Content "$TestEdgeworkerName/bundle.json" -Force
        
        $Existing = Get-EdgeWorker -EdgeWorkerName $TestEdgeworkerName @CommonParams
        if ($Existing) {
            Write-Error "Test EdgeWorker already exists"
            return
        }

        $PD = @{}
    }

    AfterAll {
        if ((Test-Path $TestEdgeworkerName)) {
            Remove-Item -Recurse $TestEdgeworkerName
        }
        if ((Test-Path $TestBundleDirectory)) {
            Remove-Item -Recurse $TestBundleDirectory
        }
        if ((Test-Path "$TestEdgeWorkerName-$TestNextEdgeWorkerVersion.tgz")) {
            Remove-Item "$TestEdgeWorkerName-$TestNextEdgeWorkerVersion.tgz"
        }
        # Purge existing EWs in case of removal failure
        Get-EdgeWorker @CommonParams | Where-Object name -eq $TestEdgeWorkerName | ForEach-Object { Remove-EdgeWorker -EdgeWorkerID $_.EdgeWorkerID @CommonParams }
    }

    Context 'New-EdgeWorker' {
        It 'completes successfully' {
            $PD.NewEdgeWorker = New-EdgeWorker -EdgeWorkerName $TestEdgeworkerName -GroupID $TestGroupID -ResourceTierID 100 @CommonParams
            $PD.NewEdgeWorker.name | Should -Be $TestEdgeworkerName
        }
    }

    Context 'Get-Edgeworker, all' {
        It 'returns a list' {
            $PD.EdgeWorkers = Get-EdgeWorker @CommonParams
            $PD.EdgeWorkers[0].edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorker by name' {
        It 'returns the correct EW' {
            $PD.GetEdgeWorkerByName = Get-EdgeWorker -EdgeWorkerName $TestEdgeworkerName @CommonParams
            $PD.GetEdgeWorkerByName.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
    }

    Context 'Get-EdgeWorker by ID' {
        It 'returns the correct EW' {
            $PD.GetEdgeWorkerByID = Get-EdgeWorker -EdgeWorkerID $PD.NewEdgeWorker.edgeWorkerId @CommonParams
            $PD.GetEdgeWorkerByID.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
    }

    Context 'Get-EdgeworkerContract' {
        It 'returns a list of contracts' {
            $PD.EdgeWorkerContracts = Get-EdgeworkerContract @CommonParams
            $PD.EdgeWorkerContracts | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeworkerGroup, all' {
        It 'returns a list of groups' {
            $PD.EdgeWorkerGroups = Get-EdgeWorkerGroup @CommonParams
            $PD.EdgeWorkerGroups[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeworkerGroup, single' {
        It 'returns the correct group' {
            $PD.Group = Get-EdgeWorkerGroup -GroupID $TestGroupId @CommonParams
            $PD.Group.groupId | Should -Be $TestGroupId
        }
    }

    Context 'Get-EdgeworkerLimit' {
        It 'returns a list of contracts' {
            $PD.EdgeWorkerLimits = Get-EdgeworkerLimit @CommonParams
            $PD.EdgeWorkerLimits[0].limitId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerReport' {
        It 'returns a list' {
            $PD.Reports = Get-EdgeWorkerReport @CommonParams
            $PD.Reports[0].reportId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-EdgeWorker by Name' {
        It 'updates correctly' {
            $PD.SetEdgeWorkerByName = Set-EdgeWorker -EdgeWorkerName $TestEdgeWorkerName -NewName $TestEdgeWorkerName -GroupID $TestGroupId @CommonParams
            $PD.SetEdgeWorkerByName.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
    }
    
    Context 'Set-EdgeWorker by ID' {
        It 'updates correctly' {
            $PD.SetEdgeWorkerByID = Set-EdgeWorker -EdgeWorkerID $PD.NewEdgeWorker.edgeWorkerId -NewName $TestEdgeWorkerName -GroupID $TestGroupId @CommonParams
            $PD.SetEdgeWorkerByID.name | Should -Be $TestEdgeWorkerName
        }
    }

    Context 'Get-EdgeWorkerResourceTier, all' {
        It 'returns tiers' {
            $PD.Tiers = Get-EdgeWorkerResourceTier -ContractId $TestContract @CommonParams
            $PD.Tiers[0].resourceTierId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerResourceTier, single' {
        It 'returns the correct data' {
            $PD.EdgeWorkerTier = Get-EdgeWorkerResourceTier -EdgeWorkerID $PD.NewEdgeWorker.edgeWorkerId @CommonParams
            $PD.EdgeWorkerTier.resourceTierId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeWorkerVersion with codebundle' {
        It 'completes successfully' {
            $PD.NewVersionByBundle = New-EdgeWorkerVersion -EdgeWorkerName $TestEdgeworkerName -CodeBundle "$($TestEdgeworkerDirectory.FullName)/$TestEdgeWorkerName-$TestEdgeWorkerVersion.tgz" @CommonParams
            $PD.NewVersionByBundle.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
    }

    Context 'New-EdgeWorkerVersion with directory' {
        It 'creates a new version' {
            $PD.NewVersionByDirectory = New-EdgeWorkerVersion -EdgeWorkerID $PD.NewEdgeWorker.edgeWorkerId -CodeDirectory $TestEdgeworkerName @CommonParams
            "$TestEdgeworkerName\$TestEdgeWorkerName-$TestNextEdgeWorkerVersion.tgz" | Should -Exist
            $PD.NewVersionByDirectory.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
    }

    Context 'Get-EdgeWorkerCodeBundle, file' {
        It 'should download a file' {
            Get-EdgeWorkerCodeBundle -EdgeWorkerName $TestEdgeWorkerName -Version latest @CommonParams
            "$TestEdgeWorkerName-$TestNextEdgeWorkerVersion.tgz" | Should -Exist
        }
    }

    Context 'Get-EdgeWorkerCodeBundle, directory' {
        It 'should download a bundle and extract it into a directory' {
            Get-EdgeWorkerCodeBundle -EdgeWorkerName $TestEdgeWorkerName -Version latest -OutputDirectory $TestBundleDirectory @CommonParams
            "$TestBundleDirectory/bundle.json" | Should -Exist
        }
    }

    Context 'Remove-EdgeWorkerVersion' {
        It 'completes successfully' {
            Remove-EdgeWorkerVersion -EdgeWorkerName $TestEdgeworkerName -Version $TestNextEdgeWorkerVersion @CommonParams 
            # Allow remove command to finish
            Start-Sleep -Seconds 10
        }
    }

    Context 'Get-EdgeWorkerVersion, all by name' {
        It 'returns at least 1 version' {
            $PD.VersionsByName = Get-EdgeWorkerVersion -EdgeWorkerName $TestEdgeworkerName @CommonParams
            $PD.VersionsByName[0].edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerVersion, all by ID' {
        It 'returns at least 1 version' {
            $PD.VersionsByID = Get-EdgeWorkerVersion -EdgeWorkerID $PD.NewEdgeWorker.edgeWorkerId @CommonParams
            $PD.VersionsByID[0].edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerVersion, single by name' {
        It 'returns the version' {
            $PD.VersionByName = Get-EdgeWorkerVersion -EdgeWorkerName $TestEdgeworkerName -Version $TestEdgeWorkerVersion @CommonParams
            $PD.VersionByName.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
    }
    
    Context 'Get-EdgeWorkerVersion, single by ID' {
        It 'returns the version' {
            $PD.VersionByID = Get-EdgeWorkerVersion -EdgeWorkerID $PD.NewEdgeWorker.edgeWorkerId -Version $TestEdgeWorkerVersion @CommonParams
            $PD.VersionByID.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
    }

    Context 'Remove-EdgeWorker' {
        It 'completes successfully' {
            Remove-EdgeWorker -EdgeWorkerID $PD.NewEdgeWorker.edgeWorkerId @CommonParams 
        }
    }
}

Describe 'Unsafe Akamai.Edgeworkers Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeWorkers/Akamai.EdgeWorkers.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Edgeworkers"
        $PD = @{}
    }
    Context 'New-EdgeWorkerActivation' {
        It 'returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeWorkerActivation.json"
                return $Response | ConvertFrom-Json
            }
            $ActivationResult = New-EdgeWorkerActivation -EdgeWorkerID 12345 -Version 0.0.1 -Network STAGING
            $ActivationResult.edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerActivation, all' {
        It 'returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerActivation_1.json"
                return $Response | ConvertFrom-Json
            }
            $Activations = Get-EdgeWorkerActivation -EdgeWorkerID 12345 -Version 0.0.1
            $Activations[0].activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerActivation, single' {
        It 'returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Activation = Get-EdgeWorkerActivation -EdgeWorkerID 12345 -ActivationID 1
            $Activation.edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-EdgeworkerActivation' {
        It 'returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-EdgeworkerActivation.json"
                return $Response | ConvertFrom-Json
            }
            $ActivationCancellation = Remove-EdgeWorkerActivation -EdgeWorkerID 12345 -ActivationID 1
            $ActivationCancellation.edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-EdgeWorkerDeactivation' {
        It 'returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeWorkerDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $DeactivationResult = New-EdgeWorkerDeactivation -EdgeWorkerID 12345 -Version 0.0.1 -Network STAGING
            $DeactivationResult.edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerDeactivation, all' {
        It 'returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerDeactivation_1.json"
                return $Response | ConvertFrom-Json
            }
            $Deactivations = Get-EdgeWorkerDeactivation -EdgeWorkerID 12345 -Version 0.0.1
            $Deactivations[0].deactivationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerDeactivation' {
        It 'single returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $Deactivation = Get-EdgeWorkerDeactivation -EdgeWorkerID 12345 -DeactivationID 1
            $Deactivation.edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerProperties' {
        It 'returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerProperties.json"
                return $Response | ConvertFrom-Json
            }
            $Properties = Get-EdgeWorkerProperties -EdgeWorkerID 12345
            $Properties.count | Should -Not -Be 0
        }
    }

    Context 'New-EdgeWorkerAuthToken' {
        It 'returns valid response' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeWorkerAuthToken.json"
                return $Response | ConvertFrom-Json
            }
            $NewToken = New-EdgeWorkerAuthToken -Hostnames www.example.com -Expiry 60
            $NewToken | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerRevision, all' {
        It 'returns a list of revisions' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerRevision_1.json"
                return $Response | ConvertFrom-Json
            }
            $Revisions = Get-EdgeWorkerRevision -EdgeWorkerID 12345
            $Revisions[1].revisionId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-EdgeWorkerRevision, single' {
        It 'returns the correct object' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerRevision.json"
                return $Response | ConvertFrom-Json
            }
            $Revision = Get-EdgeWorkerRevision -EdgeWorkerID 12345 -RevisionID 1-1
            $Revision.revisionId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-EdgeWorkerRevisionBom' {
        It 'returns the correct object' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerRevisionBom.json"
                return $Response | ConvertFrom-Json
            }
            $Bom = Get-EdgeWorkerRevisionBom -EdgeWorkerID 12345 -RevisionID 1-1
            $Bom.edgeWorkerId | Should -Be 42
            $Bom.dependencies.'redirect-geo-query'.edgeWorkerId | Should -Be 23
        }
    }
    
    Context 'Compare-EdgeWorkerRevision' {
        It 'returns the correct object' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Compare-EdgeWorkerRevision.json"
                return $Response | ConvertFrom-Json
            }
            $Comparison = Compare-EdgeWorkerRevision -EdgeWorkerID 12345 -RevisionID 1-1 -ComparisonRevisionID 1-2
            $Comparison.dependencies.'redirect-geo-query'.diff | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-EdgeWorkerRevision, pin' {
        It 'pins correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-EdgeWorkerRevision.json"
                return $Response | ConvertFrom-Json
            }
            $Pin = Set-EdgeWorkerRevision -EdgeWorkerID 12345 -RevisionID 1-1 -Operation pin -Note 'Pin!'
            $Pin.pinNote | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-EdgeWorkerRevision, unpin' {
        It 'unpins correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-EdgeWorkerRevision_1.json"
                return $Response | ConvertFrom-Json
            }
            $Pin = Set-EdgeWorkerRevision -EdgeWorkerID 12345 -RevisionID 1-1 -Operation unpin -Note 'Unpin!'
            $Pin.unpinNote | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'New-EdgeWorkerRevisionActivation' {
        It 'activates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeWorkerRevisionActivation.json"
                return $Response | ConvertFrom-Json
            }
            $RevisionActivation = New-EdgeWorkerRevisionActivation -EdgeWorkerID 12345 -RevisionID 1-1
            $RevisionActivation.activationId | Should -Not -BeNullOrEmpty
        }
    }
}

