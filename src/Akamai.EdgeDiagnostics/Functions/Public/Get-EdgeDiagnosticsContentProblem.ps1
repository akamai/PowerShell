function Get-EdgeDiagnosticsContentProblem {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RequestID,
        
        [Parameter()]
        [switch]
        $IncludeContentResponseBody,
        
        [Parameter()]
        [switch]
        $AsHashTable,
        
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

    $Path = "/edge-diagnostics/v1/content-problems/requests/$RequestID"
    $QueryParameters = @{
        'includeContentResponseBody' = $PSBoundParameters.IncludeContentResponseBody.IsPresent
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
    if ($Response.Body -is 'String') {
        #JSON conversion fails due to object names differing only by case
        $Response.BodyHash = $Response.Body | ConvertFrom-Json -AsHashtable
        if ($AsHashTable) {
            return $Response.BodyHash
        }
        else {
            $Response.BodyHash['logLines'][0]['result'].Remove('legend')
            $Response.BodyHash['summary']['logLines'][0]['result'].Remove('legend')
            $Response.Body = $Response.BodyHash | ConvertTo-Json -depth 100 | ConvertFrom-Json
        }
    }
        
    return $Response.Body
}

