function New-EdgeHostname {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $DomainPrefix,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('akamaized.net', 'edgesuite.net', 'edgekey.net')]
        [string]
        $DomainSuffix,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('IPV4', 'IPV6_COMPLIANCE', 'IPV6_PERFORMANCE')]
        [string]
        $IPVersionBehavior,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('ENHANCED_TLS', 'STANDARD_TLS', 'SHARED_CERT')]
        [string]
        $SecureNetwork,

        [Parameter(ParameterSetName = 'Attributes')]
        [int]
        $SlotNumber,

        [Parameter(ParameterSetName = 'Attributes')]
        [int]
        $CertEnrollmentID,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
        [string]
        $ContractId,

        [Parameter()]
        [string]
        $Options,

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
        $Path = "/papi/v1/edgehostnames"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
            options    = $Options
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'productId'         = $ProductID
                'domainPrefix'      = $DomainPrefix
                'domainSuffix'      = $DomainSuffix
                'ipVersionBehavior' = $IPVersionBehavior
            }

            if ($SecureNetwork -ne '') { $Body['secureNetwork'] = $SecureNetwork }
            if ($SlotNumber) { $Body['slotNumber'] = $SlotNumber }
            if ($CertEnrollmentID) { $Body['certEnrollmentId'] = $CertEnrollmentID }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Body.edgeHostnameLink -Match '\/edgehostnames\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'edgeHostnameId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}
