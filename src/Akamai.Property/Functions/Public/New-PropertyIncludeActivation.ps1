function New-PropertyIncludeActivation {
    [CmdletBinding(DefaultParameterSetName = 'ID & attributes')]
    [Alias('Deploy-PropertyInclude')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeVersion,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('Staging', 'Production')]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Note,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UseFastFallback,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string[]]
        $NotifyEmails,

        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [string]
        $ContractId,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [ValidateSet('NONE', 'OTHER', 'NO_PRODUCTION_TRAFFIC', 'EMERGENCY')]
        [string]
        $NoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $OtherNoncomplianceReason,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CustomerEmail,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $PeerReviewedBy,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UnitTested,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $TicketID,

        [Parameter()]
        [string]
        $EdgeRCFile = '~\.edgerc',

        [Parameter()]
        [string]
        $Section = 'default',

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $IncludeID, $IncludeVersion, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            if ($NoncomplianceReason -eq 'NONE' -and $Network -eq 'Production') {
                if ($CustomerEmail -eq '' -or $PeerReviewedBy -eq '' -or $UnitTested -eq $false) {
                    throw "You must supply the following when NonComplianceReason is 'NONE': CustomerEmail, PeerReviewedBy & UnitTested."
                }
            }

            $Body = @{
                includeVersion         = [int] $IncludeVersion
                network                = $Network.ToUpper()
                note                   = $Note
                useFastFallback        = $useFastFallback.ToBool()
                acknowledgeAllWarnings = $true
                notifyEmails           = $NotifyEmails
            }

            # Only add optional fields if they are present
            $ComplianceRecord = @{}
            if ($NoncomplianceReason) {
                $ComplianceRecord['noncomplianceReason'] = $NoncomplianceReason
            }
            if ($CustomerEmail) {
                $ComplianceRecord['customerEmail'] = $CustomerEmail
            }
            if ($PeerReviewedBy) {
                $ComplianceRecord['peerReviewedBy'] = $PeerReviewedBy
            }
            if ($UnitTested) {
                $ComplianceRecord['unitTested'] = $UnitTested.ToBool()
            }
            if ($TicketID) {
                $ComplianceRecord['ticketId'] = $TicketID
            }
            if ($OtherNoncomplianceReason) {
                $ComplianceRecord['otherNoncomplianceReason'] = $OtherNoncomplianceReason
            }

            # Only add compliance record to body if not empty
            if ($ComplianceRecord.count -gt 0) {
                $Body['complianceRecord'] = $ComplianceRecord
            }
        }

        $Path = "/papi/v1/includes/$IncludeID/activations"
        $QueryParameters = @{
            contractId = $ContractId
            groupId    = $GroupID
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
        if ($Response.Body.activationLink -Match '\/activations\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'activationId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}
