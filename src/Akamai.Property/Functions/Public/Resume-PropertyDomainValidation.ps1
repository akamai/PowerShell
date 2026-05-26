
function Resume-PropertyDomainValidation {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Domain,

        [Parameter()]
        [string]
        $ContractID,

        [Parameter()]
        [string]
        $GroupID,

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

    begin {
        $CollatedDomains = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        $Domain | ForEach-Object {
            $CollatedDomains.Add($_)
        }
    }

    end {
        $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $Path = "/papi/v1/properties/$PropertyID/hostnames/certificate/domain-validation/proceed"
        $QueryParameters = @{
            'contractId' = $ContractID
            'groupId'    = $GroupID
        }
        $Body = @{
            'domains' = $CollatedDomains
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.domains.items
        }
        catch {
            throw $_
        }
    }
}