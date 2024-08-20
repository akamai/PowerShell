Describe 'Safe Akamai.Property Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Property/Akamai.Property.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupName = $env:PesterGroupName
        $TestGroupID = $env:PesterGroupID
        $TestPropertyName = 'akamaipowershell-testing'
        $TestIncludeName = 'akamaipowershell-include'
        $TestHostname = $env:PesterHostname
        $TestAdditionalHostname = 'new.host'
        $TestBucketPropertyName = 'akamaipowershell-bucket'
        $TestProductName = 'Fresca'
        $TestRuleFormat = 'v2024-02-12'
        $TestRuleName = "Test Rule"
        $TestRule = @"
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
"@ | ConvertFrom-Json
        $PD = @{}
    }

    AfterAll {
        Context 'Cleanup files' {
            Remove-Item snippets.json -Force
            Remove-Item rules.json -Force
            Remove-Item includeRules.json -Force
            Remove-Item 'default.json' -Force
            Remove-Item snippets -Recurse -Force
            Remove-Item includesnippets -Recurse -Force
        }
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
        It 'lists products' {
            $PD.Products = Get-Product -ContractID $TestContract @CommonParams
            $PD.Products[0].productId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-ProductUseCases' {
        It 'lists use cases for DD' {
            $PD.ProductUseCases = Get-ProductUseCases -ContractId $TestContract -ProductID Download_Delivery @CommonParams
            $PD.ProductUseCases[0].useCase | Should -Not -BeNullOrEmpty
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
    }

    Context 'Get-Group by ID' {
        It 'gets a group' {
            $PD.GroupByID = Get-Group -GroupID $TestGroupID @CommonParams
            $PD.GroupByID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-Group by name' {
        It 'gets a group' {
            $PD.GroupByName = Get-Group -GroupName $TestGroup.groupName @CommonParams
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
        It 'should not be null' {
            $PD.CPCodes = Get-PropertyCPCode -GroupId $TestGroupID -ContractId $TestContract @CommonParams
            $PD.CPCodes | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyCPCode by CpCode' {
        It 'should not be null' {
            $PD.CPCode = Get-PropertyCPCode -CPCode $PD.CPCodes[0].cpcodeId -GroupId $TestGroupID -ContractId $TestContract @CommonParams
            $PD.CPCode | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Edge Hostnames
    #-------------------------------------------------

    Context 'Get-PropertyEdgeHostname' {
        It 'should not be null' {
            $PD.EdgeHostnames = Get-PropertyEdgeHostname -GroupId $TestGroupID -ContractId $TestContract @CommonParams
            $PD.EdgeHostnames | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyEdgeHostname' {
        It 'should not be null' {
            $PD.EdgeHostname = Get-PropertyEdgeHostname -EdgeHostnameID $PD.EdgeHostnames[0].EdgeHostnameId -GroupId $TestGroupID -ContractId $TestContract @CommonParams
            $PD.EdgeHostname | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Custom Behaviors
    #-------------------------------------------------

    Context 'Get-CustomBehavior' {
        It 'should not be null' {
            $PD.CustomBehaviors = Get-CustomBehavior @CommonParams
            $PD.CustomBehaviors | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CustomBehavior by ID' {
        It 'should not be null' {
            $PD.CustomBehavior = Get-CustomBehavior -BehaviorId $PD.CustomBehaviors[0].behaviorId @CommonParams
            $PD.CustomBehavior | Should -Not -BeNullOrEmpty
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
            $PD.ClientSettings = Set-PropertyClientSettings -RuleFormat $PD.ClientSettings.ruleFormat -UsePrefixes $PD.ClientSettings.usePrefixes @CommonParams
            $PD.ClientSettings | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Property
    #-------------------------------------------------
    
    Context 'Get-Property' {
        It 'lists properties' {
            $PD.Properties = Get-Property -GroupID $TestGroupID -ContractId $TestContract @CommonParams
            $PD.Properties.count | Should -BeGreaterThan 0
        }
    }

    Context 'Find-Property' {
        It 'finds properties' {
            $PD.FoundProperty = Find-Property -PropertyName $TestPropertyName -Latest @CommonParams
            $PD.FoundProperty | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Expand-PropertyDetails' {
        It 'returns the correct data' {
            $PD.ExpandedPropertyID, $PD.ExpandedPropertyVersion, $null, $null = Expand-PropertyDetails -PropertyName $TestPropertyName -PropertyVersion latest @CommonParams
            $PD.ExpandedPropertyID | Should -Be $PD.FoundProperty.propertyId
            $PD.ExpandedPropertyVersion | Should -Be $PD.FoundProperty.propertyVersion
        }
    }

    Context 'Get-Property by name' {
        It 'finds properties by name' {
            $PD.PropertyByName = Get-Property -PropertyName $TestPropertyName @CommonParams
            $PD.PropertyByName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-Property by ID' {
        It 'finds properties by ID' {
            $PD.PropertyByID = Get-Property -PropertyID $PD.FoundProperty.propertyId @CommonParams
            $PD.PropertyByID | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Versions
    #-------------------------------------------------

    Context 'Get-PropertyVersion using specific' {
        It 'finds specified version' {
            $PD.PropertyVersion = Get-PropertyVersion -PropertyID $PD.FoundProperty.propertyId -PropertyVersion $PD.FoundProperty.propertyVersion @CommonParams
            $PD.PropertyVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyVersion using "latest"' {
        It 'finds "latest" version' {
            $PD.PropertyVersion = Get-PropertyVersion -PropertyID $PD.FoundProperty.propertyId -PropertyVersion 'latest' @CommonParams
            $PD.PropertyVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-PropertyVersion' {
        It 'does not error' {
            $PD.NewPropertyVersion = New-PropertyVersion -PropertyID $PD.FoundProperty.propertyId -CreateFromVersion $PD.PropertyVersion.propertyVersion @CommonParams
            $PD.NewPropertyVersion.versionLink | Should -Not -BeNullOrEmpty
            $PD.NewPropertyVersion.propertyVersion | Should -Match '[\d]+'
        }
    }

    #-------------------------------------------------
    #                Rules
    #-------------------------------------------------

    Context 'Get-PropertyRules to variable' {
        It 'returns rules object' {
            $PD.Rules = Get-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest @CommonParams
            $PD.Rules | Should -BeOfType [PSCustomObject]
            $PD.Rules.rules | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyRules to file' {
        It 'creates json file' {
            Get-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest -OutputToFile -OutputFileName rules.json @CommonParams
            'rules.json' | Should -Exist
        }
        It 'fails without -Force if file exists' {
            { Get-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest -OutputToFile -OutputFileName rules.json @CommonParams } | Should -Throw
        }
    }

    Context 'Get-PropertyRules to snippets' {
        It 'creates expected files' {
            Get-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest -OutputSnippets -OutputDirectory snippets @CommonParams
            'snippets\main.json' | Should -Exist
        }
    }
    
    Context 'Get-PropertyRulesDigest' {
        It 'matches the expected format' {
            $PD.Digest = Get-PropertyRulesDigest -PropertyName $TestPropertyName -PropertyVersion latest @CommonParams
            $PD.Digest.length | Should -Be 42
            $PD.Digest | Should -Match '"[a-f0-9]{40}"'
        }
    }

    Context 'Merge-PropertyRules' {
        It 'creates expected json file' {
            Merge-PropertyRules -SourceDirectory snippets -OutputToFile -OutputFileName snippets.json
            'snippets.json' | Should -Exist
        }
    }

    Context 'Merge-PropertyRules' {
        It 'returns rules object' {
            $PD.MergedRules = Merge-PropertyRules -SourceDirectory snippets
            $PD.MergedRules | Should -BeOfType [PSCustomObject]
            $PD.MergedRules.rules | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-ChildRuleSnippet' {
        It 'creates default rule json' {
            Get-ChildRuleSnippet -Rules $PD.MergedRules.rules -Path . -CurrentDepth 0 -MaxDepth 0
            'default.json' | Should -Exist
        }
    }
    
    Context 'Expand-ChildRuleSnippet' {
        It 'returns the correct object format' {
            $Main = Get-Content snippets/main.json | ConvertFrom-Json
            $ChildInclude = $Main.children[0]
            $PD.childrule = Expand-ChildRuleSnippet -Include $ChildInclude -Path snippets -DefaultRuleDirectory snippets
            $PD.childrule.name | Should -Not -BeNullOrEmpty
            Should -ActualValue $PD.childrule.children -BeOfType 'Array'
            Should -ActualValue $PD.childrule.behaviors -BeOfType 'Array'
            Should -ActualValue $PD.childrule.criteria -BeOfType 'Array'
            $PD.childrule.criteriaMustSatisfy | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-PropertyRules via pipeline' {
        It 'returns rules object' {
            $PD.Rules = $PD.Rules | Set-PropertyRules -PropertyName $TestPropertyName -PropertyVersion $PD.NewPropertyVersion.propertyVersion @CommonParams
            $PD.Rules | Should -BeOfType PSCustomObject
            $PD.Rules.rules | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-PropertyRules from file' {
        It 'returns rules object' {
            $TestParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
                InputFile       = 'rules.json'
            }
            $PD.RulesFromFile = Set-PropertyRules @TestParams @CommonParams
            $PD.RulesFromFile | Should -BeOfType PSCustomObject
            $PD.RulesFromFile.rules | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-PropertyRules from snippets' {
        It 'returns rules object' {
            $TestParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
                InputDirectory  = 'snippets'
            }
            $PD.RulesFromDir = Set-PropertyRules @TestParams @CommonParams
            $PD.RulesFromDir | Should -BeOfType PSCustomObject
            $PD.RulesFromDir.rules | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Hostnames
    #-------------------------------------------------

    Context 'Get-PropertyHostnames' {
        It 'should not be null' {
            $PD.PropertyHostnames = Get-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion $PD.NewPropertyVersion.propertyVersion @CommonParams
            $PD.PropertyHostnames | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-HostnameAuditHistory' {
        It 'produces a list of updates' {
            $PD.HostnameHistory = Get-HostnameAuditHistory -Hostname $TestHostname @CommonParams
            $PD.HostnameHistory[0].cnameTo | Should -Be $TestHostname
            $PD.HostnameHistory[0].action | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-PropertyCertificateChallenge' {
        It 'produces a list of DV challenges' {
            $PD.CertChallenge = Get-PropertyCertificateChallenge -CnamesFrom $TestHostname @CommonParams
            $PD.CertChallenge[0].cnameFrom | Should -Be $TestHostname
            $PD.CertChallenge[0].validationCname.hostname | Should -Be "_acme-challenge.$TestHostname"
        }
    }

    Context 'Set-PropertyHostname by pipeline' {
        It 'works via pipeline' {
            $PD.SetPropertyHostnamesByPipeline = $PD.PropertyHostnames | Set-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion $PD.NewPropertyVersion.propertyVersion @CommonParams
            $PD.SetPropertyHostnamesByPipeline | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-PropertyHostname by param' {
        It 'works via param' {
            $PD.PropertyHostnamesByParam = Set-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion latest -Body $PD.PropertyHostnames @CommonParams
            $PD.PropertyHostnamesByParam | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Add-PropertyHostname via param' {
        It 'works via param' {
            $PD.HostnameToAdd = @{ 
                cnameType = "EDGE_HOSTNAME"
                cnameFrom = $TestAdditionalHostname
                cnameTo   = $PD.PropertyHostnames[0].cnameTo
            }
            $PD.AddPropertyHostnamesByParam = Add-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion $PD.NewPropertyVersion.propertyVersion -NewHostnames $PD.HostnameToAdd @CommonParams
            $PD.AddPropertyHostnamesByParam | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-PropertyHostnames' {
        It 'does not error' {
            $PD.PropertyHostnames = Remove-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion $PD.NewPropertyVersion.propertyVersion -HostnamesToRemove $TestAdditionalHostname @CommonParams
            $PD.PropertyHostnames | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Add-PropertyHostname via pipeline' {
        It 'works via pipeline' {
            $PD.AddPropertyHostnamesByPipeline = @($PD.HostnameToAdd) | Add-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion $PD.NewPropertyVersion.propertyVersion @CommonParams
            $PD.AddPropertyHostnamesByPipeline | Should -Not -BeNullOrEmpty
        }
        It 'removes successfully to return to previous numbers' {
            $PD.PropertyHostnames = Remove-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion $PD.NewPropertyVersion.propertyVersion -HostnamesToRemove $TestAdditionalHostname  @CommonParams
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
        It 'returns the correct data' {
            $PD.RuleFormat = Get-RuleFormatSchema -ProductID Fresca -RuleFormat latest @CommonParams
            $PD.RuleFormat.properties | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-PropertyRequestSchema' {
        It 'returns the correct format' {
            $PD.RequestSchema = Get-PropertyRequestSchema -Filename CreateNewEdgeHostnameRequestV0.json @CommonParams
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
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
                Path            = "/rules/children/0"
                Value           = $TestRule
            }
            $GetParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
            }
            $AddRule = Add-PropertyRule @TestParams @CommonParams
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].name | Should -Be $TestRuleName
            $UpdatedRules.rules.children.count | Should -Be ($PD.Rules.rules.children.count + 1)
        }
        
        It 'adds a criterion correctly' {
            $TestParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
                Path            = "/rules/children/0/criteria/0/options/values/1"
                Value           = "js"
            }
            $GetParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
            }
            $AddRule = Add-PropertyRule @TestParams @CommonParams
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].criteria[0].options.values | Should -Contain 'js'
            # Add additional criterion back to shared var
            $TestRule.criteria[0].options.values += 'js'
        }
    }

    Context 'Test-PropertyRule' {
        It 'throws no errors' {
            $TestParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
                Path            = "/rules/children/0"
                Value           = $TestRule
            }
            $TestRuleResult = Test-PropertyRule @TestParams @CommonParams
        }
        It 'throws an error for bad input' {
            $TestRule.Name = 'Bad Name'
            $TestParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
                Path            = "/rules/children/0"
                Value           = $TestRule
            }
            { Test-PropertyRule @TestParams @CommonParams } | Should -Throw "value differs from expectations"
        }
    }

    Context 'Update-PropertyRule' {
        It 'Updates correctly' {
            $TestParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
                Path            = "/rules/children/0/name"
                Value           = "Updated name"
            }
            $GetParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
            }
            $UpdateResult = Update-PropertyRule @TestParams @CommonParams
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children[0].name | Should -Be "Updated name"
        }
    }

    Context 'Remove-PropertyRule' {
        BeforeAll {
            $RulePosition = $PD.Rules.Children.Count
        }
        It 'Updates correctly' {
            $TestParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
                Path            = "/rules/children/0"
            }
            $GetParams = @{
                PropertyID      = $PD.FoundProperty.propertyId
                PropertyVersion = $PD.NewPropertyVersion.propertyVersion
            }
            $RemoveResult = Remove-PropertyRule @TestParams @CommonParams
            $UpdatedRules = Get-PropertyRules @GetParams @CommonParams
            $UpdatedRules.rules.children.count | Should -Be $PD.Rules.rules.children.count
        }
    }

    #-------------------------------------------------
    #                Activate
    #-------------------------------------------------

    Context 'New-PropertyActivation' {
        It 'returns activationlink' {
            $PD.Activation = New-PropertyActivation -PropertyName $TestPropertyName -PropertyVersion latest -Network Staging -NotifyEmails "mail@example.com" @CommonParams
            $PD.Activation.activationLink | Should -Not -BeNullOrEmpty
            $PD.Activation.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyActivation by ID' {
        It 'finds the correct activation' {
            # Sanitize activation ID from previous response
            $PD.ActivationID = ($PD.Activation.activationLink -split "/")[-1]
            if ($PD.ActivationID.contains("?")) {
                $PD.ActivationID = $PD.ActivationID.Substring(0, $PD.ActivationID.IndexOf("?"))
            }
            $PD.ActivationResult = Get-PropertyActivation -PropertyName $TestPropertyName -ActivationID $PD.ActivationID @CommonParams
            $PD.ActivationResult[0].activationId | Should -Be $PD.ActivationID
        }
    }

    Context 'Get-PropertyActivation' {
        It 'returns a list' {
            $PD.Activations = Get-PropertyActivation -PropertyName $TestPropertyName @CommonParams
            $PD.Activations[0].activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Undo-PropertyActivation' {
        It 'removes activationlink' {
            $PD.UndoActivation = Undo-PropertyActivation -PropertyName $TestPropertyName -ActivationID $PD.ActivationID @CommonParams
            $PD.UndoActivation.activationId | Should -Be $PD.ActivationID
            $PD.UndoActivation.status | Should -Be 'PENDING_CANCELLATION'
        }
    }

    #-------------------------------------------------
    #                    Includes
    #-------------------------------------------------

    Context 'New-PropertyInclude' {
        It 'creates an include' {
            $PD.NewInclude = New-PropertyInclude -Name $TestIncludeName -ProductID $TestProductName -GroupID $TestGroupID -RuleFormat $TestRuleFormat -IncludeType MICROSERVICES -ContractId $TestContract @CommonParams
            $PD.NewInclude.includeLink | Should -Not -BeNullOrEmpty
            $PD.NewInclude.includeId | Should -Not -BeNullOrEmpty

            # Pause for a brief time to let the creation complete
            Start-Sleep -Seconds 15
        }
    }

    Context 'Expand-PropertyIncludeDetails' {
        It 'returns the correct data' {
            $PD.ExpandedIncludeID, $PD.ExpandedIncludeVersion, $null, $null = Expand-PropertyIncludeDetails -IncludeName $TestIncludeName -IncludeVersion latest @CommonParams
            $PD.ExpandedIncludeID | Should -Be $PD.NewInclude.includeId
            $PD.ExpandedIncludeVersion | Should -Be 1
        }
    }

    Context 'Get-PropertyInclude' {
        It 'returns a list' {
            $PD.Includes = Get-PropertyInclude -GroupID $TestGroupID -ContractId $TestContract @CommonParams
            $PD.Includes[0].includeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyInclude by ID' {
        It 'returns the correct data' {
            $PD.IncludeByID = Get-PropertyInclude -IncludeID $PD.NewInclude.includeId @CommonParams
            $PD.IncludeByID.includeName | Should -Be $TestIncludeName
        }
    }

    Context 'Get-PropertyInclude by name' {
        It 'returns the correct data' {
            $PD.Include = Get-PropertyInclude -IncludeName $TestIncludeName @CommonParams
            $PD.Include.includeName | Should -Be $TestIncludeName
        }
    }

    Context 'Get-PropertyIncludeRules to object' {
        It 'returns the correct data' {
            $PD.IncludeRules = Get-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion 1 @CommonParams
            $PD.IncludeRules.includeName | Should -Be $TestIncludeName
        }
    }
    
    Context 'Get-PropertyIncludeRules to file' {
        It 'creates the json file' {
            $TestParams = @{
                IncludeID      = $PD.NewInclude.includeId
                IncludeVersion = 1
                OutputToFile   = $true
                OutputFileName = 'includeRules.json'
            }
            Get-PropertyIncludeRules @testParams @CommonParams
            'includeRules.json' | Should -Exist
        }
    }

    Context 'Get-PropertyIncludeRules to snippets' {
        It 'creates expected files' {
            Get-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion latest -OutputSnippets -OutputDir includesnippets @CommonParams
            'includesnippets\main.json' | Should -Exist
        }
    }

    Context 'Set-PropertyIncludeRules by pipeline' {
        It 'updates correctly' {
            $PD.SetIncludeRulesByPipeline = ( $PD.IncludeRules | Set-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion 1 @CommonParams)
            $PD.SetIncludeRulesByPipeline.includeName | Should -Be $TestIncludeName
        }
    }

    Context 'Set-PropertyIncludeRules by body' {
        It 'updates correctly' {
            $PD.SetIncludeRulesByBody = Set-PropertyIncludeRules -IncludeID $PD.NewInclude.includeId -IncludeVersion 1 -Body $PD.IncludeRules @CommonParams
            $PD.SetIncludeRulesByBody.includeName | Should -Be $TestIncludeName
        }
    }

    Context 'Set-PropertyIncludeRules from snippets directory' {
        It 'updates successfully' {
            $PD.SetIncludeRulesSnippets = Set-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion 1 -InputDirectory includesnippets @CommonParams
            $PD.SetIncludeRulesSnippets.includeName | Should -Be $TestIncludeName
        }
    }
    
    Context 'Set-PropertyIncludeRules from file' {
        It 'updates successfully' {
            $PD.SetIncludeRulesSnippets = Set-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion 1 -InputFile 'includeRules.json' @CommonParams
            $PD.SetIncludeRulesSnippets.includeName | Should -Be $TestIncludeName
        }
    }
    
    Context 'Get-PropertyIncludeRulesDigest' {
        It 'updates successfully' {
            $PD.IncludeDigest = Get-PropertyIncludeRulesDigest -IncludeName $TestIncludeName -IncludeVersion 1 @CommonParams
            $PD.IncludeDigest.length | Should -Be 42
            $PD.IncludeDigest | Should -Match '"[a-f0-9]{40}"'
        }
    }

    Context 'Get-PropertyIncludeVersion' {
        It 'returns the correct data' {
            $PD.IncludeVersions = Get-PropertyIncludeVersion -IncludeID $PD.NewInclude.includeId @CommonParams
            $PD.IncludeVersions[0].includeVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-PropertyIncludeVersion' {
        It 'creates a new version' {
            $PD.NewIncludeVersion = New-PropertyIncludeVersion -IncludeID $PD.NewInclude.includeId -CreateFromVersion 1 @CommonParams
            $PD.NewIncludeVersion.versionLink | Should -Not -BeNullOrEmpty
            $PD.NewIncludeVersion.includeVersion | Should -Match '[\d]+'
        }
    }

    Context 'Get-PropertyIncludeBehaviors' {
        It 'returns a list' {
            $PD.IncludeBehaviors = Get-PropertyIncludeBehaviors -IncludeID $PD.NewInclude.includeId -IncludeVersion 1 @CommonParams
            $PD.IncludeBehaviors.name | Should -Contain 'origin'
        }
    }
    
    Context 'Get-PropertyIncludeCriteria' {
        It 'returns a list' {
            $PD.IncludeCriteria = Get-PropertyIncludeCriteria -IncludeID $PD.NewInclude.includeId -IncludeVersion 1 @CommonParams
            $PD.IncludeCriteria.name | Should -Contain 'path'
        }
    }

    Context 'Remove-PropertyInclude' {
        It 'completes successfully' {
            $PD.RemoveInclude = Remove-PropertyInclude -IncludeID $PD.NewInclude.includeId @CommonParams
            $PD.RemoveInclude.message | Should -Be "Deletion Successful."
        }
    }

    #-------------------------------------------------
    #                Hostname Buckets
    #-------------------------------------------------

    Context 'Get-BucketActivation (all)' {
        It 'returns a list' {
            $PD.BucketActivations = Get-BucketActivation -PropertyName $TestBucketPropertyName @CommonParams
            $PD.BucketActivations[0].hostnameActivationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-BucketActivation (single)' {
        It 'returns the correct data' {
            $PD.BucketActivation = Get-BucketActivation -PropertyName $TestBucketPropertyName -HostnameActivationID $PD.BucketActivations[0].hostnameActivationId @CommonParams
            $PD.BucketActivation.hostnameActivationId | Should -Be $PD.BucketActivations[0].hostnameActivationId
        }
    }

    #-------------------------------------------------
    #                Overrides
    #-------------------------------------------------

    Context 'Get-CustomOverride (All)' {
        It 'returns a list' {
            $PD.CustomOverrides = Get-CustomOverride @CommonParams
            $PD.CustomOverrides.count | Should -BeGreaterThan 0
            $PD.CustomOverrides[0].overrideId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-CustomOverride (Single)' {
        It 'returns a list' {
            $PD.CustomOverride = Get-CustomOverride -OverrideID $PD.CustomOverrides[0].overrideId @CommonParams
            $PD.CustomOverride.overrideId | Should -Be $PD.CustomOverrides[0].overrideId
        }
    }

    #-------------------------------------------------
    #             Behaviors & Criteria
    #-------------------------------------------------

    Context 'Get-PropertyBehaviors' {
        It 'returns a list' {
            $PD.PropertyBehaviors = Get-PropertyBehaviors -PropertyID $PD.FoundProperty.propertyId -PropertyVersion $PD.FoundProperty.propertyVersion @CommonParams
            $PD.PropertyBehaviors.name | Should -Contain 'origin'
        }
    }
    
    Context 'Get-PropertyCriteria' {
        It 'returns a list' {
            $PD.PropertyCriteria = Get-PropertyCriteria -PropertyID $PD.FoundProperty.propertyId -PropertyVersion $PD.FoundProperty.propertyVersion @CommonParams
            $PD.PropertyCriteria.name | Should -Contain 'path'
        }
    }
}

Describe 'Unsafe Akamai.Property Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Property/Akamai.Property.psd1 -Force
        
        $TestGroupID = 123456
        $TestContract = '1-2AB34C'
        $TestAdditionalHostname = 'new.host'
        $TestBucketPropertyName = 'akamaipowershell-bucket'
        $TestProductName = 'Fresca'
        $TestRuleFormat = 'v2022-06-28'
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
        $PD = @{}
    }
    Context 'New-Property' {
        It 'creates a property' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-Property.json"
                return $Response | ConvertFrom-Json
            }
            $NewProperty = New-Property -Name myproperty -ProductID $TestProductName -RuleFormat $TestRuleFormat -GroupID $TestGroupID -ContractId $TestContract
            $NewProperty.propertyLink | Should -Not -BeNullOrEmpty
            $NewProperty.propertyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-Property' {
        It 'removes a property' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-Property.json"
                return $Response | ConvertFrom-Json
            }
            $RemoveProperty = Remove-Property -PropertyID 000000
            $RemoveProperty.message | Should -Be "Deletion Successful."
        }
    }

    Context 'New-EdgeHostname' {
        It 'creates an edge hostname' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-EdgeHostname.json"
                return $Response | ConvertFrom-Json
            }
            $NewEdgeHostname = New-EdgeHostname -DomainPrefix test -DomainSuffix edgesuite.net -IPVersionBehavior IPV4 -ProductId $TestProductName -SecureNetwork STANDARD_TLS -GroupID $TestGroupID -ContractId $TestContract
            $NewEdgeHostname.edgeHostnameLink | Should -Not -BeNullOrEmpty
            $NewEdgeHostname.edgeHostnameId | Should -Match '[\d]+'
        }
    }

    Context 'New-CPCode' {
        It 'creates a property' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CPCode.json"
                return $Response | ConvertFrom-Json
            }
            $NewCPCode = New-CPCode -CPCodeName testCP -ProductId Fresca -GroupID $TestGroupID -ContractId $TestContract
            $NewCPCode.cpcodeLink | Should -Not -BeNullOrEmpty
            $NewCPCode.cpcodeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-PropertyDeactivation' {
        It 'returns activationlink' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-PropertyDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $Deactivation = New-PropertyDeactivation -PropertyID 123456 -PropertyVersion 1 -Network Staging -NotifyEmails "mail@example.com"
            $Deactivation.activationLink | Should -Not -BeNullOrEmpty
            $Deactivation.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                    Includes
    #-------------------------------------------------

    Context 'New-PropertyIncludeActivation' {
        It 'activates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-PropertyIncludeActivation.json"
                return $Response | ConvertFrom-Json
            }
            $ActivateInclude = New-PropertyIncludeActivation -IncludeID 123456 -IncludeVersion 1 -Network Staging -NotifyEmails 'mail@example.com'
            $ActivateInclude.activationLink | Should -Not -BeNullOrEmpty
            $ActivateInclude.activationId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Undo-PropertyIncludeActivation' {
        It 'cancels activation' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Undo-PropertyIncludeActivation.json"
                return $Response | ConvertFrom-Json
            }
            $ActivateInclude = Undo-PropertyIncludeActivation -IncludeID 123456 -ActivationId atv_1696855
            $ActivateInclude.includeActivationId | Should -Not -BeNullOrEmpty
            $ActivateInclude.status | Should -Be 'PENDING_CANCELLATION'
        }
    }

    Context 'New-PropertyIncludeDeactivation' {
        It 'activates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-PropertyIncludeDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $DeactivateInclude = New-PropertyIncludeDeactivation -IncludeID 123456 -IncludeVersion 1 -Network Staging -NotifyEmails 'mail@example.com'
            $DeactivateInclude.activationLink | Should -Not -BeNullOrEmpty
            $DeactivateInclude.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyIncludeActivation by ID' {
        It 'returns the right data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-PropertyIncludeActivation.json"
                return $Response | ConvertFrom-Json
            }
            $IncludeActivation = Get-PropertyIncludeActivation -IncludeID 123456 -IncludeActivationID 123456789
            $IncludeActivation.includeId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-PropertyIncludeActivation' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-PropertyIncludeActivation.json"
                return $Response | ConvertFrom-Json
            }
            $IncludeActivations = Get-PropertyIncludeActivation -IncludeID 123456
            $IncludeActivations[0].includeId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-PropertyVersionInclude' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-PropertyVersionInclude.json"
                return $Response | ConvertFrom-Json
            }
            $PropertyIncludes = Get-PropertyVersionInclude -PropertyID 123456 -PropertyVersion 1
            $PropertyIncludes[0].includeId | Should -Not -BeNullOrEmpty
            $PropertyIncludes[0].includeType | Should -Be 'COMMON_SETTINGS'
        }
    }
    
    Context 'Test-PropertyInclude' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Test-PropertyInclude.json"
                return $Response | ConvertFrom-Json
            }
            $IncludeValidation = Test-PropertyInclude -PropertyID 123456 -PropertyVersion 1 -IncludeActivationID 123456
            $IncludeValidation.messages | Should -Not -BeNullOrEmpty
            $IncludeValidation.result | Should -Not -BeNullOrEmpty
            $IncludeValidation.stats | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Hostname Buckets
    #-------------------------------------------------

    Context 'Add-BucketHostname' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Add-BucketHostname.json"
                return $Response | ConvertFrom-Json
            }
            $BucketHostnameToAdd = @{ 
                cnameType            = "EDGE_HOSTNAME"
                cnameFrom            = $TestAdditionalHostname
                cnameTo              = 'www.example.com'
                edgeHostnameId       = 12345678
                certProvisioningType = 'CPS_MANAGED'
            }
            $AddBucketHostnames = Add-BucketHostname -PropertyID 123456 -Network STAGING -NewHostnames $BucketHostnameToAdd
            $AddBucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-BucketHostname' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BucketHostname.json"
                return $Response | ConvertFrom-Json
            }
            $BucketHostnames = Get-BucketHostname -PropertyID 123456 -Network STAGING
            $BucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Compare-BucketHostname' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Compare-BucketHostname.json"
                return $Response | ConvertFrom-Json
            }
            $BucketComparison = Compare-BucketHostname -PropertyID 123456
            $BucketComparison[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-BucketHostname' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-BucketHostname.json"
                return $Response | ConvertFrom-Json
            }
            $RemoveBucketHostnames = Remove-BucketHostname -PropertyID 123456 -Network STAGING -HostnamesToRemove $TestAdditionalHostname
            $RemoveBucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Undo-BucketActivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Undo-BucketActivation.json"
                return $Response | ConvertFrom-Json
            }
            $BucketActivationCancellation = Undo-BucketActivation -PropertyID 123456 -HostnameActivationID 987654
            $BucketActivationCancellation.hostnameActivationId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Bulk Operations
    #-------------------------------------------------

    Context 'New-BulkSearch, async' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkSearch_1.json"
                return $Response | ConvertFrom-Json
            }
            $NewBulkSearch = New-BulkSearch -Match '$.name'
            $NewBulkSearch.bulkSearchLink | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'New-BulkSearch, sync' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkSearch.json"
                return $Response | ConvertFrom-Json
            }
            $NewBulkSearchSync = New-BulkSearch -Match '$.name' -Synchronous
            $NewBulkSearchSync.results | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-BulkSearchResult' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BulkSearchResult.json"
                return $Response | ConvertFrom-Json
            }
            $GetBulkSearch = Get-BulkSearchResult -BulkSearchID 5 
            $GetBulkSearch.results | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-BulkVersion' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkVersion.json"
                return $Response | ConvertFrom-Json
            }
            $NewBulkVersion = New-BulkVersion -Body $TestBulkVersionJSON
            $NewBulkVersion.bulkCreateVersionLink | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-BulkVersionedProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BulkVersionedProperty.json"
                return $Response | ConvertFrom-Json
            }
            $BulkVersionedProperties = Get-BulkVersionedProperty -BulkCreateID 9 
            $BulkVersionedProperties.bulkCreateVersionsStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-BulkPatch' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkPatch.json"
                return $Response | ConvertFrom-Json
            }
            $NewBulkPatch = New-BulkPatch -Body $TestBulkPatchJSON
            $NewBulkPatch.bulkPatchLink | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-BulkPatchedProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BulkPatchedProperty.json"
                return $Response | ConvertFrom-Json
            }
            $BulkPatchedProperties = Get-BulkPatchedProperty -BulkPatchID 7
            $BulkPatchedProperties.bulkPatchStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-BulkActivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-BulkActivation.json"
                return $Response | ConvertFrom-Json
            }
            $NewBulkActivation = New-BulkActivation -Body $TestBulkActivateJSON
            $NewBulkActivation.bulkActivationLink | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-BulkActivatedProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-BulkActivatedProperty.json"
                return $Response | ConvertFrom-Json
            }
            $BulkActivatedProperties = Get-BulkActivatedProperty -BulkActivationID 234
            $BulkActivatedProperties.bulkActivationStatus | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Property Activation
    #-------------------------------------------------

    Context 'New-PropertyActivation, with compliance record' {
        It 'returns activationlink' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Property -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-PropertyActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                PropertyID          = 123456
                PropertyVersion     = 10
                Network             = 'Production'
                NotifyEmails        = 'mail@example.com'
                NoncomplianceReason = 'NONE'
                CustomerEmail       = 'customer@company.com'
                PeerReviewedBy      = 'okenobi@akamai.com'
                UnitTested          = $true
            }
            $Activation = New-PropertyActivation @TestParams
            $Activation.activationLink | Should -Not -BeNullOrEmpty
            $Activation.activationId | Should -Not -BeNullOrEmpty
        }
    }
}
