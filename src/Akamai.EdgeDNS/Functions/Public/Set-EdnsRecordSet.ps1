function Set-EDNSRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Attributes', SupportsShouldProcess, ConfirmImpact = 'High')]
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
        [switch]
        $AutoIncrementSOA,

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
        $Method = 'PUT'

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
            if ($Type.ToLower() -eq 'txt') {
                for ($i = 0; $i -lt $RData.count; $i++) {
                    if ($RData[$i] -notmatch '^".*"$') {
                        $RData[$i] = "`"$($RData[$i])`""
                    }
                }
            }

            $Body = @{
                'name'  = $Name
                'rdata' = $RData
                'ttl'   = $TTL
                'type'  = $Type
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Body') {
            $Path = "/config-dns/v2/zones/$Zone/recordsets"
            # Reconstruct from collated body
            if ($CollatedRecordSets.Count -gt 0) {
                $Body = @{ 'recordsets' = $CollatedRecordSets }
            }

            # Parse recordsets to handle data types and txt quoting
            foreach ($RecordSet in $Body.recordsets) {
                if ($RecordSet.Type.ToLower() -eq 'txt') {
                    for ($i = 0; $i -lt $RecordSet.RData.count; $i++) {
                        if ($RecordSet.RData[$i] -notmatch '^".*"$') {
                            $RecordSet.RData[$i] = "`"$($RecordSet.RData[$i])`""
                        }
                    }
                }
            }

            # Fall back to single update URL if only 1 record is present
            if ($Body.recordsets.count -eq 1) {
                $Body = $Body.recordsets[0]
                $Name = $Body.name
                $Type = $Body.type
                $Path = "/config-dns/v2/zones/$Zone/names/$Name/types/$Type"
            }
        }

        if ($AutoIncrementSOA) {
            # Convert to object first, if not already
            $Body = Get-BodyObject -Source $Body
            $SOA = $Body.recordsets | Where-Object type -eq 'SOA'
            if ($SOA) {
                # Should be only one, but you never know
                $SOA | ForEach-Object {
                    # Again, should be only one, but let's not assume
                    for ($i = 0; $i -lt $_.rdata.count; $i++) {
                        $Components = $_.rdata[$i] -split ' '
                        $ExistingSerial = $Components[2]
                        $NewSerial = ([int] $ExistingSerial) + 1
                        $_.rdata[$i] = $_.rdata[$i].replace($ExistingSerial, $NewSerial)
                    }
                }
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

        # Get confirmation if number of record sets is greater than 1
        if ($Body.recordsets) {
            if ($PSCmdlet.ShouldProcess("Replacing ALL recordsets in zone $Zone", "Are you sure you want to proceed?", "Updating more than one recordset with Set-EDNSRecordSet will result in replacing ALL recordsets in zone: $Zone")) {
                Write-Warning "Replacing all records in zone $Zone"
                $Response = Invoke-AkamaiRequest @RequestParams
            }
        }
        else {
            $Response = Invoke-AkamaiRequest @RequestParams
        }
        return $Response.Body
    }
}
