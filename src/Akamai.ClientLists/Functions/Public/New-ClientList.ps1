function New-ClientList {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH', 'USER_ID')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes')]
        [Object[]]
        $Items,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Notes,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Tags,

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
        $Path = "/client-list/v1/lists"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'name'       = $Name
                'type'       = $Type
                'contractId' = $ContractID
                'groupId'    = $GroupID
            }
            if ($Notes) { $Body['notes'] = $Notes }
            if ($Tags) { $Body['tags'] = $Tags }
            if ($Items) {
                $Body.items = New-Object -TypeName System.Collections.Generic.List[Object]
                $Items | ForEach-Object {
                    if ($_ -is 'String') {
                        $Body.items.Add( @{ 'value' = $_ })
                    }
                    else {
                        $Body.items.Add($_)
                    }
                }
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
    
            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                Set-AkamaiDataCache -ClientListName $Response.Body.name -ClientListID $Response.Body.listId
            }
    
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
