function Find-Property {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,
    
        [Parameter(ParameterSetName = 'Host', Mandatory)]
        [string]
        $PropertyHostname,
    
        [Parameter(ParameterSetName = 'Edge', Mandatory)]
        [string]
        $EdgeHostname,
    
        [Parameter(ParameterSetName = 'Include', Mandatory)]
        [string]
        $IncludeName,
    
        [Parameter()]
        [switch]
        $Latest,
    
        [Parameter()]
        [switch]
        $JustProductionActive,
    
        [Parameter()]
        [switch]
        $JustStagingActive,
    
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

    $Path = "/papi/v1/search/find-by-value"
    
    $Body = @{}
    if ($PropertyName) {
        $Body["propertyName"] = $PropertyName
    }
    elseif ($PropertyHostname) {
        $Body["hostname"] = $PropertyHostName
    }
    elseif ($EdgeHostname) {
        $Body["edgeHostname"] = $EdgeHostname
    }
    elseif ($IncludeName) {
        $Body["includeName"] = $IncludeName
    }
    $RequestParams = @{
        'Path'             = $Path
        'Method'           = 'POST'
        'Body'             = $Body
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    if ($Latest) {
        if ($IncludeName) {
            $SortedResult = $Response.Body.versions.items | Sort-Object -Property includeVersion -Descending
        }
        else {
            $SortedResult = $Response.Body.versions.items | Sort-Object -Property propertyVersion -Descending
        }
        if ($null -ne $SortedResult -and $SortedResult.GetType().Name -eq "Object[]") {
            return $SortedResult[0]
        }
        else {
            return $SortedResult
        }
    }
    elseif ($JustProductionActive) {
        return $Response.Body.versions.items | Where-Object { $_.productionStatus -eq "ACTIVE" }
    }
    elseif ($JustStagingActive) {
        return $Response.Body.versions.items | Where-Object { $_.stagingStatus -eq "ACTIVE" }
    }
    else {
        return $Response.Body.versions.items
    }
}
