function Get-AppSecConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = "Get one by name", Position = 0)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = "Get one by ID", ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $ConfigID,

        [Parameter(ParameterSetName = "Get all")]
        [switch]
        $IncludeContractAndGroup,

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
        [string] $ConfigID, $null = Expand-AppSecConfigDetails @PSBoundParameters
        if ($ConfigID) {
            $Path = "/appsec/v1/configs/$ConfigID"
        }
        else {
            $Path = "/appsec/v1/configs"
        }
        $QueryParameters = @{
            includeContractGroup = $PSBoundParameters.IncludeContractAndGroup
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
        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
            if ($PSCmdlet.ParameterSetName.Contains('one')) {
                # Add to data cache
                if ($AkamaiOptions.EnableDataCache) {
                    Set-AkamaiDataCache -AppSecConfigName $Response.Body.name -AppSecConfigID $Response.Body.id
                }
                return $Response.Body
            }
            else {
                # Add to data cache
                if ($AkamaiOptions.EnableDataCache) {
                    foreach ($Config in $Response.Body.configurations) {
                        Set-AkamaiDataCache -AppSecConfigName $Config.name -AppSecConfigID $Config.id
                    }
                }
                return $Response.Body.configurations
            }
        }
        catch {
            throw $_
        }
    }
}
