function Expand-CloudletLoadBalancerDetails {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $OriginID,

        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    if ($Version -eq 'latest') {
        $Versions = Get-CloudletLoadBalancerVersion -OriginID $OriginID -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey | Sort-Object -Property Version -Descending
        $Version = $Versions[0].version
    }

    return $Version
}

function Expand-CloudletPolicyDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [int]
        $PolicyID,

        [Parameter()]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter(ValueFromRemainingArguments)]
        $UnusedArgs
    )

    if ($Version -eq 'latest') {
        $Versions = @(Get-CloudletPolicyVersion -PolicyID $PolicyID -PageSize 10 -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey)
        if ($Versions.count -gt 0) {
            $Version = $Versions[0].Version
        }
    }

    return $Version
}

function Get-BodyObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        $Source
    )

    if ($Source -is 'String') {
        # Trim whitespace
        $Source = $Source.Trim()
        # Handle JSON array
        if ($Source.StartsWith('[')) {
            $BodyObject = ConvertFrom-Json -InputObject $Source -AsArray -NoEnumerate
        }
        # Handle standard JSON object
        elseif ($Source.StartsWith('{') -and $Source.EndsWith('}')) {
            $BodyObject = ConvertFrom-Json -InputObject $Source
        }
        # If none of the above, just use string as-is
        else {
            $BodyObject = $Source
        }
    }
    elseif ($Source -is 'Hashtable') {
        $BodyObject = [PScustomObject] $Source
    }
    elseif ($Source -is 'PSCustomObject' -or $Source -is 'Object' -or $Source -is 'Object[]') {
        $BodyObject = $Source
    }
    else {
        throw "Source param is of an unhandled type '$($Source.GetType().Name)'"
    }

    return $BodyObject
}

function Copy-CloudletPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(Mandatory)]
        [string]
        $NewName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $GroupID,

        [Parameter()]
        [string[]]
        $AdditionalVersions,

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

    Process {
        $Path = "/cloudlets/v3/policies/$PolicyID/clone"
        $Body = @{
            newName = $NewName
            groupId = $GroupID
        }

        if ($AdditionalVersions) {
            $Body['additionalVersions'] = $AdditionalVersions
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
        return $Response.Body
    }
}


function Get-Cloudlet {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(ParameterSetName = 'Non-shared policy', Position = 0)]
        [int]
        $CloudletID,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [switch]
        $Legacy,

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

    Process {
        if ($Legacy) {
            if ($CloudletID) {
                $Path = "/cloudlets/api/v2/cloudlet-info/$CloudletID"
            }
            else {
                $Path = "/cloudlets/api/v2/cloudlet-info"
            }
        }
        else {
            $Path = "/cloudlets/v3/cloudlet-info"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Get-CloudletGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [int]
        $GroupID,

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

    Process {
        if ($GroupID) {
            $Path = "/cloudlets/api/v2/group-info/$($PSBoundParameters.GroupID)"
        }
        else {
            $Path = "/cloudlets/api/v2/group-info"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-CloudletLoadBalancer {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0)]
        [string]
        $OriginID,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('APPLICATION_LOAD_BALANCER', 'CUSTOMER', 'NETSTORAGE')]
        [string]
        $Type,

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

    Process {
        if ($OriginID) {
            $Path = "/cloudlets/api/v2/origins/$OriginID"
        }
        else {
            $Path = "/cloudlets/api/v2/origins"
        }
        $QueryParameters = @{
            'type' = $Type
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
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Get-CloudletLoadBalancerActivation {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [string]
        $OriginID,

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

    Process {
        if ($OriginID) {
            $Path = "/cloudlets/api/v2/origins/$OriginID/activations"
        }
        else {
            $Path = "/cloudlets/api/v2/origins/currentActivations"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

function Get-CloudletLoadBalancerVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [string]
        $OriginID,

        [Parameter(Position = 1)]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $Validate,

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

    Process {
        if ($Version) {
            $Version = Expand-CloudletLoadBalancerDetails -OriginID $OriginID -Version $Version -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
            $Path = "/cloudlets/api/v2/origins/$OriginID/versions/$Version"
        }
        else {
            $Path = "/cloudlets/api/v2/origins/$OriginID/versions"
        }
        $QueryParameters = @{
            'validate' = $PSBoundParameters.Validate
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
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Get-CloudletPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0, ValueFromPipeline)]
        [int]
        $PolicyID,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IncludeDeleted,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CloudletID,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $All,

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

    Process {
        if ($Legacy) {
            if ($PolicyID) {
                $Path = "/cloudlets/api/v2/policies/$PolicyID"
            }
            else {
                $Path = "/cloudlets/api/v2/policies"
            }
            $QueryParameters = @{
                'gid'            = $PSBoundParameters.GroupID
                'includedeleted' = $PSBoundParameters.IncludeDeleted
                'cloudletId'     = $CloudletId
                'offset'         = $PSBoundParameters.Page
                'pageSize'       = $PSBoundParameters.PageSize
            }
        }
        else {
            if ($PolicyID) {
                $Path = "/cloudlets/v3/policies/$PolicyID"
            }
            else {
                $Path = "/cloudlets/v3/policies"
            }
            $QueryParameters = @{
                'page' = $PSBoundParameters.Page
                'size' = $PSBoundParameters.PageSize
            }
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
        $Response = Invoke-AkamaiRequest @RequestParams

        # If -all is selected, loop through paged responses until you get to the end.
        if ($All) {
            if ($Response.Headers.Link) {
                $NextPresent = $Response.Headers.Link | Select-Object -First 1 | Select-String -pattern '^.*,.*offset=([\d]+).*pageSize=([\d]+)>;\s+rel=\"next\".*$'
                if ($NextPresent) {
                    $NextOffset = $NextPresent.Matches.Groups[1].Value
                    $NextPageSize = $NextPresent.Matches.Groups[2].Value
                    if ($NextOffset -and $NextPageSize) {
                        Write-Debug "Loading next request with offset $NextOffset and page size $NextPageSize"
                        $PSBoundParameters.Page = $NextOffset
                        $PSBoundParameters.PageSize = $NextPageSize
                        $PagedResult = Get-CloudletPolicy @PSBoundParameters
                        if ($Legacy) {
                            $Response.Body += $PagedResult
                        }
                        else {
                            $Response.Body.Content += $PagedResult
                        }
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all' -and -not $Legacy) {
            return $Response.Body.content
        }
        else {
            return $Response.Body
        }
    }
}


function Get-CloudletPolicyActivation {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Get one')]
        [int]
        $ActivationID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('prod', 'staging', IgnoreCase = $false)]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $PropertyName,

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

    Process {
        # If activation ID supplied, assume shared
        if ($ActivationID -and $Legacy) {
            $Legacy = $false
        }

        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/activations"
            $QueryParameters = @{
                'network'      = $Network
                'propertyName' = $PropertyName
                'offset'       = $PSBoundParameters.Page
                'pageSize'     = $PSBoundParameters.PageSize
            }
        }
        else {
            if ($ActivationID) {
                $Path = "/cloudlets/v3/policies/$PolicyID/activations/$ActivationID"
            }
            else {
                $Path = "/cloudlets/v3/policies/$PolicyID/activations"
            }
            $QueryParameters = @{
                'page' = $PSBoundParameters.Page
                'size' = $PSBoundParameters.PageSize
            }
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
        $Response = Invoke-AkamaiRequest @RequestParams
        if (-not $Legacy -and -not $ActivationID) {
            return $Response.Body.content
        }
        else {
            return $Response.Body
        }
    }
}


function Get-CloudletPolicyProperty {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(ParameterSetName = 'Shared policy')]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Shared policy')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Shared policy')]
        [int]
        $PageSize,

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

    Process {
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/properties"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID/properties"
        }

        $QueryParameters = @{
            'page' = $PSBoundParameters.Page
            'size' = $PSBoundParameters.PageSize
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
        $Response = Invoke-AkamaiRequest @RequestParams
        if (-not $Legacy) {
            return $Response.Body.content
        }
        else {
            return $Response.Body
        }
    }
}


function Get-CloudletPolicyVersion {
    [CmdletBinding(DefaultParameterSetName = 'Get one')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(ParameterSetName = 'Get one', Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $OmitRules,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        if ($Legacy) {
            if ($Version) {
                $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version"
            }
            else {
                $Path = "/cloudlets/api/v2/policies/$PolicyID/versions"
            }
            $QueryParameters = @{
                'omitRules' = $PSBoundParameters.OmitRules
                'offset'    = $PSBoundParameters.Page
                'pageSize'  = $PSBoundParameters.PageSize
            }
        }
        else {
            if ($Version) {
                $Path = "/cloudlets/v3/policies/$PolicyID/versions/$Version"
            }
            else {
                $Path = "/cloudlets/v3/policies/$PolicyID/versions"
            }
            $QueryParameters = @{
                'page' = $PSBoundParameters.Page
                'size' = $PSBoundParameters.PageSize
            }
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
        $Response = Invoke-AkamaiRequest @RequestParams
        if (-not $Legacy -and ($Version -eq "" -or $null -eq $Version)) {
            return $Response.Body.content
        }
        else {
            return $Response.Body
        }
    }
}


function Get-CloudletPolicyVersionRule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(Mandatory)]
        [string]
        $AkaRuleID,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version/rules/$AkaRuleID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Get-CloudletProperty {
    [CmdletBinding()]
    Param(
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

    Process {
        $Path = "/cloudlets/api/v2/properties"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Get-CloudletSchema {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0, Mandatory)]
        [string]
        $SchemaName,

        [Parameter(ParameterSetName = 'Get all', Mandatory)]
        [ValidateSet('API Prioritization', 'Application Load Balancer', 'Audience Segmentation', 'Edge Redirector', 'Forward Rewrite', 'Phased Release', 'Request Control', 'Visitor Prioritization')]
        [string]
        $CloudletType,

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

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/cloudlets/api/v2/schemas/$SchemaName"
        }
        else {
            $Path = "/cloudlets/api/v2/schemas"
            switch ($CloudletType) {
                'API Prioritization' { $CloudletTypeCode = 'AP' }
                'Application Load Balancer' { $CloudletTypeCode = 'ALB' }
                'Audience Segmentation' { $CloudletTypeCode = 'AS' }
                'Edge Redirector' { $CloudletTypeCode = 'ER' }
                'Forward Rewrite' { $CloudletTypeCode = 'FR' }
                'Phased Release' { $CloudletTypeCode = 'CD' }
                'Request Control' { $CloudletTypeCode = 'IG' }
                'Visitor Prioritization' { $CloudletTypeCode = 'VP' }
            }
            $QueryParameters = @{
                'cloudletType' = $CloudletTypeCode
            }
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
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($SchemaName) {
            return $Response.Body
        }
        else {
            return $Response.Body.schemas
        }
    }
}


function New-CloudletLoadBalancer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]
        $OriginID,

        [Parameter()]
        [string]
        $Description,

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

    Process {
        $Path = "/cloudlets/api/v2/origins"
        $Body = @{
            'originId' = $OriginID
        }
        if ($Description) {
            $Body.description = $Description
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
        return $Response.Body
    }
}


function New-CloudletLoadBalancerActivation {
    [CmdletBinding()]
    [Alias('Deploy-CloudletLoadBalancer')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $OriginID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $Async,

        [Parameter()]
        [switch]
        $DryRun,

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

    Process {
        $Path = "/cloudlets/api/v2/origins/$OriginID/activations"
        $Version = Expand-CloudletLoadBalancerDetails -OriginID $OriginID -Version $Version -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $QueryParameters = @{
            'async' = $Async.IsPresent
        }
        $Body = @{
            'network' = $Network.ToUpper()
            'version' = [int] $Version
            'dryrun'  = $DryRun.IsPresent
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
        return $Response.Body
    }
}

function New-CloudletLoadBalancerVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]
        $OriginID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $Validate,

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

    Process {
        $Path = "/cloudlets/api/v2/origins/$OriginID/versions"
        $QueryParameters = @{
            'validate' = $PSBoundParameters.Validate
        }

        $AdditionalHeaders = @{
            'Content-Type' = 'application/json'
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
        return $Response.Body
    }
}


function New-CloudletPolicy {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Description,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory)]
        [ValidateSet('API Prioritization', 'Application Load Balancer', 'Audience Segmentation', 'Edge Redirector', 'Forward Rewrite', 'Phased Release', 'Request Control', 'Visitor Prioritization')]
        [string]
        $CloudletType,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [int]
        $ClonePolicyID,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [int]
        $ClonePolicyVersion,

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

    Process {
        $Body = @{
            'name'        = $Name
            'groupId'     = $GroupID
            'description' = $Description
        }

        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies"
            switch ($CloudletType) {
                'API Prioritization' { $CloudletID = 5 }
                'Application Load Balancer' { $CloudletID = 9 }
                'Audience Segmentation' { $CloudletID = 6 }
                'Edge Redirector' { $CloudletID = 0 }
                'Forward Rewrite' { $CloudletID = 3 }
                'Phased Release' { $CloudletID = 7 }
                'Request Control' { $CloudletID = 4 }
                'Visitor Prioritization' { $CloudletID = 1 }
            }
            $Body.cloudletId = $CloudletID
        }
        else {
            $Path = "/cloudlets/v3/policies"
            $Body.policyType = 'SHARED'
            switch ($CloudletType) {
                'API Prioritization' { $SharedType = 'AP' }
                'Application Load Balancer' { throw "'Application Load Balancer' policies must use the -Legacy switch." }
                'Audience Segmentation' { $SharedType = 'AS' }
                'Edge Redirector' { $SharedType = 'ER' }
                'Forward Rewrite' { $SharedType = 'FR' }
                'Phased Release' { $SharedType = 'CD' }
                'Request Control' { $SharedType = 'IG' }
                'Visitor Prioritization' { throw "'Visitor Prioritization' policies must use the -Legacy switch." }
            }
            $Body.cloudletType = $SharedType
        }

        $QueryParameters = @{
            'clonePolicyId' = $PSBoundParameters.ClonePolicyID
            'version'       = $PSBoundParameters.ClonePolicyVersion
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
        return $Response.Body
    }
}


function New-CloudletPolicyActivation {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    [Alias('Deploy-CloudletPolicy')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [string[]]
        $AdditionalPropertyNames,

        [Parameter(Mandatory)]
        [string]
        [ValidateSet('STAGING', 'PRODUCTION', IgnoreCase = $false)]
        $Network,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Body = @{
            'network' = $Network
        }

        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version/activations"
            if ($AdditionalPropertyNames) {
                $Body.additionalPropertyNames = $AdditionalPropertyNames
            }
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID/activations"
            $Body.operation = 'ACTIVATION'
            $Body.policyVersion = $Version
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
        return $Response.Body
    }
}

function New-CloudletPolicyDeactivation {
    [CmdletBinding()]
    [Alias('Disable-CloudletPolicy')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(Mandatory)]
        [string]
        [ValidateSet('STAGING', 'PRODUCTION', IgnoreCase = $false)]
        $Network,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Path = "/cloudlets/v3/policies/$PolicyID/activations"
        $Body = @{
            'network'       = $Network
            'operation'     = 'DEACTIVATION'
            'policyVersion' = $Version
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
        return $Response.Body
    }
}

function New-CloudletPolicyVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/versions"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID/versions"
        }

        ### Sanitize
        $Body = Get-BodyObject -Source $Body
        $Body = @{
            'description' = $Body.description
            'matchRules'  = $Body.matchRules
        }
        foreach ($Rule in $Body.matchRules) {
            $Rule.PSObject.Members.Remove('location')

            ### RC-specific
            if ($Rule.type -eq 'igMatchRule') {
                $Rule.PSObject.Members.Remove('matchURL')
            }
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
        return $Response.Body
    }

}

function New-CloudletPolicyVersionRule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $PolicyID,

        [Parameter(Mandatory)]
        [string]
        $Version,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $Index,

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
    begin {}
    process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version/rules"
        $QueryParameters = @{
            'index' = $Index
        }

        # Parse body to remove invalid matchUrl
        $Body = Get-BodyObject -Source $Body
        if ($Body.matches.count -gt 0 -and 'matchUrl' -in $Body.PSObject.Properties.Name) {
            $Body.PSObject.Members.Remove('matchUrl')
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
        return $Response.Body
    }
}


function Remove-CloudletLoadBalancer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $OriginID,

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

    Process {
        $Path = "/cloudlets/api/v2/origins/$OriginID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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
}


function Remove-CloudletPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter()]
        [switch]
        $Legacy,

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

    Process {
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Remove-CloudletPolicyVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [nullable[int]]
        $PolicyID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AllowNull()]
        $Version,

        [Parameter()]
        [switch]
        $Legacy,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID/versions/$Version"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


function Set-CloudletLoadBalancer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $OriginID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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
        $Path = "/cloudlets/api/v2/origins/$OriginID"
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

}


function Set-CloudletLoadBalancerVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $OriginID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $Validate,

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

    Process {
        $Version = Expand-CloudletLoadBalancerDetails -OriginID $OriginID -Version $Version -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Path = "/cloudlets/api/v2/origins/$OriginID/versions/$Version"
        $QueryParameters = @{
            'validate' = $PSBoundParameters.Validate
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'QueryParameters'  = $QueryParameters
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

}


function Set-CloudletPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Non-shared policy')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(ParameterSetName = 'Shared policy')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Shared policy')]
        [Parameter(Mandatory, ParameterSetName = 'Non-shared policy')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Shared policy')]
        [Parameter(ParameterSetName = 'Non-shared policy')]
        [string]
        $Description,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
        $Body,

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

    Process {
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID"
        }

        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            $Body = @{}
            if ($Name) { $Body['name'] = $Name }
            if ($GroupID) { $Body['groupId'] = $GroupID }
            if ($Description) { $Body.description = $Description }
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
}


function Set-CloudletPolicyVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter()]
        [switch]
        $OmitRules,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID/versions/$Version"
        }

        ### Sanitize
        $Body = Get-BodyObject -Source $Body
        $Body = @{
            'description' = $Body.description
            'matchRules'  = $Body.matchRules
        }
        foreach ($Rule in $Body.matchRules) {
            $Rule.PSObject.Members.Remove('location')

            ### RC-specific
            if ($Rule.type -eq 'igMatchRule') {
                $Rule.PSObject.Members.Remove('matchURL')
            }
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
}

function Set-CloudletPolicyVersionRule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $PolicyID,

        [Parameter(Mandatory)]
        [string]
        $Version,

        [Parameter(Mandatory)]
        [string]
        $AkaRuleID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version/rules/$AkaRuleID"
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
}



# SIG # Begin signature block
# MIIo2AYJKoZIhvcNAQcCoIIoyTCCKMUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAf296R7QWq7nRf
# GIrsGcMeRP+tsabZMoHP3Gp9Tr3s0KCCDg4wggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggdWMIIFPqADAgECAhAGRzH371ShX6hjGl1wSSyYMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjYwMjI1MDAwMDAwWhcNMjcwMzEw
# MjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEDAOBgNV
# BAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRz
# MRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1haSBUZWNobm9sb2dp
# ZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVzIEluYzCCAaIwDQYJ
# KoZIhvcNAQEBBQADggGPADCCAYoCggGBAJeMKuhiUI5WSRdGIPhNWLpaVPlXbSaz
# hGuvzZxTi623Ht46hiPejDtWB8F8dT2pd+nOWsx5NVgkv7x/Tz35cZcWVMDxq/K7
# wYe9R2GndGgfEL02/j5rslwHr8e6qFzy1axuL/xaGXuBTVrSQw25019l1KalUHwI
# nKLIP7Hw1HLPTacyJNNTsYmOpZNqKIiQe9ivzBd7SuPU0cGi1YHUk4ZQh6Ig5tBx
# 8XZYjTmzbiQr2WWwk/CufaoIPME5zAvmW99S05rAtOqvoUr7eoLUQ/TcMMA6eOli
# AbO5m0w/pv5YDgzhzt9hQez189zZNOkMO6AcHNitJzzsEvCg7fhPHxoXvasRJ0Ea
# CEze0nuVakLPf+mGCLoZYGRctayOn4HP6LEEOGmAnQBZkwFR6zxk0hzAMOkK/p7M
# V9V6QwOuk9q7WKnIdzS/4RjRtXNxXb2fMNyBEwrwJhdmEhWF0eS0Wd6Uz3IbSr0+
# XH8FHLflQXFCkPcZKiGPgSCp8rTP3KHr6wIDAQABo4ICAjCCAf4wHwYDVR0jBBgw
# FoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFKT3RICOlmcsnPu7KwUf
# 9HL4YegLMD0GA1UdIAQ2MDQwMgYFZ4EMAQMwKTAnBggrBgEFBQcCARYbaHR0cDov
# L3d3dy5kaWdpY2VydC5jb20vQ1BTMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAK
# BggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEz
# ODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5j
# cmwwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIw
# MjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQADggIBAGSBrSnUReHU
# zGTy9VC6hy2oDSpu2QNu5j3o/uoaaAy2CgI0hVJRL/OfYinLR4hJofuNNKORp2MW
# Xpy52L5PCGtD6/Hf92bMkDl1AP6nXuplt5HvkFPh5kVDbQ7oHfI1Pup2IOpKxb00
# UNwjtKy+38ZCX0dgkASP2vQFamBCG0eTaGUh/9ZH9rz11Nkr9p83Snz/3eW3vOeK
# AFL3S5RDEMkTvv09540mnzA4J5lKGES2eje/FhwCCQUQBvqCvoNFNZHyXvW9v8Kq
# X/3CcN1LAtGCy4XnkFjQRPyn+o/OJv5M5yX2Rm5kq9dYpWnDU2xgxMR1BZaDf+uD
# oqGsLo4OqbPV4Dftp2FDs8DHMD8xP6i/k4htaWShkdyjdijr9TBOi+pS9vNlcCKj
# wLq6aibcbkUk7ef3wxR5imhajsX22vy8Zd9ByAk07BJrccggJGczCtiKcD6LZtP3
# VjnqhYPSQ4jk6wCruqcTCTwwO7FrIROVrWb2Ro+ph+/a5Llj5ryLyp+6NAgtNwyr
# kp2WxZviLbh5AXnmg9Pnwrz64UE93LEjI23AWBJsLFdJTbisZ/tTgozdVdPZf2Dy
# 2k8xfYZoIq6V1oWiAoQCzb5B9nETV5NGjiMPskJ4GwnlzOvz+4IgLQjl0V5I08Qw
# +3uvPQ8rHHMLbKgncTqSxqtZ73kItOztMYIaIDCCGhwCAQEwfTBpMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0
# IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0Ex
# AhAGRzH371ShX6hjGl1wSSyYMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAOihTi0Jx7BI45Kw+JDy8WX
# 4I3sKFMAAgW1PG8iQNmaMA0GCSqGSIb3DQEBAQUABIIBgES9RScp4Lgac8qAkEtg
# DpRX2d3yBbKOpk/axdJ4g6oBhDWSXDbDn40Wn5Q+mrBSXUC5tDvaw2YWjZwe5XRU
# IrEh3P+SXWZp7Ky+fOQ/97o5zfM0d4ePnY4X4IHbIP3/dmwzmLSkT9qhVmP8FgIk
# nCnB10GcojCaWU6i0kR1oXpl43ouAyd89zXAmuJYzciTQYzUghMT+Sue1yjWxPuq
# jGsnqNK5kOZh2kXh+1W0h9MfZm2JnUQhxxr29UXbbESkGbdHjib7STAtR5c/u4Rk
# rm92xpk2d5Tehs/aYjeUmTVkfjIkob2SaEh0cdWXwztoWKsZibJeZ3sEI/O81MTA
# /0+JNtdPhaeqWwsGfrLMTUEZtAT5j9aFCIzZS/fZorKK581sIn4SQBxP2/xtMpBa
# mLAaIm70wYrHCzBxNolxPkSsScKxoPaOiGIcy5flJ8N6uHZyVUeF/dYBG6N1+oVT
# 6gQEgsyPqW6nlgSa7V84WGdKFjjar9GLIqk5AlbWc+ccQqGCF3YwghdyBgorBgEE
# AYI3AwMBMYIXYjCCF14GCSqGSIb3DQEHAqCCF08wghdLAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCDliRzUog3GB9s/TqoE6L6cwlUVwj1ddlb5eORkfx2o5wIQc0N4
# ArUtvIduqslimGuvxRgPMjAyNjA4MjUyMjQxMDBaoIITOjCCBu0wggTVoAMCAQIC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMx
# FzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVz
# dGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTAeFw0y
# NTA2MDQwMDAwMDBaFw0zNjA5MDMyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgU0hBMjU2IFJT
# QTQwOTYgVGltZXN0YW1wIFJlc3BvbmRlciAyMDI1IDEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDQRqwtEsae0OquYFazK1e6b1H/hnAKAd/KN8wZQjBj
# MqiZ3xTWcfsLwOvRxUwXcGx8AUjni6bz52fGTfr6PHRNv6T7zsf1Y/E3IU8kgNke
# ECqVQ+3bzWYesFtkepErvUSbf+EIYLkrLKd6qJnuzK8Vcn0DvbDMemQFoxQ2Dsw4
# vEjoT1FpS54dNApZfKY61HAldytxNM89PZXUP/5wWWURK+IfxiOg8W9lKMqzdIo7
# VA1R0V3Zp3DjjANwqAf4lEkTlCDQ0/fKJLKLkzGBTpx6EYevvOi7XOc4zyh1uSqg
# r6UnbksIcFJqLbkIXIPbcNmA98Oskkkrvt6lPAw/p4oDSRZreiwB7x9ykrjS6GS3
# NR39iTTFS+ENTqW8m6THuOmHHjQNC3zbJ6nJ6SXiLSvw4Smz8U07hqF+8CTXaETk
# VWz0dVVZw7knh1WZXOLHgDvundrAtuvz0D3T+dYaNcwafsVCGZKUhQPL1naFKBy1
# p6llN3QgshRta6Eq4B40h5avMcpi54wm0i2ePZD5pPIssoszQyF4//3DoK2O65Uc
# k5Wggn8O2klETsJ7u8xEehGifgJYi+6I03UuT1j7FnrqVrOzaQoVJOeeStPeldYR
# NMmSF3voIgMFtNGh86w3ISHNm0IaadCKCkUe2LnwJKa8TIlwCUNVwppwn4D3/Pt5
# pwIDAQABo4IBlTCCAZEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU5Dv88jHt/f3X
# 85FxYxlQQ89hjOgwHwYDVR0jBBgwFoAU729TSunkBnx6yuKQVvYv1Ensy04wDgYD
# VR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMIGVBggrBgEFBQcB
# AQSBiDCBhTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMF0G
# CCsGAQUFBzAChlFodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcnQwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3JsMCAG
# A1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOC
# AgEAZSqt8RwnBLmuYEHs0QhEnmNAciH45PYiT9s1i6UKtW+FERp8FgXRGQ/YAavX
# zWjZhY+hIfP2JkQ38U+wtJPBVBajYfrbIYG+Dui4I4PCvHpQuPqFgqp1PzC/ZRX4
# pvP/ciZmUnthfAEP1HShTrY+2DE5qjzvZs7JIIgt0GCFD9ktx0LxxtRQ7vllKluH
# WiKk6FxRPyUPxAAYH2Vy1lNM4kzekd8oEARzFAWgeW3az2xejEWLNN4eKGxDJ8WD
# l/FQUSntbjZ80FU3i54tpx5F/0Kr15zW/mJAxZMVBrTE2oi0fcI8VMbtoRAmaasl
# NXdCG1+lqvP4FbrQ6IwSBXkZagHLhFU9HCrG/syTRLLhAezu/3Lr00GrJzPQFnCE
# H1Y58678IgmfORBPC1JKkYaEt2OdDh4GmO0/5cHelAK2/gTlQJINqDr6JfwyYHXS
# d+V08X1JUPvB4ILfJdmL+66Gp3CSBXG6IwXMZUXBhtCyIaehr0XkBoDIGMUG1dUt
# wq1qmcwbdUfcSYCn+OwncVUXf53VJUNOaMWMts0VlRYxe5nK+At+DI96HAlXHAL5
# SlfYxJ7La54i71McVWRP66bW+yERNpbJCjyCYG2j+bdpxo/1Cy4uPcU3AWVPGrbn
# 5PhDBf3Froguzzhk++ami+r3Qrx5bIbY3TVzgiFI7Gq3zWcwgga0MIIEnKADAgEC
# AhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yNTA1MDcw
# MDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1l
# U3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51NrY0NlLWZ
# loMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5bap+0lgloM
# 2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf77S2uPoCj
# 7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF2hfQz3zQ
# Sku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80FiocSk1VYLZ
# lDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzVyhYn4p0+
# 8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl92QOMeRx
# ykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGPRdtBx3yG
# OP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//Wx+5kMqI
# MRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4OLu9BMIFm
# 1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM7Bu2ayBj
# UwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU729T
# SunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUF
# BwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEG
# CCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAX
# MAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBABfO+xaA
# HP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM0lBryPTQ
# M2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqWGd3rLAUt
# 6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr0UdqirZ7
# bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35k5zOCPmS
# Nq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKqMVuqte69
# M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiyfTPjLbnF
# RsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDUphPvSRmM
# Thi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTjd6xpR6oa
# Qf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2ZyJ/+xhCx
# 9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWCnb5WqxL3
# /BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIFjTCCBHWgAwIBAgIQDpsYjvnQ
# Lefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYD
# VQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAw
# WhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QN
# xDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DC
# srp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTr
# BcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463JT17l
# Necxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WC
# QTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1
# EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KS
# Op493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAs
# QWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUO
# UlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtv
# sauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCC
# ATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQD
# AgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaG
# NGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9D
# XFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6
# Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuW
# cqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLih
# Vo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBj
# xZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02f
# c7cBqZ9Xql4o4rmUMYIDfDCCA3gCAQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQg
# VGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExAhAKgO8YS43xBYLR
# xHanlXRoMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAcBgkqhkiG9w0BCQUxDxcNMjYwODI1MjI0MTAwWjArBgsqhkiG9w0BCRAC
# DDEcMBowGDAWBBTdYjCshgotMGvaOLFoeVIwB/tBfjAvBgkqhkiG9w0BCQQxIgQg
# xvMKi31/7vO8fPH/Xq+r2fAeIS8AiSH06cpJhSftZp4wNwYLKoZIhvcNAQkQAi8x
# KDAmMCQwIgQgSqA/oizXXITFXJOPgo5na5yuyrM/420mmqM08UYRCjMwDQYJKoZI
# hvcNAQEBBQAEggIAkbktlrM8dq9dJ4AlCj6kGu9YkEyahHkjud5n5ytdEY4ejwMR
# eOlqgebEFAX2Kz4B5q0pSi+MSf4NhC31dGPU1u3pY8dcRNMxRAhw9DidPQi2Cha6
# ZcZiipmNiJPuZjiNIb/Wp3JXx8hGAZnEfZG6u9KTCe2v/QvN5g+LYe2Z9ctUIlWV
# f+YDlfejkI0whlTAvnFjF7CZoSTXhgwTbyd/e4nXi5OsSDyYmDrNvwfvDzEn+1M3
# X3iIY/ZJIgb4A38eZ0agFd70rfPM3ty2ejVJXHR1/LYY9q0Vsym0mzWynhpFrELe
# H3p793EF3Dn4wOgWKQzBj2jCTlpP6+4D7S8C6MaPsbAHxRGawKOaGlLboMzyxMzv
# JNVjkGLwVlnOZ7zCadkoNxC0PA6Rja6U/LuC4pAMOTcy6V0HtGIMXxqA1vNBQ6L2
# ak0GzltpaWw0g5Yo2FP/HevTb8RZJHa9TU3yqd+ESuIia9Mt8M64zd0CUcpAt7G4
# BNSq1aVGhD/A35zA0EuPJTTRI2xOK/Wvwb8/Ke+AJRLpwFtzNpHtaSaOBksLJxeI
# CiP15wKK5AQWT6YwivdAiVcaYbo6VEKOz+37ATpiqxwxkRLwFj5o8pZ3U3yNIUeI
# JVzXhlztvdnDTnn49aGTnS4OiCY+5ZeF2KceK60et7nX15Wd8qBxnca/QZc=
# SIG # End signature block
