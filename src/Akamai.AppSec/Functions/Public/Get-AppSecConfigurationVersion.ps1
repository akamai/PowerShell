function Get-AppSecConfigurationVersion {
    [CmdletBinding(DefaultParameterSetName = 'Get all by name')]
    Param(
        [Parameter(ParameterSetName = "Get one by name", Position = 0, Mandatory)]
        [Parameter(ParameterSetName = "Get all by name", Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = "Get one by ID", Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = "Get all by ID", Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $ConfigID,

        [Parameter(ParameterSetName = "Get one by name", Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = "Get one by ID", Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = "Get all by name")]
        [Parameter(ParameterSetName = "Get all by ID")]
        [switch]
        $Detail,

        [Parameter(ParameterSetName = "Get all by name")]
        [Parameter(ParameterSetName = "Get all by ID")]
        [int]
        $Page,

        [Parameter(ParameterSetName = "Get all by name")]
        [Parameter(ParameterSetName = "Get all by ID")]
        [int]
        $PageSize = 1000,

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
        [string] $ConfigID, $VersionNumber, $null = Expand-AppSecConfigDetails @PSBoundParameters
        if ($VersionNumber) {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber"
        }
        else {
            $Path = "/appsec/v1/configs/$ConfigID/versions"
        }
        $QueryParameters = @{
            detail   = $PSBoundParameters.Detail.IsPresent
            page     = $PSBoundParameters.Page
            pageSize = $PageSize
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
        if ($PSCmdlet.ParameterSetName.Contains('one')) {
            return $Response.Body
        }
        else {
            return $Response.Body.versionList
        }
    }
}
