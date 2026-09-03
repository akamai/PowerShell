function Get-DatastreamGroups {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('LogType')]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm', 'appsec', 'answerx')]
        [string]
        $StreamType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter()]
        [string]
        $ContractID,

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
        switch ($StreamType) {
            'cdn' {
                $Path = '/datastream-config-api/v3/log/cdn/groups'
            }
            'edgeworkers' {
                $Path = '/datastream-config-api/v3/log/edgeworkers/groups'
            }
            'edns' {
                $Path = '/datastream-config-api/v3/log/edns/groups'
            }
            'gtm' {
                $Path = '/datastream-config-api/v3/log/gtm/groups'
            }
            'appsec' {
                $Path = '/datastream-config-api/v3/log/appsec/groups'
            }
            'answerx' {
                $Path = '/datastream-config-api/v3/log/answerx/groups'
            }
        }
        $QueryParameters = @{
            'contractId' = $ContractID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.groups
    }
}

