function New-EdgeWorker {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $EdgeWorkerName,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory)]
        [ValidateSet(100, 200, 400)]
        [int]
        $ResourceTierID,

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
        $Path = "/edgeworkers/v1/ids"
    
        $Body = @{
            name           = $EdgeWorkerName
            groupId        = $GroupID
            resourceTierId = $ResourceTierID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
        
            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                Set-AkamaiDataCache -EdgeWorkerName $Response.Body.name -EdgeWorkerID $Response.Body.edgeWorkerId
            }
        
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
