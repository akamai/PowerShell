BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.Property Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'

        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.Property'
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
        $TestContract = $env:PesterContractID
        $TestGroupName = $env:PesterGroupName
        $TestGroupID = $env:PesterGroupID
        $TestHostname = $env:PesterHostname
        $TestAdditionalHostname = "powershell-$timestamp.edgesuite.net"
        $TestProductName = 'Fresca'
        $TestRuleFormat = 'v2025-10-16'
        $TestPropertyPrefix = "powershell-property-$Timestamp"
        $TestExistingProperty = 'pester-ion'
        $TestExistingInclude = 'pester-include'
        $TestEdgeHostname = $env:PesterEdgeHostname
        $TestExistingProperty = 'pester-ion'
        $TestExistingInclude = 'pester-include'
        $TestEdgeHostname = $env:PesterEdgeHostname
        $TestNewTraditionalPropertyName = "$TestPropertyPrefix-traditional"
        $TestNewBucketPropertyName = "$TestPropertyPrefix-bucket"
        $TestClonePropertyName = "$TestPropertyPrefix-clone"
        $TestCopyPropertyName = "$TestPropertyPrefix-copy"
        $TestIncludeName = "powershell-include-$Timestamp"
        $TestCopyIncludeName = "$TestIncludeName-copy"
        $TestRuleName = "Test Rule"
        $TestRuleJSON = @"
{
    "name": "$TestRuleName",
    "children": [],
    "behaviors": [
        {
            "name": "gzipResponse",
            "options": {
                "behavior": "ORIGIN_RESPONSE"
            }
        }
    ],
    "criteria": [
        {
            "name": "fileExtension",
            "options": {
                "matchOperator": "IS_ONE_OF",
                "matchCaseSensitive": false,
                "values": [
                    "css"
                ]
            }
        }
    ],
    "criteriaMustSatisfy": "all",
    "comments": ""
}
"@
        $TestRule = $TestRuleJSON | ConvertFrom-Json
        $TestIncludeRule = $TestRuleJSON | ConvertFrom-Json
        $TestBulkActivateJSON = @"
{"defaultActivationSettings":{"acknowledgeAllWarnings":true,"useFastFallback":false,"fastPush":true,"notifyEmails":["you@example.com","them@example.com"]},"activatePropertyVersions":[{"propertyId":"prp_1","propertyVersion":2,"network":"STAGING","note":"Some activation note"},{"propertyId":"prp_15","propertyVersion":3,"network":"STAGING","note":"Sample activation","notifyEmails":["someoneElse@somewhere.com"]},{"propertyId":"prp_3","propertyVersion":11,"network":"PRODUCTION","acknowledgeAllWarnings":false,"note":"created by xyz","acknowledgeWarnings":["msg_123","msg_234"]}]}
"@
        $TestBulkPatchJSON = @"
{"patchPropertyVersions":[{"propertyId":"785068","propertyVersion":1,"patches":[{"op":"replace","path":"/rules/behaviors/0/options/hostname","value":"origin.example.com"}]},{"propertyId":"785069","propertyVersion":1,"patches":[{"op":"remove","path":"/rules/children/0"}]},{"propertyId":"785070","propertyVersion":1,"patches":[{"op":"add","path":"/rules/behaviors/1","value":{"name":"autoDomainValidation","options":{"autodv":""}}}]}]}
"@
        $TestBulkVersionJSON = @"
{"createPropertyVersions":[{"createFromVersion":1,"propertyId":"0001"},{"createFromVersion":9,"propertyId":"0002"}]}
"@
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Property"
        $PD = @{ }
    }

    AfterAll {
        Context 'Remove Created Properties' {
            Get-Property -GroupID $TestGroupID -ContractId $TestContract @CommonParams | Where-Object { $_.propertyName.StartsWith($TestPropertyPrefix) } | Remove-Property @CommonParams
        }
        Context 'Remove Created Includes' {
            Get-PropertyInclude -GroupID $TestGroupID -ContractId $TestContract @CommonParams | Where-Object { $_.includeName.StartsWith($TestIncludeName) } | Remove-PropertyInclude @CommonParams
        }
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'Get-AccountID' {
        It 'gets an account ID' {
            $PD.AccountID = Get-AccountID @CommonParams
            $PD.AccountID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-Contract' {
        It 'lists contracts' {
            $PD.Contracts = Get-PropertyContract @CommonParams
            $PD.Contracts[0].contractId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyBuild' {
        It 'gets build info' {
            $PD.Build = Get-PropertyBuild @CommonParams
            $PD.Build.coreVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-Product' {
        It 'lists products by parameter' {
            $TestParams = @{
                'ContractID' = $TestContract
            }
            $PD.Products = Get-Product @TestParams @CommonParams
            $PD.Products[0].productId | Should -Not -BeNullOrEmpty
        }
        It 'lists products by pipeline' {
            $Products = $TestContract | Get-Product @CommonParams
            $Products[0].productId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ProductUseCases' {
        It 'lists use cases for DD by parameter' {
            $TestParams = @{
                'ContractId' = $TestContract
                'ProductID'  = 'Download_Delivery'
            }
            $PD.ProductUseCases = Get-ProductUseCases @TestParams @CommonParams
            $PD.ProductUseCases[0].useCase | Should -Not -BeNullOrEmpty
        }
        It 'lists use cases for DD by pipeline' {
            $TestParams = @{
                'ContractId' = $TestContract
            }
            $ProductUseCases = 'Download_Delivery' | Get-ProductUseCases @TestParams @CommonParams
            $ProductUseCases[0].useCase | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Groups
    #-------------------------------------------------

    Context 'Get-Group' {
        It 'lists groups' {
            $PD.Groups = Get-Group @CommonParams
            $PD.Groups.count | Should -BeGreaterThan 0
        }
        It 'gets a group by ID by parameter' {
            $TestParams = @{
                'GroupID' = $TestGroupID
            }
            $PD.GroupByID = Get-Group @TestParams @CommonParams
            $PD.GroupByID | Should -Not -BeNullOrEmpty
        }
        It 'gets a group by ID by pipeline' {
            $GroupByID = $TestGroupID | Get-Group @CommonParams
            $GroupByID | Should -Not -BeNullOrEmpty
        }
        It 'gets a group by name' {
            $TestParams = @{
                'GroupName' = $TestGroup.groupName
            }
            $PD.GroupByName = Get-Group @TestParams @CommonParams
            $PD.GroupByName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-TopLevelGroup' {
        It 'lists groups' {
            $PD.TopLevelGroups = Get-TopLevelGroup @CommonParams
            $PD.TopLevelGroups[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                CP Codes
    #-------------------------------------------------

    Context 'Get-PropertyCPCode' {
        It 'gets a list of CP Codes' {
            $TestParams = @{
                'GroupId'    = $TestGroupID
                'ContractId' = $TestContract
            }
            $PD.CPCodes = Get-PropertyCPCode @TestParams @CommonParams
            $PD.CPCodes | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific CP Code by ID' {
            $TestParams = @{
                'CPCode'     = $PD.CPCodes[0].cpcodeId
                'GroupId'    = $TestGroupID
                'ContractId' = $TestContract
            }
            $PD.CPCode = Get-PropertyCPCode @TestParams @CommonParams
            $PD.CPCode | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Edge Hostnames
    #-------------------------------------------------

    Context 'Get-PropertyEdgeHostname' {
        It 'gets a list of edge hostnames' {
            $TestParams = @{
                'GroupId'    = $TestGroupID
                'ContractId' = $TestContract
            }
            $PD.EdgeHostnames = Get-PropertyEdgeHostname @TestParams @CommonParams
            $PD.EdgeHostnames | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific edge hostname by ID' {
            $TestParams = @{
                'EdgeHostnameID' = $PD.EdgeHostnames[0].EdgeHostnameId
                'GroupId'        = $TestGroupID
                'ContractId'     = $TestContract
            }
            $PD.EdgeHostname = Get-PropertyEdgeHostname @TestParams @CommonParams
            $PD.EdgeHostname | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Custom Behaviors
    #-------------------------------------------------

    Context 'Get-CustomBehavior' {
        It 'gets a list of custom behaviors' {
            $PD.CustomBehaviors = Get-CustomBehavior @CommonParams
            $PD.CustomBehaviors | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific custom behavior by ID by parameter' {
            $TestParams = @{
                'BehaviorId' = $PD.CustomBehaviors[0].behaviorId
            }
            $PD.CustomBehavior = Get-CustomBehavior @TestParams @CommonParams
            $PD.CustomBehavior | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific custom behavior by ID by pipeline' {
            $CustomBehavior = $PD.CustomBehaviors[0] | Get-CustomBehavior @CommonParams
            $CustomBehavior | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Client Settings
    #-------------------------------------------------

    Context 'Get-PropertyClientSettings' {
        It 'should not be null' {
            $PD.ClientSettings = Get-PropertyClientSettings @CommonParams
            $PD.ClientSettings | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-PropertyClientSettings' {
        It 'should not be null' {
            $TestParams = @{
                'RuleFormat'  = $PD.ClientSettings.ruleFormat
                'UsePrefixes' = $PD.ClientSettings.usePrefixes
            }
            $PD.SetClientSettings = Set-PropertyClientSettings @TestParams @CommonParams
            $PD.SetClientSettings.ruleFormat | Should -Be $PD.ClientSettings.ruleFormat
            $PD.SetClientSettings.usePrefixes | Should -Be $PD.ClientSettings.usePrefixes
        }
    }

    #-------------------------------------------------
    #                Property
    #-------------------------------------------------

    Context 'New-Property' -Tag 'New-Property' {
        BeforeAll {
            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = "TestDrive:/options.json"
            # Creat options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache
        }
        Context 'Traditional' {
            It 'creates a property' {
                # Create property
                $TestParams = @{
                    'Name'       = $TestNewTraditionalPropertyName
                    'ProductID'  = $TestProductName
                    'RuleFormat' = $TestRuleFormat
                    'GroupID'    = $TestGroupID
                    'ContractId' = $TestContract
                }
                $PD.NewPropertyTrad = New-Property @TestParams @CommonParams

                # Result checks
                $PD.NewPropertyTrad.propertyLink | Should -Not -BeNullOrEmpty
                $PD.NewPropertyTrad.propertyId | Should -Not -BeNullOrEmpty

                # Retrieve property and check
                $TestParams = @{
                    'PropertyID' = $PD.NewPropertyTrad.propertyId
                }
                $CreatedProperty = Get-Property @TestParams @CommonParams
                $TestParams = @{
                    'PropertyID' = $PD.NewPropertyTrad.propertyId
                }
                $CreatedProperty = Get-Property @TestParams @CommonParams
                $CreatedProperty.propertyName | Should -Be $TestNewTraditionalPropertyName
                $CreatedProperty.groupId | Should -Be $TestGroupID
                $CreatedProperty.contractId | Should -Be $TestContract

                # Update rules to confirm clone status later
                $RulesParams = @{
                    'PropertyID'      = $PD.NewPropertyTrad.propertyId
                    'PropertyVersion' = 1
                    'GroupID'         = $TestGroupID
                    'ContractId'      = $TestContract
                }
                $Rules = Get-PropertyRules @RulesParams @CommonParams
                $Rules.rules.behaviors[0].options | Add-Member -NotePropertyName 'hostname' -NotePropertyValue 'origin.example.com' -Force
                $Rules | Set-PropertyRules @RulesParams @CommonParams

                # Confirm data cache
                $AkamaiDataCache.Property.Properties.$TestNewTraditionalPropertyName.PropertyID | Should -Be $PD.NewPropertyTrad.propertyId
                $AkamaiDataCache.Property.Properties.$TestNewTraditionalPropertyName.ContractID | Should -Be $PD.NewPropertyTrad.contractId
                $AkamaiDataCache.Property.Properties.$TestNewTraditionalPropertyName.GroupID | Should -Be $PD.NewPropertyTrad.groupId
            }
        }
        Context 'Bucket' {
            It 'creates a property' {
                # Create property
                $TestParams = @{
                    'Name'              = $TestNewBucketPropertyName
                    'ProductID'         = $TestProductName
                    'RuleFormat'        = $TestRuleFormat
                    'UseHostnameBucket' = $true
                    'GroupID'           = $TestGroupID
                    'ContractId'        = $TestContract
                }
                $PD.NewPropertyBucket = New-Property @TestParams @CommonParams

                # Result tests
                $PD.NewPropertyBucket.propertyLink | Should -Not -BeNullOrEmpty
                $PD.NewPropertyBucket.propertyId | Should -Not -BeNullOrEmpty

                # Retrieve property and test
                $TestParams = @{
                    'PropertyID' = $PD.NewPropertyBucket.propertyId
                }
                $CreatedProperty = Get-Property @TestParams @CommonParams
                $TestParams = @{
                    'PropertyID' = $PD.NewPropertyBucket.propertyId
                }
                $CreatedProperty = Get-Property @TestParams @CommonParams
                $CreatedProperty.propertyName | Should -Be $TestNewBucketPropertyName
                $CreatedProperty.groupId | Should -Be $TestGroupID
                $CreatedProperty.contractId | Should -Be $TestContract
                $CreatedProperty.propertyType | Should -Be 'HOSTNAME_BUCKET'

                # Confirm data cache
                $AkamaiDataCache.Property.Properties.$TestNewBucketPropertyName.PropertyID | Should -Be $PD.NewPropertyBucket.propertyId
                $AkamaiDataCache.Property.Properties.$TestNewBucketPropertyName.ContractID | Should -Be $PD.NewPropertyBucket.contractId
                $AkamaiDataCache.Property.Properties.$TestNewBucketPropertyName.GroupID | Should -Be $PD.NewPropertyBucket.groupId
            }
        }
        Context 'Clone' {
            It 'creates a property' {
                # Create property
                $TestParams = @{
                    'Name'                 = $TestClonePropertyName
                    'ProductID'            = $TestProductName
                    'RuleFormat'           = $TestRuleFormat
                    'UseHostnameBucket'    = $true
                    'GroupID'              = $TestGroupID
                    'ContractId'           = $TestContract
                    'ClonePropertyName'    = $TestNewTraditionalPropertyName
                    'ClonePropertyVersion' = 1
                }
                $PD.NewPropertyClone = New-Property @TestParams @CommonParams

                # Result tests
                $PD.NewPropertyClone.propertyLink | Should -Not -BeNullOrEmpty
                $PD.NewPropertyClone.propertyId | Should -Not -BeNullOrEmpty

                # Retrieve property and test
                $TestParams = @{
                    'PropertyID' = $PD.NewPropertyClone.propertyId
                }
                $CreatedProperty = Get-Property @TestParams @CommonParams
                $CreatedProperty.propertyName | Should -Be $TestClonePropertyName
                $CreatedProperty.groupId | Should -Be $TestGroupID
                $CreatedProperty.contractId | Should -Be $TestContract

                # Pull rules to confirm clone was successful
                $RulesParams = @{
                    'PropertyID'      = $PD.NewPropertyClone.propertyId
                    'PropertyVersion' = 1
                    'GroupID'         = $TestGroupID
                    'ContractId'      = $TestContract
                }
                $Rules = Get-PropertyRules @RulesParams @CommonParams
                $Rules.rules.behaviors[0].options.hostname | Should -Be 'origin.example.com'

                # Confirm data cache
                $AkamaiDataCache.Property.Properties.$TestClonePropertyName.PropertyID | Should -Be $PD.NewPropertyClone.propertyId
                $AkamaiDataCache.Property.Properties.$TestClonePropertyName.ContractID | Should -Be $PD.NewPropertyClone.contractId
                $AkamaiDataCache.Property.Properties.$TestClonePropertyName.GroupID | Should -Be $PD.NewPropertyClone.groupId
            }
        }
        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache
        }
    }

    Context 'Get-Property' {
        It 'lists properties' {
            $TestParams = @{
                'GroupID'    = $TestGroupID
                'ContractId' = $TestContract
            }
            $PD.Properties = Get-Property @TestParams @CommonParams
            $PD.Properties.count | Should -BeGreaterThan 0
            $PD.Properties[0].propertyId | Should -Not -BeNullOrEmpty
        }
        It 'lists properties (pipeline)' {
            $PD.Properties = Get-Group @CommonParams | Select-Object -First 5 | Get-Property @CommonParams
            $PD.Properties.count | Should -BeGreaterThan 0
            $PD.Properties[0].propertyId | Should -Not -BeNullOrEmpty
        }
        It 'finds properties by name' {
            $TestParams = @{
                'PropertyName' = $TestExistingProperty
            }
            $PD.ExistingProperty = Get-Property @TestParams @CommonParams
            $PD.ExistingProperty.PropertyName | Should -Be $TestExistingProperty
        }
        It 'finds properties by ID' {
            $TestParams = @{
                'PropertyID' = $PD.NewPropertyTrad.propertyId
            }
            $PD.PropertyByID = Get-Property @TestParams @CommonParams
            $PD.PropertyByID.propertyId | Should -Be $PD.NewPropertyTrad.propertyId
        }
        It 'handles an empty property response' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                [PSCustomObject] @{ "properties" = [PSCustomObject] @{ "items" = @() } }
            }
            $TestParams = @{
                'GroupID'    = 123456
                'ContractId' = '1-2AB34C'
            }
            Get-Property @TestParams
        }
    }

    Context 'Find-Property' {
        It 'finds properties' {
            $TestParams = @{
                'PropertyName' = $TestNewTraditionalPropertyName
                'Latest'       = $true
            }
            $PD.FoundProperty = Find-Property @TestParams @CommonParams
            $PD.FoundProperty.PropertyName | Should -Be $TestNewTraditionalPropertyName
            $PD.FoundProperty.propertyId | Should -Not -BeNullOrEmpty
            $PD.FoundProperty.propertyVersion | Should -Not -BeNullOrEmpty
            $PD.FoundProperty.groupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Expand-PropertyDetails' -Tag 'Expand-PropertyDetails' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Property/Functions/Private/Expand-PropertyDetails.ps1

            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = "TestDrive:/options.json"
            # Creat options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache
        }
        It 'finds the latest property and version' {
            $TestParams = @{
                'PropertyName'    = $TestExistingProperty
                'PropertyVersion' = 'latest'
            }
            $PropertyID, $LatestPropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @TestParams @CommonParams
            $PropertyID | Should -Be $PD.ExistingProperty.propertyId
            $LatestPropertyVersion | Should -Be $PD.ExistingProperty.latestVersion
            $GroupID | Should -Be $PD.ExistingProperty.groupId
            $ContractID | Should -Be $PD.ExistingProperty.contractId

            $AkamaiDataCache.Property.Properties.$TestExistingProperty.PropertyID | Should -Be $PD.ExistingProperty.propertyId
            $AkamaiDataCache.Property.Properties.$TestExistingProperty.ContractID | Should -Be $ContractID
            $AkamaiDataCache.Property.Properties.$TestExistingProperty.GroupID | Should -Be $GroupID
        }
        It 'finds the production property and version' {
            $TestParams = @{
                'PropertyName'    = $TestExistingProperty
                'PropertyVersion' = 'production'
            }
            $PropertyID, $ProductionVersion, $GroupID, $ContractID = Expand-PropertyDetails @TestParams @CommonParams
            $PropertyID | Should -Be $PD.ExistingProperty.propertyId
            $ProductionVersion | Should -Be $PD.ExistingProperty.productionVersion
            $GroupID | Should -Be $PD.ExistingProperty.groupId
            $ContractID | Should -Be $PD.ExistingProperty.contractId

            $AkamaiDataCache.Property.Properties.$TestExistingProperty.PropertyID | Should -Be $PD.ExistingProperty.propertyId
            $AkamaiDataCache.Property.Properties.$TestExistingProperty.ContractID | Should -Be $ContractID
            $AkamaiDataCache.Property.Properties.$TestExistingProperty.GroupID | Should -Be $GroupID
        }
        It 'finds the staging property and version' {
            $TestParams = @{
                'PropertyName'    = $TestExistingProperty
                'PropertyVersion' = 'staging'
            }
            $PropertyID, $StagingVersion, $GroupID, $ContractID = Expand-PropertyDetails @TestParams @CommonParams
            $PropertyID | Should -Be $PD.ExistingProperty.propertyId
            $StagingVersion | Should -Be $PD.ExistingProperty.stagingVersion
            $GroupID | Should -Be $PD.ExistingProperty.groupId
            $ContractID | Should -Be $PD.ExistingProperty.contractId

            $AkamaiDataCache.Property.Properties.$TestExistingProperty.PropertyID | Should -Be $PD.ExistingProperty.propertyId
            $AkamaiDataCache.Property.Properties.$TestExistingProperty.ContractID | Should -Be $ContractID
            $AkamaiDataCache.Property.Properties.$TestExistingProperty.GroupID | Should -Be $GroupID
        }
        It 'throws when requesting a property which does not exist' {
            $TestParams = @{
                'PropertyName' = "some-random-property-which-doesnt-exist"
            }
            { Expand-PropertyDetails @TestParams @CommonParams } | Should -Throw 'Property * not found.'
        }
        It 'throws when requesting a production version but none exists' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'production'
            }
            { Expand-PropertyDetails @TestParams @CommonParams } | Should -Throw 'No production-active version of property*'
        }
        It 'throws when requesting a staging version but none exists' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'staging'
            }
            { Expand-PropertyDetails @TestParams @CommonParams } | Should -Throw 'No staging-active version of property*'
        }
        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache
            Remove-Item -Path Function:/Expand-PropertyDetails -Force
        }
    }

    #-------------------------------------------------
    #                Versions
    #-------------------------------------------------

    Context 'Get-PropertyVersion' {
        It 'lists versions by param' {
            $TestParams = @{
                'PropertyID' = $PD.NewPropertyTrad.propertyId
            }
            $PD.PropertyVersions = Get-PropertyVersion @TestParams @CommonParams
            $PD.PropertyVersions[0].propertyVersion | Should -Match '^[\d]+$'
            $PD.PropertyVersions[0].productionStatus | Should -Not -BeNullOrEmpty
            $PD.PropertyVersions[0].stagingStatus | Should -Not -BeNullOrEmpty
        }
        It 'lists versions by pipeline' {
            $PropertyVersions = $PD.NewPropertyTrad | Get-PropertyVersion @CommonParams
            $PropertyVersions[0].propertyVersion | Should -Match '^[\d]+$'
            $PropertyVersions[0].productionStatus | Should -Not -BeNullOrEmpty
            $PropertyVersions[0].stagingStatus | Should -Not -BeNullOrEmpty
        }
        It 'finds specified version by param' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 1
            }
            $PD.PropertyVersion = Get-PropertyVersion @TestParams @CommonParams
            $PD.PropertyVersion.propertyVersion | Should -Be 1
        }
        It 'finds specified version by pipeline' {
            $TestParams = @{
                'PropertyVersion' = 1
            }
            $PropertyVersion = $PD.NewPropertyTrad | Get-PropertyVersion @TestParams @CommonParams
            $PropertyVersion.propertyVersion | Should -Be 1
        }
        It 'finds "latest" version' {
            $TestParams = @{
                'PropertyID'      = $PD.ExistingProperty.propertyId
                'PropertyVersion' = 'latest'
            }
            $LatestVersion = Get-PropertyVersion @TestParams @CommonParams
            $LatestVersion.propertyVersion | Should -Be $PD.ExistingProperty.latestVersion
        }
        It 'finds "staging" version' {
            $TestParams = @{
                'PropertyID'      = $PD.ExistingProperty.propertyId
                'PropertyVersion' = 'staging'
            }
            $StagingVersion = Get-PropertyVersion @TestParams @CommonParams
            $StagingVersion.propertyVersion | Should -Be $PD.ExistingProperty.stagingVersion
        }
        It 'finds "production" version' {
            $TestParams = @{
                'PropertyID'      = $PD.ExistingProperty.propertyId
                'PropertyVersion' = 'production'
            }
            $ProductionVersion = Get-PropertyVersion @TestParams @CommonParams
            $ProductionVersion.propertyVersion | Should -Be $PD.ExistingProperty.productionVersion
        }
    }

    Context 'New-PropertyVersion' {
        It 'creates a version by param' {
            $TestParams = @{
                'PropertyID'        = $PD.NewPropertyTrad.propertyId
                'CreateFromVersion' = 'latest'
            }
            $NewPropertyVersion = New-PropertyVersion @TestParams @CommonParams
            $NewPropertyVersion.versionLink | Should -Not -BeNullOrEmpty
            $NewPropertyVersion.propertyVersion | Should -Match '[\d]+'
        }
        It 'creates a version by pipeline' {
            $PD.NewPropertyVersion = $PD.PropertyVersion | New-PropertyVersion @CommonParams
            $PD.NewPropertyVersion.versionLink | Should -Not -BeNullOrEmpty
            $PD.NewPropertyVersion.propertyVersion | Should -Match '[\d]+'
        }
    }

    #-------------------------------------------------
    #                Copy Property
    #-------------------------------------------------

    Context 'Copy-Property' -Tag 'Copy-Property' {
        It 'copies a property by parameter' {
            # Copy property
            $TestParams = @{
                'Name'                 = "$TestCopyPropertyName"
                'ProductID'            = $TestProductName
                'RuleFormat'           = $TestRuleFormat
                'UseHostnameBucket'    = $true
                'ClonePropertyID'      = $PD.PropertyByID.propertyId
                'ClonePropertyVersion' = 'latest'
                'GroupID'              = $TestGroupID
                'ContractID'           = $TestContract
            }
            $PD.CopyProperty = Copy-Property @TestParams @CommonParams

            # Result tests
            $PD.CopyProperty.propertyLink | Should -Not -BeNullOrEmpty
            $PD.CopyProperty.propertyId | Should -Not -BeNullOrEmpty
            # Retrieve property and test
            $TestParams = @{
                'PropertyID' = $PD.CopyProperty.propertyId
            }
            $CreatedProperty = Get-Property @TestParams @CommonParams
            $CreatedProperty.propertyName | Should -Be $TestCopyPropertyName
            $CreatedProperty.groupId | Should -Be $TestGroupID
            $CreatedProperty.contractId | Should -Be $TestContract

            # Pull rules to confirm clone was successful
            $RulesParams = @{
                'PropertyID'      = $PD.CopyProperty.propertyId
                'PropertyVersion' = 1
                'GroupID'         = $TestGroupID
                'ContractId'      = $TestContract
            }
            $Rules = Get-PropertyRules @RulesParams @CommonParams
            $Rules.rules.behaviors[0].options.hostname | Should -Be 'origin.example.com'

            # Confirm data cache
            $AkamaiDataCache.Property.Properties.$TestCopyPropertyName.PropertyID | Should -Be $PD.CopyProperty.propertyId
            $AkamaiDataCache.Property.Properties.$TestCopyPropertyName.ContractID | Should -Be $PD.CopyProperty.contractId
            $AkamaiDataCache.Property.Properties.$TestCopyPropertyName.GroupID | Should -Be $PD.CopyProperty.groupId
        }
        It 'copies a property by pipeline' {
            # Copy property
            $TestParams = @{
                'Name'              = "$TestCopyPropertyName-pipeline"
                'ProductID'         = $TestProductName
                'RuleFormat'        = $TestRuleFormat
                'UseHostnameBucket' = $true
            }
            $CopyProperty = $PD.NewPropertyVersion | Copy-Property @TestParams @CommonParams

            # Result tests
            $CopyProperty.propertyLink | Should -Not -BeNullOrEmpty
            $CopyProperty.propertyId | Should -Not -BeNullOrEmpty

            # Retrieve property and test
            $TestParams = @{
                'PropertyID' = $PD.CopyProperty.propertyId
            }
            $CreatedProperty = Get-Property @TestParams @CommonParams
            $CreatedProperty.propertyName | Should -Be $TestCopyPropertyName
            $CreatedProperty.groupId | Should -Be $TestGroupID
            $CreatedProperty.contractId | Should -Be $TestContract

            # Pull rules to confirm clone was successful
            $RulesParams = @{
                'PropertyID'      = $PD.CopyProperty.propertyId
                'PropertyVersion' = 1
                'GroupID'         = $TestGroupID
                'ContractId'      = $TestContract
            }
            $Rules = Get-PropertyRules @RulesParams @CommonParams
            $Rules.rules.behaviors[0].options.hostname | Should -Be 'origin.example.com'

            # Confirm data cache
            $AkamaiDataCache.Property.Properties.$TestCopyPropertyName.PropertyID | Should -Be $PD.CopyProperty.propertyId
            $AkamaiDataCache.Property.Properties.$TestCopyPropertyName.ContractID | Should -Be $PD.CopyProperty.contractId
            $AkamaiDataCache.Property.Properties.$TestCopyPropertyName.GroupID | Should -Be $PD.CopyProperty.groupId
        }
    }

    #-------------------------------------------------
    #                Rules
    #-------------------------------------------------


    Context 'Get-PropertyRules' {
        It 'returns rules object to object by param' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
            }
            $PD.Rules = Get-PropertyRules @TestParams @CommonParams
            $PD.Rules | Should -BeOfType [PSCustomObject]
            $PD.Rules.rules | Should -Not -BeNullOrEmpty
            $PD.Rules.propertyName | Should -Be $TestNewTraditionalPropertyName
        }
        It 'returns rules object to object by pipeline' {
            $Rules = $PD.NewPropertyVersion | Get-PropertyRules @CommonParams
            $Rules | Should -BeOfType [PSCustomObject]
            $Rules.rules | Should -Not -BeNullOrEmpty
            $Rules.propertyName | Should -Be $TestNewTraditionalPropertyName
        }
        It 'creates json file' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
                'OutputToFile'    = $true
                'OutputFileName'  = 'TestDrive:/rules.json'
            }
            Get-PropertyRules @TestParams @CommonParams
            'TestDrive:/rules.json' | Should -Exist
        }
        It 'creates json file without -OutputToFile param' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
                'OutputFileName'  = 'TestDrive:/rules2.json'
            }
            Get-PropertyRules @TestParams @CommonParams
            'TestDrive:/rules2.json' | Should -Exist
        }
        It 'fails without -Force if file exists' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
                'OutputToFile'    = $true
                'OutputFileName'  = 'TestDrive:/rules.json'
            }
            { Get-PropertyRules @TestParams @CommonParams } | Should -Throw
        }
        It 'creates snippet files' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
                'OutputSnippets'  = $true
                'OutputDirectory' = 'TestDrive:/snippets'
            }
            Get-PropertyRules @TestParams @CommonParams
            'TestDrive:/snippets/main.json' | Should -Exist
        }
        It 'creates snippet files without -OutputSnippets param' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
                'OutputDirectory' = 'TestDrive:/snippets2'
            }
            Get-PropertyRules @TestParams @CommonParams
            'TestDrive:/snippets2/main.json' | Should -Exist
        }
    }


    Context 'Get-PropertyRulesDigest' {
        It 'matches the expected format by parameter' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
            }
            $PD.Digest = Get-PropertyRulesDigest @TestParams @CommonParams
            $PD.Digest.length | Should -Be 42
            $PD.Digest | Should -Match '"[a-f0-9]{40}"'
        }
        It 'matches the expected format by pipeline' {
            $Digest = $PD.NewPropertyVersion | Get-PropertyRulesDigest @CommonParams
            $Digest.length | Should -Be 42
            $Digest | Should -Match '"[a-f0-9]{40}"'
        }
    }

    Context 'Merge-PropertyRules' {
        BeforeAll {
            Get-PropertyRules -PropertyName $TestNewTraditionalPropertyName -PropertyVersion latest -OutputSnippets -OutputDirectory TestDrive:/snippets @CommonParams
        }
        It 'creates expected json file' {
            Merge-PropertyRules -SourceDirectory TestDrive:/snippets -OutputToFile -OutputFileName TestDrive:/snippets.json
            'TestDrive:/snippets.json' | Should -Exist
        }
        It 'returns rules object' {
            $PD.MergedRules = Merge-PropertyRules -SourceDirectory TestDrive:/snippets
            $PD.MergedRules | Should -BeOfType [PSCustomObject]
            $PD.MergedRules.rules | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ChildRuleSnippet' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Property/Functions/Private/Get-ChildRuleSnippet.ps1
            . $PSScriptRoot/../src/Akamai.Property/Functions/Private/Format-FileName.ps1
        }
        It 'creates default rule json' {
            Get-ChildRuleSnippet -Rules $PD.MergedRules.rules -Path TestDrive:/ -CurrentDepth 0 -MaxDepth 0
            'TestDrive:/default.json' | Should -Exist
        }
        AfterAll {
            Remove-Item -Path Function:/Get-ChildRuleSnippet -Force
            Remove-Item -Path Function:/Format-FileName -Force
        }
    }

    Context 'Expand-ChildRuleSnippet' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Property/Functions/Private/Expand-ChildRuleSnippet.ps1

            Get-PropertyRules -PropertyName $TestNewTraditionalPropertyName -PropertyVersion latest -OutputSnippets -OutputDirectory TestDrive:/snippets @CommonParams
        }
        It 'returns the correct object format' {
            $Main = Get-Content TestDrive:/snippets/main.json | ConvertFrom-Json
            $ChildInclude = $Main.children[0]
            $PD.childrule = Expand-ChildRuleSnippet -Include $ChildInclude -Path TestDrive:/snippets -DefaultRuleDirectory snippets
            $PD.childrule.name | Should -Not -BeNullOrEmpty
            Should -ActualValue $PD.childrule.children -BeOfType 'Array'
            Should -ActualValue $PD.childrule.behaviors -BeOfType 'Array'
            Should -ActualValue $PD.childrule.criteria -BeOfType 'Array'
            $PD.childrule.criteriaMustSatisfy | Should -Not -BeNullOrEmpty
        }
        AfterAll {
            Remove-Item -Path Function:/Expand-ChildRuleSnippet -Force
        }
    }

    Context 'Set-PropertyRules' {
        BeforeAll {
            $GetRulesParams = @{
                'PropertyName'    = $TestExistingProperty
                'PropertyVersion' = 'latest'
                'OutputToFile'    = $true
                'OutputFileName'  = 'TestDrive:/rules.json'
                'OutputSnippets'  = $true
                'OutputDirectory' = 'TestDrive:/snippets'
                'PassThru'        = $true
            }
            $Rules = Get-PropertyRules @GetRulesParams @CommonParams
        }
        It 'updates by json file' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'InputFile'       = 'TestDrive:/rules.json'
            }
            $PD.RulesFromFile = Set-PropertyRules @TestParams @CommonParams
            $PD.RulesFromFile | Should -BeOfType PSCustomObject
            $PD.RulesFromFile.rules | Should -Not -BeNullOrEmpty
        }
        It 'updates by snippets' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'InputDirectory'  = 'TestDrive:/snippets'
            }
            $PD.RulesFromDir = Set-PropertyRules @TestParams @CommonParams
            $PD.RulesFromDir | Should -BeOfType PSCustomObject
            $PD.RulesFromDir.rules | Should -Not -BeNullOrEmpty
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
            }
            $PD.Rules = $Rules | Set-PropertyRules @TestParams @CommonParams
            $PD.Rules | Should -BeOfType PSCustomObject
            $PD.Rules.rules | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Hostnames
    #-------------------------------------------------

    Context 'Add-PropertyHostname' {
        It 'works via param' {
            $PD.HostnameToAdd = @{
                'cnameType' = "EDGE_HOSTNAME"
                'cnameFrom' = $TestAdditionalHostname
                'cnameTo'   = $TestEdgeHostname
            }
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = $PD.NewPropertyVersion.propertyVersion
                'NewHostnames'    = $PD.HostnameToAdd
            }
            $PD.AddPropertyHostnamesByParam = Add-PropertyHostname @TestParams @CommonParams
            $PD.AddPropertyHostnamesByParam | Should -Not -BeNullOrEmpty
        }
        It 'works via pipeline' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = $PD.NewPropertyVersion.propertyVersion
            }
            $PD.AddPropertyHostnamesByPipeline = @($PD.HostnameToAdd) | Add-PropertyHostname @TestParams @CommonParams
            $PD.AddPropertyHostnamesByPipeline | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyHostnames' {
        It 'gets a list of hostnames by parameter' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = $PD.NewPropertyVersion.propertyVersion
            }
            $PD.PropertyHostnames = Get-PropertyHostname @TestParams @CommonParams
            $PD.PropertyHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
            $PD.PropertyHostnames[0].cnameTo | Should -Not -BeNullOrEmpty
            $PD.PropertyHostnames[0].cnameType | Should -Not -BeNullOrEmpty
        }
        It 'gets a list of hostnames by pipeline' {
            $PropertyHostnames = $PD.NewPropertyVersion | Get-PropertyHostname @CommonParams
            $PropertyHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
            $PropertyHostnames[0].cnameTo | Should -Not -BeNullOrEmpty
            $PropertyHostnames[0].cnameType | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-HostnameAuditHistory' {
        It 'produces a list of updates by parameter' {
            $TestParams = @{
                'Hostname' = $TestHostname
            }
            $PD.HostnameHistory = Get-HostnameAuditHistory @TestParams @CommonParams
            $PD.HostnameHistory[0].cnameTo | Should -Be $TestEdgeHostname
            $PD.HostnameHistory[0].action | Should -Not -BeNullOrEmpty
        }
        It 'produces a list of updates by pipeline' {
            $HostnameHistory = $TestHostname | Get-HostnameAuditHistory @CommonParams
            $HostnameHistory[0].cnameTo | Should -Be $TestEdgeHostname
            $HostnameHistory[0].action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyCertificateChallenge' {
        It 'produces a list of DV challenges by parameter' {
            $TestParams = @{
                'CnamesFrom' = $TestHostname
            }
            $PD.CertChallenge = Get-PropertyCertificateChallenge @TestParams @CommonParams
            $PD.CertChallenge[0].cnameFrom | Should -Be $TestHostname
            $PD.CertChallenge[0].validationCname.hostname | Should -Be "_acme-challenge.$TestHostname"
        }
        It 'produces a list of DV challenges by pipeline' {
            $CertChallenge = $TestHostname | Get-PropertyCertificateChallenge @CommonParams
            $CertChallenge[0].cnameFrom | Should -Be $TestHostname
            $CertChallenge[0].validationCname.hostname | Should -Be "_acme-challenge.$TestHostname"
        }
    }

    Context 'Set-PropertyHostname' {
        It 'updates by pipeline' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = $PD.NewPropertyVersion.propertyVersion
            }
            $PD.SetPropertyHostnamesByPipeline = $PD.PropertyHostnames | Set-PropertyHostname @TestParams @CommonParams
            $PD.SetPropertyHostnamesByPipeline | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
                'Body'            = @($PD.PropertyHostnames)
            }
            $PD.PropertyHostnamesByParam = Set-PropertyHostname @TestParams @CommonParams
            $PD.PropertyHostnamesByParam | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-PropertyHostnames' {
        It 'removes successfully to return to previous numbers' {
            $TestParams = @{
                'PropertyName'      = $TestNewTraditionalPropertyName
                'PropertyVersion'   = $PD.NewPropertyVersion.propertyVersion
                'HostnamesToRemove' = $TestAdditionalHostname
            }
            $PD.PropertyHostnames = Remove-PropertyHostname @TestParams @CommonParams
            $PD.PropertyHostnames | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Rule Formats
    #-------------------------------------------------

    Context 'Get-RuleFormat' {
        It 'returns results' {
            $PD.RuleFormats = Get-RuleFormat @CommonParams
            $PD.RuleFormats | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-RuleFormatSchema' {
        It 'returns the correct data by parameter' {
            $TestParams = @{
                'ProductID'  = 'Fresca'
                'RuleFormat' = 'latest'
            }
            $PD.RuleFormat = Get-RuleFormatSchema @TestParams @CommonParams
            $PD.RuleFormat.properties | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $TestParams = @{
                'ProductID' = 'Fresca'
            }
            $RuleFormats = Get-RuleFormat @CommonParams | Get-RuleFormatSchema @TestParams @CommonParams
            $RuleFormats.properties | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyRequestSchema' {
        It 'returns the correct format' {
            $TestParams = @{
                'Filename' = 'CreateNewEdgeHostnameRequestV0.json'
            }
            $PD.RequestSchema = Get-PropertyRequestSchema @TestParams @CommonParams
            $PD.RequestSchema.description | Should -Not -BeNullOrEmpty
            $PD.RequestSchema.properties | Should -Not -BeNullOrEmpty
            $PD.RequestSchema.required | Should -Not -BeNullOrEmpty
            $PD.RequestSchema.id | Should -BeLike '*CreateNewEdgeHostnameRequestV0.json*'
        }
    }

    #-------------------------------------------------
    #                PATCH Rules
    #-------------------------------------------------

    Context 'Add-PropertyRule' {
        It 'adds a rule correctly' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'Path'            = "/rules/children/0"
                'Value'           = $TestRule
            }
            Add-PropertyRule @TestParams @CommonParams

            $GetParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
            }
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].name | Should -Be $TestRuleName
            $UpdatedRules.rules.children.count | Should -Be ($PD.Rules.rules.children.count + 1)
        }

        It 'adds a criterion correctly' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'Path'            = "/rules/children/0/criteria/0/options/values/1"
                'Value'           = "js"
            }
            Add-PropertyRule @TestParams @CommonParams

            $GetParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
            }
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].criteria[0].options.values | Should -Contain 'js'
            # Add additional criterion back to shared var
            $TestRule.criteria[0].options.values += 'js'
        }
    }

    Context 'Test-PropertyRule' {
        It 'throws no errors by parameter' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'Path'            = "/rules/children/0"
                'Value'           = $TestRule
            }
            Test-PropertyRule @TestParams @CommonParams
        }
        It 'throws no errors by pipeline' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'Path'            = "/rules/children/0"
            }
            $TestRule | Test-PropertyRule @TestParams @CommonParams
        }
        It 'throws an error for bad input' {
            $TestRule.Name = 'Bad Name'
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'Path'            = "/rules/children/0"
                'Value'           = $TestRule
            }
            { Test-PropertyRule @TestParams @CommonParams } | Should -Throw "*JSON Patch Invalid - value differs from expectations*"
        }
    }

    Context 'Update-PropertyRule' {
        It 'Updates correctly by parameter' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'Path'            = "/rules/children/0/name"
                'Value'           = "Updated name"
            }
            Update-PropertyRule @TestParams @CommonParams

            $GetParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
            }
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].name | Should -Be "Updated name"
        }
        It 'Updates correctly by pipeline' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'Path'            = "/rules/children/0/name"
            }
            "Even further updated value" | Update-PropertyRule @TestParams @CommonParams

            $GetParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
            }
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].name | Should -Be "Even further updated value"
        }
    }

    Context 'Remove-PropertyRule' {
        It 'Updates correctly' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
                'Path'            = "/rules/children/0"
            }
            Remove-PropertyRule @TestParams @CommonParams

            $GetParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
            }
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children.count | Should -Be $PD.Rules.rules.children.count
            $UpdatedRules.rules.children[0].Name | Should -Not -Be $TestRuleName
        }
    }

    #-------------------------------------------------
    #                Activate
    #-------------------------------------------------

    Context 'New-PropertyActivation' {
        It 'returns activationlink by parameter' {
            $TestParams = @{
                'PropertyName'    = $TestNewTraditionalPropertyName
                'PropertyVersion' = 'latest'
                'Network'         = 'Staging'
                'NotifyEmails'    = 'mail@example.com'
            }
            $PD.Activation = New-PropertyActivation @TestParams @CommonParams
            $PD.Activation.activationLink | Should -Not -BeNullOrEmpty
            $PD.Activation.activationId | Should -Not -BeNullOrEmpty
        }
        It 'returns activationlink by pipeline' {
            $TestParams = @{
                'Network'      = 'Staging'
                'NotifyEmails' = 'mail@example.com'
            }
            { $PD.NewPropertyVersion | New-PropertyActivation @TestParams @CommonParams } | Should -Throw '*Property version activation is still pending*'
        }
    }

    Context 'Get-PropertyActivation' {
        It 'finds the correct activation' {
            $TestParams = @{
                'PropertyName' = $TestNewTraditionalPropertyName
                'ActivationID' = $PD.Activation.activationId
            }
            $PD.ActivationResult = Get-PropertyActivation @TestParams @CommonParams
            $PD.ActivationResult.activationId | Should -Be $PD.Activation.activationId
        }
        It 'returns a list' {
            $TestParams = @{
                'PropertyName' = $TestNewTraditionalPropertyName
            }
            $PD.Activations = Get-PropertyActivation @TestParams @CommonParams
            $PD.Activations[0].activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Undo-PropertyActivation' {
        It 'cancels an activation by parameter' {
            $TestParams = @{
                'PropertyName' = $TestNewTraditionalPropertyName
                'ActivationID' = $PD.Activation.activationId
            }
            $PD.UndoActivation = Undo-PropertyActivation @TestParams @CommonParams
            $PD.UndoActivation.activationId | Should -Be $PD.Activation.activationId
            $PD.UndoActivation.status | Should -Be 'PENDING_CANCELLATION'
        }
        It 'cancels an activation by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Undo-PropertyActivation.json"
                return $Response | ConvertFrom-Json
            }

            $TestParams = @{
                'ActivationID' = $PD.Activation.activationId
            }
            $UndoActivation = $PD.PropertyByID | Undo-PropertyActivation @TestParams @CommonParams
            $UndoActivation.activationId | Should -Match '(atv_)?[0-9]+'
            $UndoActivation.status | Should -Be 'ABORTED'
        }
    }

    #-------------------------------------------------
    #                    Includes
    #-------------------------------------------------

    Context 'New-PropertyInclude' {
        It 'creates an include' {
            $TestParams = @{
                'Name'        = $TestIncludeName
                'ProductID'   = $TestProductName
                'RuleFormat'  = $TestRuleFormat
                'IncludeType' = 'MICROSERVICES'
                'ContractId'  = $TestContract
                'GroupID'     = $TestGroupID
            }
            $PD.NewInclude = New-PropertyInclude @TestParams @CommonParams
            $PD.NewInclude.includeLink | Should -Not -BeNullOrEmpty
            $PD.NewInclude.includeId | Should -Not -BeNullOrEmpty

            # Pause for a brief time to let the creation complete
            Start-Sleep -Seconds 15
        }
    }

    Context 'Get-PropertyInclude' {
        It 'gets a list of includes' {
            $TestParams = @{
                'GroupID'    = $TestGroupID
                'ContractId' = $TestContract
            }
            $PD.Includes = Get-PropertyInclude @TestParams @CommonParams
            $PD.Includes[0].includeId | Should -Not -BeNullOrEmpty
        }
        It 'gets an include by ID by param' {
            $TestParams = @{
                'IncludeID' = $PD.NewInclude.includeId
            }
            $PD.IncludeByID = Get-PropertyInclude @TestParams @CommonParams
            $PD.IncludeByID.includeName | Should -Be $TestIncludeName
        }
        It 'gets an include by ID by pipeline' {
            $Include = $PD.NewInclude | Get-PropertyInclude @CommonParams
            $Include.includeName | Should -Be $TestIncludeName
        }
        It 'gets an include by name' {
            $TestParams = @{
                'IncludeName' = $TestExistingInclude
            }
            $PD.ExistingInclude = Get-PropertyInclude @TestParams @CommonParams
            $PD.ExistingInclude.includeName | Should -Be $TestExistingInclude
        }
    }

    Context 'Expand-PropertyIncludeDetails' -Tag 'Expand-PropertyIncludeDetails' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Property/Functions/Private/Expand-PropertyIncludeDetails.ps1

            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = "TestDrive:/options.json"
            # Creat options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache
        }
        It 'finds the latest Include and version' {
            $TestParams = @{
                'IncludeName'    = $TestExistingInclude
                'IncludeVersion' = 'latest'
            }
            $IncludeID, $Version, $GroupID, $ContractID = Expand-PropertyIncludeDetails @TestParams @CommonParams
            $IncludeID | Should -Be $PD.ExistingInclude.IncludeId
            $Version | Should -Be $PD.ExistingInclude.latestVersion
            $GroupID | Should -Be $PD.ExistingInclude.groupId
            $ContractID | Should -Be $PD.ExistingInclude.contractId

            $AkamaiDataCache.Property.Includes.$TestExistingInclude.IncludeID | Should -Be $PD.ExistingInclude.IncludeId
            $AkamaiDataCache.Property.Includes.$TestExistingInclude.ContractID | Should -Be $ContractID
            $AkamaiDataCache.Property.Includes.$TestExistingInclude.GroupID | Should -Be $GroupID
        }
        It 'finds the production Include and version' {
            $TestParams = @{
                'IncludeName'    = $TestExistingInclude
                'IncludeVersion' = 'production'
            }
            $IncludeID, $ProductionVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @TestParams @CommonParams
            $IncludeID | Should -Be $PD.ExistingInclude.IncludeId
            $ProductionVersion | Should -Be $PD.ExistingInclude.productionVersion
            $GroupID | Should -Be $PD.ExistingInclude.groupId
            $ContractID | Should -Be $PD.ExistingInclude.contractId
        }
        It 'finds the staging Include and version' {
            $TestParams = @{
                'IncludeName'    = $TestExistingInclude
                'IncludeVersion' = 'staging'
            }
            $IncludeID, $StagingVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @TestParams @CommonParams
            $IncludeID | Should -Be $PD.ExistingInclude.IncludeId
            $StagingVersion | Should -Be $PD.ExistingInclude.stagingVersion
            $GroupID | Should -Be $PD.ExistingInclude.groupId
            $ContractID | Should -Be $PD.ExistingInclude.contractId
        }
        It 'throws when requesting a Include which does not exist' {
            $TestParams = @{
                'IncludeName' = "some-random-Include-which-doesnt-exist"
            }
            { Expand-PropertyIncludeDetails @TestParams @CommonParams } | Should -Throw 'Include * not found.'
        }
        It 'throws when requesting a production version but none exists' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.IncludeId
                'IncludeVersion' = 'production'
            }
            { Expand-PropertyIncludeDetails @TestParams @CommonParams } | Should -Throw 'No production-active version of Include*'
        }
        It 'throws when requesting a staging version but none exists' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.IncludeId
                'IncludeVersion' = 'staging'
            }
            { Expand-PropertyIncludeDetails @TestParams @CommonParams } | Should -Throw 'No staging-active version of Include*'
        }
        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache

            Remove-Item -Path Function:/Expand-PropertyIncludeDetails -Force
        }
    }

    Context 'Get-PropertyIncludeVersion' {
        It 'lists versions' {
            $TestParams = @{
                'IncludeId' = $PD.NewInclude.includeId
            }
            $PD.IncludeVersions = Get-PropertyIncludeVersion @TestParams @CommonParams
            $PD.IncludeVersions[0].includeVersion | Should -Match '^[\d]+$'
            $PD.IncludeVersions[0].productionStatus | Should -Not -BeNullOrEmpty
            $PD.IncludeVersions[0].stagingStatus | Should -Not -BeNullOrEmpty
        }
        It 'finds specified version' {
            $TestParams = @{
                'IncludeId'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
            }
            $PD.IncludeVersion = Get-PropertyIncludeVersion @TestParams @CommonParams
            $PD.IncludeVersion.includeVersion | Should -Be 1
        }
        It 'finds "latest" version' {
            $TestParams = @{
                'IncludeId'      = $PD.ExistingInclude.includeId
                'IncludeVersion' = 'latest'
            }
            $LatestVersion = Get-PropertyIncludeVersion @TestParams @CommonParams
            $LatestVersion.includeVersion | Should -Be $PD.ExistingInclude.latestVersion
        }
        It 'finds "staging" version' {
            $TestParams = @{
                'IncludeId'      = $PD.ExistingInclude.includeId
                'IncludeVersion' = 'staging'
            }
            $StagingVersion = Get-PropertyIncludeVersion @TestParams @CommonParams
            $StagingVersion.includeVersion | Should -Be $PD.ExistingInclude.stagingVersion
        }
        It 'finds "production" version' {
            $TestParams = @{
                'IncludeId'      = $PD.ExistingInclude.includeId
                'IncludeVersion' = 'production'
            }
            $ProductionVersion = Get-PropertyIncludeVersion @TestParams @CommonParams
            $ProductionVersion.includeVersion | Should -Be $PD.ExistingInclude.productionVersion
        }
    }

    Context 'Copy-PropertyInclude' -Tag 'Copy-PropertyInclude' {
        BeforeAll {
            # Update first include's rules so we can check the copy status
            $SourceRulesParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'GroupID'        = $TestGroupID
                'ContractId'     = $TestContract
            }
            $SourceRules = Get-PropertyIncludeRules @SourceRulesParams @CommonParams
            $SourceRules.rules.behaviors += @{
                'name'    = "denyAccess"
                'options' = @{
                    'reason'  = "pester test"
                    'enabled' = $true
                }
            }
            $SourceRules | Set-PropertyIncludeRules @SourceRulesParams @CommonParams
        }
        It 'copies an include by param' {
            $TestParams = @{
                'Name'                = $TestCopyIncludeName
                'ProductID'           = $TestProductName
                'RuleFormat'          = $TestRuleFormat
                'IncludeType'         = 'MICROSERVICES'
                'GroupID'             = $TestGroupID
                'ContractId'          = $TestContract
                'CloneIncludeName'    = $TestIncludeName
                'CloneIncludeVersion' = 'latest'
            }
            $PD.CopyInclude = Copy-PropertyInclude @TestParams @CommonParams

            # Result tests
            $PD.CopyInclude.includeLink | Should -Not -BeNullOrEmpty
            $PD.CopyInclude.includeId | Should -Not -BeNullOrEmpty

            # Retrieve property and test
            $TestParams = @{
                'IncludeID' = $PD.CopyInclude.includeId
            }
            $PD.CopiedInclude = Get-PropertyInclude @TestParams @CommonParams
            $PD.CopiedInclude.includeName | Should -Be $TestCopyIncludeName
            $PD.CopiedInclude.groupId | Should -Be $TestGroupID
            $PD.CopiedInclude.contractId | Should -Be $TestContract

            # Pull rules to confirm clone was successful
            $RulesParams = @{
                'IncludeID'      = $PD.CopyInclude.includeId
                'IncludeVersion' = 1
                'GroupID'        = $TestGroupID
                'ContractId'     = $TestContract
            }
            $Rules = Get-PropertyIncludeRules @RulesParams @CommonParams
            $Rules.rules.behaviors[0].options.reason | Should -Be 'pester test'

            # Confirm data cache
            $AkamaiDataCache.Property.Includes.$TestCopyIncludeName.IncludeID | Should -Be $PD.CopyInclude.includeId
            $AkamaiDataCache.Property.Includes.$TestCopyIncludeName.ContractID | Should -Be $PD.CopyInclude.contractId
            $AkamaiDataCache.Property.Includes.$TestCopyIncludeName.GroupID | Should -Be $PD.CopyInclude.group.id
        }
        It 'copies an include by pipeline' {
            $TestParams = @{
                'Name'        = "$TestCopyIncludeName-pipeline"
                'ProductID'   = $TestProductName
                'RuleFormat'  = $TestRuleFormat
                'IncludeType' = 'MICROSERVICES'
            }
            $CopyInclude = $PD.IncludeVersion | Copy-PropertyInclude @TestParams @CommonParams

            # Result tests
            $CopyInclude.includeLink | Should -Not -BeNullOrEmpty
            $CopyInclude.includeId | Should -Not -BeNullOrEmpty

            # Retrieve property and test
            $TestParams = @{
                'IncludeID' = $CopyInclude.includeId
            }
            $CopiedInclude = Get-PropertyInclude @TestParams @CommonParams
            $CopiedInclude.includeName | Should -Be "$TestCopyIncludeName-pipeline"
            $CopiedInclude.groupId | Should -Be $TestGroupID
            $CopiedInclude.contractId | Should -Be $TestContract

            # Pull rules to confirm clone was successful
            $RulesParams = @{
                'IncludeID'      = $CopiedInclude.includeId
                'IncludeVersion' = 1
                'GroupID'        = $TestGroupID
                'ContractId'     = $TestContract
            }
            $Rules = Get-PropertyIncludeRules @RulesParams @CommonParams
            $Rules.rules.behaviors[0].options.reason | Should -Be 'pester test'

            # Confirm data cache
            $AkamaiDataCache.Property.Includes.$TestCopyIncludeName.IncludeID | Should -Be $PD.CopyInclude.includeId
            $AkamaiDataCache.Property.Includes.$TestCopyIncludeName.ContractID | Should -Be $PD.CopyInclude.contractId
            $AkamaiDataCache.Property.Includes.$TestCopyIncludeName.GroupID | Should -Be $PD.CopyInclude.group.id
        }
    }

    Context 'New-PropertyIncludeVersion' {
        It 'creates a new version' {
            $TestParams = @{
                'IncludeID'         = $PD.NewInclude.includeId
                'CreateFromVersion' = 1
            }
            $PD.NewIncludeVersion = New-PropertyIncludeVersion @TestParams @CommonParams
            $PD.NewIncludeVersion.versionLink | Should -Not -BeNullOrEmpty
            $PD.NewIncludeVersion.includeVersion | Should -Match '[\d]+'
        }
    }

    Context 'Get-PropertyIncludeRules' {
        It 'gets rules to object by parameter' {
            $TestParams = @{
                'IncludeName'    = $TestIncludeName
                'IncludeVersion' = 1
            }
            $PD.IncludeRules = Get-PropertyIncludeRules @TestParams @CommonParams
            $PD.IncludeRules.includeName | Should -Be $TestIncludeName
            $PD.IncludeRules.rules | Should -Not -BeNullOrEmpty
        }
        It 'gets rules to object by pipeline' {
            $IncludeRules = $PD.IncludeVersion | Get-PropertyIncludeRules @CommonParams
            $IncludeRules.includeName | Should -Be $TestIncludeName
            $IncludeRules.rules | Should -Not -BeNullOrEmpty
        }
        It 'creates a json file' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'OutputToFile'   = $true
                'OutputFileName' = 'TestDrive:/includeRules.json'
            }
            Get-PropertyIncludeRules @testParams @CommonParams
            'TestDrive:/includeRules.json' | Should -Exist
        }
        It 'creates a json file without the OutputToFile param' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'OutputFileName' = 'TestDrive:/includeRules2.json'
            }
            Get-PropertyIncludeRules @testParams @CommonParams
            'TestDrive:/includeRules2.json' | Should -Exist
        }
        It 'creates snippet files' {
            $TestParams = @{
                'IncludeName'    = $TestIncludeName
                'IncludeVersion' = 'latest'
                'OutputSnippets' = $true
                'OutputDir'      = 'TestDrive:/includesnippets'
            }
            Get-PropertyIncludeRules @TestParams @CommonParams
            'TestDrive:/includesnippets/main.json' | Should -Exist
        }
        It 'creates snippet files without OutputSnippets param' {
            $TestParams = @{
                'IncludeName'    = $TestIncludeName
                'IncludeVersion' = 'latest'
                'OutputDir'      = 'TestDrive:/includesnippets2'
            }
            Get-PropertyIncludeRules @TestParams @CommonParams
            'TestDrive:/includesnippets2/main.json' | Should -Exist
        }
    }

    Context 'Set-PropertyIncludeRules by pipeline' {
        BeforeAll {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'OutputToFile'   = $true
                'OutputFileName' = 'TestDrive:/includeRules.json'
            }
            Get-PropertyIncludeRules @testParams @CommonParams
            Get-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion latest -OutputSnippets -OutputDir TestDrive:/includesnippets @CommonParams
        }
        It 'updates rules by pipeline' {
            $TestParams = @{
                'IncludeName'    = $TestIncludeName
                'IncludeVersion' = 1
            }
            $PD.SetIncludeRulesByPipeline = $PD.IncludeRules | Set-PropertyIncludeRules @TestParams @CommonParams
            $PD.SetIncludeRulesByPipeline.includeName | Should -Be $TestIncludeName
        }
        It 'updates rules by body' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Body'           = $PD.IncludeRules
            }
            $PD.SetIncludeRulesByBody = Set-PropertyIncludeRules @TestParams @CommonParams
            $PD.SetIncludeRulesByBody.includeName | Should -Be $TestIncludeName
        }
        It 'updates rules from snippets' {
            $TestParams = @{
                'IncludeName'    = $TestIncludeName
                'IncludeVersion' = 1
                'InputDirectory' = 'TestDrive:/includesnippets'
            }
            $PD.SetIncludeRulesSnippets = Set-PropertyIncludeRules @TestParams @CommonParams
            $PD.SetIncludeRulesSnippets.includeName | Should -Be $TestIncludeName
        }
        It 'updates rules from json file' {
            $TestParams = @{
                'IncludeName'    = $TestIncludeName
                'IncludeVersion' = 1
                'InputFile'      = 'TestDrive:/includeRules.json'
            }
            $PD.SetIncludeRulesSnippets = Set-PropertyIncludeRules @TestParams @CommonParams
            $PD.SetIncludeRulesSnippets.includeName | Should -Be $TestIncludeName
        }
    }

    Context 'Get-PropertyIncludeRulesDigest' {
        It 'gets a digest by parameter' {
            $TestParams = @{
                'IncludeName'    = $TestIncludeName
                'IncludeVersion' = 1
            }
            $PD.IncludeDigest = Get-PropertyIncludeRulesDigest @TestParams @CommonParams
            $PD.IncludeDigest.length | Should -Be 42
            $PD.IncludeDigest | Should -Match '"[a-f0-9]{40}"'
        }
        It 'gets a digest by pipeline' {
            $IncludeDigest = $PD.IncludeVersion | Get-PropertyIncludeRulesDigest @CommonParams
            $IncludeDigest.length | Should -Be 42
            $IncludeDigest | Should -Match '"[a-f0-9]{40}"'
        }
    }

    Context 'Get-PropertyIncludeBehaviors' {
        It 'returns a list of behaviors by parameter' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
            }
            $PD.IncludeBehaviors = Get-PropertyIncludeBehaviors @TestParams @CommonParams
            $PD.IncludeBehaviors.name | Should -Contain 'origin'
        }
        It 'returns a list of behaviors by pipeline' {
            $PD.IncludeBehaviors = $PD.IncludeVersion | Get-PropertyIncludeBehaviors @CommonParams
            $PD.IncludeBehaviors.name | Should -Contain 'origin'
        }
    }

    Context 'Get-PropertyIncludeCriteria' {
        It 'returns a list' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
            }
            $PD.IncludeCriteria = Get-PropertyIncludeCriteria @TestParams @CommonParams
            $PD.IncludeCriteria.name | Should -Contain 'path'
        }
        It 'returns a list of criteria by pipeline' {
            $PD.IncludeCriteria = $PD.IncludeVersion | Get-PropertyIncludeCriteria @CommonParams
            $PD.IncludeCriteria.name | Should -Contain 'path'
        }
    }

    #-------------------------------------------------
    #             PATCH Include Rules
    #-------------------------------------------------

    Context 'Add-PropertyIncludeRule' {
        It 'adds a rule correctly' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Path'           = "/rules/children/0"
                'Value'          = $TestIncludeRule
            }
            $GetParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
            }
            Add-PropertyIncludeRule @TestParams @CommonParams
            $UpdatedRules = Get-PropertyIncludeRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].name | Should -Be $TestRuleName
            $UpdatedRules.rules.children.count | Should -Be 1
        }

        It 'adds a criterion correctly' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Path'           = "/rules/children/0/criteria/0/options/values/1"
                'Value'          = "js"
            }
            $GetParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
            }
            Add-PropertyIncludeRule @TestParams @CommonParams
            $UpdatedRules = Get-PropertyIncludeRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].criteria[0].options.values | Should -Contain 'js'
            # Add additional criterion back to shared var
            $TestIncludeRule.criteria[0].options.values += 'js'
        }
    }

    Context 'Test-PropertyIncludeRule' {
        It 'throws no errors by parameter' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Path'           = "/rules/children/0"
                'Value'          = $TestIncludeRule
            }
            Test-PropertyIncludeRule @TestParams @CommonParams
        }
        It 'throws no errors by pipeline' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Path'           = "/rules/children/0"
            }
            $TestIncludeRule | Test-PropertyIncludeRule @TestParams @CommonParams
        }
        It 'throws an error for bad input' {
            $TestIncludeRule.Name = 'Bad Name'
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Path'           = "/rules/children/0"
                'Value'          = $TestIncludeRule
            }
            { Test-PropertyIncludeRule @TestParams @CommonParams } | Should -Throw "*JSON Patch Invalid - value differs from expectations*"
        }
    }

    Context 'Update-PropertyIncludeRule' {
        It 'Updates correctly by parameter' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Path'           = "/rules/children/0/name"
                'Value'          = "Updated name"
            }
            Update-PropertyIncludeRule @TestParams @CommonParams

            $UpdatedRules = $PD.IncludeVersion | Get-PropertyIncludeRules @CommonParams
            $UpdatedRules.rules.children[0].name | Should -Be "Updated name"
        }
        It 'Updates correctly by pipeline' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Path'           = "/rules/children/0/name"
            }
            "Even more updated name" | Update-PropertyIncludeRule @TestParams @CommonParams

            $UpdatedRules = $PD.IncludeVersion | Get-PropertyIncludeRules @CommonParams
            $UpdatedRules.rules.children[0].name | Should -Be "Even more updated name"
        }
    }

    Context 'Remove-PropertyIncludeRule' {
        It 'removes the rule correctly correctly' {
            $TestParams = @{
                'IncludeID'      = $PD.NewInclude.includeId
                'IncludeVersion' = 1
                'Path'           = "/rules/children/0"
            }
            Remove-PropertyIncludeRule @TestParams @CommonParams

            $UpdatedRules = $PD.IncludeVersion | Get-PropertyIncludeRules @CommonParams
            $UpdatedRules.rules.children.count | Should -Be 0
        }
    }

    #-------------------------------------------------
    #                    Remove
    #-------------------------------------------------

    Context 'Remove-PropertyInclude' {
        Context 'by param' {
            It 'completes successfully' {
                $TestParams = @{
                    'IncludeID' = $PD.NewInclude.includeId
                }
                $PD.RemoveIncludeParam = Remove-PropertyInclude @TestParams @CommonParams
                $PD.RemoveIncludeParam.message | Should -Be "Deletion Successful."
            }
        }
        Context 'by pipeline' {
            It 'completes successfully' {
                $PD.RemoveIncludePipeline = $PD.CopiedInclude | Remove-PropertyInclude @CommonParams
                $PD.RemoveIncludePipeline.message | Should -Be "Deletion Successful."
            }
        }
    }

    #-------------------------------------------------
    #                Hostname Buckets
    #-------------------------------------------------

    Context 'Get-BucketActivation' {
        It 'gets a list of activations by param' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BucketActivation_1.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'PropertyID' = 123456
            }
            $PD.BucketActivations = Get-BucketActivation @TestParams
            $PD.BucketActivations[0].hostnameActivationId | Should -Not -BeNullOrEmpty
        }
        It 'gets a list of activations by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BucketActivation_1.json"
                return $Response | ConvertFrom-Json
            }
            $PD.BucketActivations = $PD.PropertyByID | Get-BucketActivation
            $PD.BucketActivations[0].hostnameActivationId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific activation by ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BucketActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'PropertyID'           = 123456
                'HostnameActivationID' = 654321
            }
            $PD.BucketActivation = Get-BucketActivation @TestParams
            $PD.BucketActivation.hostnameActivationId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Overrides
    #-------------------------------------------------

    Context 'Get-CustomOverride' {
        It 'gets a list of overrides' {
            $PD.CustomOverrides = @(Get-CustomOverride @CommonParams)
            $PD.CustomOverrides.count | Should -BeGreaterThan 0
            $PD.CustomOverrides[0].overrideId | Should -Not -BeNullOrEmpty
        }
        It 'gets a specific override by ID by param' {
            $TestParams = @{
                'OverrideID' = $PD.CustomOverrides[0].overrideId
            }
            $PD.CustomOverride = Get-CustomOverride @TestParams @CommonParams
            $PD.CustomOverride.overrideId | Should -Be $PD.CustomOverrides[0].overrideId
        }
        It 'gets a specific override by ID by pipeline' {
            $CustomOverride = $PD.CustomOverrides[0] | Get-CustomOverride @CommonParams
            $CustomOverride.overrideId | Should -Be $PD.CustomOverrides[0].overrideId
        }
    }

    #-------------------------------------------------
    #             Behaviors & Criteria
    #-------------------------------------------------

    Context 'Get-PropertyBehaviors' {
        It 'returns a list by param' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
            }
            $PD.PropertyBehaviors = Get-PropertyBehaviors @TestParams @CommonParams
            $PD.PropertyBehaviors.name | Should -Contain 'origin'
        }
        It 'returns a list by pipeline' {
            $PropertyBehaviors = $PD.NewPropertyVersion | Get-PropertyBehaviors @CommonParams
            $PropertyBehaviors.name | Should -Contain 'origin'
        }
    }

    Context 'Get-PropertyCriteria' {
        It 'returns a list' {
            $TestParams = @{
                'PropertyID'      = $PD.NewPropertyTrad.propertyId
                'PropertyVersion' = 'latest'
            }
            $PD.PropertyCriteria = Get-PropertyCriteria @TestParams @CommonParams
            $PD.PropertyCriteria.name | Should -Contain 'path'
        }
        It 'returns a list by pipeline' {
            $PropertyCriteria = $PD.NewPropertyVersion | Get-PropertyCriteria @CommonParams
            $PropertyCriteria.name | Should -Contain 'path'
        }
    }

    Context 'New-EdgeHostname' {
        It 'creates an edge hostname' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeHostname.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'DomainPrefix'      = 'test'
                'DomainSuffix'      = 'edgesuite.net'
                'IPVersionBehavior' = 'IPV4'
                'ProductId'         = $TestProductName
                'SecureNetwork'     = 'STANDARD_TLS'
                'GroupID'           = $TestGroupID
                'ContractId'        = $TestContract
            }
            $NewEdgeHostname = New-EdgeHostname @TestParams
            $NewEdgeHostname.edgeHostnameLink | Should -Not -BeNullOrEmpty
            $NewEdgeHostname.edgeHostnameId | Should -Match '[\d]+'
        }
    }

    Context 'New-CPCode' {
        It 'creates a property' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CPCode.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'CPCodeName' = 'testCP'
                'ProductId'  = 'Fresca'
                'GroupID'    = $TestGroupID
                'ContractId' = $TestContract
            }
            $NewCPCode = New-CPCode @TestParams
            $NewCPCode.cpcodeLink | Should -Not -BeNullOrEmpty
            $NewCPCode.cpcodeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-PropertyDeactivation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-PropertyDeactivation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'deactivates by parameter' {
            $TestParams = @{
                'PropertyID'      = 123456
                'PropertyVersion' = 1
                'Network'         = 'Staging'
                'NotifyEmails'    = 'mail@example.com'
            }
            $Deactivation = New-PropertyDeactivation @TestParams
            $Deactivation.activationLink | Should -Not -BeNullOrEmpty
            $Deactivation.activationId | Should -Not -BeNullOrEmpty
        }
        It 'deactivates by pipeline' {
            $TestParams = @{
                'Network'      = 'Staging'
                'NotifyEmails' = 'mail@example.com'
            }
            $Deactivation = $PD.NewPropertyVersion | New-PropertyDeactivation @TestParams
            $Deactivation.activationLink | Should -Not -BeNullOrEmpty
            $Deactivation.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                    Includes
    #-------------------------------------------------

    Context 'New-PropertyIncludeActivation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-PropertyIncludeActivation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'activates by parameter' {
            $TestParams = @{
                'IncludeID'      = 123456
                'IncludeVersion' = 1
                'Network'        = 'Staging'
                'NotifyEmails'   = 'mail@example.com'
            }
            $ActivateInclude = New-PropertyIncludeActivation @TestParams
            $ActivateInclude.activationLink | Should -Not -BeNullOrEmpty
            $ActivateInclude.activationId | Should -Not -BeNullOrEmpty
        }
        It 'activates by pipeline' {
            $TestParams = @{
                'Network'      = 'Staging'
                'NotifyEmails' = 'mail@example.com'
            }
            $ActivateInclude = $PD.IncludeVersion | New-PropertyIncludeActivation @TestParams
            $ActivateInclude.activationLink | Should -Not -BeNullOrEmpty
            $ActivateInclude.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Undo-PropertyIncludeActivation' {
        It 'cancels activation' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Undo-PropertyIncludeActivation.json"
                return $Response | ConvertFrom-Json
            }

            $TestParams = @{
                'IncludeID'    = 123456
                'ActivationId' = 'atv_1696855'
            }
            $ActivateInclude = Undo-PropertyIncludeActivation @TestParams
            $ActivateInclude.includeActivationId | Should -Not -BeNullOrEmpty
            $ActivateInclude.status | Should -Be 'PENDING_CANCELLATION'
        }
    }

    Context 'New-PropertyIncludeDeactivation' {
        It 'activates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-PropertyIncludeDeactivation.json"
                return $Response | ConvertFrom-Json
            }

            $TestParams = @{
                'IncludeID'      = 123456
                'IncludeVersion' = 1
                'Network'        = 'Staging'
                'NotifyEmails'   = 'mail@example.com'
            }
            $DeactivateInclude = New-PropertyIncludeDeactivation @TestParams
            $DeactivateInclude.activationLink | Should -Not -BeNullOrEmpty
            $DeactivateInclude.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyIncludeActivation' {
        It 'returns the a specific activation by ID' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-PropertyIncludeActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'IncludeID'           = 123456
                'IncludeActivationID' = 123456789
            }
            $IncludeActivation = Get-PropertyIncludeActivation @TestParams
            $IncludeActivation.includeId | Should -Not -BeNullOrEmpty
        }
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-PropertyIncludeActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'IncludeID' = 123456
            }
            $IncludeActivations = Get-PropertyIncludeActivation @TestParams
            $IncludeActivations[0].includeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyVersionInclude' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-PropertyVersionInclude.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets included Includes by param' {
            $TestParams = @{
                'PropertyID'      = 123456
                'PropertyVersion' = 1
            }
            $PropertyIncludes = Get-PropertyVersionInclude @TestParams
            $PropertyIncludes[0].includeId | Should -Not -BeNullOrEmpty
            $PropertyIncludes[0].includeType | Should -Be 'COMMON_SETTINGS'
        }
        It 'gets included Includes by pipeline' {
            $PropertyIncludes = $PD.NewPropertyVersion | Get-PropertyVersionInclude
            $PropertyIncludes[0].includeId | Should -Not -BeNullOrEmpty
            $PropertyIncludes[0].includeType | Should -Be 'COMMON_SETTINGS'
        }
    }

    Context 'Test-PropertyInclude' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Test-PropertyInclude.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns the correct data by parameter' {
            $TestParams = @{
                'PropertyID'          = 123456
                'PropertyVersion'     = 1
                'IncludeActivationID' = 123456
            }
            $IncludeValidation = Test-PropertyInclude @TestParams
            $IncludeValidation.messages | Should -Not -BeNullOrEmpty
            $IncludeValidation.result | Should -Not -BeNullOrEmpty
            $IncludeValidation.stats | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $TestParams = @{
                'IncludeActivationID' = 123456
            }
            $IncludeValidation = $PD.NewPropertyVersion | Test-PropertyInclude @TestParams
            $IncludeValidation.messages | Should -Not -BeNullOrEmpty
            $IncludeValidation.result | Should -Not -BeNullOrEmpty
            $IncludeValidation.stats | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyIncludeParent' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-PropertyIncludeParent.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets the parent config by parameter' {
            $TestParams = @{
                'IncludeID' = 123456
            }
            $Parent = Get-PropertyIncludeParent @TestParams
            $Parent.propertyId | Should -Not -BeNullOrEmpty
            $Parent.propertyName | Should -Not -BeNullOrEmpty
            $Parent.isIncludeUsedInStagingVersion | Should -Not -BeNullOrEmpty
        }
        It 'gets the parent config by pipeline' {
            $Parent = $PD.IncludeByID | Get-PropertyIncludeParent
            $Parent.propertyId | Should -Not -BeNullOrEmpty
            $Parent.propertyName | Should -Not -BeNullOrEmpty
            $Parent.isIncludeUsedInStagingVersion | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Hostname Buckets
    #-------------------------------------------------

    Context 'Add-BucketHostname' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Add-BucketHostname.json"
                return $Response | ConvertFrom-Json
            }
            $BucketHostnameToAdd = @{
                'cnameType'            = "EDGE_HOSTNAME"
                'cnameFrom'            = $TestAdditionalHostname
                'cnameTo'              = $TestEdgeHostname
                'edgeHostnameId'       = 12345678
                'certProvisioningType' = 'CPS_MANAGED'
            }
            $TestParams = @{
                'PropertyID'   = 123456
                'Network'      = 'STAGING'
                'NewHostnames' = $BucketHostnameToAdd
            }
            $AddBucketHostnames = Add-BucketHostname @TestParams
            $AddBucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-BucketHostname' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BucketHostname.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by parameter' {
            $TestParams = @{
                'PropertyID' = 123456
                'Network'    = 'STAGING'
            }
            $BucketHostnames = Get-BucketHostname @TestParams
            $BucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $TestParams = @{
                'Network' = 'STAGING'
            }
            $BucketHostnames = $PD.PropertyByID | Get-BucketHostname @TestParams
            $BucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Compare-BucketHostname' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Compare-BucketHostname.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets a comparison by parameter' {
            $TestParams = @{
                'PropertyID' = 123456
            }
            $BucketComparison = Compare-BucketHostname @TestParams
            $BucketComparison[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
        It 'gets a comparison by pipeline' {
            $BucketComparison = $PD.PropertyByID | Compare-BucketHostname
            $BucketComparison[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-BucketHostname' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-BucketHostname.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'removes a hostname by parameter' {
            $TestParams = @{
                'PropertyID'        = 123456
                'Network'           = 'STAGING'
                'HostnamesToRemove' = $TestAdditionalHostname
            }
            $RemoveBucketHostnames = Remove-BucketHostname @TestParams
            $RemoveBucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
        It 'removes a hostname by pipeline' {
            $TestParams = @{
                'PropertyID' = 123456
                'Network'    = 'STAGING'
            }
            $RemoveBucketHostnames = $TestAdditionalHostname | Remove-BucketHostname @TestParams
            $RemoveBucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Undo-BucketActivation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Undo-BucketActivation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'cancels an activation by parameter' {
            $TestParams = @{
                'PropertyID'           = 123456
                'HostnameActivationID' = 987654
            }
            $BucketActivationCancellation = Undo-BucketActivation @TestParams
            $BucketActivationCancellation.hostnameActivationId | Should -Not -BeNullOrEmpty
        }
        It 'cancels an activation by pipeline' {
            $TestParams = @{
                'HostnameActivationID' = 987654
            }
            $BucketActivationCancellation = $PD.PropertyByID | Undo-BucketActivation @TestParams
            $BucketActivationCancellation.hostnameActivationId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Bulk Operations
    #-------------------------------------------------

    Context 'New-BulkSearch' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkSearch_1.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Match' = '$.name'
            }
            $NewBulkSearch = New-BulkSearch @TestParams
            $NewBulkSearch.bulkSearchLink | Should -Not -BeNullOrEmpty
            $NewBulkSearch.BulkSearchID | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data using -Synchronous' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkSearch.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Match'       = '$.name'
                'Synchronous' = $true
            }
            $NewBulkSearchSync = New-BulkSearch @TestParams
            $NewBulkSearchSync.results | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-BulkSearchResult' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BulkSearchResult.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'BulkSearchID' = 5
            }
            $GetBulkSearch = Get-BulkSearchResult @TestParams
            $GetBulkSearch.results | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-BulkVersion' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkVersion.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $TestBulkVersionJSON
            }
            $NewBulkVersion = New-BulkVersion @TestParams
            $NewBulkVersion.bulkCreateVersionLink | Should -Not -BeNullOrEmpty
            $NewBulkVersion.BulkCreateID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-BulkVersionedProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BulkVersionedProperty.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'BulkCreateID' = 9
            }
            $BulkVersionedProperties = Get-BulkVersionedProperty @TestParams
            $BulkVersionedProperties.bulkCreateVersionsStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-BulkPatch' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkPatch.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $TestBulkPatchJSON
            }
            $NewBulkPatch = New-BulkPatch @TestParams
            $NewBulkPatch.bulkPatchLink | Should -Not -BeNullOrEmpty
            $NewBulkPatch.BulkPatchID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-BulkPatchedProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BulkPatchedProperty.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'BulkPatchID' = 7
            }
            $BulkPatchedProperties = Get-BulkPatchedProperty @TestParams
            $BulkPatchedProperties.bulkPatchStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-BulkActivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $TestBulkActivateJSON
            }
            $NewBulkActivation = New-BulkActivation @TestParams
            $NewBulkActivation.bulkActivationLink | Should -Not -BeNullOrEmpty
            $NewBulkActivation.BulkActivationID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-BulkActivatedProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BulkActivatedProperty.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'BulkActivationID' = 234
            }
            $BulkActivatedProperties = Get-BulkActivatedProperty @TestParams
            $BulkActivatedProperties.bulkActivationStatus | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Domain Validation
    #-------------------------------------------------

    Context 'Update-PropertyDomainValidation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Update-PropertyDomainValidation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'updates successfully by parameter' {
            $TestParams = @{
                'PropertyID' = 123456
                'Domain'     = 'www.example.com'
            }
            $UpdateValidation = Update-PropertyDomainValidation @TestParams
            $UpdateValidation.domain | Should -Not -BeNullOrEmpty
            $UpdateValidation.reason | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'PropertyID' = 123456
            }
            $UpdateValidation = 'www.example.com' | Update-PropertyDomainValidation @TestParams
            $UpdateValidation.domain | Should -Not -BeNullOrEmpty
            $UpdateValidation.reason | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Resume-PropertyDomainValidation' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Update-PropertyDomainValidation.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'updates successfully by parameter' {
            $TestParams = @{
                'PropertyID' = 123456
                'Domain'     = 'www.example.com'
            }
            $UpdateValidation = Resume-PropertyDomainValidation @TestParams
            $UpdateValidation.domain | Should -Not -BeNullOrEmpty
            $UpdateValidation.reason | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'PropertyID' = 123456
            }
            $UpdateValidation = 'www.example.com' | Resume-PropertyDomainValidation @TestParams
            $UpdateValidation.domain | Should -Not -BeNullOrEmpty
            $UpdateValidation.reason | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyDomainOwnershipChallenge' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-PropertyDomainOwnershipChallenge.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets domain challenges by parameter' {
            $TestParams = @{
                'Hostname' = 'www.example.com', 'www2.example.com'
            }
            $DomainValidation = Get-PropertyDomainOwnershipChallenge @TestParams
            $DomainValidation[0].hostname | Should -Not -BeNullOrEmpty
            $DomainValidation[0].validationCname | Should -Not -BeNullOrEmpty
        }
        It 'gets domain challenges by parameter' {
            $DomainValidation = 'www.example.com', 'www2.example.com' | Get-PropertyDomainOwnershipChallenge
            $DomainValidation[0].hostname | Should -Not -BeNullOrEmpty
            $DomainValidation[0].validationCname | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                  Removals
    #-------------------------------------------------

    Context 'Remove-Property' {
        Context 'single by param' {
            It 'removes a property' {
                $TestParams = @{
                    'PropertyID' = $PD.NewPropertyTrad.propertyId
                }
                $RemoveProperty = Remove-Property @TestParams @CommonParams
                $RemoveProperty.message | Should -Be "Deletion Successful."
            }
        }
        Context 'single by pipeline' {
            It 'removes a property' {
                $RemoveProperty = $PD.NewPropertyBucket | Remove-Property  @CommonParams
                $RemoveProperty.message | Should -Be "Deletion Successful."
            }
        }
        Context 'multi by pipeline' {
            It 'waits 10s for deletions to take effect' {
                Start-Sleep -Seconds 10
            }
            It 'removes a property' {
                $TestParams = @{
                    'GroupID'    = $TestGroupID
                    'ContractId' = $TestContract
                }
                $PropertiesToRemove = Get-Property @TestParams @CommonParams | Where-Object { $_.propertyName.StartsWith($TestPropertyPrefix) }
                $PropertiesToRemove | Remove-Property @CommonParams
            }
            It 'waits 30s for final removals' {
                Start-Sleep -Seconds 30
            }
        }
    }
}