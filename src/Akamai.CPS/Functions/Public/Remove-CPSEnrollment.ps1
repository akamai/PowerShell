function Remove-CPSEnrollment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter()]
        [switch]
        $AllowCancelPendingChanges,

        [Parameter()]
        [string]
        $DeployNotAfter,

        [Parameter()]
        [string]
        $DeployNotBefore,

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
        $DateMatch = '[\d]{4}-[\d]{2}-[\d]{2}'
        if (($DeployNotAfter -or $DeployNotBefore) -and ($DeployNotAfter -notmatch $DateMatch -or $DeployNotBefore -notmatch $DateMatch)) {
            throw "ERROR: DeployNotAfter & DeployNotBefore must be in the format 'YYYY-MM-DD'"
        }
    
        $AdditionalHeaders = @{
            'accept' = 'application/vnd.akamai.cps.enrollment-status.v1+json'
        }
        $Path = "/cps/v2/enrollments/$EnrollmentID"
        $QueryParameters = @{
            'allow-cancel-pending-changes' = $PSBoundParameters.AllowCancelPendingChanges
            'deploy-not-after'             = $DeployNotAfter
            'deploy-not-before'            = $DeployNotBefore
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'DELETE'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
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
