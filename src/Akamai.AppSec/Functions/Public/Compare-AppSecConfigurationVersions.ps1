function Compare-AppSecConfigurationVersions {
    [CmdletBinding(DefaultParameterSetName = 'Config name')]
    Param(
        [Parameter(ParameterSetName = 'Config name', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $ConfigID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('version')]
        [int]
        $From,

        [Parameter(Mandatory)]
        [int]
        $To,

        [Parameter()]
        [ValidateSet('MODIFIED', 'UNMODIFIED', 'Both')]
        [string]
        $Outcomes,

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
        [string] $ConfigID, $null, $null = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/diff"
        $Body = @{
            'from' = $From
            'to'   = $To
        }
        if ($Outcomes) {
            if ($Outcomes -eq 'Both') {
                $Outcomes = @('MODIFIED', 'UNMODIFIED')
            }
            else {
                $Body['outcomes'] = @($Outcomes)
            }
        }
        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
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
