Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.IVM/Akamai.IVM.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:Network = 'Staging'
$Script:TestImagePolicySetName = 'akamaipowershell-testing-image'
$Script:TestImagePolicyName = 'akamaipowershell-image-policy'
$Script:TestImagePolicyBody = '{"output":{"quality":85},"breakpoints":{"widths":[1024,2048]}}'
$Script:TestImagePolicy = ConvertFrom-Json $TestImagePolicyBody
$Script:TestVideoPolicySetName = 'akamaipowershell-testing-video'
$Script:TestVideoPolicyName = 'akamaipowershell-video-policy'
$Script:TestVideoPolicyBody = '{"breakpoints":{"widths":[854,1280,1920]},"id":"low-vid","output":{"perceptualQuality":"mediumLow"}}'
$Script:TestVideoPolicy = ConvertFrom-Json $TestVideoPolicyBody
$Script:TestImageCollectionId = "akamaipowershell-testing-collection"
$Script:TestImageCollection = ConvertFrom-Json @"
{"id":"$TestImageCollectionId","description":"akamaiPowershellTestCollection from Pipeline","definition":{"version":1,"items":[{"type":"image","url":"https://www.example.com/1234.jpg"}]}}
"@

Describe 'Safe ImageManager Tests' {
    #************************************************#
    #                       Image Tests              #
    #************************************************#

    ### Create a new image policy set
    $Script:NewImagePolicySet = New-IVMPolicySet -EdgeRCFile $EdgeRCFile -Section $Section -Name $TestImagePolicySetName -ContractID $TestContract -Type Image -Region EMEA
    it 'New-IVMPolicySet creates an image policy set' {
        $NewImagePolicySet.name | Should -Be $TestImagePolicySetName
    }

    ### Get all policy sets
    $Script:AllPolicySets = Get-IVMPolicySet -EdgeRCFile $EdgeRCFile -Section $Section -ContractID $TestContract 
    it 'Get-IVMPolicySet gets all policy sets' {
        $AllPolicySets[0].name | Should -Not -BeNullOrEmpty
    }

    ### Get a single policy set
    $Script:GetSingleImagePolicySet = Get-IVMPolicySet -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract 
    it 'Get-IVMPolicySet gets a image policy set' {
        $GetSingleImagePolicySet.name | Should -Be $TestImagePolicySetName
    }

    ### Add a new image policy to the policy set via pipeline
    $Script:NewImagePolicyPipe = $TestImagePolicy | New-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $Network 
    it 'New-IVMPolicy creates a new Image policy via pipeline' {
        $NewImagePolicyPipe.operationPerformed | Should -Be "CREATED"
    }

    ### Creation fails if the policy with the same name already exists
    $Script:NewImagePolicyExists = { $TestImagePolicy | New-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $Network } | Should -Throw 
    it 'New-IVMPolicy fails if policy already exists' {
        $NewImagePolicyExists | Should -BeNullOrEmpty
    }

    ### Change output quality  parameter to update the policy settings in the next test case
    $TestImagePolicy.output.quality = 95

    ### Update an existing image policy
    $Script:SetImagePolicyPipe = $TestImagePolicy | Set-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $Network 
    it 'Set-IVMPolicy updates a Image policy via pipeline' {
        $SetImagePolicyPipe.operationPerformed | Should -Be "UPDATED"
    }

    ### Restore an image policy to the previous version
    $Script:RestoreImagePolicy = Restore-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $Network 
    it 'Restore-IVMPolicy reverts a policy back to the previous version' {
        $RestoreImagePolicy.operationPerformed | Should -Be "UPDATED"
        $RestoreImagePolicy.description | Should -BeLike "*has been rolled back to version*"
    }

    ### Remove the image Policy
    { $Script:RemoveImagePolicy = Remove-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $Network } | Should -Not -Throw
    It "Remove-IVMPolicy deletes an image policy " {
        $RemoveImagePolicy.operationPerformed | Should -Be "DELETED"
    }

    ### Create an image policy with body parameter
    $Script:NewImagePolicyBody = New-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $Network -Body $TestImagePolicyBody
    it 'New-IVMPolicy creates a new Image policy with body parameter' {
        $NewImagePolicyBody.operationPerformed | Should -Be "CREATED"
    }

    ### Get all Policies
    $Script:AllImagePolicies = Get-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -Network $Network
    it 'Get-IVMPolicy gets all Image Policies' {
        $AllImagePolicies[0].id | Should -Not -BeNullOrEmpty
    }

    ### Get a single Policy
    $Script:GetSingleImagePolicy = Get-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $Network
    it 'Get-IVMPolicy gets a single Image Policy' {
        $GetSingleImagePolicy.id | Should -Be $TestImagePolicyName
    }

    $Script:SetImagePolicySet = Set-IVMPolicySet -EdgeRCFile $EdgeRCFile -Section $Section -ContractID $TestContract -Region US -Name "akamaipowershell-testing-image-changed-name" -PolicySetID $NewImagePolicySet.id
    it 'Set-IVMPolicySet updates an image policy sets name and region' {
        $SetImagePolicySet.name | Should -Match "-changed-name"
        $SetImagePolicySet.region | Should -Be "US"
    }

    $Script:GetImagePolicyHistory = Get-IVMPolicyHistory -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -PolicyID $TestImagePolicyName -Network $Network
    it 'Get-IVMPolicyHistory gets the Image Policy history' {
        $GetImagePolicyHistory  | Should -Not -BeNullOrEmpty
    }

    ### Create a IM Image Collection via Pipeline
    $Script:NewImageCollection = $TestImageCollection | New-IVMImageCollection -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract
    it 'New-IVMImageCollection creates a new Image collection via pipeline' {
        $NewImageCollection.operationPerformed | Should -Be "CREATED"
    }

    ### Creation fails if the collection with the same name already exists
    $Script:NewImageCollectionExists = { $TestImageCollection | New-IVMImageCollection -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract } | Should -Throw 
    it 'New-IVMImageCollection fails if collection already exists' {
        $NewImageCollectionExists | Should -BeNullOrEmpty
    }

    ### Change content of the Image Collection for update
    $TestImageCollectionBody = '{"id":"akamaipowershell-testing-collection","description":"akamaiPowershellTestCollection","definition":{"version":1,"items":[{"type":"image","url":"https://www.example.com/5678.jpg"}]}}'
    
    ### Update a IM Image collection with Body parameter
    $Script:SetImageCollection = Set-IVMImageCollection -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -ImageCollectionID $NewImageCollection.id -Body $TestImageCollectionBody
    it 'Set-IVMImageCollection updates an Image collection with Body Parameter' {
        $SetImageCollection.operationPerformed | Should -Be "UPDATED"
    }
    ### Get all Image collections
    $Script:AllImageCollections = Get-IVMImageCollection -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract
    it 'Get-IVMImageCollection gets all Image Collections' {
        $AllImageCollections.totalItems | Should -GT 0
    }

    ### Get a single Image collection
    $Script:GetSingleImageCollection = Get-IVMImageCollection -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -ImageCollectionId $TestImageCollection.id
    it 'Get-IVMImageCollection gets a single Image Collection' {
        $GetSingleImageCollection.id | Should -Be $TestImageCollectionId
    }
    
    $Script:RemoveImageCollection = Remove-IVMImageCollection -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract -ImageCollectionId $TestImageCollection.id
    it 'Remove-IVMImageCollection deletes an Image collection' {
        $RemoveImageCollection.operationPerformed | Should -Be "DELETED"
    }

    # Remove the Policy Set
    It "Remove-IVMPolicySet deletes an image policy set" {
        { Remove-IVMPolicySet -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewImagePolicySet.id -ContractID $TestContract } | Should -Not -Throw
    }

    #************************************************#
    #                       Video Tests              #
    #************************************************#

    ### Create a new video policy set
    $Script:NewVideoPolicySet = New-IVMPolicySet -EdgeRCFile $EdgeRCFile -Section $Section -Name $TestVideoPolicySetName -ContractID $TestContract -Type Video -Region US
    it 'New-IVMPolicySet creates a video policy set' {
        $NewVideoPolicySet.name | Should -Be $TestVideoPolicySetName
    }

    ### Get a single video policy set
    $Script:GetSingleVideoPolicySet = Get-IVMPolicySet -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewVideoPolicySet.id -ContractID $TestContract 
    it 'Get-IVMPolicySet gets a video policy set' {
        $GetSingleVideoPolicySet.name | Should -Be $TestVideoPolicySetName
    }

    ### Create a video policy via pipeline
    $Script:NewVideoPolicyPipe = $TestVideoPolicy | New-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewVideoPolicySet.id -ContractID $TestContract -PolicyID $TestVideoPolicyName -Network $Network
    it 'New-IVMPolicy creates a new Video policy via pipeline' {
        $NewVideoPolicyPipe.operationPerformed | Should -Be "CREATED"
    }

    ### Remove a video policy
    { $Script:RemoveVideoPolicy = Remove-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewVideoPolicySet.id -ContractID $TestContract -PolicyID $TestVideoPolicyName -Network $Network } | Should -Not -Throw
    It "Remove-IVMPolicy deletes a video policy " {
        $RemoveVideoPolicy.operationPerformed | Should -Be "DELETED"
    }

    ### Create a video policy with body parameter
    $Script:NewVideoPolicyBody = New-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewVideoPolicySet.id -ContractID $TestContract -PolicyID $TestVideoPolicyName -Network $Network -Body $TestVideoPolicyBody
    it 'New-IVMPolicy creates a new Video policy with body parameter' {
        $NewVideoPolicyBody.operationPerformed | Should -Be "CREATED"
    }

    ### Get a single video policy
    $Script:GetSingleVideoPolicy = Get-IVMPolicy -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewVideoPolicySet.id -ContractID $TestContract -PolicyID $TestVideoPolicyName -Network $Network
    it 'Get-IVMPolicy gets a single Video Policy' {
        $GetSingleVideoPolicy.id | Should -Be $TestVideoPolicyName
    }

    ### Remove the video policy set
    It "Remove-IVMPolicySet deletes a video policy set" {
        { Remove-IVMPolicySet -EdgeRCFile $EdgeRCFile -Section $Section -PolicySetID $NewVideoPolicySet.id -ContractID $TestContract } | Should -Not -Throw

    }

    AfterAll {
        ### Cleanup files
    }
    
}

Describe 'Unsafe ImageManager Tests' {
    #************************************************#
    #               Log and Error Tests              #
    #************************************************#
    ### Create a new image policy set
    $Script:ErrorDetails = Get-IVMErrorDetails -EdgeRCFile $SafeEdgeRCFile -Section $Section -PolicySetID 'videoPolicy' -Network Production
    it 'Get-IVMErrorDetails gets error details' {
        $ErrorDetails | Should -Not -BeNullOrEmpty
    }

    $Script:LogDetails = Get-IVMLogDetails -EdgeRCFile $SafeEdgeRCFile -Section $Section -PolicySetID 'videoPolicy' -Network Production
    it 'Get-IVMLogDetails gets log details' {
        $LogDetails | Should -Not -BeNullOrEmpty
    }
    
    # Get-IVMImage, all
    $Script:Images = Get-IVMImage -PolicySetID 'imagePolicy' -Network Production -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IVMImage, all, lists images' {
        $Images[0].url | Should -Not -BeNullOrEmpty
    }
    
    # Get-IVMImage, single
    $Script:Image = Get-IVMImage -PolicySetID 'imagePolicy' -Network Production -ImageID '/images/image.jpg?imageId=format/jpg' -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-IVMImage, single, retrieves a single image' {
        $Image.url | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        ### Cleanup files
    }
    
}