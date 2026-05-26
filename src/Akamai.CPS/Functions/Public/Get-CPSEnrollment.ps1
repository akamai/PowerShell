function Get-CPSEnrollment {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline)]
        [int]
        $EnrollmentID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ContractID,

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
        if ($EnrollmentID) {
            $Path = "/cps/v2/enrollments/$EnrollmentID"
        }
        else {
            $Path = "/cps/v2/enrollments"
        }

        if ($PSBoundParameters.EnrollmentID) {
            $AcceptHeader = 'application/vnd.akamai.cps.enrollment.v12+json'
        }
        else {
            $AcceptHeader = 'application/vnd.akamai.cps.enrollments.v12+json'
        }

        $AdditionalHeaders = @{
            'accept' = $AcceptHeader
        }
        $QueryParameters = @{
            'contractId' = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'QueryParameters'   = $QueryParameters
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PSBoundParameters.EnrollmentID) {
            return $Response.Body | Format-CPSResponse
        }
        else {
            return $Response.Body.enrollments | Format-CPSResponse
        }
    }
}
