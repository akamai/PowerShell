function New-CPSEnrollment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $DeployNotAfter,

        [Parameter()]
        [string]
        $DeployNotBefore,

        [Parameter()]
        [switch]
        $AllowDuplicateCN,

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

        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.enrollment-status.v1+json'
            'content-type' = 'application/vnd.akamai.cps.enrollment.v12+json'
        }
        $Path = "/cps/v2/enrollments"
        $QueryParameters = @{
            'contractId'        = $ContractID
            'deploy-not-after'  = $DeployNotAfter
            'deploy-not-before' = $DeployNotBefore
            'allowDuplicateCN'  = $PSBoundParameters.AllowDuplicateCN
        }
    }
    process {
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
            'Method'            = 'POST'
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
