BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.DataStream Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.DataStream/Akamai.DataStream.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestStreamID = $env:PesterDataStreamID
        $TestPropertyID = $env:PesterPropertyID
        $TestZoneName = $env:PesterTestZoneName
        $TestGTMDomain = $env:PesterGTMDomain

        $NowUTC = (Get-Date).ToUniversalTime()
        $DateString = Get-date $NowUTC -Format 'yyyyMMddhhmmss'
        $StreamTemplate = @"
{
  "streamName": "replaceme",
  "groupId": $TestGroupID,
  "contractId": "$TestContract",
  "datasetFields": [],
  "destination": {
    "destinationType": "HTTPS",
    "displayName": "httpbin",
    "authenticationType": "NONE",
    "endpoint": "https://httpbin.org/post",
    "compressLogs": true
  },
  "deliveryConfiguration": {
    "frequency": {
      "intervalInSeconds": 60
    },
    "format": "JSON"
  }
}
"@

        # ---- Configure stream objects
        ## CDN
        $TestCDNStream = $StreamTemplate | ConvertFrom-Json
        $TestCDNStream.streamName = "powershell-cdn-$DateString"
        999, 1005, 1019, 1033 | ForEach-Object { $TestCDNStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }
        $Properties = @(
            @{
                propertyId = $TestPropertyID    
            }
        )
        $TestCDNStream | Add-Member -NotePropertyName properties -NotePropertyValue $Properties

        ## EdgeWorker
        $TestEWStream = $StreamTemplate | ConvertFrom-Json
        $TestEWStream.streamName = "powershell-edgeworkers-$DateString"
        6000..6003 | ForEach-Object { $TestEWStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }
        
        ## EdgeDNS
        $TestEDNSStream = $StreamTemplate | ConvertFrom-Json
        $TestEDNSStream.streamName = "powershell-edns-$DateString"
        4002, 4003, 4010, 4011 | ForEach-Object { $TestEDNSStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }
        $Zones = @(
            @{
                zoneName = $TestZoneName
            }
        )
        $TestEDNSStream | Add-Member -NotePropertyName zones -NotePropertyValue $Zones

        ## GTM
        $TestGTMStream = $StreamTemplate | ConvertFrom-Json
        $TestGTMStream.streamName = "powershell-gtm-$DateString"
        5002, 5003, 5010, 5011 | ForEach-Object { $TestGTMStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }
        $GTMProperties = @(
            @{
                propertyName = "@.$TestGTMDomain"
            }
        )
        $TestGTMStream | Add-Member -NotePropertyName properties -NotePropertyValue $GTMProperties


        $PD = @{}
    }

    AfterAll {
        Get-DataStream -LogType cdn @CommonParams | Where-Object streamName -like "powershell-cdn-*" | Remove-DataStream -LogType cdn @CommonParams
        Get-DataStream -LogType edgeworkers @CommonParams | Where-Object streamName -like "powershell-edgeworkers-*" | Remove-DataStream -LogType edgeworkers @CommonParams
        Get-DataStream -LogType edns @CommonParams | Where-Object streamName -like "powershell-edns-*" | Remove-DataStream -LogType edns @CommonParams
        Get-DataStream -LogType gtm @CommonParams | Where-Object streamName -like "powershell-gtm-*" | Remove-DataStream -LogType gtm @CommonParams
    }

    Context 'New-DataStream' -Tag 'New-DataStream' {
        Context 'CDN Stream' {
            It 'creates successfully' {
                $PD.NewCDNStream = $TestCDNStream | New-DataStream -LogType cdn @CommonParams
                $PD.NewCDNStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewCDNStream.streamStatus | Should -Be "INACTIVE"
                $PD.NewCDNStream.streamName | Should -Be $TestCDNStream.streamName
                $PD.NewCDNStream.properties[0].propertyId | Should -Be $TestPropertyID
            }
        }
        
        Context 'EdgeWorkers Stream' {
            It 'creates successfully' {
                $PD.NewEWStream = $TestEWStream | New-DataStream -LogType edgeworkers @CommonParams
                $PD.NewEWStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewEWStream.streamStatus | Should -Be "INACTIVE"
                $PD.NewEWStream.streamName | Should -Be $TestEWStream.streamName
            }
        }

        Context 'EDNS Stream' {
            It 'creates successfully' {
                $PD.NewEDNSStream = $TestEDNSStream | New-DataStream -LogType edns @CommonParams
                $PD.NewEDNSStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewEDNSStream.streamStatus | Should -Be "INACTIVE"
                $PD.NewEDNSStream.streamName | Should -Be $TestEDNSStream.streamName
                $PD.NewEDNSStream.zones[0].zoneName | Should -Be $TestZoneName
            }
        }

        Context 'GTM Stream' {
            It 'creates successfully' {
                $PD.NewGTMStream = $TestGTMStream | New-DataStream -LogType gtm @CommonParams
                $PD.NewGTMStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewGTMStream.streamStatus | Should -Be "INACTIVE"
                $PD.NewGTMStream.streamName | Should -Be $TestGTMStream.streamName
                $PD.NewGTMStream.properties[0].propertyName | Should -Be "@.$TestGTMDomain"
            }
        }
    }

    Context 'Get-DataStream' {
        Context 'List all CDN Streams' {
            It 'returns a list in the right format' {
                $PD.CDNStreams = Get-DataStream @CommonParams
                $PD.CDNStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.CDNStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.CDNStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.CDNStreams[0].properties | Should -Not -BeNullOrEmpty
            }
        }
        
        Context 'List all EdgeWorker Streams' {
            It 'returns a list in the right format' {
                $PD.EdgeWorkerStreams = Get-DataStream -LogType edgeworkers @CommonParams
                $PD.EdgeWorkerStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStreams[0].properties | Should -BeNullOrEmpty
            }
        }

        Context 'List all EDNS Streams' {
            It 'returns a list in the right format' {
                $PD.EDNSStreams = Get-DataStream -LogType edns @CommonParams
                $PD.EDNSStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.EDNSStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.EDNSStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.EDNSStreams[0].properties | Should -BeNullOrEmpty
                $PD.EDNSStreams[0].zones | Should -Not -BeNullOrEmpty
            }
        }
        
        Context 'List all GTM Streams' {
            It 'returns a list in the right format' {
                $PD.GTMStreams = Get-DataStream -LogType gtm @CommonParams
                $PD.GTMStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.GTMStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.GTMStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.GTMStreams[0].properties | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get single CDN stream' {
            It 'returns the correct stream' {
                $PD.CDNStream = Get-DataStream -StreamID $PD.NewCDNStream.streamID @CommonParams
                $PD.CDNStream.StreamID | Should -Be $PD.NewCDNStream.streamID
                $PD.CDNStream.streamName | Should -Be $PD.NewCDNStream.streamName
                $PD.CDNStream.properties[0].propertyId | Should -Be $TestPropertyID
                $PD.CDNStream.latestVersion | Should -Be 1
                $PD.CDNStream.datasetFields | Should -Not -BeNullOrEmpty
                $PD.CDNStream.destination | Should -Not -BeNullOrEmpty
                $PD.CDNStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
            }
        }
        
        Context 'Get single EdgeWorkers stream' {
            It 'returns the correct stream' {
                $PD.EdgeWorkerStream = Get-DataStream -LogType edgeworkers -StreamID $PD.NewEWStream.streamID @CommonParams
                $PD.EdgeWorkerStream.StreamID | Should -Be $PD.NewEWStream.streamID
                $PD.EdgeWorkerStream.streamName | Should -Be $PD.NewEWStream.streamName
                $PD.EdgeWorkerStream.latestVersion | Should -Be 1
                $PD.EdgeWorkerStream.datasetFields | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStream.destination | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
            }
        }
        
        Context 'Get single EDNS stream' {
            It 'returns the correct stream' {
                $PD.EDNSStream = Get-DataStream -LogType edns -StreamID $PD.NewEDNSStream.streamID @CommonParams
                $PD.EDNSStream.StreamID | Should -Be $PD.NewEDNSStream.streamID
                $PD.EDNSStream.streamName | Should -Be $PD.NewEDNSStream.streamName
                $PD.EDNSStream.latestVersion | Should -Be 1
                $PD.EDNSStream.datasetFields | Should -Not -BeNullOrEmpty
                $PD.EDNSStream.destination | Should -Not -BeNullOrEmpty
                $PD.EDNSStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
                $PD.EDNSStream.zones[0].zoneName | Should -Be $TestZoneName
            }
        }
        
        Context 'Get single GTM stream' {
            It 'returns the correct stream' {
                $PD.GTMStream = Get-DataStream -LogType gtm -StreamID $PD.NewGTMStream.streamID @CommonParams
                $PD.GTMStream.StreamID | Should -Be $PD.NewGTMStream.streamID
                $PD.GTMStream.streamName | Should -Be $PD.NewGTMStream.streamName
                $PD.GTMStream.properties[0].propertyName | Should -Be "@.$TestGTMDomain"
                $PD.GTMStream.latestVersion | Should -Be 1
                $PD.GTMStream.datasetFields | Should -Not -BeNullOrEmpty
                $PD.GTMStream.destination | Should -Not -BeNullOrEmpty
                $PD.GTMStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-DataStreamDatasets' {
        It 'returns a list of CDN datasets' {
            $PD.CDNDatasets = Get-DataStreamDatasets @CommonParams
            $PD.CDNDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            "CP code" | Should -BeIn $PD.CDNDatasets.datasetFieldName
        }
        It 'returns a list of EdgeWorker datasets' {
            $PD.EWDatasets = Get-DataStreamDatasets -LogType edgeworkers @CommonParams
            $PD.EWDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            "Severity" | Should -BeIn $PD.EWDatasets.datasetFieldName
        }
        It 'returns a list of EdgeDNS datasets' {
            $PD.EDNSDatasets = Get-DataStreamDatasets -LogType edns @CommonParams
            $PD.EDNSDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            "Epoch timestamp" | Should -BeIn $PD.EDNSDatasets.datasetFieldName
        }
        It 'returns a list of GTM datasets' {
            $PD.GTMDatasets = Get-DataStreamDatasets -LogType gtm @CommonParams
            $PD.GTMDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            5002 | Should -BeIn $PD.GTMDatasets.datasetFieldId
        }
    }

    Context 'Get-DataStreamGroup' {
        It 'returns a list' {
            $PD.Groups = Get-DataStreamGroups @CommonParams
            $PD.Groups[0].groupName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DataStreamHistory' {
        It 'returns the correct stream' {
            $PD.StreamHistory = Get-DataStreamHistory -StreamID $TestStreamID @CommonParams
            $PD.StreamHistory[0].streamId | Should -Be $TestStreamID
        }
    }

    Context 'Get-DataStreamProperties' {
        It 'returns a list' {
            $Properties = Get-DataStreamProperties -GroupID $TestGroupID @CommonParams
            $Properties[0].propertyId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-DataStreamEDNSZones' {
        It 'returns a list' {
            $Zones = Get-DataStreamEDNSZones -ContractID $TestContract @CommonParams
            $Zones[0].zoneName | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-DataStreamGTMProperties' {
        It 'returns a list' {
            $GTMProperties = Get-DataStreamGTMProperties -ContractID $TestContract @CommonParams
            $GTMProperties[0].propertyName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-DataStream' {
        Context 'CDN Stream' {
            BeforeAll {
                # Add a new data set field
                $PD.CDNStream.datasetFields += [PSCustomObject] @{
                    datasetFieldId = 2014
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetCDNStreamPipeline = $PD.CDNStream | Set-DataStream -LogType cdn @CommonParams
                    $PD.SetCDNStreamPipeline.streamStatus | Should -Be "INACTIVE"
                    $PD.SetCDNStreamPipeline.StreamID | Should -Be $PD.CDNStream.streamID
                    $PD.SetCDNStreamPipeline.streamName | Should -Be $PD.CDNStream.streamName
                    $PD.SetCDNStreamPipeline.properties[0].propertyId | Should -Be $TestPropertyID
                    $PD.SetCDNStreamPipeline.latestVersion | Should -Be 2
                    $PD.SetCDNStreamPipeline.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamPipeline.destination | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamPipeline.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamPipeline.datasetFields.datasetFieldId | Should -Contain 2014
                }
            }
        
            Context 'by body' {
                It 'updates successfully' {
                    $TestParams = @{
                        LogType  = 'cdn'
                        StreamID = $PD.CDNStream.streamId
                        Body     = ($PD.CDNStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetCDNStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetCDNStreamBody.streamStatus | Should -Be "INACTIVE"
                    $PD.SetCDNStreamBody.StreamID | Should -Be $PD.CDNStream.streamID
                    $PD.SetCDNStreamBody.streamName | Should -Be $PD.CDNStream.streamName
                    $PD.SetCDNStreamBody.properties[0].propertyId | Should -Be $TestPropertyID
                    $PD.SetCDNStreamBody.latestVersion | Should -Be 3
                    $PD.SetCDNStreamBody.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamBody.destination | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamBody.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamBody.datasetFields.datasetFieldId | Should -Contain 2014
                }
            }
        }

        Context 'EdgeWorkers Stream' {
            BeforeAll {
                # Add a new data set field
                $PD.EdgeWorkerStream.datasetFields += [PSCustomObject] @{
                    datasetFieldId = 6008
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetEWStreamPipeline = $PD.EdgeWorkerStream | Set-DataStream -LogType edgeworkers @CommonParams
                    $PD.SetEWStreamPipeline.streamStatus | Should -Be "INACTIVE"
                    $PD.SetEWStreamPipeline.StreamID | Should -Be $PD.EdgeWorkerStream.streamID
                    $PD.SetEWStreamPipeline.streamName | Should -Be $PD.EdgeWorkerStream.streamName
                    $PD.SetEWStreamPipeline.latestVersion | Should -Be 2
                    $PD.SetEWStreamPipeline.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetEWStreamPipeline.destination | Should -Not -BeNullOrEmpty
                    $PD.SetEWStreamPipeline.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetEWStreamPipeline.datasetFields.datasetFieldId | Should -Contain 6008
                }
            }
        
            Context 'by body' {
                It 'updates successfully' {
                    $TestParams = @{
                        LogType  = 'edgeworkers'
                        StreamID = $PD.EdgeWorkerStream.streamId
                        Body     = ($PD.EdgeWorkerStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetEWStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetEWStreamBody.streamStatus | Should -Be "INACTIVE"
                    $PD.SetEWStreamBody.StreamID | Should -Be $PD.EdgeWorkerStream.streamID
                    $PD.SetEWStreamBody.streamName | Should -Be $PD.EdgeWorkerStream.streamName
                    $PD.SetEWStreamBody.latestVersion | Should -Be 3
                    $PD.SetEWStreamBody.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetEWStreamBody.destination | Should -Not -BeNullOrEmpty
                    $PD.SetEWStreamBody.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetEWStreamBody.datasetFields.datasetFieldId | Should -Contain 6008
                }
            }
        }

        Context 'EDNS Stream' {
            BeforeAll {
                # Add a new data set field
                $PD.EDNSStream.datasetFields += [PSCustomObject] @{
                    datasetFieldId = 4013
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetEDNSStreamPipeline = $PD.EDNSStream | Set-DataStream -LogType edns @CommonParams
                    $PD.SetEDNSStreamPipeline.streamStatus | Should -Be "INACTIVE"
                    $PD.SetEDNSStreamPipeline.StreamID | Should -Be $PD.EDNSStream.streamID
                    $PD.SetEDNSStreamPipeline.streamName | Should -Be $PD.EDNSStream.streamName
                    $PD.SetEDNSStreamPipeline.latestVersion | Should -Be 2
                    $PD.SetEDNSStreamPipeline.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetEDNSStreamPipeline.destination | Should -Not -BeNullOrEmpty
                    $PD.SetEDNSStreamPipeline.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetEDNSStreamPipeline.datasetFields.datasetFieldId | Should -Contain 4013
                }
            }
        
            Context 'by body' {
                It 'updates successfully' {
                    $TestParams = @{
                        LogType  = 'edns'
                        StreamID = $PD.EDNSStream.streamId
                        Body     = ($PD.EDNSStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetEDNSStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetEDNSStreamBody.streamStatus | Should -Be "INACTIVE"
                    $PD.SetEDNSStreamBody.StreamID | Should -Be $PD.EDNSStream.streamID
                    $PD.SetEDNSStreamBody.streamName | Should -Be $PD.EDNSStream.streamName
                    $PD.SetEDNSStreamBody.latestVersion | Should -Be 3
                    $PD.SetEDNSStreamBody.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetEDNSStreamBody.destination | Should -Not -BeNullOrEmpty
                    $PD.SetEDNSStreamBody.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetEDNSStreamBody.datasetFields.datasetFieldId | Should -Contain 4013
                }
            }
        }

        Context 'GTM Stream' {
            BeforeAll {
                # Add a new data set field
                $PD.GTMStream.datasetFields += [PSCustomObject] @{
                    datasetFieldId = 5013
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetGTMStreamPipeline = $PD.GTMStream | Set-DataStream -LogType gtm @CommonParams
                    $PD.SetGTMStreamPipeline.streamStatus | Should -Be "INACTIVE"
                    $PD.SetGTMStreamPipeline.StreamID | Should -Be $PD.GTMStream.streamID
                    $PD.SetGTMStreamPipeline.streamName | Should -Be $PD.GTMStream.streamName
                    $PD.SetGTMStreamPipeline.latestVersion | Should -Be 2
                    $PD.SetGTMStreamPipeline.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamPipeline.destination | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamPipeline.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamPipeline.datasetFields.datasetFieldId | Should -Contain 5013
                }
            }
        
            Context 'by body' {
                It 'updates successfully' {
                    $TestParams = @{
                        LogType  = 'gtm'
                        StreamID = $PD.GTMStream.streamId
                        Body     = ($PD.GTMStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetGTMStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetGTMStreamBody.streamStatus | Should -Be "INACTIVE"
                    $PD.SetGTMStreamBody.StreamID | Should -Be $PD.GTMStream.streamID
                    $PD.SetGTMStreamBody.streamName | Should -Be $PD.GTMStream.streamName
                    $PD.SetGTMStreamBody.latestVersion | Should -Be 3
                    $PD.SetGTMStreamBody.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamBody.destination | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamBody.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamBody.datasetFields.datasetFieldId | Should -Contain 5013
                }
            }
        }
    }

    Context 'Update-DataStream' {
        Context 'CDN stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        path  = '/streamName'
                        op    = "REPLACE"
                        value = "$($PD.CDNStream.StreamName)-Updated"
                    }
                )
                $UpdateResult = $Update | Update-DataStream -LogType cdn -StreamID $PD.CDNStream.StreamID @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.CDNStream.StreamName)-Updated"
            }
        }

        Context 'EdgeWorkers stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        path  = '/streamName'
                        op    = "REPLACE"
                        value = "$($PD.EdgeWorkerStream.StreamName)-Updated"
                    }
                )
                $UpdateResult = $Update | Update-DataStream -LogType edgeworkers -StreamID $PD.EdgeWorkerStream.StreamID @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.EdgeWorkerStream.StreamName)-Updated"
            }
        }
        
        Context 'EDNS stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        path  = '/streamName'
                        op    = "REPLACE"
                        value = "$($PD.EDNSStream.StreamName)-Updated"
                    }
                )
                $UpdateResult = $Update | Update-DataStream -LogType edns -StreamID $PD.EDNSStream.StreamID @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.EDNSStream.StreamName)-Updated"
            }
        }
        
        Context 'GTM stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        path  = '/streamName'
                        op    = "REPLACE"
                        value = "$($PD.GTMStream.StreamName)-Updated"
                    }
                )
                $UpdateResult = $Update | Update-DataStream -LogType gtm -StreamID $PD.GTMStream.StreamID @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.GTMStream.StreamName)-Updated"
            }
        }
    }

    Context 'Remove-DataStream' {
        Context 'Remove CDN Stream' {
            It 'deletes successfully' {
                $PD.NewCDNStream | Remove-DataStream -LogType cdn @CommonParams
            }
        }
        
        Context 'Remove EdgeWorkers Stream' {
            It 'deletes successfully' {
                $PD.NewEWStream | Remove-DataStream -LogType edgeworkers @CommonParams
            }
        }
        
        Context 'Remove EDNS Stream' {
            It 'deletes successfully' {
                $PD.NewEDNSStream | Remove-DataStream -LogType edns @CommonParams
            }
        }
        
        Context 'Remove GTM Stream' {
            It 'deletes successfully' {
                $PD.NewGTMStream | Remove-DataStream -LogType gtm @CommonParams
            }
        }
    }
}

Describe 'Unsafe Akamai.DataStream Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.DataStream/Akamai.DataStream.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.DataStream"
        $PD = @{}
    }
    
    Context 'New-DataStreamActivation' {
        It 'activates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.DataStream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-DataStreamActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Activate = New-DataStreamActivation -StreamID 123456
            $Activate.streamStatus | Should -Be "ACTIVATING"
        }
    }

    Context 'New-DataStreamDeactivation' {
        It 'deactivates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.DataStream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-DataStreamDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $Deactivate = New-DataStreamDeactivation -StreamID 123456
            $Deactivate.streamStatus | Should -Be "ACTIVATING"
        }
    }
    
    Context 'Get-DataStreamMetrics' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.DataStream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-DataStreamMetrics.json"
                return $Response | ConvertFrom-Json
            }
            $Metrics = Get-DataStreamMetrics -Start "2024-01-01T09:00:00" -End "01/01/2022 09:00:00"
            $Metrics.fileUploadMetrics[0].streamId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DataStreamActivationHistory' {
        It 'returns the correct stream' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.DataStream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-DataStreamActivationHistory.json"
                return $Response | ConvertFrom-Json
            }
            $ActivationHistory = Get-DataStreamActivationHistory -StreamID 123456
            $ActivationHistory[0].streamId | Should -Match '^[0-9]+$'
        }
    }
}


