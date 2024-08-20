Describe 'Safe Akamai.IVM Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.IVM/Akamai.IVM.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestNetwork = 'Staging'
        $TestImagePolicySetName = 'akamaipowershell-testing-image'
        $TestImagePolicyName = 'akamaipowershell-image-policy'
        $TestImagePolicyBody = '{"output":{"quality":85},"breakpoints":{"widths":[1024,2048]}}'
        $TestImagePolicy = ConvertFrom-Json $TestImagePolicyBody
        $TestVideoPolicySetName = 'akamaipowershell-testing-video'
        $TestVideoPolicyName = 'akamaipowershell-video-policy'
        $TestVideoPolicyBody = '{"breakpoints":{"widths":[854,1280,1920]},"id":"low-vid","output":{"perceptualQuality":"mediumLow"}}'
        $TestVideoPolicy = ConvertFrom-Json $TestVideoPolicyBody
        $PD = @{}
    }

    AfterAll {
        # Find and remove all testing policySets
        Get-IVMPolicySet @CommonParams | Where-Object policySetName -like akamaipowershell-testing* | ForEach-Object {
            Remove-IVMPolicySet -PolicySetID $_.id @CommonParams
        }
    }

    #-------------------------------------------------
    #                  Image Tests
    #-------------------------------------------------

    Context 'New-IVMPolicySet' {
        It 'creates an image policy set' {
            $PD.NewImagePolicySet = New-IVMPolicySet -Name $TestImagePolicySetName -ContractID $TestContract -Type Image -Region EMEA @CommonParams
            $PD.NewImagePolicySet.name | Should -Be $TestImagePolicySetName
        }
    }

    Context 'Get-IVMPolicySet, All' {
        It 'gets all policy sets' {
            $PD.AllPolicySets = Get-IVMPolicySet @CommonParams -ContractID $TestContract 
            $PD.AllPolicySets[0].name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IVMPolicySet, Single' {
        It 'gets a image policy set' {
            $PD.GetSingleImagePolicySet = Get-IVMPolicySet -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract @CommonParams
            $PD.GetSingleImagePolicySet.name | Should -Be $TestImagePolicySetName
        }
    }

    Context 'New-IVMPolicy, Pipeline' {
        It 'creates a new Image policy via pipeline' {
            $PD.NewImagePolicyPipe = $TestImagePolicy | New-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams
            $PD.NewImagePolicyPipe.operationPerformed | Should -Be 'CREATED'
        }
        It 'fails if policy already exists' {
            { $TestImagePolicy | New-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams } | Should -Throw
        }
    }

    Context 'Set-IVMPolicy ' {
        It 'updates a Image policy via pipeline' {
            $TestImagePolicy.output.quality = 95
            $PD.SetImagePolicyPipe = $TestImagePolicy | Set-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams
            $PD.SetImagePolicyPipe.operationPerformed | Should -Be 'UPDATED'
        }
    }

    Context 'Restore-IVMPolicy' {
        It 'reverts a policy back to the previous version' {
            $PD.RestoreImagePolicy = Restore-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams
            $PD.RestoreImagePolicy.operationPerformed | Should -Be 'UPDATED'
            $PD.RestoreImagePolicy.description | Should -BeLike '*has been rolled back to version*'
        }
    }

    Context 'Remove-IVMPolicy' {
        It 'deletes an image policy' {
            $PD.RemoveImagePolicy = Remove-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $TestNetwork  @CommonParams
            $PD.RemoveImagePolicy.operationPerformed | Should -Be 'DELETED'
        }
    }

    Context 'Create an image policy with body parameter' {
        It 'New-IVMPolicy creates a new Image policy with body parameter' {
            $PD.NewImagePolicyBody = New-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $TestNetwork -Body $TestImagePolicyBody @CommonParams
            $PD.NewImagePolicyBody.operationPerformed | Should -Be 'CREATED'
        }
    }

    Context 'Get-IVMPolicy, All' {
        It 'gets all Image Policies' {
            $PD.AllImagePolicies = Get-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -Network $TestNetwork @CommonParams
            $PD.AllImagePolicies[0].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IVMPolicy, Single' {
        It 'gets a single Image Policy' {
            $PD.GetSingleImagePolicy = Get-IVMPolicy -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams
            $PD.GetSingleImagePolicy.id | Should -Be $TestImagePolicyName
        }
    }

    Context 'Set-IVMPolicySet' {
        It 'updates an image policy sets name and region' {
            $PD.SetImagePolicySet = Set-IVMPolicySet -ContractID $TestContract -Region US -Name 'akamaipowershell-testing-image-changed-name' -PolicySetID $PD.NewImagePolicySet.id @CommonParams
            $PD.SetImagePolicySet.name | Should -Match '-changed-name'
            $PD.SetImagePolicySet.region | Should -Be 'US'
        }
    }

    Context 'Get-IVMPolicyHistory' {
        It 'gets the Image Policy history' {
            $PD.GetImagePolicyHistory = Get-IVMPolicyHistory -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $TestNetwork @CommonParams
            $PD.GetImagePolicyHistory | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-IVMPolicySet' {
        It "deletes an image policy set" {
            Remove-IVMPolicySet -PolicySetID $PD.NewImagePolicySet.id -ContractID $TestContract @CommonParams
        }
    }

    #-------------------------------------------------
    #                       Video Tests              #
    #-------------------------------------------------

    Context 'New-IVMPolicySet' {
        It 'creates a video policy set' {
            $PD.NewVideoPolicySet = New-IVMPolicySet -Name $TestVideoPolicySetName -ContractID $TestContract -Type Video -Region US @CommonParams
            $PD.NewVideoPolicySet.name | Should -Be $TestVideoPolicySetName
        }
    }

    Context 'Get-IVMPolicySet, Single' {
        It 'gets a video policy set' {
            $PD.GetSingleVideoPolicySet = Get-IVMPolicySet -PolicySetID $PD.NewVideoPolicySet.id -ContractID $TestContract @CommonParams
            $PD.GetSingleVideoPolicySet.name | Should -Be $TestVideoPolicySetName
        }
    }

    Context 'New-IVMPolicy' {
        It 'creates a new Video policy via pipeline' {
            $PD.NewVideoPolicyPipe = $TestVideoPolicy | New-IVMPolicy -PolicySetID $PD.NewVideoPolicySet.id -ContractID $TestContract -PolicyID $TestVideoPolicyName -Network $TestNetwork @CommonParams
            $PD.NewVideoPolicyPipe.operationPerformed | Should -Be 'CREATED'
        }
    }

    Context 'Remove-IVMPolicy' {
        It 'deletes a video policy' {
            $PD.RemoveVideoPolicy = Remove-IVMPolicy -PolicySetID $PD.NewVideoPolicySet.id -ContractID $TestContract -PolicyID $TestVideoPolicyName -Network $TestNetwork @CommonParams
            $PD.RemoveVideoPolicy.operationPerformed | Should -Be 'DELETED'
        }
    }

    Context 'New-IVMPolicy' {
        It 'creates a new Video policy with body parameter' {
            $PD.NewVideoPolicyBody = New-IVMPolicy -PolicySetID $PD.NewVideoPolicySet.id -ContractID $TestContract -PolicyID $TestVideoPolicyName -Network $TestNetwork -Body $TestVideoPolicyBody @CommonParams
            $PD.NewVideoPolicyBody.operationPerformed | Should -Be 'CREATED'
        }
    }

    Context 'Get-IVMPolicy, Single' {
        It 'gets a single Video Policy' {
            $PD.GetSingleVideoPolicy = Get-IVMPolicy -PolicySetID $PD.NewVideoPolicySet.id -ContractID $TestContract -PolicyID $TestVideoPolicyName -Network $TestNetwork @CommonParams
            $PD.GetSingleVideoPolicy.id | Should -Be $TestVideoPolicyName
        }
    }

    Context 'Remove-IVMPolicySet' {
        It 'deletes a video policy set' {
            Remove-IVMPolicySet -PolicySetID $PD.NewVideoPolicySet.id -ContractID $TestContract @CommonParams
        }
    }
}
Describe 'Unsafe Akamai.IVM Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.IVM/Akamai.IVM.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.IVM"
        $PD = @{}
    }
    #-------------------------------------------------
    #               Log and Error Tests
    #-------------------------------------------------

    Context 'Get-IVMErrorDetails' {
        It 'gets error details' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IVM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IVMErrorDetails.json"
                return $Response | ConvertFrom-Json
            }
            $ErrorDetails = Get-IVMErrorDetails -PolicySetID 'videoPolicy' -Network Production
            $ErrorDetails | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IVMLogDetails' {
        It 'gets log details' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IVM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IVMLogDetails.json"
                return $Response | ConvertFrom-Json
            }
            $LogDetails = Get-IVMLogDetails -PolicySetID 'videoPolicy' -Network Production
            $LogDetails | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-IVMImage, All' {
        It 'lists images' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IVM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IVMImage_1.json"
                return $Response | ConvertFrom-Json
            }
            $Images = Get-IVMImage -PolicySetID 'imagePolicy' -Network Production
            $Images[0].url | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-IVMImage, single' {
        It 'retrieves a single image' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.IVM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-IVMImage.json"
                return $Response | ConvertFrom-Json
            }
            $Image = Get-IVMImage -PolicySetID 'imagePolicy' -Network Production -ImageID '/images/image.jpg?imageId=format/jpg'
            $Image.url | Should -Not -BeNullOrEmpty
        }
    }
}

