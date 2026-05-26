function Set-CPSEnrollment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $AllowCancelPendingChanges,

        [Parameter()]
        [switch]
        $AllowStagingBypass,

        [Parameter()]
        [string]
        $DeployNotAfter,

        [Parameter()]
        [string]
        $DeployNotBefore,

        [Parameter()]
        [switch]
        $ForceRenewal,

        [Parameter()]
        [switch]
        $RenewalDateCheckOverride,

        [Parameter()]
        [switch]
        $AllowMissingCertificateAddition,

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
        $DateMatch = '[\d]{4}-[\d]{2}-[\d]{2}'
        if (($DeployNotAfter -or $DeployNotBefore) -and ($DeployNotAfter -notmatch $DateMatch -or $DeployNotBefore -notmatch $DateMatch)) {
            throw "ERROR: DeployNotAfter & DeployNotBefore must be in the format 'YYYY-MM-DD'"
        }

        $QueryParameters = @{
            'allow-cancel-pending-changes'       = $PSBoundParameters.AllowCancelPendingChanges
            'allow-staging-bypass'               = $PSBoundParameters.AllowStagingBypass
            'force-renewal'                      = $PSBoundParameters.ForceRenewal
            'renewal-date-check-override'        = $PSBoundParameters.RenewalDateCheckOverride
            'allow-missing-certificate-addition' = $PSBoundParameters.AllowMissingCertificateAddition
        }
        
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.enrollment-status.v1+json'
            'content-type' = 'application/vnd.akamai.cps.enrollment.v12+json'
        }
    }
    
    process {
        $Path = "/cps/v2/enrollments/$EnrollmentID"
        # Cleanup request body to remove additional elements added in Get-CPSEnrollment
        $Body = Get-BodyObject -Source $Body
        if ($Body.pendingChanges) {
            $Body.pendingChanges | ForEach-Object {
                if ($_.changeId) {
                    $_.PSObject.Members.Remove('changeId')
                }
            }
        }

        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
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
