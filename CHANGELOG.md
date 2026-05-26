## 3.0.0 (May 26, 2026)

### Breaking changes

Upgraded all METS endpoints to METS v2 API.
Most function names and parameters stayed the same with a few additions.

### Bug Fixes

This release fixes the following issues.

#### All

Submodules were sharing GUIDs. All submodules now use unique ones.

#### Contracts

`Get-ContractReportingGroup`. The Akamai property referenced was missing a `/`, so it always threw an error. It's been added and works.

#### Common

* `New-EdgeAuthToken`. Removed `start` from the produced token when `-Start` wasn't used.
* `Invoke-AkamaiRequest`. Error handling no longer tries to expand non-HTTP errors and threw an entirely different error.
* Functions no longer attempt to write failed requests to the data cache.
* Added handling to properly format the CPS API's `429` response. Resolves [Issue 27](https://github.com/akamai/powershell/issues/27).

#### Edge Diagnostics

`New-EdgeDiagnosticsESIDebug`. The format of `ClientRequestHeaders` has been corrected.

#### METS

The format of `dateTime` fields is no longer lost when converting to or from JSON.

#### MOKS

`Complete-MOKSClientCertVersion`. Line breaks in certificate files no longer cause a malformed request body.

### New

#### All

* Combined all `.ps1` files into a module `.psm1` file, allowing for faster module loading (approx. 5-6x).
  > **Important:** We kept our repo's `src` directory file structure as is. Individual function files don't contain signatures anymore. Only files in the `dist` directory have signatures.
* Functions in the `functions/private` directories of each submodule are not exported in the module manifest. This reduces clutter when listing module functions but also prevents their use unless you dot-source the module `.psm1` file manually.

#### API support

[Domain Ownership Manager](https://techdocs.akamai.com/domain-validation/docs/welcome).

#### New functions

##### API Definitions

* `Find-APIOperation`. Searches for operations by query type.
* `Get-APIEndpoint`. Gets one or all of your endpoints.
* `Get-APIEndpointMultistepGroup`. Gets one or all of your endpoints.
* `Get-APIEndpointVersionPIISettings`. Lists PII settings for an endpoint version.
* `New-APIEndpointMultistepGroup`. Creates a multistep group.
* `Remove-APIEndpointMultistepGroup`. Deletes a multistep group.
* `Rename-APIEndpointMultistepGroup`. Renames a multistep group.
* `Set-APIEndpointVersionPIISettings`. Updates an endpoint's PII settings.

##### AppSec

* `Compare-AppSecConfigurationVersions`. Compares two versions of a configuration.
* `Disable-AppSecPolicyRapidRules`. Disables your rapid rules.
* `Enable-AppSecPolicyRapidRules`. Enables your rapid rules.
* `Get-AppSecAttackPayload`. Gets the attack payload log settings for a configuration.
* `Get-AppSecBehavioralDDOS`. Gets a Behavioral DDoS profile.
* `Get-AppSecCookieSettings`. Gets cookie settings.
* `Get-AppSecCustomRuleUsage`. Lists custom rules use by security policies.
* `Get-AppSecCVE`. Gets details for a specific CVE.
* `Get-AppSecCVECoverage`. Gets the CVE coverage provided by your configurations, attack groups, and rules.
* `Get-AppSecCVESubscription`. Lists the CVEs you subscribe to.
* `Get-AppSecExport`. Gets a security configuration version's export data from a previously completed asynchronous task.
* `Get-AppSecExportStatus`. Gets a security configuration version's export status.
* `Get-AppSecJA4Fingerprint`. Gets JA4 client TLS fingerprint settings for a configuration.
* `Get-AppSecOnboarding`. Lists all current onboardings or get details on a specific task by its `OnboardingID`.
* `Get-AppSecOnboardingActivation`. Gets the status of an onboarding activation.
* `Get-AppSecOnboardingCertificateValidation`. Gets the information for certificate validation.
* `Get-AppSecOnboardingCNAMERecord`. Lists hostname CNAME DNS records.
* `Get-AppSecOnboardingOriginValidation`. Lists origin hostname DNS records.
* `Get-AppSecOnboardingSettings`. Gets the settings for a specific onboarding.
* `Get-AppSecPolicyBehavioralDDOS`. Lists all Behavioral DDoS profiles currently in use.
* `Get-AppSecPolicyCPC`. Gets Client-Side Protection & Compliance settings.
* `Get-AppSecPolicyCustomRule`. Lists custom rule actions.
* `Get-AppSecPolicyEvaluationPenaltyBoxCondition`. Gets penalty box conditions in evaluation mode.
* `Get-AppSecPolicyPenaltyBoxCondition`. Gets penalty box conditions.
* `Get-AppSecPolicyRapidRule`. Gets a rapid rule's action.
* `Get-AppSecPolicyRapidRuleCondition`. Lists a rapid rule's conditions and exceptions.
* `Get-AppSecPolicyRapidRuleDefaultAction`. Gets rapid rules' default action.
* `Get-AppSecPolicyRapidRuleLock`. Gets a rapid rule's lock status.
* `Get-AppSecPolicyRapidRulesStatus`. Gets rapid rules' status.
* `Lock-AppSecPolicyRapidRule`. Updates a rapid rule's lock status.
* `New-AppSecBehavioralDDOS`. Creates a behavioral DDoS profile.
* `New-AppSecCVESubscription`. Subscribes to notifications for specific CVEs.
* `New-AppSecOnboarding`. Creates an onboarding.
* `New-AppSecOnboardingActivation`. Activates an onboarding.
* `Remove-AppSecBehavioralDDOS`. Removes a behavioral DDoS profile.
* `Remove-AppSecCVESubscription`. Unsubscribes from recommendation emails.
* `Remove-AppSecOnboarding`. Deletes an onboarding.
* `Set-AppSecAttackPayload`. Modifies attack payload log settings for a configuration.
* `Set-AppSecBehavioralDDOS`. Modifies a Behavioral DDoS profile.
* `Set-AppSecCookieSettings`. Modifies cookie settings.
* `Set-AppSecEvaluationRatePolicy`. Modifies a rate policy evaluation.
* `Set-AppSecJA4Fingerprint`. Modifies JA4 client TLS fingerprint settings.
* `Set-AppSecOnboardingSettings`. Modifies onboarding settings.
* `Set-AppSecPolicyBehavioralDDOS`. Modifies a Behavioral DDoS profile action.
* `Set-AppSecPolicyCPC`. Modifies Client-Side Protections & Compliance settings.
* `Set-AppSecPolicyEvaluationPenaltyBoxCondition`. Modifies the penalty box conditions in evaluation mode.
* `Set-AppSecPolicyPenaltyBoxCondition`. Modifies the penalty box conditions.
* `Set-AppSecPolicyRapidRule`. Updates a rapid rule's action.
* `Set-AppSecPolicyRapidRuleCondition`. Updates a rapid rule's conditions and exceptions.
* `Set-AppSecPolicyRapidRuleDefaultAction`. Updates rapid rules' default action.
* `Skip-AppSecOnboardingOriginValidation`. Skips origin hostnames DNS record validation.
* `Submit-AppSecOnboardingCertificateValidation`. Validates onboarding certificate.
* `Submit-AppSecOnboardingCNAMERecord`. Validates hostname CNAME DNS records.
* `Submit-AppSecOnboardingOriginValidation`. Validates origin hostnames DNS records.
* `Unlock-AppSecPolicyRapidRule`. Updates a rapid rule's lock status.

##### Client Lists

* `Import-ClientListItem`. Imports entries from a CSV file.
* `New-ClientListSubscription`. Subscribes to client lists.
* `Remove-ClientListItem`. Updates client list entries.
* `Remove-ClientListSubscription`. Unsubscribes to client lists.
* `Test-ClientListItem`. Validates entries from a CSV file.

##### Cloud Access Manager

* `Remove-CloudAccessKey`. Deletes an access key version. |
* `Rename-CloudAccessKey`. Renames an access key.

##### Cloudlets

`Remove-CloudletLoadBalancer`. Deletes a load balancing configuration.

##### Common

* `Clear-EdgegridCredentials`. Clears EdgeGrid credentials environment variables.
* `Clear-NetstorageCredentials`. Clears Netstorage credentials environment variables.
* `Export-EdgegridCredentials`. Exports EdgeGrid credentials to a file.
* `Export-NetstorageCredentials`. Exports Netstorage credentials to a file.
* `Get-EdgegridCredentials`. Gets EdgeGrid credentials.
* `Import-EdgegridCredentials`. Loads EdgeGrid credentials to environment variables.
* `Import-NetstorageCredentials`. Loads Netstorage usage API credentials to environment variables.
* `Invoke-NetstorageRequest`. Makes a request to the Netstorage usage API.
* `New-AkamaiDataCache`. Creates a default data cache object.
* `Test-EdgegridCredentials`. Tests your EdgeGrid credentials.

##### Contracts

* `Get-ContractReportingGroup`. Lists CP code reporting groups.
* `Get-ContractReportingGroupIdentifier`. Lists CP code reporting group IDs.

##### EdgeDNS

* `Get-EDNSZoneDNSKEY`. Gets a zone's DNSSEC DNSKEY records.
* `Remove-EDNSZone`. Submits a bulk zone delete request.

##### EdgeKV

* `Export-EdgeKVData`. Downloads group data.
* `Get-EdgeKVUpload`. Gets namespace upload job details.
* `Import-EdgeKVData`. Uploads namespace data.

##### GTM

* `Get-GTMContract`. Gets one or all contracts.
* `Get-GTMDomainAuthority`. Gets one or all domain authorities.
* `Get-GTMDomainList`. Lists domains.
* `Get-GTMDomainSummary`. Gets domain details.
* `Get-GTMGroup`. Gets one or all groups.
* `Get-GTMIdentity`. Gets identity.

##### MediaServicesLive

* `Get-MSLMigration`. Lists streams being migrated.
* `New-MSLMigration`. Migrates streams to MSL5.
* `Undo-MSLMigration`. Reverts stream migration.

##### METS

* `Copy-METSCASet`. Clones a CA set.
* `Get-METSCASetAssociation`. Gets CA set associations.
* `Remove-METSCASetVersion`. Deletes a version.
* `Test-METSCASetVersion`. Validates certificates.

##### Netstorage

* `Add-NetstorageUploadAccountHTTPKey`. Adds G2O keys to an upload account.
* `Disable-NetstorageUploadAccountHTTPKey`. Disables an upload account's G2O keys.
* `Enable-NetstorageUploadAccountHTTPKey`. Enables an upload account's G2O keys.
* `New-NetstorageCredentials`. Creates a set of Netstorage credentials.
* `Remove-NetstorageUploadAccountHTTPKey`. Deletes an upload account's G2O keys.

##### Network Lists

* `Add-NetworkListItem`. Adds a list item.
* `Remove-NetworkListItem`. Removes a list item.

##### Property

* `Add-PropertyIncludeRule`. Patches an include's rule tree.
* `Get-PropertyDomainOwnershipChallenge`. Generates challenges to verify domain ownership.
* `Get-PropertyIncludeParent`. Lists parent properties.
* `Remove-PropertyIncludeRule`. Patches an include's rule tree.
* `Resume-PropertyDomainValidation`. Resumes domain validation.
* `Test-PropertyIncludeRule`. Tests an include's rule tree|
* `Update-PropertyDomainValidation`. Regenerates domain validation challenges.
* `Update-PropertyIncludeRule`. Replaces a rule or setting in a property.

##### Purge

`Get-PurgeLimit`. Checks rate and object limit statuses.

##### Reporting

* `Get-LegacyReport`. Gets a cacheable report. Uses Reporting v1 API.
* `Get-LegacyReportType`. Gets one or list all report types. Uses Reporting v1 API.
* `Get-LegacyReportTypeVersions`. Gets report versions. Uses Reporting v1 API.
* `Get-ReportingArea`. Lists reporting areas.
* `Get-ReportProductFamily`. Lists product families.
* `New-LegacyReport`. Generates a report. Uses Reporting v1 API.

##### Test Center

* `Get-TestRunResults`. Gets test run's detailed results.
* `Start-PropertyVersionTest`. Starts a test run for a property version.
* `Start-Test`. Starts a test run.
* `Start-TestSuite`. Starts a test run for a test suite.
* `Test-TestFunction`. Checks how functions work.

### Updates

#### All

* Parameters that took a comma-separated string of values are now arrays. Previously, for example, the `-NotifyEmails` parameter in `Deploy-Property` took a value of `'a@b.com, c@d.com'`. Now, as an array, the value is `'a@b.com', 'b@c.com'`.
* Expanded support for pipelining. Most `Get-` and `Remove-` commands now take piped input.
* Adjusted any function that currently supports `latest` for a version to also support `production` and `staging`, or for METS, `deployed`.
* Changed to human-readable parameter set names, for example, `single-name` reads `Get one by name`.
* Unified `pageSize` parameters to use the same parameter name, `-PageSize` and the highest allowed value per API. This returns as many results as possible. Smaller page sizes and paging are still supported if you specify lower `-PageSize` and `-Page` values.

#### CPS

Upgraded API enrollment object version from v11 to v12 and change management object from v5 to v6.

#### EdgeKV

`New-EdgeKVAccessToken`. Added new `RestrictToEdgeWorkerIDs` option.

#### EdgeWorkers

`New-EdgeWorkerVersion`

* Added the ability to auto-increment versions in your `bundle.json` file. You can specify `-Major`, `-Minor`, or `-Patch` to increment the semantic version or use `-Version` to specify the version directly.
* Moved the location of the created `.tgz` bundle to a temporary directory so you no longer need to clean it up. You can specify an alternate location with `-SaveBundleTo`.

#### GTM

Upgraded object version from v1.6 to v1.8.

#### IAM

* `New-IAMAPICredentials`. Included the `accessToken` and `host` of a credential to allow output piping to import and export functions.
  * `Export-EdgeGridCredentials` to save your new credential to an EdgeRC file.
  * `Import-EdgeGridCredentials` to load the credentials into memory for immediate use.
* `Get-AccountSwitchKey`. Removed the requirement for the `-Search` parameter. Resolves [Issue 30](https://github.com/akamai/powershell/issues/30).

#### Netstorage

* Changed customized web request function, `Invoke-NSAPIRequest`, to `Invoke-NetstorageRequest`.
* `Write-NetstorageObject`. Added the `-IndexZip` parameter that instructs Netstorage to index an uploaded `.zip` file for the "Serve from Zip" feature.

#### MOKS

`New-MOKSClientCert`. Added support for specifying key algorithms.

#### Property

* `Get-PropertyRules` and `Get-PropertyIncludeRules`. Adjusted the `-OutputFileName` parameter's functionality to include that of `-OutputToFile`, reducing the number of required options you have to send. `-OutputToFile` is still available.
* Added response enhancement to include `ContractID`, `GroupID` and `IncludeID` as part of broader pipeline improvements for these functions.

  * `Get-PropertyVersion`
  * `Get-PropertyIncludeVersion`
  * `New-PropertyVersion`
  * `New-PropertyIncludeVersion`

* Added response enhancement to `New-Bulk*` commands to facilitate piping results into the corresponding `Get-Bulk*` command.

#### Reporting

Upgraded to v2 of the Reporting API. All v1 functions have the `Legacy` prefix added to the command name. Resolves [Issue 28](https://github.com/akamai/powershell/issues/28).

#### Test Center

`New-TestVariable`.  Included options to specify the properties variables in parameters instead of using `-Body`.

### Removed

#### Common

* Removed due to rename.

  `Get-AkamaiCredentials` is now `Get-EdgegridCredentials`.

* Removed due to expanded capabilities of the new credentials functions.

  * `Get-AkamaiSession`
  * `New-AkamaiSession`
  * `Remove-AkamaiSession`
  * `Set-AkamaiSession`

* Removed due to end-of-life.

  `Uninstall-Akamai`. This function was designed to purge v1 of the AkamaiPowershell module which is no longer supported.

#### DataStream

`Get-DataStream`. Removed `-Version` parameter as it has no effect in v3 of the DataStream API.

#### EdgeKV

`New-EdgeKVAccessToken`. Removed the deprecated `Expiry` param.

#### Network Lists

* `Add-NetworkListElement` renamed to `Add-NetworkListItem`.
* `Remove-NetworkListElement` renamed to `Remove-NetworkListItem`.

#### Reporting

`Get-ReportTypeVersions` renamed to `Get-LegacyReportTypeVersions`.

#### Test Center

`New-TestRun` replaced by more specific functions, `Start-PropertyVersionTest`, `Start-Test`, and `Start-TestSuite`.

## 2.3.1 (Aug 15, 2025)

### Bug Fix

`New-CPSEnrollment` and `Set-CPSEnrollment`. New response body elements added in 2.3.0 were invalid when sent with a `POST` or `PUT`. These are now filtered out.

#### Netstorage

`New-NetstorageAuth` renamed to `New-NetstorageCredentials`.

#### NetworkLists

Add-NetworkListElement
Remove-NetworkListElement

## 2.3.0 (Aug 4, 2025)

### New

#### CPS

`Get-CPSActiveCertificate`. Gets active certificates for a given account or contract.

#### Datastream

* `Get-DatastreamEDNSZones`. Returns Edge DNS zones on your contract.
* `Get-DatastreamGTMProperties`. Returns Global Traffic Management (GTM) domain properties on your contract.

#### EdgeWorkers

* `Get-EdgeWorkerLoggingOverride`. Get status information about a specific logging override.
* `New-EdgeWorkerLoggingOverride`. Override the default JavaScript logging level for an EdgeWorker specified by its `EdgeWorkerName` or `EdgeWorkerID`.

#### Test Center

`Initialize-TestSuite`. Generates the request body for a new test suite. This addition clears up a confusing workflow when using `New-TestSuite -AutoGenerate`.

### Bug Fixes

This update fixes the following issues.

* `Akamai.Common` module. Options are no longer reset when module is imported.
* `Akamai.GTM` module. `MapName` is now mandatory on `Remove-GTMCIDRMap`.
* `Akamai.EdgeDNS` module. Unified casing of EdgeDNS.
* `Akamai.Reporting` module. `Limit` and `Filters` are now applied correctly.
* `New-EdgeKVNamespace`. The `GroupID` parameter is now mandatory.

### Updates

#### Common

* Added support for `$ENV:proxy_use_default_credentials` that was available in v1 but missed in the upgrade to v2.
* Improved handling of unexpected errors whose response body does not contain the HTTP status.

#### Datastream

Migrated to v3 of the API. This adds stream support for CDN, EdgeWorkers, EdgeDNS and GTM. All functions now have a `LogType` parameter that defaults to `cdn` for backwards compatibility.

#### EdgeKV

`New-EdgeKVNamespace`. Added `RestrictDataAccess` parameter so you can control namespace access in Standard TLS.

#### IAM

Added `PropertyID` alias to any command using `AssetID` for backwards compatibility.

#### SIEM

`Get-SIEMData`. The `To` parameter is no longer mandatory to match the API.

#### Test Center

`New-TestSuite`. Added parameters option to better support creation of simple test suites.

## 2.2.1 (Apr 15, 2025)

### Bug Fixes

This update fixes the following issues.

* `Akamai.Common` module. When using `New-NetstorageSymlink` without having run `Invoke-AkamaiRestMethod` in the same session, it couldn't find the system HTTP utility. The `System.Web` assembly is now auto-loaded for PowerShell 5.1 clients. Resolves [Issue 10](https://github.com/akamai/powershell/issues/10).
* `Invoke-AkamaiRequest`. It didn't parse correctly when using PowerShell 5.1 on Windows Server without Internet Explorer installed. Added a `-UseBasicParsing` parameter. Resolves [Issue 14](https://github.com/akamai/powershell/issues/14).
* GTM `Body` parameter. A body is required in several functions but wasn't set to `Mandatory`. Corrected.
* GTM `DatacenterID` parameter. It was a string. Updated to `int`.
* GTM return object. It wasn't scoped properly in several `New` functions. Rescoped to `resource` property.

### Updates

#### GTM

Added Pipeline support for multiple functions.

* `Remove-GTMASMap`
* `Remove-GTMCIDRMap`
* `Remove-GTMDatacenter`
* `Remove-GTMGeoMap`
* `Remove-GTMProperty`
* `Remove-GTMResource`

## 2.2.0 (Apr 8, 2025)

### New

#### Submodules

MTLS Origin Keystore (MOKS)

#### General

* `Invoke-AkamaiRequest`. Replaces `Invoke-AkamaiRestMethod` in all higher function. It's based on `Invoke-WebRequest` rather than `Invoke-RestMethod`, so all functions work the same for PowerShell v5.1 and ≥7.0.
* `Uninstall-Akamai`. Handles migration from Akamaipowershell v1.
* Added options architecture that manage server and rate limiting error impact, provides troubleshooting information, and stores Akamai asset IDs for reuse.

  * Error retries
  * Rate Limit retries and warnings
  * Property API prefixes
  * Suggested actions
  * Data cache

#### EdgeKV

* `Get-EdgeKVNamespaceDelete`. Gets the namespace delete time.
* `Get-EdgeKVNamespaceGroup`. Lists groups within a namespace.
* `Remove-EdgeKVNamespace`. Deletes a namespace.
* `Restore-EdgeKVNamespace`. Cancels a scheduled namespace delete.
* `Update-EdgeKVAccessToken`. Refreshes an access token.

#### NetStorage

`Read-NetstorageDirectory`. Recursively downloads an entire directory from a storage group.

### Bug Fixes

This update fixes the following issues.

* `New-Property`. Always placed a cloned property in the existing property's group. Resolves [Issue 11](https://github.com/akamai/powershell/issues/11).
* `Get-PropertyIncludeRulesDigest`. Didn't require the`-IncludeVersion` parameter, missing mandatory annotation on the parameter.
* `Get-PropertyHostname`. Didn't pass the `-Network` parameter to recursive calls.
* `AllowCancelPendingChanges`. A typo prevented its use.
* `Get-IAMGroup`. Unexpected behavior when using the `-Flatten` option in PowerShell 5.1. Resolves [Akamaipowershell issue 54](https://github.com/akamai/akamaipowershell/issues/54).
* `*-EdgeKVItem`. Overloaded use of the word _group_ in functions that fused item and access control groups. Access control groups now use a string.
* `New-AppSecActivation`. Body data not sent if not a string.

### Updates

#### General

* Overhauled error handling, making displayed errors much more useful.
* Added the module version to`RequiredModules` in all submodules.
* Added splatting to all functions using `Invoke-AkamaiRequest`.
* Expanded debugging so parameters are passed down to `Invoke-AkamaiRequest`.

#### AppSec

* Added error handling to `Expand-AppSecConfigDetails` if the given `ConfigName` is not found. Previously it just warned the user.
* `Get-AppSecMatchTarget`: changed `IncludeChildObjectName` switch parameter to `OmitChildObjectName`. Inclusion of child objects is the default API behavior, so you could only previously remove them by the use of `-IncludeChildObjectName:$false`, which is confusing.
* Improved pipeline handling, particularly with `Remove-*` functions.

#### CPS

Added the `ContractID` parameter to `Get-CPSEnrollment` to allow for both get one and get all functionality.

#### Datastream

Added `-Activate` switch to `New-DataStream` that combines creation and activation of the datastream.

#### Edge DNS

Included support for updating multiple records and to auto-increment zone SOA record if required to `Set-EdnsRecordSet`.

#### Edge Diagnostics

Forced inclusion of `useStaging` in request body to mitigate an API issue.

#### Identity & Access Management

* Added an option that disables the implicit inclusion of account switch keys in `Get-AccountSwitchKey`.
* Changed the `PropertyID` parameter to `AssetID` so that it's inline with API documentation and matches the Property API format.

#### Netstorage

* Improved `Get-NetstorageDirectory` to properly handle `StartPath` and `EndPath` parameters.
* Added error handling in `New-NetstorageAuth` when the provided `UploadAccountID` does not have HTTP API access enabled.
* Added functionality to `Read-NetstorageObject` to create necessary folders in the local path.

#### Property

* Added pipeline support for `Get-Property` to retrieve groups and list their properties.
* Clarified function response in `Get-PropertyIncludeRules`.

#### SLA

Improved pipeline support.

### End-of-Life

The Media Delivery Reports service hit end end-of-life. This service's functions were available in v1 but had yet to be added to v2. Because of its lifecycle state, they will not be added to v2.

### Removed

Redundant `Set-APIEndpointVersionPIIParameters` function from API Definitions submodule.

## 2.1.0 (Aug 16, 2024)

### New

#### Submodules

* API Key Manager
* ChinaCDN
* Client Lists
* Cloud Wrapper
* Media Services Live
* mTLS Edge Trust Store (METS)
* SLA

#### General

Added Docker support for both both AMD64 and ARM64.

#### Property

* Expanded Property submodule to include cmdlets for add, remove, test, and update property rules.
* Added `OriginalInput` and `UpgradeRules` switches to support Flex PAPI features.
* Added functions to get rule digest (Powershell 6+).

### Updates

#### AppSec

* Moved `Copy-AppSecPolicy` functionality into `New-AppSecPolicy` with `-CreateFromPolicyName` and `-CreateFromPolicyID` options.
* Added `-Override` option to `Set-AppSecPolicyRequestSizeLimit` to allow for enforcement of customized limits.

#### CPS

Bumped deployment content-type to v8.

#### Property

* Added additional response body object members in cmdlets that only returned a link, removing the need to parse IDs for use downstream. For example, `New-Property` now returns both a `PropertyLink`, `/papi/v1/properties/prp_97654?contractId=ctr_C-0N7RAC7&groupId=grp_12345`, and an isolated `PropertyID`, `97654` or `prp_97654` depending on your client settings.
* Simplified `Get-PropertyRules` and `Get-PropertyIncludeRules` to support multiple output types.
* Broadened `Get-PropertyHostname` to list all account hostnames if no property information provided.

### Removed

#### Common

Scoping for 100-continue removal.

#### AppSec
`Copy-AppSecPolicy`. Functionality moved into `New-AppSecPolicy`.

#### Image & Video Manager
ImageCollection functions.

### Known issues

All other previous known issues are resolved with this release's new submodules.

## 2.0.0 (Apr 17, 2024)

### New

Refactored entire module.

* Split module into parent and child architecture to improve import speed and flexibility.
* Created parent manifest module that allows an install or import of all child modules in a single command.
* Constructed `Expand-` functions to make lookups more efficient when asset names or versions of `latest` are used

### Updates

#### All submodules

* Added clear function and parameter descriptions in help documentation.
* Revised existing functions to use the most recent API versions.
* Removed all unapproved verbs.
* Combined singular and plural functions into one, removing `List-` functions.
* Merged object and string request body parameters into `-Body` that accepts any datatype that converts to JSON.
* Extended support for pipelining.

#### Cloudlets

United shared and non-shared endpoints into single functions with a default of shared and a `-Legacy` switch to create and manage non-shared policies.

#### NetStorage

Joined Config and Usage functions into a single submodule to simplify storage group and content management.

#### Property

Amalgamated rule management functions into `Get-PropertyRules` and `Set-PropertyRules` with equivalents for include that support PowerShell objects, JSON files, and snippets directories.

### Known issues

At the time of this release, there is no 1:1 support for these v1 services. To use Akamai PowerShell with these services, continue to use v1.

* API Key Manager
* China CDN
* Media Services Live
* Service Level Agreement
