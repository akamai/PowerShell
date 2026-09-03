function New-EDNSRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $TTL,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string[]]
        $RData,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
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

    begin {
        $CollatedRecordSets = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        if ($Body -and $Body -isnot 'String') {
            if ($null -eq $Body.recordsets -and $null -ne $Body.name) {
                # If body has recordsets top-level object then it is not a piped array
                $CollatedRecordSets.Add($Body)
            }
        }
    }

    end {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/$Zone/recordsets"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            if ($Type.ToLower() -eq 'txt') {
                for ($i = 0; $i -lt $RData.count; $i++) {
                    if ($RData[$i] -notmatch '^".*"$') {
                        $RData[$i] = "`"$($RData[$i])`""
                    }
                }
            }

            $Body = @{
                'recordsets' = @(
                    @{
                        'name'  = $Name
                        'rdata' = $RData
                        'ttl'   = $TTL
                        'type'  = $Type
                    }
                )
            }
        }
        else {
            if ($CollatedRecordSets.count -gt 0) {
                $Body = @{ 'recordsets' = $CollatedRecordSets }
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
