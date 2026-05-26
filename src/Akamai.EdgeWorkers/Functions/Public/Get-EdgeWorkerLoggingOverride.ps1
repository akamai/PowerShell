
function Get-EdgeWorkerLoggingOverride {
    [CmdletBinding(DefaultParameterSetName = 'Get by name')]
    Param(
        [Parameter(ParameterSetName = 'Get by name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'Get by ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter()]
        [int]
        $LoggingID,

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
        $EdgeWorkerID, $null, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        if ($LoggingID) {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/loggings/$LoggingID"
        }
        else {
            $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/loggings"
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($LoggingID) {
                return $Response.Body
            }
            else {
                return $Response.Body.loggings
            }
        }
        catch {
            throw $_
        }
    }
}
