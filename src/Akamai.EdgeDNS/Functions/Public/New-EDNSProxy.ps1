
function New-EDNSProxy {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContractID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $GroupID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string[]]
        $OriginNameServers,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $ZoneTransferNameServers,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $HealthCheckRecordType,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $HealthCheckRecordName,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
        $Body,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $Path = "/config-dns/v2/proxies"
        $QueryParameters = @{
            'contractId' = $ContractID
            'gid'        = $PSBoundParameters.GroupID
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'name'              = $Name
                'contractId'        = $ContractID
                'healthCheck'       = @{
                    'recordType' = $HealthCheckRecordType
                }
                'originNameServers' = New-Object -TypeName System.Collections.Generic.List[hashtable]
            }

            # Populate name servers
            $OriginNameServers | Foreach-Object {
                if ($_.Contains(":")) {
                    $NSComponents = $_ -split ":"
                    $Body.originNameServers.Add(
                        @{
                            'name' = $NSComponents[0]
                            'port' = $NSComponents[1]
                        }
                    )
                }
                else {
                    $Body.originNameServers.Add(
                        @{
                            'name' = $_
                        }
                    )
                }
            }

            $ZoneTransferNameServers | Foreach-Object {
                $ZTNS = New-Object -TypeName System.Collections.Generic.List[hashtable]
                if ($_.Contains(":")) {
                    $NSComponents = $_ -split ":"
                    $ZTNS.Add(
                        @{
                            'name' = $NSComponents[0]
                            'port' = $NSComponents[1]
                        }
                    )
                }
                else {
                    $ZTNS.Add(
                        @{
                            'name' = $_
                        }
                    )
                }
                $Body.zoneTransferNameservers = $ZTNS
            }

            if ($HealthCheckRecordName) {
                $Body.healthCheck.recordName = $HealthCheckRecordName
            }
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
