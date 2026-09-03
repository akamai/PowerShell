function Get-SIEMData {
    [CmdletBinding(DefaultParameterSetName = 'Offset')]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Mandatory, ParameterSetName = 'Offset')]
        [string]
        $Offset,

        [Parameter(Mandatory, ParameterSetName = 'Time period')]
        [int]
        $From,

        [Parameter(ParameterSetName = 'Time period')]
        [int]
        $To,

        [Parameter()]
        [int]
        $Limit,

        [Parameter()]
        [switch]
        $Decode,

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
        $Path = "/siem/v1/configs/$ConfigID"
        $QueryParameters = @{
            'offset' = $PSBoundParameters.offset
            'limit'  = $PSBoundParameters.limit
            'from'   = $PSBoundParameters.from
            'to'     = $PSBoundParameters.to
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

        $SIEMEvents = New-Object -TypeName System.Collections.ArrayList
        $Output = New-Object -TypeName PSCustomObject

        ### Invoke-RestMethod doesn't handle the json due to it being multiple objects, so we split on line breaks, then convert to objects in an array
        if ($Response.Body -is "String") {
            ## Parse out empty last line
            if ($Response.Body.EndsWith("`n")) {
                $Response.Body = $Response.Body.SubString(0, ($Response.Body.Length - 1))
            }
            $ResponseArray = $Response.Body -split "`n"
            $ResponseContext = $ResponseArray[-1] | ConvertFrom-Json -Depth 100

            if ($ResponseArray.count -gt 1) {
                $UnprocessedEvents = $ResponseArray[0..($ResponseArray.Count - 2)]
                foreach ($JSONEvent in $UnprocessedEvents) {
                    $SIEMEvent = $JSONEvent | ConvertFrom-Json -Depth 100
                    if ($Decode) {
                        ## Call parsing function to url and base64-decode event members
                        $ParsedEvent = Format-SIEMEvent -SIEMEvent $SIEMEvent
                        $SIEMEvents.Add($ParsedEvent) | Out-Null
                    }
                    else {
                        $SIEMEvents.Add($SIEMEvent) | Out-Null
                    }
                }
            }
            else {
                $SIEMEvents = $null
            }

            $Output | Add-Member -MemberType NoteProperty -Name "Events" -Value $SIEMEvents
            $Output | Add-Member -MemberType NoteProperty -Name "ResponseContext" -Value $ResponseContext
        }
        else {
            $Output | Add-Member -MemberType NoteProperty -Name "Events" -Value $null
            $Output | Add-Member -MemberType NoteProperty -Name "ResponseContext" -Value $Response.Body
        }

        return $Output
    }
}