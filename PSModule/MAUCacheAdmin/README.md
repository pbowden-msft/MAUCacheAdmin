# MAUCacheAdmin PowerShell Module

This module was designed to mimic the MAUCacheAdmin shell script but in PowerShell.  
Clearly things got out of hand and it turned into the module you see today.

The module is compatible with PowerShell for Windows as well as PowerShell Core.
Its been tested with PS 5.1 on Windows, PS 7.3.4 on Windows and macOS.

[`HttpClient`](https://learn.microsoft.com/en-us/dotnet/api/system.net.http.httpclient) has been used in place of `Invoke-WebRequest` due to memory and performance issues when dealing with lots of small requests as well as large files ( this module does both ).

## Examples
### Mimics the same behaviour of `MAUCacheAdmin --CachePath:/Volumes/web/MAU/cache`
```PowerShell
# Get the current builds
$builds = Get-MAUProductionBuilds

# Get the production apps
$apps = Get-MAUApps -Channel Production

# Get the download jobs for the apps limited by the builds
$dlJobs = Get-MAUCacheDownloadJobs -MAUApps $apps -DeltaFromBuildLimiter $builds

# Download the packages to the cache path
Invoke-MAUCacheDownload -MAUCacheDownloadJobs $dlJobs -CachePath "/Volumes/web/MAU/cache" -ScratchPath "/tmp/MAUCache" -Force

# Save the collateral files to the cache path
Save-MAUCollaterals -MAUApps $apps -CachePath "/Volumes/web/MAU/cache"
```
### Append a version to the builds that is no longer in the production builds/collaterals.
Imagine You are deploying Microsoft_Office_16.67.22111300_Installer.pkg to all new mac and 16.67.22111300 is no longer in the "base" MAU collaterals.
MAU will be trying to download files such as `Word_16.67.22111300_to_16.69.23011600_Delta.pkg` to bring the current version up to the latest production build.
```PowerShell
# Get the current builds
$builds = Get-MAUProductionBuilds

# Get the production apps
$apps = Get-MAUApps -Channel Production

# Get the download jobs for the apps limited by the builds
$dlJobs = Get-MAUCacheDownloadJobs -MAUApps $apps -DeltaFromBuildLimiter ($builds + "16.67.22111300") -IncludeHistoricDeltas

# Download the packages to the cache path
Invoke-MAUCacheDownload -MAUCacheDownloadJobs $dlJobs -CachePath "/Volumes/web/MAU/cache" -ScratchPath "/tmp/MAUCache" -Force
```
### CACHE ALL THE THINGS!!
This example will cache everything based on the packages in each apps collateral as well as the history xmls.  
Warning, this will download 1340 files totalling ~266GB of content at the time of writing this!
```PowerShell
# Get the production apps
$apps = Get-MAUApps -Channel Production

# Get the download jobs for the apps limited by the builds (This may take a while)
$dlJobs = Get-MAUCacheDownloadJobs -MAUApps $apps -IncludeHistoricDeltas -IncludeHistoricVersions

# Download the packages to the cache path (This may take a while)
Invoke-MAUCacheDownload -MAUCacheDownloadJobs $dlJobs -CachePath "/Volumes/web/MAU/cache" -ScratchPath "/tmp/MAUCache" -Force
```

## Cmdlets
### `Get-MAUProductionBuilds`
Returns a string array containing the current production build versions. This array of builds can be used to scope down the delta files from the cache.
#### Arguments
 - NA


### `Get-MAUApps`
Returns an array of objects that represents each app with its various Collateral URIs and Packages
#### Arguments
 - Channel
   - Set the update channel, valid values: `Production`, `Preview`, `Beta`


### `Get-MAUCacheDownloadJobs`
Returns an array of objects that represents the download jobs for all of the provided MAU Apps.  
Optionally you can provide an array of builds that will be used to filter the delta packages
#### Arguments
 - MAUApps
   - Mandatory
   - Array of MAUApp objects
 - DeltaFromBuildLimiter
   - Array of build strings to be used to limit the deltas
   - EG `*[build]_to_*`
 - DeltaToBuildLimiter
   - Array of build strings to be used to limit the deltas
   - EG `*_to_[build]*`
 - IncludeHistoricVersions
   - Switch to optionally include historic packages in the download jobs
   - Warning this will generate a lot of download jobs


### `Invoke-MAUCacheDownload`
Downloads the provided download jobs to the provided folder.  
Optionally it can "Mirror" the cache directory to automatically cleanup items in the cache that are not defined in the download jobs
#### Arguments
 - MAUCacheDownloadJobs
   - Mandatory
   - Array of MAU Cache Download Job objects
 - CachePath
   - Mandatory
   - Target path for the cache items
 - ScratchPath
   - Mandatory
   - Target scratch path for the cache items
 - Force
   - Switch to automatically clear the scratch path if items already exist
 - Mirror
   - Switch to remote and existing items in the CachePath that are not defined in the input Download Jobs
   - Similar to `Robocopy /MIR`
 - CompareLastModified
   - Switch to also compare the last modified as well as length
   - This currently has issues due to the MAU CDN returning inconsistent Last Modified dates for certain files


### `Save-MAUCollaterals`
Saves the various Collateral files to the `collateral/{version}` subfolder of the cache path.  
 - MAUApps
   - Mandatory
   - Array of MAUApp objects
 - CachePath
   - Mandatory
   - Target path for the cache items


### `Set-MAUCacheAdminHttpClientHandler`
Allows you to inject a custom [`HttpClientHandler`](https://learn.microsoft.com/en-us/dotnet/api/system.net.http.httpclienthandler)  
Useful if you need to configure a WebProxy for use in your environment. The `HttpClientHandler` provided to this function will be used for all subsuquent web requests by the module.
#### Arguments
 - Handler
   - Mandatory
   - System.Net.Http.HttpClientHandler object