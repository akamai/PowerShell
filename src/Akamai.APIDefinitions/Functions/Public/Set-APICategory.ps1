function Set-APICategory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $APICategoryID,

        [Parameter(Mandatory)]
        [string]
        $APICategoryName,
        
        [Parameter()]
        [string]
        $APICategoryDescription,

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

    $Path = "/api-definitions/v2/categories/$APICategoryID"
    $Body = @{
        'apiCategoryName'        = $APICategoryName
        'apiCategoryDescription' = $APICategoryDescription
    }
    $RequestParams = @{
        'Path'             = $Path
        'Method'           = 'PUT'
        'Body'             = $Body
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body
}

