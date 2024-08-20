Describe 'Safe Akamai.Datastream Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Datastream/Akamai.Datastream.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestStreamID = $env:PesterDatastreamID
        $PD = @{}
    }

    AfterAll {
        
    }

    Context 'Get-DataStream, all' {
        It 'Get-DataStream returns a list' {
            $PD.Streams = Get-DataStream @CommonParams
            $PD.Streams[0].StreamID | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-DataStream, single' {
        It 'returns the correct stream' {
            $PD.Stream = Get-DataStream -StreamID $TestStreamID @CommonParams
            $PD.Stream.StreamID | Should -Be $TestStreamID
        }
    }

    Context 'Get-DatastreamDatasets' {
        It 'Get-DatastreamDatasetField returns a list' {
            $PD.Fields = Get-DatastreamDatasets @CommonParams
            $PD.Fields[0].datasetFieldName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DatastreamGroup' {
        It 'returns a list' {
            $PD.Groups = Get-DatastreamGroups @CommonParams
            $PD.Groups[0].groupName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DataStreamHistory' {
        It 'returns the correct stream' {
            $PD.StreamHistory = Get-DataStreamHistory -StreamID $TestStreamID @CommonParams
            $PD.StreamHistory[0].streamId | Should -Be $TestStreamID
        }
    }

    Context 'Get-DataStreamActivationHistory' {
        It 'returns the correct stream' {
            $PD.ActivationHistory = Get-DataStreamActivationHistory -StreamID $TestStreamID @CommonParams
            $PD.ActivationHistory[0].streamId | Should -Be $TestStreamID
        }
    }
}

Describe 'Unsafe Akamai.Datastream Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Datastream/Akamai.Datastream.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Datastream"
        $PD = @{}
    }

    Context 'Get-DataStreamProperties' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Datastream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-DataStreamProperties.json"
                return $Response | ConvertFrom-Json
            }
            $Properties = Get-DataStreamProperties -GroupID 111111
            $Properties[0].propertyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-DataStream' {
        It 'creates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Datastream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-DataStream.json"
                return $Response | ConvertFrom-Json
            }
            $PD.Stream = Get-DataStream -StreamID 123456
            $NewStream = New-DataStream -Body $PD.Stream
            $NewStream.streamStatus | Should -Be "ACTIVATING"
        }
    }

    Context 'Remove-DataStream' {
        It 'deletes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Datastream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-DataStream.json"
                return $Response | ConvertFrom-Json
            }
            Remove-DataStream -StreamID 123456 
        }
    }

    Context 'Set-DataStream by pipeline' {
        It 'Set-DataStream completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Datastream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-DataStream.json"
                return $Response | ConvertFrom-Json
            }
            $StreamByPipeline = ( $PD.Stream | Set-DataStream -StreamID 123456 )
            $StreamByPipeline.streamStatus | Should -Be "ACTIVATING"
        }
    }

    Context 'Set-DataStream by body' {
        It 'Set-DataStream completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Datastream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-DataStream.json"
                return $Response | ConvertFrom-Json
            }
            $StreamByBody = Set-DataStream -StreamID 123456 -Body $PD.Stream
            $StreamByBody.streamStatus | Should -Be "ACTIVATING"
        }
    }
    
    Context 'New-DatastreamActivation' {
        It 'activates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Datastream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-DatastreamActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Activate = New-DatastreamActivation -StreamID 123456
            $Activate.streamStatus | Should -Be "ACTIVATING"
        }
    }

    Context 'New-DatastreamDeactivation' {
        It 'deactivates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Datastream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-DatastreamDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $Deactivate = New-DatastreamDeactivation -StreamID 123456
            $Deactivate.streamStatus | Should -Be "ACTIVATING"
        }
    }
    
    Context 'Get-DataStreamMetrics' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Datastream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-DataStreamMetrics.json"
                return $Response | ConvertFrom-Json
            }
            $Metrics = Get-DataStreamMetrics -Start "2024-01-01T09:00:00" -End "01/01/2022 09:00:00"
            $Metrics.fileUploadMetrics[0].streamId | Should -Not -BeNullOrEmpty
        }
    }
}


