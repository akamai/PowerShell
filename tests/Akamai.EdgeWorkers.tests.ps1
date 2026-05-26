BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.Edgeworkers Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.EdgeWorkers'
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
        $TestGroupID = $env:PesterGroupID
        $TestContractID = $env:PesterContractID
        $TestEdgeworkerName = "pester-$Timestamp"
        $TestEdgeworkerVersion = '0.0.1'
        $TestNextEdgeWorkerVersion = '0.0.2'
        $TestHostname = $env:PesterHostname

        # Get existing edgeworker
        $ExistingEdgeWorker = Get-EdgeWorker -EdgeWorkerName 'pester' @CommonParams

        # Customize bundle
        $TestBundleJson = @"
{
    "edgeworker-version": "0.0.1",
    "description": "Pester testing",
    "dependencies": {
        "child": {
            "edgeWorkerId": $($ExistingEdgeWorker.EdgeWorkerId),
            "version": "active"
        }
    }
}
"@
        $TestMainJS = 'export function onClientRequest(request){}'
        $BigFileLocation = 'https://raw.githubusercontent.com/adamdehaven/Brackets-BTTF-Ipsum/master/src/script.txt'
        $TestBundleDirectory = 'TestDrive:/bundledirectory'
        
        # Prepare files
        $TestEdgeWorkerDirectory = New-Item -ItemType Directory -Name $TestEdgeworkerName -Path TestDrive:/
        $TestBundleJson | Set-Content -Path "$TestEdgeWorkerDirectory/bundle.json"
        $TestMainJS | Set-Content -Path "$TestEdgeWorkerDirectory/main.js"
        Invoke-RestMethod -Uri $BigFileLocation -OutFile "$TestEdgeWorkerDirectory/data.txt" | Out-Null
        
        # Create TGZ of first version
        $CurrentDir = Get-Location
        Set-Location $TestEdgeWorkerDirectory
        tar -czf "$TestEdgeWorkerName-$TestEdgeWorkerVersion.tgz" --exclude=*.tgz * #| Out-Null
        Set-Location $CurrentDir
        
        # Update JSON for higher version with directory option
        $TestBundle = ConvertFrom-Json $TestBundleJson
        $TestBundle.'edgeworker-version' = $TestNextEdgeWorkerVersion
        $TestBundle | ConvertTo-Json -Compress | Set-Content "$TestEdgeWorkerDirectory/bundle.json" -Force
        
        $TestParams = @{
            EdgeWorkerName = $TestEdgeworkerName
        }
        $Existing = Get-EdgeWorker @TestParams @CommonParams
        if ($Existing) {
            throw "Test EdgeWorker already exists"
        }

        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Edgeworkers"
        $PD = @{}
    }

    AfterAll {
        # Purge existing EWs in case of removal failure
        Get-EdgeWorker @CommonParams | Where-Object name -eq $TestEdgeWorkerName | Remove-EdgeWorker @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'New-EdgeWorker' {
        It 'completes successfully' {
            $TestParams = @{
                'EdgeWorkerName' = $TestEdgeworkerName
                'GroupID'        = $TestGroupID
                'ResourceTierID' = 100
            }
            $PD.NewEdgeWorker = New-EdgeWorker @TestParams @CommonParams
            $PD.NewEdgeWorker.name | Should -Be $TestEdgeworkerName
        }
    }

    Context 'Copy-EdgeWorker' {
        It 'completes successfully by parameter' {
            $TestParams = @{
                'EdgeWorkerName' = $TestEdgeworkerName
                'GroupID'        = $TestGroupID
                'ResourceTierID' = 200
                'NewName'        = "$TestEdgeworkerName-copy"
            }
            $CopyEdgeWorker = Copy-EdgeWorker @TestParams @CommonParams
            $CopyEdgeWorker.name | Should -Be "$TestEdgeworkerName-copy"
        }
        It 'completes successfully by pipeline' {
            $TestParams = @{
                'NewName'        = "$TestEdgeworkerName-copy"
                'GroupID'        = $TestGroupID
                'ResourceTierID' = 200
            }
            $CopyEdgeWorker = $PD.NewEdgeWorker | Copy-EdgeWorker @TestParams @CommonParams
            $CopyEdgeWorker.name | Should -Be "$TestEdgeworkerName-copy"
        }
        AfterEach {
            $CopyEdgeWorker | Remove-EdgeWorker @CommonParams
        }
    }

    Context 'Get-Edgeworker' {
        It 'returns a list' {
            $PD.EdgeWorkers = Get-EdgeWorker @CommonParams
            $PD.EdgeWorkers[0].edgeWorkerId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct EW by name' {
            $TestParams = @{
                'EdgeWorkerName' = $TestEdgeworkerName
            }
            $PD.EdgeWorker = Get-EdgeWorker @TestParams @CommonParams
            $PD.EdgeWorker.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
        It 'returns the correct EW by ID by param' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.NewEdgeWorker.edgeWorkerId
            }
            $GetEdgeWorkerByID = Get-EdgeWorker @TestParams @CommonParams
            $GetEdgeWorkerByID.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
        It 'returns the correct EW by ID by pipeline' {
            $PD.GetEdgeWorkerByID = $PD.EdgeWorker | Get-EdgeWorker @CommonParams
            $PD.GetEdgeWorkerByID.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
    }

    Context 'Get-EdgeworkerContract' {
        It 'returns a list of contracts' {
            $PD.EdgeWorkerContracts = Get-EdgeworkerContract @CommonParams
            $PD.EdgeWorkerContracts | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeworkerGroup' {
        It 'returns a list of groups' {
            $PD.EdgeWorkerGroups = Get-EdgeWorkerGroup @CommonParams
            $PD.EdgeWorkerGroups[0].groupId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct group' {
            $TestParams = @{
                'GroupID' = $TestGroupId
            }
            $PD.Group = Get-EdgeWorkerGroup @TestParams @CommonParams
            $PD.Group.groupId | Should -Be $TestGroupId
        }
    }

    Context 'Get-EdgeworkerLimit' {
        It 'returns a list of contracts' {
            $PD.EdgeWorkerLimits = Get-EdgeworkerLimit @CommonParams
            $PD.EdgeWorkerLimits[0].limitId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerReport' -Tag 'Get-EdgeWorkerReport' {
        It 'returns a list' {
            $PD.Reports = Get-EdgeWorkerReport @CommonParams
            $PD.Reports[0].reportId | Should -Not -BeNullOrEmpty
        }
        Context "Single report" {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerReport.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It "returns a single edgeworker's reports" {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
                    'ReportID'     = 0
                    'Start'        = '2026-01-01T00:00:00Z'
                    'End'          = '2026-01-02T00:00:00Z'
                }
                $PD.Report = Get-EdgeWorkerReport @TestParams @CommonParams
                $PD.Report.reportId | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Set-EdgeWorker' {
        It 'updates by param' {
            $TestParams = @{
                'EdgeWorkerName' = $TestEdgeWorkerName
                'NewName'        = $TestEdgeWorkerName
                'GroupID'        = $TestGroupId
            }
            $PD.SetEdgeWorkerByName = Set-EdgeWorker @TestParams @CommonParams
            $PD.SetEdgeWorkerByName.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
        It 'updates by pipeline' {
            $PD.SetEdgeWorkerByID = $PD.EdgeWorker | Set-EdgeWorker -NewName $TestEdgeworkerName @CommonParams
            $PD.SetEdgeWorkerByID.name | Should -Be $TestEdgeWorkerName
        }
    }

    Context 'Get-EdgeWorkerResourceTier' {
        It 'returns tiers' {
            $TestParams = @{
                'ContractId' = $TestContractID
            }
            $PD.Tiers = Get-EdgeWorkerResourceTier @TestParams @CommonParams
            $PD.Tiers[0].resourceTierId | Should -Not -BeNullOrEmpty
        }
        It 'returns a single tier by param' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
            }
            $PD.EdgeWorkerTier = Get-EdgeWorkerResourceTier @TestParams @CommonParams
            $PD.EdgeWorkerTier.resourceTierId | Should -Not -BeNullOrEmpty
        }
        It 'returns a single tier by pipeline' {
            $PD.EdgeWorkerTier = $PD.EdgeWorker | Get-EdgeWorkerResourceTier @CommonParams
            $PD.EdgeWorkerTier.resourceTierId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-EdgeWorkerCodeBundle' {
        BeforeAll {
            # Duplicate code to temp directory to fix tax issues with TestDrive:/
            $TempDirectory = [System.Io.Path]::GetTempFileName()
            Remove-Item -Path $TempDirectory -Force
            Copy-Item -Recurse -Path $TestEdgeWorkerDirectory -Destination $TempDirectory
        }
        It 'validates by code directory' {
            $TestParams = @{
                'CodeDirectory' = $TempDirectory
            }
            $Result = Test-EdgeWorkerCodeBundle @TestParams @CommonParams
            $Result.errors.Count | Should -Be 0
            $Result.warnings.Count | Should -Be 0
        }
        It 'validates by code bundle' {
            $TestParams = @{
                'CodeBundle' = "$TestEdgeWorkerDirectory/$TestEdgeWorkerName-$TestEdgeWorkerVersion.tgz"
            }
            $Result = Test-EdgeWorkerCodeBundle @TestParams @CommonParams
            $Result.errors.Count | Should -Be 0
            $Result.warnings.Count | Should -Be 0
        }
    }

    Context 'New-EdgeWorkerVersion' {
        It 'creates with a codebundle' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.NewEdgeWorker.edgeWorkerId
                'CodeBundle'   = "$($TestEdgeWorkerDirectory.FullName)/$TestEdgeWorkerName-$TestEdgeWorkerVersion.tgz"
            }
            $PD.NewVersionByBundle = New-EdgeWorkerVersion @TestParams @CommonParams
            $PD.NewVersionByBundle.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
        It 'creates with a directory, and saves the code bundle' {
            $TestParams = @{
                'EdgeWorkerID'  = $PD.NewEdgeWorker.edgeWorkerId
                'CodeDirectory' = $TestEdgeWorkerDirectory
                'SaveBundleTo'  = "TestDrive:/bundle-output.tgz"
            }
            $PD.NewVersionByDirectory = New-EdgeWorkerVersion @TestParams @CommonParams
            "TestDrive:/bundle-output.tgz" | Should -Exist
            $PD.NewVersionByDirectory.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
        Context 'Auto-versioning' {
            It 'creates a new version with version specified' {
                $SpecifiedVersion = '1.0.0'
                $TestParams = @{
                    'EdgeWorkerID'  = $PD.NewEdgeWorker.edgeWorkerId
                    'CodeDirectory' = $TestEdgeWorkerDirectory
                    'Version'       = $SpecifiedVersion
                }
                $Result = New-EdgeWorkerVersion @TestParams @CommonParams
                $Result.Version | Should -Be '1.0.0'
            }
            It 'creates a new version with major auto-increment' {
                $TestParams = @{
                    'EdgeWorkerID'  = $PD.NewEdgeWorker.edgeWorkerId
                    'CodeDirectory' = $TestEdgeWorkerDirectory
                    'Version'       = $SpecifiedVersion
                    'Major'         = $true
                }
                $Result = New-EdgeWorkerVersion @TestParams @CommonParams
                $Result.Version | Should -Be '2.0.0'
            }
            It 'creates a new version with minor auto-increment' {
                $TestParams = @{
                    'EdgeWorkerID'  = $PD.NewEdgeWorker.edgeWorkerId
                    'CodeDirectory' = $TestEdgeWorkerDirectory
                    'Version'       = $SpecifiedVersion
                    'Minor'         = $true
                }
                $Result = New-EdgeWorkerVersion @TestParams @CommonParams
                $Result.Version | Should -Be '2.1.0'
            }
            It 'creates a new version with patch auto-increment, and updates description' {
                $TestParams = @{
                    'EdgeWorkerID'  = $PD.NewEdgeWorker.edgeWorkerId
                    'CodeDirectory' = $TestEdgeWorkerDirectory
                    'Version'       = $SpecifiedVersion
                    'Patch'         = $true
                    'Description'   = 'Pester update'
                }
                $Result = New-EdgeWorkerVersion @TestParams @CommonParams
                $Result.Version | Should -Be '2.1.1'
                Get-Content -Raw "$TestEdgeWorkerDirectory/bundle.json" | ConvertFrom-Json | Select-Object -ExpandProperty description | Should -Be 'Pester update'
            }
        }
    }

    Context 'Get-EdgeWorkerCodeBundle' {
        It 'should download a file' {
            $BundleFile = [System.Io.Path]::GetTempFileName()
            $TestParams = @{
                'EdgeWorkerName' = $TestEdgeWorkerName
                'Version'        = 'latest'
                'OutputFile'     = $BundleFile
            }
            Get-EdgeWorkerCodeBundle @TestParams @CommonParams
            $BundleFile | Should -Exist
        }
        It 'should download a bundle and extract it into a directory' {
            $BundleFolderPath = [System.Io.Path]::GetTempFileName()
            Remove-Item -Path $BundleFolderPath -Force
            $TestParams = @{
                'ItemType' = 'Directory'
                'Path'     = $BundleFolderPath
            }
            $BundleFolder = New-Item @TestParams
            $TestParams = @{
                'EdgeWorkerName'  = $TestEdgeWorkerName
                'Version'         = 'latest'
                'OutputDirectory' = $BundleFolder
            }
            Get-EdgeWorkerCodeBundle @TestParams @CommonParams
            "$BundleFolder/bundle.json" | Should -Exist
        }
    }

    Context 'Remove-EdgeWorkerVersion' {
        It 'completes successfully by pipeline' {
            $PD.NewVersionByDirectory | Remove-EdgeWorkerVersion @CommonParams 
            # Allow remove command to finish
            Start-Sleep -Seconds 10
        }
        Context 'Mocked tests' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-EdgeWorkerVersion.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'completes successfully by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.NewVersionByDirectory.edgeWorkerId
                    'Version'      = $PD.NewVersionByDirectory.version
                }
                Remove-EdgeWorkerVersion @TestParams @CommonParams 
            }
            It 'handles empty input' {
                $Result = & {} | Remove-EdgeWorkerVersion @CommonParams
                $Result | Should -Not -Be 'IAR executed'
            }
        }
    }

    Context 'Get-EdgeWorkerVersion' {
        It 'gets a list of versions by param' {
            $TestParams = @{
                'EdgeWorkerName' = $TestEdgeworkerName
            }
            $PD.VersionsByName = Get-EdgeWorkerVersion @TestParams @CommonParams
            $PD.VersionsByName[0].edgeWorkerId | Should -Not -BeNullOrEmpty
        }
        It 'gets a list of versions by pipeline' {
            $PD.VersionsByID = $PD.EdgeWorker | Get-EdgeWorkerVersion @CommonParams
            $PD.VersionsByID[0].edgeWorkerId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific version by name and version' {
            $TestParams = @{
                'EdgeWorkerName' = $TestEdgeworkerName
                'Version'        = $TestEdgeWorkerVersion
            }
            $PD.VersionByName = Get-EdgeWorkerVersion @TestParams @CommonParams
            $PD.VersionByName.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
        }
        It 'gets a specific version by ID and version' {
            $PD.VersionByID = $PD.NewVersionByBundle | Get-EdgeWorkerVersion @CommonParams
            $PD.VersionByID.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
            $PD.VersionByID.version | Should -Be $PD.NewVersionByBundle.version
        }
    }

    # Context 'Expand-EdgeWorkerDetails' {
    #     BeforeAll {
    #         . $PSScriptRoot/../src/Akamai.EdgeWorkers/Functions/Private/Expand-EdgeWorkerDetails.ps1

    #         $PreviousOptionsPath = $env:AkamaiOptionsPath
    #         $env:AkamaiOptionsPath = "TestDrive:/options.json"
    #         # Creat options
    #         New-AkamaiOptions
    #         # Enable data cache
    #         Set-AkamaiOptions -EnableDataCache $true | Out-Null
    #         Clear-AkamaiDataCache
    #     }
    #     It 'finds the right EdgeWorker' {
    #         $TestParams = @{
    #             'EdgeWorkerName' = $TestEdgeworkerName
    #         }
    #         $PD.ExpandedID, $null, $null, $null = Expand-EdgeWorkerDetails @TestParams @CommonParams
    #         $PD.ExpandedID | Should -Be $PD.NewEdgeWorker.edgeWorkerId
    #         $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$TestEdgeworkerName.EdgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
    #     }
    #     It 'throws when EdgeWorker does not exist' {
    #         $TestParams = @{
    #             'EdgeWorkerName' = 'ew-which-does-not-exist'
    #         }
    #         { Expand-EdgeWorkerDetails @TestParams @CommonParams } | Should -Throw 'EdgeWorker * not found.'
    #     }
    #     It 'finds the latest version' {
    #         $TestParams = @{
    #             'EdgeWorkerName' = $TestEdgeworkerName
    #             'Version'        = 'latest'
    #         }
    #         $PD.ExpandedID, $Version, $null, $null = Expand-EdgeWorkerDetails @TestParams @CommonParams
    #         $PD.ExpandedID | Should -Be $PD.NewEdgeWorker.edgeWorkerId
    #         $Version | Should -Be '2.1.1'
    #         $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$TestEdgeworkerName.EdgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
    #     }
    #     It 'finds the staging version of existing EW' {
    #         $TestParams = @{
    #             'EdgeWorkerName' = 'pester'
    #             'Version'        = 'staging'
    #         }
    #         Expand-EdgeWorkerDetails @TestParams @CommonParams
    #     }
    #     It 'finds the production version of existing EW' {
    #         $TestParams = @{
    #             'EdgeWorkerName' = 'pester'
    #             'Version'        = 'production'
    #         }
    #         Expand-EdgeWorkerDetails @TestParams @CommonParams
    #     }
    #     It 'throws when there is no production version' {
    #         $TestParams = @{
    #             'EdgeWorkerName' = $TestEdgeworkerName
    #             'Version'        = 'production'
    #         }
    #         { Expand-EdgeWorkerDetails @TestParams @CommonParams } | Should -Throw 'No production-active version of EdgeWorker *'
    #     }
    #     It 'throws when there is no staging version' {
    #         $TestParams = @{
    #             'EdgeWorkerName' = $TestEdgeworkerName
    #             'Version'        = 'staging'
    #         }
    #         { Expand-EdgeWorkerDetails @TestParams @CommonParams } | Should -Throw 'No staging-active version of EdgeWorker *'
    #     }
    #     AfterAll {
    #         Remove-Item -Path $env:AkamaiOptionsPath -Force
    #         $env:AkamaiOptionsPath = $PreviousOptionsPath
    #         Clear-AkamaiDataCache

    #         Remove-Item -Path Function:/Expand-EdgeWorkerDetails -Force
    #     }
    # }

    Context 'Activations' {
        Context 'New-EdgeWorkerActivation' {
            It 'returns valid response by pipeline' {
                $PD.ProductionActivation = $PD.NewVersionByBundle | New-EdgeWorkerActivation -Network PRODUCTION @CommonParams
                $PD.ProductionActivation.edgeWorkerId | Should -Not -BeNullOrEmpty
            }
            It 'returns valid response by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.NewVersionByBundle.edgeWorkerId
                    'Version'      = $PD.NewVersionByBundle.version
                    'Network'      = 'STAGING'
                }
                $PD.StagingActivation = New-EdgeWorkerActivation @TestParams @CommonParams
                $PD.StagingActivation.edgeWorkerId | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get-EdgeWorkerActivation' {
            Context 'All' {
                It 'gets a list by param' {
                    $TestParams = @{
                        'EdgeWorkerID' = $PD.NewVersionByBundle.edgeWorkerId
                        'Version'      = $PD.NewVersionByBundle.version
                    }
                    $PD.Activations = Get-EdgeWorkerActivation @TestParams @CommonParams
                    $PD.Activations[0].activationId | Should -Not -BeNullOrEmpty
                }
                It 'gets a list by pipeline' {
                    $Activations = $PD.VersionByID | Get-EdgeWorkerActivation @CommonParams
                    $Activations[0].activationId | Should -Not -BeNullOrEmpty
                }
            }
            Context 'Single' {
                It 'gets a single activation by ID by param' {
                    $TestParams = @{
                        'EdgeWorkerID' = $PD.NewVersionByBundle.edgeWorkerId
                        'ActivationID' = $PD.Activations[0].activationId
                    }
                    $PD.Activation = Get-EdgeWorkerActivation @TestParams @CommonParams
                    $PD.Activation.edgeWorkerId | Should -Not -BeNullOrEmpty
                }
                It 'gets a single activation by ID by pipeline' {
                    $TestParams = @{
                        'ActivationID' = $PD.Activations[0].activationId
                    }
                    $PD.Activation = $PD.VersionByID | Get-EdgeWorkerActivation @TestParams @CommonParams
                    $PD.Activation.edgeWorkerId | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context 'Remove-EdgeworkerActivation' {
            It 'removes an activation by pipeline' {
                $ActivationCancellation = $PD.StagingActivation | Remove-EdgeWorkerActivation @CommonParams
                $ActivationCancellation.edgeWorkerId | Should -Not -BeNullOrEmpty
            }
            It 'removes an activation by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.ProductionActivation.edgeWorkerId
                    'ActivationID' = $PD.ProductionActivation.activationId
                }
                $ActivationCancellation = Remove-EdgeWorkerActivation @TestParams @CommonParams
                $ActivationCancellation.edgeWorkerId | Should -Not -BeNullOrEmpty
            }
            Context 'Empty input' {
                BeforeAll {
                    Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                        return 'IAR executed'
                    }
                }
                It 'handles empty input' {
                    $Result = & {} | Remove-EdgeWorkerActivation
                    $Result | Should -Not -Be 'IAR executed'
                }
            }
        }
    }

    Context 'Logging' {
        Context 'New-EdgeWorkerLoggingOverride' {
            BeforeEach {
                $LogLevel = 'DEBUG'
                $TestParams = @{
                    'Network' = 'STAGING'
                    'Level'   = $LogLevel
                }
            }
            It 'adds a logging override in the right format by pipeline' {
                $PD.NewLoggingOverride = $PD.EdgeWorker | New-EdgeWorkerLoggingOverride @TestParams @CommonParams
                $PD.NewLoggingOverride.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
                $PD.NewLoggingOverride.network | Should -Be 'STAGING'
                $PD.NewLoggingOverride.level | Should -Be 'DEBUG'
            }
            Context 'Mocked' {
                BeforeAll {
                    Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                        $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeWorkerLoggingOverride.json"
                        return $Response | ConvertFrom-Json
                    }
                }
                BeforeEach {
                    $LogLevel = 'DEBUG'
                    $TestParams = @{
                        'Network' = 'STAGING'
                        'Level'   = $LogLevel
                    }
                }
                It 'adds a logging override in the right format by param' {
                    $TestParams.'EdgeWorkerID' = $PD.NewEdgeWorker.edgeWorkerId
                    $NewLoggingOverride = New-EdgeWorkerLoggingOverride @TestParams @CommonParams
                    $NewLoggingOverride.edgeWorkerId | Should -Be 42
                    $NewLoggingOverride.network | Should -Be 'PRODUCTION'
                    $NewLoggingOverride.level | Should -Be 'DEBUG'
                }
            }
        }

        Context 'Get-EdgeWorkerLoggingOverride' {
            It 'lists logging overrides by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.NewEdgeWorker.edgeWorkerId
                }
                $LoggingOverrides = Get-EdgeWorkerLoggingOverride @TestParams @CommonParams
                $LoggingOverrides[0].edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
                $LoggingOverrides[0].network | Should -Not -BeNullOrEmpty
                $LoggingOverrides[0].level | Should -Not -BeNullOrEmpty
            }
            It 'lists logging overrides by pipeline' {
                $PD.LoggingOverrides = $PD.EdgeWorker | Get-EdgeWorkerLoggingOverride @CommonParams
                $PD.LoggingOverrides[0].edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
                $PD.LoggingOverrides[0].network | Should -Not -BeNullOrEmpty
                $PD.LoggingOverrides[0].level | Should -Not -BeNullOrEmpty
            }

            It 'retrieves a single logging overrides' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.NewEdgeWorker.edgeWorkerId
                    'LoggingID'    = $PD.LoggingOverrides[0].loggingId
                }
                $PD.LoggingOverride = Get-EdgeWorkerLoggingOverride @TestParams @CommonParams
                $PD.LoggingOverride.edgeWorkerId | Should -Be $PD.NewEdgeWorker.edgeWorkerId
                $PD.LoggingOverride.network | Should -Be $PD.LoggingOverrides[0].network
                $PD.LoggingOverride.level | Should -Be $PD.LoggingOverrides[0].level
            }
        }
    }

    Context 'New-EdgeWorkerDeactivation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeWorkerDeactivation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'creates a deactivation by pipeline' {
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $DeactivationResult = $PD.NewVersionByBundle | New-EdgeWorkerDeactivation @TestParams
            $DeactivationResult.edgeWorkerId | Should -Not -BeNullOrEmpty
        }
        It 'creates a deactivation by param' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.NewVersionByBundle.edgeWorkerId
                'Version'      = $PD.NewVersionByBundle.version
                'Network'      = 'STAGING'
            }
            $DeactivationResult = New-EdgeWorkerDeactivation @TestParams
            $DeactivationResult.edgeWorkerId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerDeactivation' {
        Context 'All' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerDeactivation_1.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets a list of deactivations by pipeline' {
                $Deactivations = $PD.VersionByID | Get-EdgeWorkerDeactivation
                $Deactivations[0].deactivationId | Should -Not -BeNullOrEmpty
            }
            It 'gets a list of deactivations by param' {
                $TestParams = @{
                    'EdgeWorkerID' = 12345
                    'Version'      = '0.0.1'
                }
                $Deactivations = Get-EdgeWorkerDeactivation @TestParams
                $Deactivations[0].deactivationId | Should -Not -BeNullOrEmpty
            }
    
        }
        Context 'Single' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerDeactivation.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'get a single deactivation by ID by pipeline' {
                $TestParams = @{
                    'DeactivationID' = 1
                }
                $Deactivation = $PD.EdgeWorker | Get-EdgeWorkerDeactivation @TestParams
                $Deactivation.edgeWorkerId | Should -Not -BeNullOrEmpty
            }
            It 'get a single deactivation by ID by param' {
                $TestParams = @{
                    'EdgeWorkerID'   = 12345
                    'DeactivationID' = 1
                }
                $Deactivation = Get-EdgeWorkerDeactivation @TestParams
                $Deactivation.edgeWorkerId | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Undo-EdgeWorkerActivation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Undo-EdgeWorkerActivation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'rolls back to the previous version by parameter (Mocked)' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.NewVersionByBundle.edgeWorkerId
                'Network'      = 'STAGING'
            }
            $RollbackResult = Undo-EdgeWorkerActivation @TestParams
            $RollbackResult.edgeWorkerId | Should -Not -BeNullOrEmpty
            $RollbackResult.activationId | Should -Not -BeNullOrEmpty
        }
        It 'rolls back to the previous version by pipeline (Mocked)' {
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $RollbackResult = $PD.NewVersionByBundle | Undo-EdgeWorkerActivation @TestParams
            $RollbackResult.edgeWorkerId | Should -Not -BeNullOrEmpty
            $RollbackResult.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerProperties' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerProperties.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns valid response by pipeline' {
            $Properties = $PD.EdgeWorker | Get-EdgeWorkerProperties
            $Properties.count | Should -Not -Be 0
        }
        It 'returns valid response by param' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
            }
            $Properties = Get-EdgeWorkerProperties @TestParams
            $Properties.count | Should -Not -Be 0
        }
    }

    Context 'New-EdgeWorkerAuthToken' {
        It 'returns valid response' {
            $TestParams = @{
                'Hostnames' = $TestHostname
                'Expiry'    = 60
            }
            $NewToken = New-EdgeWorkerAuthToken @TestParams @CommonParams
            $NewToken | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeWorkerRevision' {
        Context 'All' {
            It 'gets a list of revisions by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
                }
                $PD.Revisions = Get-EdgeWorkerRevision @TestParams @CommonParams
                $PD.Revisions[1].revisionId | Should -Not -BeNullOrEmpty
            }
            It 'gets a list of revisions by pipeline' {
                $Revisions = $PD.EdgeWorker | Get-EdgeWorkerRevision @CommonParams
                $Revisions[1].revisionId | Should -Not -BeNullOrEmpty
            }
        }
        Context 'Single' {
            It 'gets a single revision by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
                    'RevisionID'   = $PD.Revisions[1].revisionId
                }
                $PD.Revision = Get-EdgeWorkerRevision @TestParams @CommonParams
                $PD.Revision.revisionId | Should -Not -BeNullOrEmpty
            }
            It 'gets a single revision by pipeline' {
                $Revision = $PD.Revisions[1] | Get-EdgeWorkerRevision @CommonParams
                $Revision.revisionId | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context 'Get-EdgeWorkerRevisionBom' {
        It 'gets the BOM by pipeline' {
            $Bom = $PD.Revision | Get-EdgeWorkerRevisionBom @CommonParams
            $Bom.edgeWorkerId | Should -Be $PD.EdgeWorker.edgeWorkerId
            $Bom.dependencies.'child'.edgeWorkerId | Should -Be $ExistingEdgeWorker.edgeWorkerId
        }
        It 'gets the BOM by param' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
                'RevisionID'   = $PD.Revision.revisionId
            }
            $Bom = Get-EdgeWorkerRevisionBom @TestParams @CommonParams
            $Bom.edgeWorkerId | Should -Be $PD.EdgeWorker.edgeWorkerId
            $Bom.dependencies.'child'.edgeWorkerId | Should -Be $ExistingEdgeWorker.edgeWorkerId
        }
    }

    Context 'Get-EdgeWorkerRevisionCodeBundle' {
        It 'gets a code bundle to tgz file by parameter' {
            $OutputFile = 'TestDrive:/revision-codebundle-param.tgz'
            $TestParams = @{
                'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
                'RevisionID'   = $PD.Revision.revisionId
                'OutputFile'   = $OutputFile
            }
            Get-EdgeWorkerRevisionCodeBundle @TestParams @CommonParams
            $OutputFile | Should -Exist
        }
        It 'gets a code bundle to tgz file by pipeline' {
            $OutputFile = 'TestDrive:/revision-codebundle-pipeline.tgz'
            $TestParams = @{
                'OutputFile' = $OutputFile
            }
            $PD.Revision | Get-EdgeWorkerRevisionCodeBundle @TestParams @CommonParams
            $OutputFile | Should -Exist
        }
        It 'gets a code bundle to directory by parameter' {
            $TempDirectory = [System.Io.Path]::GetTempFileName()
            Remove-Item -Path $TempDirectory -Force
            $OutputDirectory = New-Item -Path $TempDirectory -ItemType Directory
            $TestParams = @{
                'EdgeWorkerID'    = $PD.EdgeWorker.edgeWorkerId
                'RevisionID'      = $PD.Revision.revisionId
                'OutputDirectory' = $OutputDirectory
            }
            Get-EdgeWorkerRevisionCodeBundle @TestParams @CommonParams
            "$OutputDirectory/dependencies" | Should -Exist
        }
        It 'gets a code bundle to directory by pipeline' {
            $TempDirectory = [System.Io.Path]::GetTempFileName()
            Remove-Item -Path $TempDirectory -Force
            $OutputDirectory = New-Item -Path $TempDirectory -ItemType Directory
            $TestParams = @{
                'OutputDirectory' = $OutputDirectory
            }
            $PD.Revision | Get-EdgeWorkerRevisionCodeBundle @TestParams @CommonParams
            "$OutputDirectory/dependencies" | Should -Exist
        }
    }
    
    Context 'Compare-EdgeWorkerRevision' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Compare-EdgeWorkerRevision.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets a comparison by pipeline' {
            $TestParams = @{
                'ComparisonRevisionID' = $PD.Revisions[0].revisionId
            }
            $Comparison = $PD.Revision | Compare-EdgeWorkerRevision @TestParams @CommonParams
            $Comparison.dependencies.'redirect-geo-query'.diff | Should -Not -BeNullOrEmpty
        }
        It 'gets a comparison by param' {
            $TestParams = @{
                'EdgeWorkerID'         = $PD.EdgeWorker.edgeWorkerId
                'RevisionID'           = $PD.Revision.revisionId
                'ComparisonRevisionID' = $PD.Revisions[0].revisionId
            }
            $Comparison = Compare-EdgeWorkerRevision @TestParams @CommonParams
            $Comparison.dependencies.'redirect-geo-query'.diff | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-EdgeWorkerRevision' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-EdgeWorkerRevision.json"
                return $Response | ConvertFrom-Json
            }
        }
        Context 'Pin' {
            It 'pins correctly by pipeline' {
                $TestParams = @{
                    'Operation' = 'pin'
                    'Note'      = 'Pin it'
                }
                $Pin = $PD.Revision | Set-EdgeWorkerRevision @TestParams @CommonParams
                $Pin.pinNote | Should -Not -BeNullOrEmpty
            }
            It 'pins correctly by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
                    'RevisionID'   = $PD.Revision.revisionId
                    'Operation'    = 'pin'
                    'Note'         = 'Pin it'
                }
                $Pin = Set-EdgeWorkerRevision @TestParams @CommonParams
                $Pin.pinNote | Should -Not -BeNullOrEmpty
            }
        }
        Context 'Unpin' {
            It 'unpins correctly by pipeline' {
                $TestParams = @{
                    'Operation' = 'unpin'
                    'Note'      = 'Unpin it'
                }
                $UnPin = $PD.Revision | Set-EdgeWorkerRevision @TestParams @CommonParams
                $UnPin.pinNote | Should -Not -BeNullOrEmpty # Nock body assumes pinning, rather than unpinning
            }
            It 'unpins correctly by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
                    'RevisionID'   = $PD.Revision.revisionId
                    'Operation'    = 'unpin'
                    'Note'         = 'Unpin it'
                }
                $UnPin = Set-EdgeWorkerRevision @TestParams @CommonParams
                $UnPin.pinNote | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context 'New-EdgeWorkerRevisionActivation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeWorkerRevisionActivation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'activates correctly by pipeline' {
            $RevisionActivation = $PD.Revision | New-EdgeWorkerRevisionActivation
            $RevisionActivation.activationId | Should -Not -BeNullOrEmpty
        }
        It 'activates correctly by param' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.EdgeWorker.edgeWorkerId
                'RevisionID'   = $PD.Revision.revisionId
            }
            $RevisionActivation = New-EdgeWorkerRevisionActivation @TestParams
            $RevisionActivation.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-EdgeworkerRevisionActivation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-EdgeWorkerRevisionActivation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets a list of revision activations by pipeline' {
            $RevisionActivations = $PD.NewVersionByBundle | Get-EdgeWorkerRevisionActivation
            $RevisionActivations[0].activationId | Should -Not -BeNullOrEmpty
        }
        It 'gets a list of revision activations by param' {
            $TestParams = @{
                'EdgeWorkerID' = $PD.NewVersionByBundle.edgeWorkerId
                'Version'      = $PD.NewVersionByBundle.version
            }
            $RevisionActivations = Get-EdgeWorkerRevisionActivation @TestParams
            $RevisionActivations[0].activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-EdgeWorker' {
        BeforeAll {
            $Activations = $PD.NewVersionByBundle | Get-EdgeWorkerActivation @CommonParams
            while ('CANCELLING' -in $Activations.status) {
                Write-Warning "Delaying for 30s for pending activation cancellation"
                Start-Sleep -Seconds 30
                $Activations = $PD.NewVersionByBundle | Get-EdgeWorkerActivation @CommonParams
            }
        }
        It 'completes successfully by pipeline' {
            $PD.NewEdgeWorker | Remove-EdgeWorker @CommonParams 
        }
        Context 'Mocked tests' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.EdgeWorkers -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-EdgeWorker.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'completes successfully by param' {
                $TestParams = @{
                    'EdgeWorkerID' = $PD.NewEdgeWorker.edgeWorkerId
                }
                Remove-EdgeWorker @TestParams
            }
            It 'handles empty input' {
                $Result = & {} | Remove-EdgeWorker @CommonParams
                $Result | Should -Not -Be 'IAR executed'
            }
        }
    }
}