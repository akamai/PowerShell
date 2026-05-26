BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.IVM Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.IVM'
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
        $TestGroupID = $env:PesterGroupID
        $TestNetwork = 'Staging'
        $TestImagePolicySetName = "pester-testing-image-$Timestamp"
        $TestImagePolicyName = "pester-image-policy-$Timestamp"
        $TestImagePolicyBody = '{"output":{"quality":85},"breakpoints":{"widths":[1024,2048]}}'
        $TestImagePolicy = ConvertFrom-Json $TestImagePolicyBody
        $TestVideoPolicySetName = "pester-testing-video-$Timestamp"
        $TestVideoPolicyName = "pester-video-policy-$Timestamp"
        $TestVideoPolicyBody = '{"breakpoints":{"widths":[854,1280,1920]},"id":"low-vid","output":{"perceptualQuality":"mediumLow"}}'
        $TestVideoPolicy = ConvertFrom-Json $TestVideoPolicyBody
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.IVM"
        $PD = @{}
    }

    AfterAll {
        # Find and remove all testing policySets
        Get-IVMPolicySet @CommonParams | Where-Object policySetName -in $TestImagePolicySetName, $TestVideoPolicySetName | ForEach-Object {
            Remove-IVMPolicySet -PolicySetID $_.id @CommonParams
        }
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #-------------------------------------------------
    #                  Image Tests
    #-------------------------------------------------

    Context 'New-IVMPolicySet' {
        It 'creates an image policy set' {
            $TestParams = @{
                'Name'       = $TestImagePolicySetName
                'ContractID' = $TestContractID
                'Type'       = 'Image'
                'Region'     = 'EMEA'
            }
            $PD.NewImagePolicySet = New-IVMPolicySet @TestParams @CommonParams
            $PD.NewImagePolicySet.name | Should -Be $TestImagePolicySetName
        }
    }

    Context 'Get-IVMPolicySet' {
        It 'gets all policy sets' {
            $PD.AllPolicySets = Get-IVMPolicySet @CommonParams -ContractID $TestContractID 
            $PD.AllPolicySets[0].name | Should -Not -BeNullOrEmpty
        }
        It 'gets an image policy set' {
            $TestParams = @{
                'PolicySetID' = $PD.NewImagePolicySet.id
                'ContractID'  = $TestContractID
            }
            $PD.GetSingleImagePolicySet = Get-IVMPolicySet @TestParams @CommonParams
            $PD.GetSingleImagePolicySet.name | Should -Be $TestImagePolicySetName
        }
    }

    Context 'New-IVMPolicy, Pipeline' {
        It 'creates a new Image policy via pipeline' {
            $PD.NewImagePolicyPipe = $TestImagePolicy | New-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContractID -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams
            $PD.NewImagePolicyPipe.operationPerformed | Should -Be 'CREATED'
        }
        It 'fails if policy already exists' {
            { $TestImagePolicy | New-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContractID -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams } | Should -Throw
        }
    }

    Context 'Set-IVMPolicy ' {
        It 'updates a Image policy via pipeline' {
            $TestImagePolicy.output.quality = 95
            $PD.SetImagePolicyPipe = $TestImagePolicy | Set-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContractID -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams
            $PD.SetImagePolicyPipe.operationPerformed | Should -Be 'UPDATED'
        }
    }

    Context 'Restore-IVMPolicy' {
        It 'reverts a policy back to the previous version' {
            $TestParams = @{
                'PolicySetID' = $PD.NewImagePolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestImagePolicyName
                'Network'     = $TestNetwork
            }
            $PD.RestoreImagePolicy = Restore-IVMPolicy @TestParams @CommonParams
            $PD.RestoreImagePolicy.operationPerformed | Should -Be 'UPDATED'
            $PD.RestoreImagePolicy.description | Should -BeLike '*has been rolled back to version*'
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith { return 'IAR executed' }
            $Result = & {} | Restore-IVMPolicy -PolicySetID testpolicyset -Network Production
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-IVMPolicy' {
        It 'deletes an image policy' {
            $TestParams = @{
                'PolicySetID' = $PD.NewImagePolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestImagePolicyName
                'Network'     = $TestNetwork
            }
            $PD.RemoveImagePolicy = Remove-IVMPolicy @TestParams @CommonParams
            $PD.RemoveImagePolicy.operationPerformed | Should -Be 'DELETED'
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-IVMPolicy -PolicySetID testpolicyset -Network Production
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Create an image policy with body parameter' {
        It 'New-IVMPolicy creates a new Image policy with body parameter' {
            $TestParams = @{
                'PolicySetID' = $PD.NewImagePolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestImagePolicyName
                'Network'     = $TestNetwork
                'Body'        = $TestImagePolicyBody
            }
            $PD.NewImagePolicyBody = New-IVMPolicy @TestParams @CommonParams
            $PD.NewImagePolicyBody.operationPerformed | Should -Be 'CREATED'
        }
    }

    Context 'Get-IVMPolicy' {
        It 'gets all Image Policies' {
            $TestParams = @{
                'PolicySetID' = $PD.NewImagePolicySet.id
                'ContractID'  = $TestContractID
                'Network'     = $TestNetwork
            }
            $PD.AllImagePolicies = Get-IVMPolicy @TestParams @CommonParams
            $PD.AllImagePolicies[0].id | Should -Not -BeNullOrEmpty
        }
        It 'gets a single Image Policy' {
            $TestParams = @{
                'PolicySetID' = $PD.NewImagePolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestImagePolicyName
                'Network'     = $TestNetwork
            }
            $PD.GetSingleImagePolicy = Get-IVMPolicy @TestParams @CommonParams
            $PD.GetSingleImagePolicy.id | Should -Be $TestImagePolicyName
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith { return 'IAR executed' }
            $Result = & {} | Get-IVMPolicy
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-IVMPolicySet' {
        It 'updates an image policy sets name and region' {
            $TestParams = @{
                'ContractID'  = $TestContractID
                'Region'      = 'US'
                'Name'        = 'pester-testing-image-changed-name'
                'PolicySetID' = $PD.NewImagePolicySet.id
            }
            $PD.SetImagePolicySet = Set-IVMPolicySet @TestParams @CommonParams
            $PD.SetImagePolicySet.name | Should -Match '-changed-name'
            $PD.SetImagePolicySet.region | Should -Be 'US'
        }
    }

    Context 'Get-IVMPolicyHistory' {
        It 'gets the Image Policy history' {
            $TestParams = @{
                'PolicySetID' = $PD.NewImagePolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestImagePolicyName
                'Network'     = $TestNetwork
            }
            $PD.GetImagePolicyHistory = Get-IVMPolicyHistory @TestParams @CommonParams
            $PD.GetImagePolicyHistory | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-IVMPolicySet' {
        It "deletes an image policy set" {
            Remove-IVMPolicySet -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContractID @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-IVMPolicySet
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #-------------------------------------------------
    #                       Video Tests              #
    #-------------------------------------------------

    Context 'New-IVMPolicySet' {
        It 'creates a video policy set' {
            $TestParams = @{
                'Name'       = $TestVideoPolicySetName
                'ContractID' = $TestContractID
                'Type'       = 'Video'
                'Region'     = 'US'
            }
            $PD.NewVideoPolicySet = New-IVMPolicySet @TestParams @CommonParams
            $PD.NewVideoPolicySet.name | Should -Be $TestVideoPolicySetName
        }
    }

    Context 'Get-IVMPolicySet, Single' {
        It 'gets a video policy set' {
            $TestParams = @{
                'PolicySetID' = $PD.NewVideoPolicySet.id
                'ContractID'  = $TestContractID
            }
            $PD.GetSingleVideoPolicySet = Get-IVMPolicySet @TestParams @CommonParams
            $PD.GetSingleVideoPolicySet.name | Should -Be $TestVideoPolicySetName
        }
    }

    Context 'New-IVMPolicy' {
        It 'creates a new Video policy via pipeline' {
            $TestParams = @{
                'PolicySetID' = $PD.NewVideoPolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestVideoPolicyName
                'Network'     = $TestNetwork
            }
            $PD.NewVideoPolicyPipe = $TestVideoPolicy | New-IVMPolicy @TestParams @CommonParams
            $PD.NewVideoPolicyPipe.operationPerformed | Should -Be 'CREATED'
        }
    }

    Context 'Remove-IVMPolicy' {
        It 'deletes a video policy' {
            $TestParams = @{
                'PolicySetID' = $PD.NewVideoPolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestVideoPolicyName
                'Network'     = $TestNetwork
            }
            $PD.RemoveVideoPolicy = Remove-IVMPolicy @TestParams @CommonParams
            $PD.RemoveVideoPolicy.operationPerformed | Should -Be 'DELETED'
        }
    }

    Context 'New-IVMPolicy' {
        It 'creates a new Video policy with body parameter' {
            $TestParams = @{
                'PolicySetID' = $PD.NewVideoPolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestVideoPolicyName
                'Network'     = $TestNetwork
                'Body'        = $TestVideoPolicyBody
            }
            $PD.NewVideoPolicyBody = New-IVMPolicy @TestParams @CommonParams
            $PD.NewVideoPolicyBody.operationPerformed | Should -Be 'CREATED'
        }
    }

    Context 'Get-IVMPolicy' {
        It 'gets a single Video Policy' {
            $TestParams = @{
                'PolicySetID' = $PD.NewVideoPolicySet.id
                'ContractID'  = $TestContractID
                'PolicyID'    = $TestVideoPolicyName
                'Network'     = $TestNetwork
            }
            $PD.GetSingleVideoPolicy = Get-IVMPolicy @TestParams @CommonParams
            $PD.GetSingleVideoPolicy.id | Should -Be $TestVideoPolicyName
        }
    }

    Context 'Remove-IVMPolicySet' {
        It 'deletes a video policy set' {
            Remove-IVMPolicySet -PolicySetID $PD.NewVideoPolicySet.id -ContractID $TestContractID @CommonParams
        }
    }

    #-------------------------------------------------
    #               Log and Error Tests
    #-------------------------------------------------

    Context 'Get-IVMErrorDetails' {
        It 'gets error details' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IVMErrorDetails.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Network'     = 'Production'
                'PolicySetID' = 'videoPolicy'
            }
            $ErrorDetails = Get-IVMErrorDetails @TestParams
            $ErrorDetails | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith { return 'IAR executed' }
            $Result = & {} | Get-IVMErrorDetails
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-IVMLogDetails' {
        It 'gets log details' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IVMLogDetails.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Network'     = 'Production'
                'PolicySetID' = 'videoPolicy'
            }
            $LogDetails = Get-IVMLogDetails @TestParams
            $LogDetails | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith { return 'IAR executed' }
            $Result = & {} | Get-IVMLogDetails
            $Result | Should -Not -Be 'IAR executed'
        }
    }
    
    Context 'Get-IVMImage' {
        It 'lists images' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IVMImage_1.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Network'     = 'Production'
                'PolicySetID' = 'imagePolicy'
            }
            $Images = Get-IVMImage @TestParams
            $Images[0].url | Should -Not -BeNullOrEmpty
        }
        It 'retrieves a single image' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IVMImage.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ImageID'     = '/images/image.jpg?imageId=format/jpg'
                'Network'     = 'Production'
                'PolicySetID' = 'imagePolicy'
            }
            $Image = Get-IVMImage @TestParams
            $Image.url | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.IVM -MockWith { return 'IAR executed' }
            $Result = & {} | Get-IVMImage
            $Result | Should -Not -Be 'IAR executed'
        }
    }
}

