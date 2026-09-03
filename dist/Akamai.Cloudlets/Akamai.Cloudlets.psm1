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
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBYfCRtN1gJsTxj
# iXUz4A7iAJe+XuGk5s/DXXX6rvp/oqCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
# X6hjGl1wSSyYMA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBD
# b2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjYwMjI1MDAw
# MDAwWhcNMjcwMzEwMjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcG
# CysGAQQBgjc8AgECEwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6
# YXRpb24xEDAOBgNVBAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1N
# YXNzYWNodXNldHRzMRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1h
# aSBUZWNobm9sb2dpZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVz
# IEluYzCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAJeMKuhiUI5WSRdG
# IPhNWLpaVPlXbSazhGuvzZxTi623Ht46hiPejDtWB8F8dT2pd+nOWsx5NVgkv7x/
# Tz35cZcWVMDxq/K7wYe9R2GndGgfEL02/j5rslwHr8e6qFzy1axuL/xaGXuBTVrS
# Qw25019l1KalUHwInKLIP7Hw1HLPTacyJNNTsYmOpZNqKIiQe9ivzBd7SuPU0cGi
# 1YHUk4ZQh6Ig5tBx8XZYjTmzbiQr2WWwk/CufaoIPME5zAvmW99S05rAtOqvoUr7
# eoLUQ/TcMMA6eOliAbO5m0w/pv5YDgzhzt9hQez189zZNOkMO6AcHNitJzzsEvCg
# 7fhPHxoXvasRJ0EaCEze0nuVakLPf+mGCLoZYGRctayOn4HP6LEEOGmAnQBZkwFR
# 6zxk0hzAMOkK/p7MV9V6QwOuk9q7WKnIdzS/4RjRtXNxXb2fMNyBEwrwJhdmEhWF
# 0eS0Wd6Uz3IbSr0+XH8FHLflQXFCkPcZKiGPgSCp8rTP3KHr6wIDAQABo4ICAjCC
# Af4wHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFKT3
# RICOlmcsnPu7KwUf9HL4YegLMD0GA1UdIAQ2MDQwMgYFZ4EMAQMwKTAnBggrBgEF
# BQcCARYbaHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmlu
# Z1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hB
# Mzg0MjAyMUNBMS5jcmwwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNB
# NDA5NlNIQTM4NDIwMjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQAD
# ggIBAGSBrSnUReHUzGTy9VC6hy2oDSpu2QNu5j3o/uoaaAy2CgI0hVJRL/OfYinL
# R4hJofuNNKORp2MWXpy52L5PCGtD6/Hf92bMkDl1AP6nXuplt5HvkFPh5kVDbQ7o
# HfI1Pup2IOpKxb00UNwjtKy+38ZCX0dgkASP2vQFamBCG0eTaGUh/9ZH9rz11Nkr
# 9p83Snz/3eW3vOeKAFL3S5RDEMkTvv09540mnzA4J5lKGES2eje/FhwCCQUQBvqC
# voNFNZHyXvW9v8KqX/3CcN1LAtGCy4XnkFjQRPyn+o/OJv5M5yX2Rm5kq9dYpWnD
# U2xgxMR1BZaDf+uDoqGsLo4OqbPV4Dftp2FDs8DHMD8xP6i/k4htaWShkdyjdijr
# 9TBOi+pS9vNlcCKjwLq6aibcbkUk7ef3wxR5imhajsX22vy8Zd9ByAk07BJrccgg
# JGczCtiKcD6LZtP3VjnqhYPSQ4jk6wCruqcTCTwwO7FrIROVrWb2Ro+ph+/a5Llj
# 5ryLyp+6NAgtNwyrkp2WxZviLbh5AXnmg9Pnwrz64UE93LEjI23AWBJsLFdJTbis
# Z/tTgozdVdPZf2Dy2k8xfYZoIq6V1oWiAoQCzb5B9nETV5NGjiMPskJ4GwnlzOvz
# +4IgLQjl0V5I08Qw+3uvPQ8rHHMLbKgncTqSxqtZ73kItOztMYIClDCCApACAQEw
# fTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hB
# Mzg0IDIwMjEgQ0ExAhAGRzH371ShX6hjGl1wSSyYMA0GCWCGSAFlAwQCAQUAoGow
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMum05/QcXy3rONkCSZ+TNelpM0Lys+h
# QGMaNf80M+ldMA0GCSqGSIb3DQEBAQUABIIBgAapzdK9pGWmZ7B6ch9K5O16VfN7
# fcq5oMmy7iUW8+DPbzKMk5MD1ZscJnBp8ce3tltU3OA/ZSACYWRIBU2HZUco1C0W
# KKYZHqLIJuk7+5giHD/4j5e8HusFu5BDida218jgER2EWjHWi7JDph3ETIZw82GN
# mPSiRikqdFRvFYEHZR6fqCbkfPwvJ3mgv5mUoQEiq/Y9lbaVDu8YwOrfFfWovTYW
# 2QQJMPc+QhKnbZ6tPTjtybHoismgV/zrahTLpWy0MdJlKi8YjA3XBMM4XOAnBUQZ
# wK3aMYlDnvESE5wGIFEZXc7EjDJj+/gz6uWPGrC4VdGrhKY4pxJEbV3Pbl6LHEHS
# P2i7JZBJUDK3UE2uYFalhpmtXBe8u+jaESTTO60Eu6b2dTv1hC3mtGxQRAk8KTdb
# eQIyltI/Y1DhDAxBcX0VeJ1xCBBESZ8kJffOZr+j/k5r/HeqdfxQrzusoz/XLVpY
# rrfOB1fIr2N/qCKPv0aK5s+uYP+p9ebDVUtJyQ==
# SIG # End signature block
