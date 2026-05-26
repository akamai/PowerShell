function New-APIEndpointVersionPII {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]
        $APIEndpointName,

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName)]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $VersionNumber,

        [Parameter(Mandatory)]
        [Int64]
        $ParamID,

        [Parameter(Mandatory)]
        [ValidateSet('PERSONAL_EMAIL', 'CREDIT_OR_DEBIT_CARD_NUMBER')]
        [string[]]
        $Types,

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
        $APIEndpointID, $VersionNumber = Expand-APIEndpointDetails @PSBoundParameters
        $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/piis/parameters/$ParamID"
        $Body = @{
            types = $Types
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
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

