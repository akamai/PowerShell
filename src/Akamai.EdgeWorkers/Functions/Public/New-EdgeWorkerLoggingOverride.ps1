
function New-EdgeWorkerLoggingOverride {
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [ValidateSet('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]
        $Level,

        [Parameter()]
        [string]
        $Schema,

        [Parameter()]
        [string]
        $Timeout,

        [Parameter()]
        [int]
        $DS2ID,

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
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/loggings"
        $Body = @{
            network = $Network
            level   = $Level
        }
        if ($Schema) {
            $Body.schema = $Schema
        }
        if ($Timeout) {
            $Body.timeout = $Timeout
        }
        if ($null -ne $PSBoundParameters.DS2ID) {
            $Body.schema = $Schema
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
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
