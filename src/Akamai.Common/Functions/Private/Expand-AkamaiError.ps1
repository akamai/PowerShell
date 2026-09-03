function Expand-AkamaiError {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord,
        
        [Parameter()]
        [PSCustomObject]
        $Options
    )

    # Extract response content type
    Write-Debug "Extracting content type"
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        if ('Content-Type' -in $ErrorRecord.Exception.Response.Headers.Keys) {
            $ResponseContentType = $ErrorRecord.Exception.Response.Headers.GetValues('Content-Type') -join ','
        }
    }
    else {
        if ($null -ne $ErrorRecord.Exception.Response.Content.Headers -and $ErrorRecord.Exception.Response.Content.Headers.Contains('Content-Type')) {
            $ResponseContentType = $ErrorRecord.Exception.Response.Content.Headers.GetValues('Content-Type') -join ','
        }
    }
    Write-Debug "ResponseContentType = $ResponseContentType"
    
    # If json, convert to object to extract useful info
    $ErrorData = $null
    if ($ResponseContentType -and $ResponseContentType.Contains('json')) {
        if ($ErrorRecord.ErrorDetails.Message) {
            try {
                Write-Debug "Extracting error data."
                $ErrorData = ConvertFrom-Json -InputObject $ErrorRecord.ErrorDetails.Message
            }
            catch {
                Write-Debug "Failed to convert error response body from JSON."
                Write-Debug $_
            }
    
            if ($ErrorData) {
                try {
                    # Remove closing full stops for printing
                    'title', 'errors', 'detail' | ForEach-Object {
                        if ($ErrorData.$_ -and $ErrorData.$_ -is 'String' -and $ErrorData.$_.EndsWith('.')) {
                            $ErrorData.$_ = $ErrorData.$_.SubString(0, $ErrorData.$_.Length - 1)
                        }
                    }
                }
                catch {
                    Write-Debug "Failed to clean up error data"
                    Write-Debug $_
                }
            }
        }
        else {
            Write-Debug "Thrown error has no Message element."
        }
    }

    # Add status if missing
    if ($null -ne $ErrorData -and $null -eq $ErrorData.status -and $null -ne $ErrorRecord.Exception.Response.StatusCode) {
        $ErrorData | Add-Member -NotePropertyName status -NotePropertyValue ([int] $ErrorRecord.Exception.Response.StatusCode)
    }
    Write-Debug "Status = $($ErrorData.Status)"

    # Override error details
    $ErrorMessage = $ErrorRecord.ErrorDetails.Message
    if ($null -ne $ErrorData.status -and $null -ne $ErrorData.detail) {
        Write-Debug "Setting errormessage from title and detail."
        $ErrorMessage = "HTTP $($ErrorData.status) - $($ErrorData.title) - $($ErrorData.detail). See `$Error[0].exception.data for more information."
    }
    elseif ($null -ne $ErrorData.status -and $ErrorData.errors -is 'String') {
        Write-Debug "Setting errormessage from title ($($ErrorData.title)) and errors ($($ErrorData.errors))."
        $ErrorMessage = "HTTP $($ErrorData.status) - $($ErrorData.title) - $($ErrorData.errors). See `$Error[0].exception.data for more information."
    }
    elseif ($null -ne $ErrorData.status -and $ErrorData.errors -isnot 'String') {
        Write-Debug "Setting errormessage from title only."
        $ErrorMessage = "HTTP $($ErrorData.status) - $($ErrorData.title). See `$Error[0].exception.data for more information."
    }
    elseif ($null -ne $ErrorData.code -and $null -ne $ErrorData.title) {
        Write-Debug "Setting errormessage from title only."
        $ErrorMessage = "$($ErrorData.code) - $($ErrorData.title). See `$Error[0].exception.data for more information."
    }
    elseif ($ErrorRecord.Exception -is [InvalidOperationException]) {
        Write-Debug "Invalid operation. Using original message."
    }
    # Use default error message if API data is not available
    else {
        Write-Debug "Defaulting to original error message."
        $ErrorMessage = $ErrorRecord.Exception.Message
    }

    # Create new error
    $ExpandedError = [System.Management.Automation.ErrorRecord]::new(
        [System.InvalidOperationException]::new($ErrorMessage, $ErrorRecord.Exception),
        $ErrorRecord.FullyQualifiedErrorId,
        $ErrorRecord.CategoryInfo.Category,
        $ErrorRecord.TargetObject)
    # Copy items which aren't replicated
    'Response', 'HttpRequestError', 'StatusCode' | ForEach-Object {
        $ExpandedError.Exception | Add-Member -MemberType NoteProperty -Name $_ -Value $ErrorRecord.Exception.$_
    }
        
    # Evaluate known errors and add recommended actions if found
    if ($null -ne $ErrorMessage) {
        $ExpandedError.ErrorDetails = $ErrorMessage
        # Set recommendedAction, if found
        $KnownError = $Script:KnownErrors | Where-Object { $ErrorData.Detail -like "*$($_.Error)*" }
        if ($KnownError) {
            if ($Options.EnableRecommendedActions -and $KnownError.recommendedAction) {
                $ExpandedError.ErrorDetails.RecommendedAction = $KnownError.recommendedAction
            }
        }
    }
    
    # Rerun loop to copy data to target exception
    if ($null -ne $ErrorData) {
        $ErrorData.PSObject.Properties.Name | foreach-object {
            $ExpandedError.Exception.Data.Add($_, $ErrorData.$_)
        }
    }

    return $ExpandedError
}
