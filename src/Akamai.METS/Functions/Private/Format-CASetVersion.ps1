function Format-CASetVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        $Version
    )

    $TopLevelAllowedProperties = @(
        'allowInsecureSha1',
        'certificates',
        'description'
    )
    $CertificateAllowedProperties = @(
        'certificatePem',
        'description'
    )
    $FormattedVersion = Get-BodyObject -Source $Version
    # Remove null FormattedVersion members
    foreach ($Property in $FormattedVersion.PSObject.Properties.Name) {
        if ($null -eq $FormattedVersion.$Property) {
            $FormattedVersion.PSObject.Properties.Remove($Property)
        }
        if ($Property -notin $TopLevelAllowedProperties) {
            $FormattedVersion.PSObject.Properties.Remove($Property)
        }
    }
    foreach ($Certificate in $FormattedVersion.certificates) {
        foreach ($Property in $Certificate.PSObject.Properties.Name) {
            if ($null -eq $Certificate.$Property) {
                $Certificate.PSObject.Properties.Remove($Property)
            }
            if ($Property -notin $CertificateAllowedProperties) {
                $Certificate.PSObject.Properties.Remove($Property)
            }
        }
    }

    # Convert comments to description to support v1-format bodies
    if ($FormattedVersion.comments) {
        $FormattedVersion | Add-Member -NotePropertyName description -NotePropertyValue $FormattedVersion.comments.PSObject.Copy()
        $FormattedVersion.PSObject.Properties.Remove('comments')
    }

    return $FormattedVersion
}