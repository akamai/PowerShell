function Get-DataStreamAnswerXSSIDs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter()]
        [int]
        $PageSize,

        [Parameter()]
        [int]
        $Page,

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
        $Path = "/datastream-config-api/v3/log/answerx/contracts/$ContractID/answerxSSIDs"

        $QueryParameters = @{
            'page'     = $PSBoundParameters.Page
            'pageSize' = $PSBoundParameters.PageSize
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        try {
            $Response = Invoke-AkamaiRequest @RequestParams
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
