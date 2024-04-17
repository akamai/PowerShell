Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Datastream/Akamai.Datastream.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:TestStreamID = $env:PesterDatastreamID

Describe 'Safe Datastream Tests' {

    BeforeDiscovery {
        
    }

    ### Get-DataStream, all
    $Script:Streams = Get-DataStream -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-DataStream returns a list' {
        $Streams[0].StreamID | Should -Not -BeNullOrEmpty
    }
    
    ### Get-DataStream, single
    $Script:Stream = Get-DataStream -StreamID $TestStreamID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-DataStream, single returns the correct stream' {
        $Stream.StreamID | Should -Be $TestStreamID
    }

    ### Get-DatastreamDatasets
    $Script:Fields = Get-DatastreamDatasets -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-DatastreamDatasetField returns a list' {
        $Fields[0].datasetFieldName | Should -Not -BeNullOrEmpty
    }

    ### Get-DatastreamGroup
    $Script:Groups = Get-DatastreamGroups -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-DatastreamGroup returns a list' {
        $Groups[0].groupName | Should -Not -BeNullOrEmpty
    }

    ### Get-DataStreamHistory
    $Script:StreamHistory = Get-DataStreamHistory -StreamID $TestStreamID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-DataStreamHistory returns the correct stream' {
        $StreamHistory[0].streamId | Should -Be $TestStreamID
    }

    ### Get-DataStreamActivationHistory
    $Script:ActivationHistory = Get-DataStreamActivationHistory -StreamID $TestStreamID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-DataStreamActivationHistory returns the correct stream' {
        $ActivationHistory[0].streamId | Should -Be $TestStreamID
    }

    AfterAll {
        
    }
    
}

Describe 'Unsafe Datastream Tests' {
    ### Get-DataStreamPropertie
    $Script:Properties = Get-DataStreamProperties -GroupID $TestGroupID -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-DataStreamPropertie returns a list' {
        $Properties[0].propertyId | Should -Not -BeNullOrEmpty
    }

    ### New-DataStream
    $Script:NewStream = New-DataStream -Body $Stream -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-DataStream creates successfully' {
        $NewStream.streamStatus | Should -Be "ACTIVATING"
    }

    ### Remove-DataStream
    it 'Remove-DataStream deletes successfully' {
        { Remove-DataStream -StreamID $TestStreamID -EdgeRCFile $SafeEdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Set-DataStream by pipeline
    $Script:StreamByPipeline = ( $Stream | Set-DataStream -StreamID $TestStreamID -EdgeRCFile $SafeEdgeRCFile -Section $Section )
    it 'Set-DataStream completes successfully' {
        $StreamByPipeline.streamStatus | Should -Be "ACTIVATING"
    }

    ### Set-DataStream by body
    $Script:StreamByBody = Set-DataStream -StreamID $TestStreamID -Body $Stream -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-DataStream completes successfully' {
        $StreamByBody.streamStatus | Should -Be "ACTIVATING"
    }
    
    ### New-DatastreamActivation
    $Script:Activate = New-DatastreamActivation -StreamID $TestStreamID -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-DatastreamActivation activates successfully' {
        $Activate.streamStatus | Should -Be "ACTIVATING"
    }

    ### New-DatastreamDeactivation
    $Script:Deactivate = New-DatastreamDeactivation -StreamID $TestStreamID -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-DatastreamDeactivation deactivates successfully' {
        $Deactivate.streamStatus | Should -Be "ACTIVATING"
    }
    
    ### Get-DataStreamMetrics
    $Script:Metrics = Get-DataStreamMetrics -Start "2024-01-01T09:00:00" -End "01/01/2022 09:00:00" -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-DataStreamMetrics returns the correct data' {
        $Metrics.fileUploadMetrics[0].streamId | Should -Not -BeNullOrEmpty
    }
}
