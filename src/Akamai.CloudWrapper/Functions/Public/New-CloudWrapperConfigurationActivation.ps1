
function New-CloudWrapperConfigurationActivation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64[]]
        $ConfigurationIDs,

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
        $CollatedIDs = New-Object -TypeName System.Collections.Generic.List['int64']
    }

    process {
        foreach ($ConfigurationID in $ConfigurationIDs) {
            $CollatedIDs.Add($ConfigurationID)
        }
    }
    
    end {
        $Path = "/cloud-wrapper/v1/configurations/activate"
        $Body = @{
            'configurationIds' = $CollatedIDs
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
