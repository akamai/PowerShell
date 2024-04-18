Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.EdgeDiagnostics/Akamai.EdgeDiagnostics.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestIPAddress = '1.2.3.4'
$Script:TestHostname = $env:PesterHostname
$Script:TestESIURL = "https://$TestHostname/ns/esi/include.html"
$Script:1HourAgo = (Get-Date).AddHours(-1)
$Script:EpochTime = [Math]::Floor([decimal](Get-Date($1HourAgo).ToUniversalTime() -uformat "%s"))
$Script:TestErrorCode = "9.44ae3017.$($EpochTime).38e4d065"
$Script:TestDiagnosticsNote = 'AkamaiPowerShell testing. Please ignore'
$Script:TestGrepJSON = @"
{
    "httpStatusCodes": {
      "comparison": "EQUALS",
      "value": [
        "200"
      ]
    },
    "logType": "R",
    "edgeIp": "192.0.2.0",
    "start": "2022-03-15T06:08:40.000Z",
    "end": "2022-03-15T06:08:43.000Z"
}
"@

Describe 'Safe Edge Diagnostics Tests' {

    BeforeDiscovery {

    }

    ### Get-EdgeDiagnosticsLocations
    $Script:EdgeLocations = Get-EdgeDiagnosticsLocations -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsLocations returns a list' {
        $EdgeLocations.count | Should -Not -Be 0
    }

    ### Get-EdgeDiagnosticsIPAHostnames
    $Script:IPAHostnames = Get-EdgeDiagnosticsIPAHostnames -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsIPAHostnames returns a list' {
        $IPAHostnames.count | Should -Not -Be 0
    }

    ### Find-IPAddress
    $Script:IPLocation = Find-IPAddress -IPAddress $TestIPAddress -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Find-IPAddress returns the correct data' {
        $IPLocation.geolocation | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeDiagnosticsDig
    $Script:Dig = New-EdgeDiagnosticsDig -Hostname $TestHostname -QueryType CNAME -EdgeLocation $EdgeLocations[0].id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsDig returns the correct data' {
        $Dig.result | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeDiagnosticsCurl
    $Script:Curl = New-EdgeDiagnosticsCurl -URL "https://$TestHostname" -IPVersion IPV4 -EdgeLocation $EdgeLocations[0].id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsCurl returns the correct data' {
        $Curl.result | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeDiagnosticsMTR
    $Script:MTR = New-EdgeDiagnosticsMTR -Destination $TestHostname -DestinationType HOST -PacketType TCP -Port 80 -ResolveDNS -Source $EdgeLocations[0].id -SourceType LOCATION -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsMTR returns the correct data' {
        $MTR.result | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeDiagnosticsMetadataTraceLocations
    $Script:MDTLocations = Get-EdgeDiagnosticsMetadataTraceLocations -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsMetadataTraceLocations returns the correct data' {
        $MDTLocations[0].id | Should -Not -BeNullOrEmpty
    }
    
    ### New-EdgeDiagnosticsMetadataTrace
    $Script:NewTrace = New-EdgeDiagnosticsMetadataTrace -URL "https://$TestHostname" -HTTPMethod GET -MDTLocationID $MDTLocations[0].id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsMetadataTrace returns the correct data' {
        $NewTrace.requestId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeDiagnosticsMetadataTrace
    $Script:GetTrace = Get-EdgeDiagnosticsMetadataTrace -RequestID $NewTrace.requestId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsMetadataTrace returns the correct data' {
        $GetTrace.requestId | Should -Be $NewTrace.requestId
    }

    ### Test-EdgeDiagnosticsIP
    $Script:TestIP = Test-EdgeDiagnosticsIP -IPAddress $TestIPAddress -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Test-EdgeDiagnosticsIP executes successfully' {
        $TestIP.executionStatus | Should -Be 'SUCCESS'
        $TestIP.request.ipAddresses[0] | Should -Be $TestIPAddress
    }
   
    ### Test-EdgeDiagnosticsIP with location
    $Script:TestIPWithLocation = Test-EdgeDiagnosticsIP -IPAddress $TestIPAddress -IncludeLocation -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Test-EdgeDiagnosticsIP executes successfully' {
        $TestIPWithLocation.executionStatus | Should -Be 'SUCCESS'
        $TestIPWithLocation.request.ipAddress | Should -Be $TestIPAddress
        $TestIPWithLocation.result.geoLocation.countryCode | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeDiagnosticsErrorTranslation
    $Script:NewErrorTranslation = New-EdgeDiagnosticsErrorTranslation -ErrorCode $TestErrorCode -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsErrorTranslation executes successfully' {
        $NewErrorTranslation.executionStatus | Should -Be 'IN_PROGRESS'
    }

    ### Get-EdgeDiagnosticsErrorTranslation
    $Script:GetErrorTranslation = Get-EdgeDiagnosticsErrorTranslation -RequestID $NewErrorTranslation.requestId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsErrorTranslation executes successfully' {
        $GetErrorTranslation.requestId | Should -Be $NewErrorTranslation.requestId
    }

    ### New-EdgeDiagnosticsLink
    $Script:DiagLink = New-EdgeDiagnosticsLink -URL "https://$TestHostname" -Note $TestDiagnosticsNote  -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsLink executes successfully' {
        $DiagLink.note | Should -Be $TestDiagnosticsNote
    }

    ### Get-EdgeDiagnosticsGroup, all
    $Script:DiagGroups = Get-EdgeDiagnosticsGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsGroup, all, returns a list' {
        $DiagGroups[0].groupId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeDiagnosticsGroup, single
    $Script:DiagGroup = Get-EdgeDiagnosticsGroup -GroupID $DiagGroups[0].groupId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsGroup, single, returns the correct data' {
        $DiagGroup.groupId | Should -Be $DiagGroups[0].groupId
    }
    
    ### New-EdgeDiagnosticsConnectivityProblem
    $Script:NewConnectivityProblem = New-EdgeDiagnosticsConnectivityProblem -URL "https://$TestHostname" -Port 443 -IPVersion IPV4 -EdgeLocationID $EdgeLocations[0].id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsConnectivityProblem returns the correct data' {
        $NewConnectivityProblem.requestId | Should -Not -BeNullOrEmpty
        $NewConnectivityProblem.executionStatus | Should -Be "IN_PROGRESS"
    }
    
    ### Get-EdgeDiagnosticsConnectivityProblem
    $Script:GetConnectivityProblem = Get-EdgeDiagnosticsConnectivityProblem -RequestID $NewConnectivityProblem.requestId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsConnectivityProblem returns the correct data' {
        $GetConnectivityProblem.request.url | Should -Be "https://$TestHostname"
        $GetConnectivityProblem.executionStatus | Should -Be "IN_PROGRESS"
    }
    
    ### New-EdgeDiagnosticsContentProblem
    $Script:NewContentProblem = New-EdgeDiagnosticsContentProblem -URL "https://$TestHostname" -IPVersion IPV4 -EdgeLocationID $EdgeLocations[0].id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsContentProblem returns the correct data' {
        $NewContentProblem.requestId | Should -Not -BeNullOrEmpty
        $NewContentProblem.executionStatus | Should -Be "IN_PROGRESS"
    }
    
    ### Get-EdgeDiagnosticsContentProblem
    $Script:GetContentProblem = Get-EdgeDiagnosticsContentProblem -RequestID $NewContentProblem.requestId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsContentProblem returns the correct data' {
        $GetContentProblem.request.url | Should -Be "https://$TestHostname"
        $GetContentProblem.executionStatus | Should -Be "IN_PROGRESS"
        $GetContentProblem.internalIp | Should -Not -BeNullOrEmpty
    }
    
    ### Get-EdgeDiagnosticsGTMProperties
    $Script:GTMProperties = Get-EdgeDiagnosticsGTMProperties -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsGTMProperties returns the correct data' {
        $GTMProperties[0].domain | Should -Not -BeNullOrEmpty
    }
    
    ### Get-EdgeDiagnosticsGTMPropertyIPs
    $Script:GTMPropertyIPs = Get-EdgeDiagnosticsGTMPropertyIPs -Domain $GTMProperties[0].domain -Property $GTMProperties[0].property -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsGTMPropertyIPs returns the correct data' {
        $GTMPropertyIPs.domain | Should -Be $GTMProperties[0].domain
        $GTMPropertyIPs.property | Should -Be $GTMProperties[0].property
        $GTMPropertyIPs.testIps | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeDiagnosticsESIDebug
    $Script:ESI = New-EdgeDiagnosticsESIDebug -URL $TestESIUrl -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsESIDebug returns the correct data' {
        $ESI.sourceDebugPage | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeDiagnosticsURLHealthCheck
    $Script:NewHealthCheck = New-EdgeDiagnosticsURLHealthCheck -URL "https://$TestHostname" -IPVersion IPV4 -EdgeLocationID $EdgeLocations[0].id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsURLHealthCheck returns the correct data' {
        $NewHealthCheck.requestId | Should -Not -BeNullOrEmpty
        $NewHealthCheck.executionStatus | Should -Be "IN_PROGRESS"
    }
    
    ### Get-EdgeDiagnosticsURLHealthCheck
    $Script:GetHealthCheck = Get-EdgeDiagnosticsURLHealthCheck -RequestID $NewHealthCheck.requestId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsURLHealthCheck returns the correct data' {
        $GetHealthCheck.request.url | Should -Be "https://$TestHostname"
        $GetHealthCheck.executionStatus | Should -Be "IN_PROGRESS"
    }

    AfterAll {
        
    }
    
}

Describe 'Unsafe Edge Diagnostics Tests' {
    
    ## Get-EdgeDiagnosticsErrorStatistics
    $Script:EStats = Get-EdgeDiagnosticsErrorStatistics -CPCode 123456 -ErrorType EDGE_ERRORS -Delivery ENHANCED_TLS -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsErrorStatistics returns the correct data' {
        $EStats.result | Should -Not -BeNullOrEmpty
    }

    ## Get-EdgeDiagnosticsLogs
    $Script:Logs = Get-EdgeDiagnosticsLogs -EdgeIP 1.2.3.4 -CPCode 123456 -ClientIP 3.4.5.6 -LogType F -EdgeRCFile $SafeEdgeRCFile -Start 2022-12-20 -End 2022-12-21 -Section $Section
    it 'Get-EdgeDiagnosticsLogs returns the correct data' {
        $Logs.result | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeDiagnosticsGrep
    $Script:NewGrep = New-EdgeDiagnosticsGrep -Body $TestGrepJSON -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-EdgeDiagnosticsGrep returns the correct data' {
        $NewGrep.executionStatus | Should -Be "Success"
        $NewGrep.requestId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-EdgeDiagnosticsGrep
    $Script:GetGrep = Get-EdgeDiagnosticsGrep -RequestID 123 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeDiagnosticsGrep returns the correct data' {
        $GetGrep.executionStatus | Should -Be "Success"
    }
}