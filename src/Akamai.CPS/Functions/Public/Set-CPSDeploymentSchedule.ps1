function Set-CPSDeploymentSchedule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter()]
        [string]
        $NotAfter,

        [Parameter()]
        [string]
        $NotBefore,

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
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/deployment-schedule"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.deployment-schedule.v1+json'
        }
    
        $Body = @{}
        if ($NotAfter) {
            $Body['notAfter'] = $NotAfter
        }
        if ($NotBefore) {
            $Body['notBefore'] = $NotBefore
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
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
