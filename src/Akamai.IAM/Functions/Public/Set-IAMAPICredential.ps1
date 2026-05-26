function Set-IAMAPICredential {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter()]
        [string]
        $ClientID = 'self',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CredentialID,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $ExpiresOn,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('ACTIVE', 'INACTIVE', 'DELETED')]
        [string]
        $Status,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
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
        if ($ClientID -eq 'self') {
            $Path = "/identity-management/v3/api-clients/self/credentials/$CredentialId"
        }
        else {
            $Path = "/identity-management/v3/api-clients/$ClientID/credentials/$CredentialId"
        }
        if ($PSCmdlet.ParameterSetName.contains('Attributes')) {
            $Body = @{
                'expiresOn' = $ExpiresOn
                'status'    = $Status
            }
            if ($Description) {
                $Body.description = $Description
            }
        }

        # Format expiresOn
        $Body = Get-BodyObject -Source $Body
        if ($Body.expiresOn -is 'DateTime') {
            $Body.expiresOn = $Body.expiresOn.toString('yyyy-MM-ddThh:mm:ss.000Z')
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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
