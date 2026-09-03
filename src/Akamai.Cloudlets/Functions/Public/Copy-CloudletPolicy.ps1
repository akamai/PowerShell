function Copy-CloudletPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(Mandatory)]
        [string]
        $NewName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $GroupID,

        [Parameter()]
        [string[]]
        $AdditionalVersions,

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

    Process {
        $Path = "/cloudlets/v3/policies/$PolicyID/clone"
        $Body = @{
            newName = $NewName
            groupId = $GroupID
        }
    
        if ($AdditionalVersions) {
            $Body['additionalVersions'] = $AdditionalVersions
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

