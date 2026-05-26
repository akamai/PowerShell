function Expand-AppSecConfigDetails {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $ConfigName,

        [Parameter()]
        $ConfigID,

        [Parameter()]
        [Alias('CreateFromVersion')]
        [string]
        $VersionNumber,

        [Parameter()]
        [string]
        $PolicyName,

        [Parameter()]
        [string]
        $PolicyID,

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

    process {
        $CommonParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        if ($ConfigName -ne '') {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $ConfigID = $Global:AkamaiDataCache.AppSec.Configs.$ConfigName.ConfigID
            }
    
            if (-not $ConfigID) {
                Write-Debug "Expand-AppSecConfigDetails: '$ConfigName' - Retrieving Config details."
                $Config = Get-AppSecConfiguration @CommonParams | Where-Object { $_.name -eq $ConfigName }
                if ($Config) {
                    $ConfigID = $Config.id
                }
                else {
                    throw "Security config '$ConfigName' not found"
                }
            }
            
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache -and -not $Global:AkamaiDataCache.AppSec.Configs.$ConfigName) {
                $Global:AkamaiDataCache.AppSec.Configs.$ConfigName = @{
                    'ConfigID' = $ConfigID
                    'Policies' = @{}
                }
            }
            Write-Debug "Expand-AppSecConfigDetails: ConfigID = $ConfigID"
        }
        if ($VersionNumber -and $VersionNumber -notmatch '^[0-9]+$') {
            if (-not $Config) {
                Write-Debug "Expand-AppSecConfigDetails: '$ConfigID' - Retrieving Config."
                $Config = Get-AppSecConfiguration -ConfigID $ConfigID @CommonParams
            }
    
            if ($VersionNumber -eq 'latest') {
                $VersionNumber = $Config.latestVersion
            }
            if ($VersionNumber -eq 'production') {
                if ($null -eq $Config.productionVersion) {
                    throw "No production-active version of config '$($Config.name)'."
                }
                else {
                    $VersionNumber = $Config.productionVersion
                }
            }
            if ($VersionNumber -eq 'staging') {
                if ($null -eq $Config.stagingVersion) {
                    throw "No staging-active version of config '$($Config.name)'."
                }
                else {
                    $VersionNumber = $Config.stagingVersion
                }
            }
            Write-Debug "Expand-AppSecConfigDetails: VersionNumber = $VersionNumber."
        }
        if ($PolicyName -ne '') {
            # Check cache if enabled
            if ($Global:AkamaiOptions.EnableDataCache) {
                $PolicyID = $Global:AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName.PolicyID
            }
    
            if (-not $PolicyID) {
                Write-Debug "Expand-AppSecConfigDetails: '$PolicyName' - Retrieving policy details."
                $Policy = Get-AppSecPolicy -ConfigID $ConfigID -VersionNumber $VersionNumber @CommonParams | Where-Object { $_.policyName -eq $PolicyName }
                if ($Policy) {
                    $PolicyID = $Policy.policyId
                }
                else {
                    throw "Security policy '$PolicyName' not found."
                }
            }
            
            # Add to data cache
            if ($Global:AkamaiOptions.EnableDataCache) {
                # Check for cache entry. It may not exist
                if ($Global:AkamaiDataCache.AppSec.Configs.$ConfigName) {
                    $Global:AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName = @{
                        'PolicyID' = $PolicyID
                    }
                }
                else {
                    Write-Debug "Expand-AppSecConfigDetails: Cannot create data cache entry without ConfigName."
                }
            } 
            Write-Debug "Expand-AppSecConfigDetails: PolicyID = $PolicyID."
        }
    
        return $ConfigID, $VersionNumber, $PolicyID
    }
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


function Get-AppsecPolicyContentProtectorJavascriptInjectionRule {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ContentProtectionJavaScriptInjectionRuleID')]
        [string]
        $JavaScriptInjectionRuleID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        if ($JavaScriptInjectionRuleID) {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-javascript-injection-rules/$JavaScriptInjectionRuleID"
        }
        else {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-javascript-injection-rules"
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($JavaScriptInjectionRuleID) {
                return $Response.Body
            }
            else {
                return $Response.Body.contentProtectionJavaScriptInjectionRules
            }
        }
        catch {
            throw $_
        }
    }

}


function Get-AppsecPolicyContentProtectorRule {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ContentProtectionRuleID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        if ($ContentProtectionRuleID) {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-rules/$ContentProtectionRuleID"
        }
        else {
            $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-rules"
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($ContentProtectionRuleID) {
                return $Response.Body
            }
            else {
                return $Response.Body.contentProtectionRules
            }
        }
        catch {
            throw $_
        }
    }

}


function Get-AppsecPolicyContentProtectorRuleSequence {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-rule-sequence"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function New-AppsecPolicyContentProtectorJavascriptInjectionRule {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-javascript-injection-rules"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function New-AppsecPolicyContentProtectorRule {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-rules"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Remove-AppsecPolicyContentProtectorJavascriptInjectionRule {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('ContentProtectionJavaScriptInjectionRuleID')]
        [string]
        $JavaScriptInjectionRuleID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-javascript-injection-rules/$JavaScriptInjectionRuleID"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'DELETE'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Remove-AppsecPolicyContentProtectorRule {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ContentProtectionRuleID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-rules/$ContentProtectionRuleID"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'DELETE'
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Set-AppsecPolicyContentProtectorJavascriptInjectionRule {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('ContentProtectionJavaScriptInjectionRuleID')]
        [string]
        $JavaScriptInjectionRuleID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-javascript-injection-rules/$JavaScriptInjectionRuleID"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'PUT'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Set-AppsecPolicyContentProtectorRule {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContentProtectionRuleID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-rules/$ContentProtectionRuleID"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'PUT'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


function Set-AppsecPolicyContentProtectorRuleSequence {
    [CmdletBinding(DefaultParameterSetName = 'Config name & policy name')]
    Param(
        [Parameter(ParameterSetName = 'Config name & policy name', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Config name & policy ID', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID & policy name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $ConfigID,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name & policy name', Position = 2, Mandatory)]
        [Parameter(ParameterSetName = 'Config ID & policy name', Position = 2, Mandatory)]
        [string]
        $PolicyName,

        [Parameter(ParameterSetName = 'Config name & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID & policy ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PolicyID,

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
        [string] $ConfigID, $VersionNumber, $PolicyID = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/versions/$VersionNumber/security-policies/$PolicyID/content-protection-rule-sequence"

        $RequestParameters = @{
            Path             = $Path
            Method           = 'PUT'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}


# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAp5bT36FJ3jeA9
# 2ckEAhq/3GE3JOHqyoFwqVKGO7DH6qCCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBHrDiTbiAL7SLTnD68gd+u4cWEn5xwb
# 1rD+jILNkhXPMA0GCSqGSIb3DQEBAQUABIIBgEHY9s4k675x/wuQB2ahELVhT6aJ
# HnRTFf/HFsV2pjtPUfoAQ/6WAF28xzZg5S7gjAOGGd4cxynkzbWIZhS2qGugSNfy
# tVo1dNL44UksfAXU3it9t16yDwstZQJvUqb9X4IUJUWX22xvFJ8NE3ff2O0AOaCi
# Bu63ybtKWfzxtnPyCvbADy2WGP97cnr4Vz9JBzTgtUpir8iCKoGXlr/moagbmvT/
# 6DYUZoKHfmfM8MXCRhgJegMHPisqSng0Ioe7m15eCLBXijtoEUImiwoXG7SmIrbz
# SfgWZjqV/UlnaOOCaRPCmef0wbKv6GJSodM9UAiUXhd+K6mXkvM7rMBPWO6GS3t7
# m32GRrjLD7zS/6ZCpGWKnDEM+DVAr5Xjvhj36Yk3slWvlLyts2a1Lk5L882DA4Fp
# xOiS8h3Uv+ef2IIUQmVmUWwiZelZoxGcBLj7dd30j5I+uJYB6htxDHQNu6QBNlQN
# P0GZV8hkFrtqUJpQ0QM0tL3p2QPJMXgTyJmZhA==
# SIG # End signature block
