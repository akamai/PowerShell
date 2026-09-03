function Confirm-CPSPostVerificationWarnings {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter(Mandatory)]
        [ValidateSet('acknowledge', 'deny')]
        [string]
        $Acknowledgement,

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
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/update/post-verification-warnings-ack"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.acknowledgement.v1+json'
        }
        $Body = @{
            'acknowledgement' = $Acknowledgement
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body | Format-CPSResponse
    }
}
