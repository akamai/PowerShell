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

function Get-IVMErrorDetails {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicySetID,
        
        [Parameter()]
        [string]
        $PolicyID,

        [Parameter()] 
        [int] 
        $Limit,

        [Parameter()] 
        [string] 
        $Url,

        [Parameter()] 
        [int] 
        $Size,

        [Parameter()]
        [ValidateSet('REALTIME', 'OFFLINE')] 
        [string]
        $TransformationType,

        [Parameter()]
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network = 'Production',
        
        [Parameter()]
        [string]
        $ContractID,

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
        $Network = $Network.ToLower()
        if ($TransformationType -ne '') {
            $TransformationType = $TransformationType.ToUpper()
        }
    
        $Path = "/imaging/v2/network/$Network/details/errors"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
    
        $QueryParameters = @{
            'limit'              = $PSBoundParameters.Limit
            'url'                = $PSBoundParameters.Url
            'size'               = $PSBoundParameters.Size
            'transformationtype' = $PSBoundParameters.TransformationType
            'policyid'           = $PSBoundParameters.policyId
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.items
    }
}

function Get-IVMImage {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [string]
        $PolicySetID,

        [Parameter()]
        [ValidateSet('Staging', 'Production')]
        [string]
        $Network = 'Production',

        [Parameter(ParameterSetName = 'Get one')]
        [string]
        $ImageID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $PolicyID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Limit,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $URL,

        [Parameter()]
        [string]
        $ContractID,

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
        $Network = $Network.ToLower()
        if ($ImageID) {
            $Path = "/imaging/v2/network/$Network/images$ImageId"
        }
        else {
            $Path = "/imaging/v2/network/$Network/images"
        }
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }

        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }

        $QueryParameters = @{
            'limit'    = $PSBoundParameters.Limit
            'url'      = $URL
            'policyId' = $PolicyID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($ImageID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}

function Get-IVMLogDetails {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [string] 
        $PolicySetID,
        
        [Parameter()]
        [string]
        $PolicyID,

        [Parameter()] 
        [int] 
        $Limit,

        [Parameter()] 
        [string] 
        $Url,

        [Parameter()] 
        [int] 
        $Size,

        [Parameter()]
        [ValidateSet('REALTIME', 'OFFLINE')]
        [string]  
        $TransformationType,

        [Parameter()]
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network = 'Production',
        
        [Parameter()]
        [string]
        $ContractID,

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
        $Network = $Network.ToLower()
        if ($TransformationType -ne '') {
            $TransformationType = $TransformationType.ToUpper()
        }
        $Path = "/imaging/v2/network/$Network/details/logs"
    
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
    
        $QueryParameters = @{
            'limit'              = $PSBoundParameters.Limit
            'url'                = $PSBoundParameters.Url
            'size'               = $PSBoundParameters.Size
            'transformationtype' = $PSBoundParameters.TransformationType
            'policyid'           = $PSBoundParameters.policyId
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.items
    }
}

function Get-IVMPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [string] 
        $PolicySetID,
        
        [Parameter()]
        [string]
        $PolicyID,
 
        [Parameter()]
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network = 'Production',
    
        [Parameter()]
        [string]
        $ContractID,

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
        $Network = $Network.ToLower()
        if ($PolicyID) {
            $Path = "/imaging/v2/network/$Network/policies/$PolicyID"
        }
        else {
            $Path = "/imaging/v2/network/$Network/policies"
        }
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
    
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($PolicyID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}

function Get-IVMPolicyHistory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [string] 
        $PolicySetID,
        
        [Parameter(Mandatory)]
        [string]
        $PolicyID,

        [Parameter()]
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network = 'Production',
        
        [Parameter()]
        [string]
        $ContractID,

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
        $Network = $Network.ToLower()
        $Path = "/imaging/v2/network/$Network/policies/history/$PolicyID"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
    
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.items
    }
}


function Get-IVMPolicySet {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [string]
        $PolicySetID,

        [Parameter()]
        [string]
        $ContractID,
        
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
        if ($PolicySetID) {
            $Path = "/imaging/v2/policysets/$PolicySetID"
        }
        else {
            $Path = "/imaging/v2/policysets"
        }
    
        if ($ContractID -ne '') {
            $AdditionalHeaders = @{'Contract' = $ContractID }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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

function New-IVMPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]  
        [string] 
        $PolicySetID,
        
        [Parameter(Mandatory)]
        [string]
        $PolicyID,

        [Parameter(Mandatory)]  
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network,
        
        [Parameter()]
        [string]
        $ContractID,

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

    Begin {
        try {
            $ExistingPolicy = Get-IVMPolicy -PolicySetID $PolicySetID -PolicyID $PolicyID -Network $Network -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        }
        catch {}
        
        if ($ExistingPolicy) {
            throw "Policy $PolicyID already exists in Policy Set $PolicySetID"
        }
    }

    Process {
        $Network = $Network.ToLower()
        $Path = "/imaging/v2/network/$Network/policies/$PolicyID"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }

        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
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
        return $Response.Body
    }

    End {}
}

function New-IVMPolicySet {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('US', 'EMEA', 'ASIA', 'AUSTRALIA', 'JAPAN', 'CHINA')]
        [string]
        $Region,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('IMAGE', 'VIDEO')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes')]
        [Object]
        $DefaultPolicy,

        [Parameter(Mandatory, ParameterSetName = 'Body', ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $ContractID,

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
        $AdditionalHeaders = @{}
        $Path = "/imaging/v2/policysets"

        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'name'   = $Name
                'region' = $Region
                'type'   = $Type
            }
            if ($DefaultPolicy) {
                $Body.defaultPolicy = $DefaultPolicy
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Remove-IVMPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]  
        [string] 
        $PolicySetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicyID,

        [Parameter(Mandatory)]  
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network,

        [Parameter()] 
        [string] 
        $ContractID,

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
        $Network = $Network.ToLower()
        $Path = "/imaging/v2/network/$Network/policies/$PolicyID"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
    
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'DELETE'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Remove-IVMPolicySet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicySetID,

        [Parameter()] 
        [string] 
        $ContractID,

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
        $Path = "/imaging/v2/policysets/$PolicySetID"
        $AdditionalHeaders = @{}
    
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'DELETE'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Restore-IVMPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string] 
        $PolicySetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicyID,

        [Parameter(Mandatory)]  
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network,

        [Parameter()] 
        [string] 
        $ContractID,

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
        $Network = $Network.ToLower()
        $Path = "/imaging/v2/network/$Network/policies/rollback/$PolicyID"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
    
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
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

function Set-IVMPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]  
        [string] 
        $PolicySetID,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]  
        [string] 
        $PolicyID,

        [Parameter(Mandatory)]  
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network,
        
        [Parameter()]
        [string]
        $ContractID,

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
        $Network = $Network.ToLower()
        $Path = "/imaging/v2/network/$Network/policies/$PolicyID"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }

        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
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
        return $Response.Body
    }
}

function Set-IVMPolicySet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicySetID,
        
        [Parameter()] 
        [string] 
        $Name,

        [Parameter()] 
        [ValidateSet('US', 'EMEA', 'ASIA', 'AUSTRALIA', 'JAPAN', 'CHINA')] 
        [string] 
        $Region,

        [Parameter()] 
        [string] 
        $ContractID,

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
        $Path = "/imaging/v2/policysets/$PolicySetID"
        if ($ContractID -ne '') {
            $AdditionalHeaders = @{ 'Contract' = $ContractID }
        }
    
        $Body = @{}
        if ($Name) { $Body.name = $Name }
        if ($Region) { $Body.region = $Region }
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
        return $Response.Body
    }
}


# SIG # Begin signature block
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDDfaQQuL16utyo
# HD2XclaX4l23KG/OWR3SBEuRJD9c/6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
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
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBUyNFIPDgOxvypYRZqPFELgNCLAyK+R
# RngCxQumLidfMA0GCSqGSIb3DQEBAQUABIIBgEXBwSCj2sO4rfmrAUph82UoEcer
# NnCSktQIbuycp84tXIgDPmj7ymSC+G/4zGrqihYckgVL0CbDEJ4bePUHp+033yNx
# JbaOqJjC42gJ0fcHZlKUmJ+2xmaNfrwKM26bjFW38MhdnnDDaU5gdEyudqRJ90D7
# BRw9bge9G2QvJ0w7CWqpnk8JuSuLC0DjMdhQoT9eBAraQXKQ1G5m/Uf3EJ0TgtFL
# 2MEq72U6LHiLLZ8nQkrCfPWxYYCnpDDXG3CaWzHq38t6tP2EllNHjvOSllYUUooE
# x1qt7WUtD+/1PeFVD41I2niDFm898BpVYuXybapCCpO0YVLOQTqYC8luLllOYeQz
# xSacSc8Nv4ixlpSr5b1uZnSj4Etpn526p4EvGostGfoD3Iyenv68TgPdRMxfFf72
# wAiTzwKo+OlcbGpcZdB7+QCZh2oPOs5eiZzKAzQggbh1+vK9ifHMNPC100G+MsZO
# st3++mwnwentM8eTji+j8zv2xyDEasw4Wx4YTQ==
# SIG # End signature block
