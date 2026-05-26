function Expand-APIEndpointDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $APIEndpointName,
        
        [Parameter()]
        [string]
        $APIEndpointID,

        [Parameter()]
        [Alias('CloneVersionNumber')]
        [string]
        $VersionNumber,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    $CommonParams = @{
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    if ($APIEndpointName) {
        # Check cache if enabled
        if ($Global:AkamaiOptions.EnableDataCache) {
            $APIEndpointID = $Global:AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName.APIEndpointID
        }

        if (-not $APIEndpointID) {
            Write-Debug "Expand-APIEndpointDetails: '$APIEndpointName' - Retrieving endpoint details."
            $APIEndpoint = Get-APIEndpoints -Contains $APIEndpointName @CommonParams | Where-Object apiEndpointName -eq $APIEndpointName
            if ($null -eq $APIEndpoint) {
                throw "API Endpoint $APIEndpointName not found"
            }
            else {
                $APIEndpointID = $APIEndpoint.apiEndPointId
            }
        }

        # Add to data cache
        if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName) {
            $Global:AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName = @{
                'APIEndpointID' = $APIEndpointID
            }
        }
        Write-Debug "Expand-APIEndpointDetails: APIEndpointID = $APIEndpointID"
    }

    if ($VersionNumber.ToLower() -eq "latest") {
        Write-Debug "Expand-APIEndpointDetails: '$APIEndpointID' - Retrieving endpoint versions."
        $Versions = Get-APIEndpointVersion -APIEndpointID $APIEndpointID @CommonParams | Sort-Object -Property versionNumber -Descending
        $VersionNumber = $Versions[0].versionNumber
        Write-Debug "Expand-APIEndpointDetails: VersionNumber = $VersionNumber"
    }

    return $APIEndpointID, $VersionNumber
}
