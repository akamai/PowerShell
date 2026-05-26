function Update-DataStream {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm')]
        [string]
        $LogType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter(Mandatory)]
        [int]
        $StreamID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $Activate,

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
        $CollatedUpdates = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        if ($Body -isnot 'String') {
            if ($Body -is 'array') {
                if ($Body.Count -eq 1) {
                    $CollatedUpdates.Add($Body)
                }
                elseif ($Body.Count -gt 1) {
                    $CollatedUpdates.AddRange($Body)
                }
            }
            elseif ($Body -is 'hashtable' -or $Body -is 'PSCustomObject') {
                $CollatedUpdates.Add($Body)
            }
        }
    }

    end {
        $Path = "/datastream-config-api/v3/log/$LogType/streams/$StreamID"
        if ($CollatedUpdates.Count -gt 0) {
            $Body = $CollatedUpdates
        }

        $QueryParameters = @{
            'activate' = $PSBoundParameters.Activate.IsPresent
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
