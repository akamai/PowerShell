BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw 'Required environment variables are missing'
    }
}

Describe 'Akamai.DataStream Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'

        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.DataStream'
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
        $TestStreamID = $env:PesterDataStreamID
        $TestPropertyID = $env:PesterPropertyID
        $TestZoneName = $env:PesterTestZoneName
        $TestGTMDomain = $env:PesterGTMDomain
        $TestAppSecID = $env:PesterAppSecConfigID
        $TestAppSecName = $env:PesterAppsecConfigName

        $NowUTC = (Get-Date).ToUniversalTime()
        $StreamTemplate = @"
{
  "streamName": "replaceme",
  "groupId": "$TestGroupID",
  "contractId": "$TestContractID",
  "datasetFields": [],
  "destination": {
    "destinationType": "HTTPS",
    "displayName": "httpbin",
    "authenticationType": "NONE",
    "endpoint": "https://httpbun.pwsh.aka-dev.net/anything",
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

        $TestAnswerXSSID = 1213
        $TestAnswerXSSID2 = 1257
        $TestAnswerXName = "pester"
        $TestAnswerXName2 = "pester2"
        $TestAnswerXStream = 119602

        # ---- Configure stream objects
        ## CDN
        $TestCDNStream = $StreamTemplate | ConvertFrom-Json
        $TestCDNStream.streamName = "pester-cdn-$Timestamp"
        999, 1005, 1019, 1033 | ForEach-Object { $TestCDNStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }
        $Properties = @(
            @{
                'propertyId' = $TestPropertyID
            }
        )
        $TestCDNStream | Add-Member -NotePropertyName properties -NotePropertyValue $Properties

        ## EdgeWorker
        $TestEWStream = $StreamTemplate | ConvertFrom-Json
        $TestEWStream.streamName = "pester-edgeworkers-$Timestamp"
        6000..6003 | ForEach-Object { $TestEWStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }

        ## EdgeDNS
        $TestEDNSStream = $StreamTemplate | ConvertFrom-Json
        $TestEDNSStream.streamName = "pester-edns-$Timestamp"
        4002, 4003, 4010, 4011 | ForEach-Object { $TestEDNSStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }
        $Zones = @(
            @{
                'zoneName' = $TestZoneName
            }
        )
        $TestEDNSStream | Add-Member -NotePropertyName zones -NotePropertyValue $Zones

        ## GTM
        $TestGTMStream = $StreamTemplate | ConvertFrom-Json
        $TestGTMStream.streamName = "pester-gtm-$Timestamp"
        5002, 5003, 5010, 5011 | ForEach-Object { $TestGTMStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }
        $GTMProperties = @(
            @{
                'propertyName' = "@.$TestGTMDomain"
            }
        )
        $TestGTMStream | Add-Member -NotePropertyName properties -NotePropertyValue $GTMProperties

        ### AppSec
        $TestAppSecStream = $StreamTemplate | ConvertFrom-Json
        $TestAppSecStream.streamName = "pester-appsec-$Timestamp"
        $TestAppSecStream | Add-Member -NotePropertyName appSecConfigs -NotePropertyValue @(
            @{
                'appSecId'   = $TestAppSecID
                'appSecName' = $TestAppSecName
            }
        )

        ### AnswerX
        $TestAnswerXStream = $StreamTemplate | ConvertFrom-Json
        $TestAnswerXStream.streamName = "pester-answerx-$Timestamp"
        $TestAnswerXStream | Add-Member -NotePropertyName serviceSubletterIds -NotePropertyValue @(@{ 'ssid' = $TestAnswerXSSID2 })
        9020 | ForEach-Object { $TestAnswerXStream.datasetFields += [PSCustomObject] @{ datasetFieldId = $_ } }

        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.DataStream"
        $PD = @{}
    }

    AfterAll {
        Get-DataStream -StreamType cdn @CommonParams | Where-Object streamName -Like "pester-cdn-$Timestamp*" | Remove-DataStream @CommonParams
        Get-DataStream -StreamType edgeworkers @CommonParams | Where-Object streamName -Like "pester-edgeworkers-$Timestamp*" | Remove-DataStream @CommonParams
        Get-DataStream -StreamType edns @CommonParams | Where-Object streamName -Like "pester-edns-$Timestamp*" | Remove-DataStream @CommonParams
        Get-DataStream -StreamType gtm @CommonParams | Where-Object streamName -Like "pester-gtm-$Timestamp*" | Remove-DataStream @CommonParams
        Get-DataStream -StreamType appsec @CommonParams | Where-Object streamName -Like "pester-appsec-$Timestamp*" | Remove-DataStream  @CommonParams
        Get-DataStream -StreamType answerx @CommonParams | Where-Object streamName -Like "pester-answerx-$Timestamp*" | Remove-DataStream @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'New-DataStream' -Tag 'New-DataStream' {
        Context 'CDN Stream' {
            It 'creates successfully using alias' {
                $TestParams = @{
                    'LogType' = 'cdn'
                }
                $PD.NewCDNStream = $TestCDNStream | New-DataStream @TestParams @CommonParams
                $PD.NewCDNStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewCDNStream.streamStatus | Should -Be 'INACTIVE'
                $PD.NewCDNStream.streamName | Should -Be $TestCDNStream.streamName
                $PD.NewCDNStream.streamType | Should -Be 'cdn'
                $PD.NewCDNStream.properties[0].propertyId | Should -Be $TestPropertyID
            }
        }

        Context 'EdgeWorkers Stream' {
            It 'creates successfully' {
                $TestParams = @{
                    'StreamType' = 'edgeworkers'
                }
                $PD.NewEWStream = $TestEWStream | New-DataStream @TestParams @CommonParams
                $PD.NewEWStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewEWStream.streamStatus | Should -Be 'INACTIVE'
                $PD.NewEWStream.streamName | Should -Be $TestEWStream.streamName
                $PD.NewEWStream.streamType | Should -Be 'edgeworkers'
            }
        }

        Context 'EDNS Stream' {
            It 'creates successfully' {
                $TestParams = @{
                    'StreamType' = 'edns'
                }
                $PD.NewEDNSStream = $TestEDNSStream | New-DataStream @TestParams @CommonParams
                $PD.NewEDNSStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewEDNSStream.streamStatus | Should -Be 'INACTIVE'
                $PD.NewEDNSStream.streamName | Should -Be $TestEDNSStream.streamName
                $PD.NewEDNSStream.streamType | Should -Be 'edns'
                $PD.NewEDNSStream.zones[0].zoneName | Should -Be $TestZoneName
            }
        }

        Context 'GTM Stream' {
            It 'creates successfully' {
                $TestParams = @{
                    'StreamType' = 'gtm'
                }
                $PD.NewGTMStream = $TestGTMStream | New-DataStream @TestParams @CommonParams
                $PD.NewGTMStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewGTMStream.streamStatus | Should -Be 'INACTIVE'
                $PD.NewGTMStream.streamName | Should -Be $TestGTMStream.streamName
                $PD.NewGTMStream.streamType | Should -Be 'gtm'
                $PD.NewGTMStream.properties[0].propertyName | Should -Be "@.$TestGTMDomain"
            }
        }

        Context 'AppSec Stream' {
            It 'creates successfully' {
                $TestParams = @{
                    'StreamType' = 'appsec'
                }
                $PD.NewAppSecStream = $TestAppSecStream | New-DataStream @TestParams @CommonParams
                $PD.NewAppSecStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewAppSecStream.streamStatus | Should -Be 'INACTIVE'
                $PD.NewAppSecStream.streamName | Should -Be $TestAppSecStream.streamName
                $PD.NewAppSecStream.streamType | Should -Be 'appsec'
                $PD.NewAppSecStream.appSecConfigs[0].appSecId | Should -Be $TestAppSecID
                $PD.NewAppSecStream.appSecConfigs[0].appSecName | Should -Be $TestAppSecName
            }
        }

        Context 'AnswerX Stream' {
            It 'creates successfully' {
                $TestParams = @{
                    'StreamType' = 'answerx'
                }
                $PD.NewAnswerXStream = $TestAnswerXStream | New-DataStream @TestParams @CommonParams
                $PD.NewAnswerXStream.streamId | Should -Match '^[0-9]+$'
                $PD.NewAnswerXStream.streamStatus | Should -Be 'INACTIVE'
                $PD.NewAnswerXStream.streamName | Should -Be $TestAnswerXStream.streamName
                $PD.NewAnswerXStream.streamType | Should -Be 'answerx'
                $PD.NewAnswerXStream.serviceSubletterIds[0].ssid | Should -Be $TestAnswerXSSID2
                $PD.NewAnswerXStream.serviceSubletterIds[0].name | Should -Be $TestAnswerXName2
            }
        }
    }

    Context 'Get-DataStream' {
        Context 'List all CDN Streams using assumed default' {
            It 'returns a list in the right format' {
                $PD.CDNStreams = Get-DataStream @CommonParams
                $PD.CDNStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.CDNStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.CDNStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.CDNStreams[0].streamType | Should -Be 'cdn'
                $PD.CDNStreams[0].properties | Should -Not -BeNullOrEmpty
            }
        }

        Context 'List all EdgeWorker Streams using alias' {
            It 'returns a list in the right format' {
                $TestParams = @{
                    'LogType' = 'edgeworkers'
                }
                $PD.EdgeWorkerStreams = Get-DataStream @TestParams @CommonParams
                $PD.EdgeWorkerStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStreams[0].streamType | Should -Be 'edgeworkers'
                $PD.EdgeWorkerStreams[0].properties | Should -BeNullOrEmpty
            }
        }

        Context 'List all EDNS Streams' {
            It 'returns a list in the right format' {
                $TestParams = @{
                    'StreamType' = 'edns'
                }
                $PD.EDNSStreams = Get-DataStream @TestParams @CommonParams
                $PD.EDNSStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.EDNSStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.EDNSStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.EDNSStreams[0].streamType | Should -Be 'edns'
                $PD.EDNSStreams[0].properties | Should -BeNullOrEmpty
                $PD.EDNSStreams[0].zones | Should -Not -BeNullOrEmpty
            }
        }

        Context 'List all GTM Streams' {
            It 'returns a list in the right format' {
                $TestParams = @{
                    'StreamType' = 'gtm'
                }
                $PD.GTMStreams = Get-DataStream @TestParams @CommonParams
                $PD.GTMStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.GTMStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.GTMStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.GTMStreams[0].streamType | Should -Be 'gtm'
                $PD.GTMStreams[0].properties | Should -Not -BeNullOrEmpty
            }
        }

        Context 'List all AppSec Streams' {
            It 'returns a list in the right format' {
                $TestParams = @{
                    'StreamType' = 'appsec'
                }
                $PD.AppSecStreams = Get-DataStream @TestParams @CommonParams
                $PD.AppSecStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.AppSecStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.AppSecStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.AppSecStreams[0].streamType | Should -Be 'appsec'
                $PD.AppSecStreams[0].appSecConfigs | Should -Not -BeNullOrEmpty
            }
        }

        Context 'List all AnswerX Streams' {
            It 'returns a list in the right format' {
                $TestParams = @{
                    'StreamType' = 'answerx'
                }
                $PD.AnswerXStreams = Get-DataStream @TestParams @CommonParams
                $PD.AnswerXStreams[0].streamID | Should -Not -BeNullOrEmpty
                $PD.AnswerXStreams[0].streamName | Should -Not -BeNullOrEmpty
                $PD.AnswerXStreams[0].streamVersion | Should -Not -BeNullOrEmpty
                $PD.AnswerXStreams[0].streamType | Should -Be 'answerx'
                $PD.AnswerXStreams[0].serviceSubletterIds | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get single CDN stream' {
            It 'returns the correct stream' {
                $PD.CDNStream = $PD.NewCDNStream | Get-DataStream @CommonParams
                $PD.CDNStream.StreamID | Should -Be $PD.NewCDNStream.streamID
                $PD.CDNStream.streamName | Should -Be $PD.NewCDNStream.streamName
                $PD.CDNStream.streamType | Should -Be 'cdn'
                $PD.CDNStream.properties[0].propertyId | Should -Be $TestPropertyID
                $PD.CDNStream.latestVersion | Should -Be 1
                $PD.CDNStream.datasetFields | Should -Not -BeNullOrEmpty
                $PD.CDNStream.destination | Should -Not -BeNullOrEmpty
                $PD.CDNStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get single EdgeWorkers stream' {
            It 'returns the correct stream' {
                $TestParams = @{
                    'StreamType' = 'edgeworkers'
                    'StreamID'   = $PD.NewEWStream.streamID
                }
                $PD.EdgeWorkerStream = Get-DataStream @TestParams @CommonParams
                $PD.EdgeWorkerStream.StreamID | Should -Be $PD.NewEWStream.streamID
                $PD.EdgeWorkerStream.streamName | Should -Be $PD.NewEWStream.streamName
                $PD.EdgeWorkerStream.streamType | Should -Be 'edgeworkers'
                $PD.EdgeWorkerStream.latestVersion | Should -Be 1
                $PD.EdgeWorkerStream.datasetFields | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStream.destination | Should -Not -BeNullOrEmpty
                $PD.EdgeWorkerStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get single EDNS stream' {
            It 'returns the correct stream' {
                $TestParams = @{
                    'StreamType' = 'edns'
                    'StreamID'   = $PD.NewEDNSStream.streamID
                }
                $PD.EDNSStream = Get-DataStream @TestParams @CommonParams
                $PD.EDNSStream.StreamID | Should -Be $PD.NewEDNSStream.streamID
                $PD.EDNSStream.streamName | Should -Be $PD.NewEDNSStream.streamName
                $PD.EDNSStream.streamType | Should -Be 'edns'
                $PD.EDNSStream.latestVersion | Should -Be 1
                $PD.EDNSStream.datasetFields | Should -Not -BeNullOrEmpty
                $PD.EDNSStream.destination | Should -Not -BeNullOrEmpty
                $PD.EDNSStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
                $PD.EDNSStream.zones[0].zoneName | Should -Be $TestZoneName
            }
        }

        Context 'Get single GTM stream' {
            It 'returns the correct stream' {
                $TestParams = @{
                    'StreamType' = 'gtm'
                    'StreamID'   = $PD.NewGTMStream.streamID
                }
                $PD.GTMStream = Get-DataStream @TestParams @CommonParams
                $PD.GTMStream.StreamID | Should -Be $PD.NewGTMStream.streamID
                $PD.GTMStream.streamName | Should -Be $PD.NewGTMStream.streamName
                $PD.GTMStream.streamType | Should -Be 'gtm'
                $PD.GTMStream.properties[0].propertyName | Should -Be "@.$TestGTMDomain"
                $PD.GTMStream.latestVersion | Should -Be 1
                $PD.GTMStream.datasetFields | Should -Not -BeNullOrEmpty
                $PD.GTMStream.destination | Should -Not -BeNullOrEmpty
                $PD.GTMStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get single AppSec stream' {
            It 'returns the correct stream' {
                $TestParams = @{
                    'StreamType' = 'appsec'
                    'StreamID'   = $PD.NewAppSecStream.streamID
                }
                $PD.AppSecStream = Get-DataStream @TestParams @CommonParams
                $PD.AppSecStream.StreamID | Should -Be $PD.NewAppSecStream.streamID
                $PD.AppSecStream.streamName | Should -Be $PD.NewAppSecStream.streamName
                $PD.AppSecStream.streamType | Should -Be 'appsec'
                $PD.AppSecStream.appSecConfigs[0].appSecName | Should -Be $TestAppSecName
                $PD.AppSecStream.latestVersion | Should -Be 1
                $PD.AppSecStream.destination | Should -Not -BeNullOrEmpty
                $PD.AppSecStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get single AnswerX stream' {
            It 'returns the correct stream' {
                $TestParams = @{
                    'StreamType' = 'answerx'
                    'StreamID'   = $PD.NewAnswerXStream.streamID
                }
                $PD.AnswerXStream = Get-DataStream @TestParams @CommonParams
                $PD.AnswerXStream.streamID | Should -Be $PD.NewAnswerXStream.streamID
                $PD.AnswerXStream.streamName | Should -Be $PD.NewAnswerXStream.streamName
                $PD.AnswerXStream.streamType | Should -Be 'answerx'
                $PD.AnswerXStream.serviceSubletterIds[0] | Should -Not -BeNullOrEmpty
                $PD.AnswerXStream.latestVersion | Should -Be 1
                $PD.AnswerXStream.destination | Should -Not -BeNullOrEmpty
                $PD.AnswerXStream.deliveryConfiguration | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-DataStreamDatasets' {
        It 'returns a list of CDN datasets' {
            $PD.CDNDatasets = Get-DataStreamDatasets @CommonParams
            $PD.CDNDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            'CP code' | Should -BeIn $PD.CDNDatasets.datasetFieldName
        }
        It 'returns a list of EdgeWorker datasets using alias' {
            $TestParams = @{
                'LogType' = 'edgeworkers'
            }
            $PD.EWDatasets = Get-DataStreamDatasets @TestParams @CommonParams
            $PD.EWDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            'Severity' | Should -BeIn $PD.EWDatasets.datasetFieldName
        }
        It 'returns a list of EdgeDNS datasets' {
            $TestParams = @{
                'StreamType' = 'edns'
            }
            $PD.EDNSDatasets = Get-DataStreamDatasets @TestParams @CommonParams
            $PD.EDNSDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            'Epoch timestamp' | Should -BeIn $PD.EDNSDatasets.datasetFieldName
        }
        It 'returns a list of GTM datasets' {
            $TestParams = @{
                'StreamType' = 'gtm'
            }
            $PD.GTMDatasets = Get-DataStreamDatasets @TestParams @CommonParams
            $PD.GTMDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            5002 | Should -BeIn $PD.GTMDatasets.datasetFieldId
        }
        It 'returns a list of AppSec datasets' {
            $TestParams = @{
                'StreamType' = 'appsec'
            }
            $PD.AppSecDatasets = Get-DataStreamDatasets @TestParams @CommonParams
            $PD.AppSecDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            8002 | Should -BeIn $PD.AppSecDatasets.datasetFieldId
        }
        It 'returns a list of AnswerX datasets' {
            $TestParams = @{
                'StreamType' = 'answerx'
            }
            $PD.AnswerXDatasets = Get-DataStreamDatasets @TestParams @CommonParams
            $PD.AnswerXDatasets[0].datasetFieldName | Should -Not -BeNullOrEmpty
            9017 | Should -BeIn $PD.AnswerXDatasets.datasetFieldId
        }
    }

    Context 'Get-DataStreamGroup' {
        It 'returns a list' {
            $PD.Groups = Get-DatastreamGroups @CommonParams
            $PD.Groups[0].groupName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DataStreamHistory' {
        It 'returns the correct stream' {
            $TestParams = @{
                'StreamID' = $TestStreamID
            }
            $PD.StreamHistory = Get-DataStreamHistory @TestParams @CommonParams
            $PD.StreamHistory[0].streamId | Should -Be $TestStreamID
        }
    }

    Context 'Get-DataStreamProperties' {
        It 'returns a list' {
            $TestParams = @{
                'GroupID' = $TestGroupID
            }
            $Properties = Get-DataStreamProperties @TestParams @CommonParams
            $Properties[0].propertyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DataStreamEDNSZones' {
        It 'returns a list' {
            $Zones = $TestContractID | Get-DatastreamEDNSZones @CommonParams
            $Zones[0].zoneName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DataStreamGTMProperties' {
        It 'returns a list' {
            $GTMProperties = $TestContractID | Get-DatastreamGTMProperties @CommonParams
            $GTMProperties[0].propertyName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DataStreamAnswerXSSIDs' {
        It 'returns a list' {
            $AnswerXSSIDs = Get-DataStreamAnswerXSSIDs -ContractID $TestContractID @CommonParams
            $AnswerXSSIDs[0].serviceSubletterIds | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-DataStream' {
        Context 'CDN Stream' {
            BeforeAll {
                # Add a new data set field
                $PD.NewCDNStream.datasetFields += [PSCustomObject] @{
                    'datasetFieldId' = 2014
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetCDNStreamPipeline = $PD.NewCDNStream | Set-DataStream @CommonParams
                    $PD.SetCDNStreamPipeline.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetCDNStreamPipeline.StreamID | Should -Be $PD.NewCDNStream.streamID
                    $PD.SetCDNStreamPipeline.streamName | Should -Be $PD.NewCDNStream.streamName
                    $PD.SetCDNStreamPipeline.streamType | Should -Be 'cdn'
                    $PD.SetCDNStreamPipeline.properties[0].propertyId | Should -Be $TestPropertyID
                    $PD.SetCDNStreamPipeline.latestVersion | Should -Be 2
                    $PD.SetCDNStreamPipeline.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamPipeline.destination | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamPipeline.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetCDNStreamPipeline.datasetFields.datasetFieldId | Should -Contain 2014
                }
            }

            Context 'by body using alias' {
                It 'updates successfully' {
                    $TestParams = @{
                        'LogType'  = 'cdn'
                        'StreamID' = $PD.NewCDNStream.streamId
                        'Body'     = ($PD.NewCDNStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetCDNStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetCDNStreamBody.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetCDNStreamBody.StreamID | Should -Be $PD.NewCDNStream.streamID
                    $PD.SetCDNStreamBody.streamName | Should -Be $PD.NewCDNStream.streamName
                    $PD.SetCDNStreamBody.streamType | Should -Be 'cdn'
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
                $PD.NewEWStream.datasetFields += [PSCustomObject] @{
                    'datasetFieldId' = 6008
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetEWStreamPipeline = $PD.NewEWStream | Set-DataStream @CommonParams
                    $PD.SetEWStreamPipeline.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetEWStreamPipeline.StreamID | Should -Be $PD.NewEWStream.streamID
                    $PD.SetEWStreamPipeline.streamName | Should -Be $PD.NewEWStream.streamName
                    $PD.SetEWStreamPipeline.streamType | Should -Be 'edgeworkers'
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
                        'StreamType' = 'edgeworkers'
                        'StreamID'   = $PD.NewEWStream.streamId
                        'Body'       = ($PD.NewEWStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetEWStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetEWStreamBody.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetEWStreamBody.StreamID | Should -Be $PD.NewEWStream.streamID
                    $PD.SetEWStreamBody.streamName | Should -Be $PD.NewEWStream.streamName
                    $PD.SetEWStreamBody.streamType | Should -Be 'edgeworkers'
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
                $PD.NewEDNSStream.datasetFields += [PSCustomObject] @{
                    'datasetFieldId' = 4013
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetEDNSStreamPipeline = $PD.NewEDNSStream | Set-DataStream @CommonParams
                    $PD.SetEDNSStreamPipeline.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetEDNSStreamPipeline.StreamID | Should -Be $PD.NewEDNSStream.streamID
                    $PD.SetEDNSStreamPipeline.streamName | Should -Be $PD.NewEDNSStream.streamName
                    $PD.SetEDNSStreamPipeline.streamType | Should -Be 'edns'
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
                        'StreamType' = 'edns'
                        'StreamID'   = $PD.NewEDNSStream.streamId
                        'Body'       = ($PD.NewEDNSStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetEDNSStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetEDNSStreamBody.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetEDNSStreamBody.StreamID | Should -Be $PD.NewEDNSStream.streamID
                    $PD.SetEDNSStreamBody.streamName | Should -Be $PD.NewEDNSStream.streamName
                    $PD.SetEDNSStreamBody.streamType | Should -Be 'edns'
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
                $PD.NewGTMStream.datasetFields += [PSCustomObject] @{
                    'datasetFieldId' = 5013
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetGTMStreamPipeline = $PD.NewGTMStream | Set-DataStream @CommonParams
                    $PD.SetGTMStreamPipeline.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetGTMStreamPipeline.StreamID | Should -Be $PD.NewGTMStream.streamID
                    $PD.SetGTMStreamPipeline.streamName | Should -Be $PD.NewGTMStream.streamName
                    $PD.SetGTMStreamPipeline.streamType | Should -Be 'gtm'
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
                        'StreamType' = 'gtm'
                        'StreamID'   = $PD.NewGTMStream.streamId
                        'Body'       = ($PD.NewGTMStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetGTMStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetGTMStreamBody.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetGTMStreamBody.StreamID | Should -Be $PD.NewGTMStream.streamID
                    $PD.SetGTMStreamBody.streamName | Should -Be $PD.NewGTMStream.streamName
                    $PD.SetGTMStreamBody.streamType | Should -Be 'gtm'
                    $PD.SetGTMStreamBody.latestVersion | Should -Be 3
                    $PD.SetGTMStreamBody.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamBody.destination | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamBody.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetGTMStreamBody.datasetFields.datasetFieldId | Should -Contain 5013
                }
            }
        }

        Context 'AppSec Stream' {
            BeforeAll {
                # Update frequency
                $PD.NewAppSecStream.deliveryConfiguration.frequency.intervalInSeconds = 30
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetAppSecStreamPipeline = $PD.NewAppSecStream | Set-DataStream @CommonParams
                    $PD.SetAppSecStreamPipeline.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetAppSecStreamPipeline.StreamID | Should -Be $PD.NewAppSecStream.streamID
                    $PD.SetAppSecStreamPipeline.streamName | Should -Be $PD.NewAppSecStream.streamName
                    $PD.SetAppSecStreamPipeline.streamType | Should -Be 'appsec'
                    $PD.SetAppSecStreamPipeline.latestVersion | Should -Be 2
                    $PD.SetAppSecStreamPipeline.destination | Should -Not -BeNullOrEmpty
                    $PD.SetAppSecStreamPipeline.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetAppSecStreamPipeline.deliveryConfiguration.frequency.intervalInSeconds | Should -Be 30
                }
            }

            Context 'by body' {
                It 'updates successfully' {
                    $TestParams = @{
                        'StreamType' = 'appsec'
                        'StreamID'   = $PD.NewAppSecStream.streamId
                        'Body'       = ($PD.NewAppSecStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetAppSecStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetAppSecStreamBody.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetAppSecStreamBody.StreamID | Should -Be $PD.NewAppSecStream.streamID
                    $PD.SetAppSecStreamBody.streamName | Should -Be $PD.NewAppSecStream.streamName
                    $PD.SetAppSecStreamBody.streamType | Should -Be 'appsec'
                    $PD.SetAppSecStreamBody.latestVersion | Should -Be 3
                    $PD.SetAppSecStreamBody.destination | Should -Not -BeNullOrEmpty
                    $PD.SetAppSecStreamBody.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetAppSecStreamBody.deliveryConfiguration.frequency.intervalInSeconds | Should -Be 30
                }
            }
        }

        Context 'AnswerX Stream' {
            BeforeAll {
                # Add a new data set field
                $PD.NewAnswerXStream.datasetFields += [PSCustomObject] @{
                    'datasetFieldId' = 9019
                }
            }
            Context 'by pipeline' {
                It 'updates successfully' {
                    $PD.SetAnswerXStreamPipeline = $PD.NewAnswerXStream | Set-DataStream @CommonParams
                    $PD.SetAnswerXStreamPipeline.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetAnswerXStreamPipeline.StreamID | Should -Be $PD.NewAnswerXStream.streamID
                    $PD.SetAnswerXStreamPipeline.streamName | Should -Be $PD.NewAnswerXStream.streamName
                    $PD.SetAnswerXStreamPipeline.streamType | Should -Be 'answerx'
                    $PD.SetAnswerXStreamPipeline.latestVersion | Should -Be 2
                    $PD.SetAnswerXStreamPipeline.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetAnswerXStreamPipeline.destination | Should -Not -BeNullOrEmpty
                    $PD.SetAnswerXStreamPipeline.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetAnswerXStreamPipeline.datasetFields.datasetFieldId | Should -Contain 9019
                }
            }

            Context 'by body' {
                It 'updates successfully' {
                    $TestParams = @{
                        'StreamType' = 'answerx'
                        'StreamID'   = $PD.NewAnswerXStream.streamId
                        'Body'       = ($PD.NewAnswerXStream | ConvertTo-Json -Depth 100)
                    }
                    $PD.SetAnswerXStreamBody = Set-DataStream @TestParams @CommonParams
                    $PD.SetAnswerXStreamBody.streamStatus | Should -Be 'INACTIVE'
                    $PD.SetAnswerXStreamBody.StreamID | Should -Be $PD.NewAnswerXStream.streamID
                    $PD.SetAnswerXStreamBody.streamName | Should -Be $PD.NewAnswerXStream.streamName
                    $PD.SetAnswerXStreamBody.streamType | Should -Be 'answerx'
                    $PD.SetAnswerXStreamBody.latestVersion | Should -Be 3
                    $PD.SetAnswerXStreamBody.datasetFields | Should -Not -BeNullOrEmpty
                    $PD.SetAnswerXStreamBody.destination | Should -Not -BeNullOrEmpty
                    $PD.SetAnswerXStreamBody.deliveryConfiguration | Should -Not -BeNullOrEmpty
                    $PD.SetAnswerXStreamBody.datasetFields.datasetFieldId | Should -Contain 9019
                }
            }
        }
    }

    Context 'Update-DataStream' {
        Context 'CDN stream using alias' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        'path'  = '/streamName'
                        'op'    = 'REPLACE'
                        'value' = "$($PD.CDNStream.StreamName)-Updated"
                    }
                )
                $TestParams = @{
                    'LogType'  = 'cdn'
                    'StreamID' = $PD.CDNStream.StreamID
                }
                $UpdateResult = $Update | Update-DataStream @TestParams @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.CDNStream.StreamName)-Updated"
                $UpdateResult.streamType | Should -Be 'cdn'
            }
        }

        Context 'EdgeWorkers stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        'path'  = '/streamName'
                        'op'    = 'REPLACE'
                        'value' = "$($PD.EdgeWorkerStream.StreamName)-Updated"
                    }
                )
                $TestParams = @{
                    'StreamType' = 'edgeworkers'
                    'StreamID'   = $PD.EdgeWorkerStream.StreamID
                }
                $UpdateResult = $Update | Update-DataStream @TestParams @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.EdgeWorkerStream.StreamName)-Updated"
                $UpdateResult.streamType | Should -Be 'edgeworkers'
            }
        }

        Context 'EDNS stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        'path'  = '/streamName'
                        'op'    = 'REPLACE'
                        'value' = "$($PD.EDNSStream.StreamName)-Updated"
                    }
                )
                $TestParams = @{
                    'StreamType' = 'edns'
                    'StreamID'   = $PD.EDNSStream.StreamID
                }
                $UpdateResult = $Update | Update-DataStream @TestParams @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.EDNSStream.StreamName)-Updated"
                $UpdateResult.streamType | Should -Be 'edns'
            }
        }

        Context 'GTM stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        'path'  = '/streamName'
                        'op'    = 'REPLACE'
                        'value' = "$($PD.GTMStream.StreamName)-Updated"
                    }
                )
                $TestParams = @{
                    'StreamType' = 'gtm'
                    'StreamID'   = $PD.GTMStream.StreamID
                }
                $UpdateResult = $Update | Update-DataStream @TestParams @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.GTMStream.StreamName)-Updated"
                $UpdateResult.streamType | Should -Be 'gtm'
            }
        }

        Context 'AppSec stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        'path'  = '/streamName'
                        'op'    = 'REPLACE'
                        'value' = "$($PD.AppSecStream.StreamName)-Updated"
                    }
                )
                $TestParams = @{
                    'StreamType' = 'appsec'
                    'StreamID'   = $PD.AppSecStream.StreamID
                }
                $UpdateResult = $Update | Update-DataStream @TestParams @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.AppSecStream.StreamName)-Updated"
                $UpdateResult.streamType | Should -Be 'appsec'
            }
        }

        Context 'AnswerX stream' {
            It 'updates successfully' {
                $Update = @(
                    @{
                        'path'  = '/streamName'
                        'op'    = 'REPLACE'
                        'value' = "$($PD.AnswerXStream.streamName)-Updated"
                    }
                )
                $TestParams = @{
                    'StreamType' = 'answerx'
                    'StreamID'   = $PD.AnswerXStream.streamID
                }
                $UpdateResult = $Update | Update-DataStream @TestParams @CommonParams
                $UpdateResult.streamName | Should -Be "$($PD.AnswerXStream.streamName)-Updated"
                $UpdateResult.streamType | Should -Be 'answerx'
            }
        }
    }

    Context 'Remove-DataStream' {
        Context 'Remove CDN Stream' {
            It 'deletes successfully using alias' {
                $TestParams = @{
                    'LogType' = 'cdn'
                }
                $PD.NewCDNStream | Remove-DataStream @TestParams @CommonParams
            }
        }

        Context 'Remove EdgeWorkers Stream' {
            It 'deletes successfully with provided stream type' {
                $TestParams = @{
                    'StreamType' = 'edgeworkers'
                }
                $PD.NewEWStream | Remove-DataStream @TestParams @CommonParams
            }
        }

        Context 'Remove EDNS Stream' {
            It 'deletes successfully, inferring stream type from object' {
                $PD.NewEDNSStream | Remove-DataStream @CommonParams
            }
        }

        Context 'Remove GTM Stream' {
            It 'deletes successfully, inferring stream type from object' {
                $PD.NewGTMStream | Remove-DataStream @CommonParams
            }
        }

        Context 'Remove AppSec Stream' {
            It 'deletes successfully, inferring stream type from object' {
                $PD.NewAppSecStream | Remove-DataStream @CommonParams
            }
        }

        Context 'Remove AnswerX Stream' {
            It 'deletes successfully, inferring stream type from object' {
                $PD.NewAnswerXStream | Remove-DataStream @CommonParams
            }
        }
    }

    # ---- Mocked tests
    Context 'New-DataStreamActivation' {
        It 'activates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.DataStream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-DataStreamActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Stream = [PSCustomObject] @{
                'streamId' = 123456
            }
            $Activate = $Stream | New-DataStreamActivation
            $Activate.streamStatus | Should -Be 'ACTIVATING'
            $Activate.streamType | Should -Be 'cdn'
        }
    }

    Context 'New-DataStreamDeactivation' {
        It 'deactivates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.DataStream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-DataStreamDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $Stream = [PSCustomObject] @{
                'streamId' = 123456
            }
            $Deactivate = $Stream | New-DataStreamDeactivation
            $Deactivate.streamStatus | Should -Be 'ACTIVATING'
            $Deactivate.streamType | Should -Be 'cdn'
        }
    }

    Context 'Get-DataStreamMetrics' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.DataStream -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-DataStreamMetrics.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'End'   = '01/01/2022 09:00:00'
                'Start' = '2024-01-01T09:00:00'
            }
            $Metrics = Get-DataStreamMetrics @TestParams
            $Metrics.fileUploadMetrics[0].streamId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DataStreamActivationHistory' {
        It 'returns the correct CDN stream' {
            $Stream = [PSCustomObject] @{
                'streamId' = $TestStreamID
            }
            $ActivationHistory = $Stream | Get-DataStreamActivationHistory @CommonParams
            $ActivationHistory[0].streamId | Should -Match '^[0-9]+$'
        }
    }

    Context 'Get-DataStreamActivationHistory' {
        It 'returns the correct AnswerX stream' {
            $Stream = [PSCustomObject] @{
                'streamId' = $TestStreamID
            }
            $ActivationHistory = $Stream | Get-DataStreamActivationHistory @CommonParams
            $ActivationHistory[0].streamId | Should -Match '^[0-9]+$'
        }
    }
}
