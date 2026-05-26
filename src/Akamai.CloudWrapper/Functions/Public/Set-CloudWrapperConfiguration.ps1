
function Set-CloudWrapperConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'Activate')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int64]
        $ConfigID,

        [Parameter(ParameterSetName = 'Activate')]
        [switch]
        $Activate,

        [Parameter(ParameterSetName = 'Deactivate')]
        [switch]
        $Deactivate,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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
        $Path = "/cloud-wrapper/v1/configurations/$ConfigID"
        $QueryParameters = @{}
        if ($Activate) {
            $QueryParameters['activate'] = $true
        }
        if ($Deactivate) {
            $QueryParameters['activate'] = $false
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
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
