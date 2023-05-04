function Invoke-MAUCacheDownload {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]
        $MAUCacheDownloadJobs,
        [Parameter(Mandatory=$true)]
        [string]
        $CachePath,
        [Parameter(Mandatory=$true)]
        [string]
        $ScratchPath,
        [switch]
        $Force,
        [switch]
        $Mirror,
        [switch]
        $CompareLastModified
    )

    $logPrefix = "$($MyInvocation.MyCommand):"

    # Validate provided paths exist
    if (-not (Test-Path -Path $CachePath)) {
        throw "The target Cache Path does not exist ($CachePath)"
    }
    if (-not (Test-Path -Path $ScratchPath)) {
        throw "The target Scratch Path does not exist ($ScratchPath)"
    }

    # Make sure scratch path is clear
    $scratchItems = Get-ChildItem -Path $ScratchPath -Recurse
    if (-not $Force -and $scratchItems.Count -gt 0) {
        throw "$($scratchItems.Count) items found in scratch directory, run with -Force to automatically clear the scratch path"
    }
    $scratchItems | Remove-Item -Force -Recurse

    # Validate we have at least 1 valid download job
    if ($MAUCacheDownloadJobs.Count -lt 1) {
        throw "No MAUCacheDownloadJobs provided"
    }
    if ($null -eq $MAUCacheDownloadJobs[0].LocationUri) {
        throw "Unable to validate Download Job object"
    }

    $cachedItems = @()

    $count = 0
    foreach ($dlJob in $MAUCacheDownloadJobs) {
        $count++
        $statusString = "$count of $($MAUCacheDownloadJobs.Count)"
        Write-Host "$('=' * (25 - $statusString.Length / 2))$statusString$('=' * (25 - $statusString.Length / 2))"
        Write-Host "Application: $($dlJob.AppName)"
        Write-Host "Package: $($dlJob.Payload)"
        Write-Host "Size: $(ConvertFrom-BytesToString -Bytes $dlJob.SizeBytes)"
        Write-Host "URL: $($dlJob.LocationUri)"

        $targetCacheItem = [System.IO.FileInfo]::new($(Join-Path -Path $CachePath -ChildPath $dlJob.Payload))
        $targetScratchItem = [System.IO.FileInfo]::new($(Join-Path -Path $ScratchPath -ChildPath $dlJob.Payload))

        $cachedItems += $targetCacheItem.FullName

        $cacheIsValid = $true

        if (-not $targetCacheItem.Exists) {
            Write-Verbose "$logPrefix $($dlJob.Payload) not found in the cache"
            $cacheIsValid = $false
        }

        if ($targetCacheItem.Length -ne $dlJob.SizeBytes) {
            Write-Warning "Package $($dlJob.Payload) exists in the cache but the file size does not match... Will redownload"
            $cacheIsValid = $false
        }

        if ($CompareLastModified -and $cacheIsValid -and $targetCacheItem.LastWriteTimeUtc -ne $dlJob.LastModified) {
            Write-Warning "Package $($dlJob.Payload) exists in the cache but the Last Modified does not match... Will redownload"
            $cacheIsValid = $false
        }

        if (-not $cacheIsValid) {
            Write-Host "Downloading $($dlJob.Payload) to $($targetScratchItem.FullName)" -ForegroundColor Cyan
            $dlAttempt = 0
            while ($dlAttempt -lt 2) {
                try {
                    Invoke-HttpClientDownload -Uri $dlJob.LocationUri -OutFile $targetScratchItem.FullName -UseRemoteLastModified -Force
                    break
                }
                catch {
                    # Sometimes the download will timeout, suspect some kind of throtteling on the CDN
                    $message = $_.Exception.Message
                    if ($message -notmatch "The response ended prematurely") {
                        throw
                        break
                    }
                    Write-Verbose "$logPrefix retrying download ($dlAttempt times)"
                    $dlAttempt++
                }
            }
            $targetScratchItem.Refresh()
            Move-Item -Path $targetScratchItem.FullName -Destination $targetCacheItem.FullName -Force
        } else {
            Write-Host "$($dlJob.Payload) is in the cache and is healthy" -ForegroundColor Green
        }
    }

    if ($Mirror) {
        # Get excess files in cache dir and delete them
        $excessCacheFiles = @(Get-ChildItem -Path $CachePath -File | Where-Object {-not $cachedItems.Contains($_.FullName)})
        Write-Verbose "$logPrefix Removing $($excessCacheFiles.Count) excess files from the cache"
        $excessCacheFiles | Remove-Item -Force
    }
}