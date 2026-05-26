function Get-GTMLivenessPerProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [string]
        $PropertyName,

        [Parameter(Mandatory)]
        [string]
        $Date,

        [Parameter()]
        [string]
        $AgentIP,

        [Parameter()]
        [string]
        $TargetIP,

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

    Process {
        $DateMatch = '[\d]{4}-[\d]{2}-[\d]{2}'
        if ($Date -and $Date -notmatch $DateMatch) {
            throw "ERROR: Date must be in the format 'YYYY-MM-DD'"
        }
    
        $Path = "/gtm-api/v1/reports/liveness-tests/domains/$DomainName/properties/$PropertyName"
        $QueryParameters = @{
            'date'     = $Date
            'agentIp'  = $AgentIP
            'targetIp' = $TargetIP
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
        return $Response.Body
    }
}

