function New-AppSecDiscoveredAPIEndpoint {
    [CmdletBinding(DefaultParameterSetName = 'New')]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Hostname,

        [Parameter(Mandatory)]
        [string]
        $BasePath,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [string]
        $APIName,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [string]
        $ContractID,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [int]
        $GroupID,

        [Parameter(Mandatory, ParameterSetName = 'Existing')]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory, ParameterSetName = 'Existing')]
        [int]
        $Version,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
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
        $Base64Match = '^[a-zA-Z0-9+\/]+=*$'
        if ($Hostname -notmatch $Base64Match) {
            $Hostname = ConvertTo-Base64 -UnencodedString $Hostname
        }
        if ($BasePath -notmatch $Base64Match -or $BasePath.StartsWith('/')) {
            $BasePath = ConvertTo-Base64 -UnencodedString $BasePath
        }
        $Path = "/appsec/v1/api-discovery/host/$Hostname/basepath/$BasePath/endpoints"
        if ($PSCmdlet.ParameterSetName -eq 'New') {
            $Body = @{
                'apiName'    = $APIName
                'contractId' = $ContractID
                'groupId'    = $GroupID
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Existing') {
            $Body = @{
                'apiEndpointId' = $APIEndpointID
                'version'       = $Version
            }
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
