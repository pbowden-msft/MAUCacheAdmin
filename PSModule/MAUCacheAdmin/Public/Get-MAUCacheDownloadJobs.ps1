function Get-MAUCacheDownloadJobs {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [OutputType('System.Object[]')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $MAUApps,
        [Parameter()]
        [string[]]
        $DeltaToBuildLimiter = @(),
        [Parameter()]
        [string[]]
        $DeltaFromBuildLimiter = @(),
        [switch]
        $IncludeHistoricDeltas,
        [switch]
        $IncludeHistoricVersions
    )

    $logPrefix = "$($MyInvocation.MyCommand):"
    Write-Verbose "$logPrefix Getting download jobs for $($MAUApps.Count) Collaterals"

    # Set http client for the function
    $httpClient = [System.Net.Http.HttpClient]::new((Get-HttpClientHandler), $false)

    Write-Progress -Id 0 -Activity "Getting Download Jobs"
    $colPos = 0
    $downloadJobs = @(foreach ($MAUApp in $MAUApps) {
        Write-Verbose "$logPrefix Getting download jobs for $($MAUApp.AppName)"
        Write-Progress -Id 0 -Activity "Getting Download Jobs" -Status "$($MAUApp.AppName) - $($colPos + 1) of $($MAUApps.Count)" -PercentComplete $(if ($colPos -eq 0) {0} else {($colPos / $MAUApps.Count * 100)})
        $colPos++

        $packageUris = @(($MAUApp.Packages.Location + $MAUApp.Packages.BinaryUpdaterLocation + $MAUApp.Packages.FullUpdaterLocation) | Sort-Object -Unique)

        if ($IncludeHistoricVersions -and $MAUApp.HistoricPackages.Count -gt 0) {
            $historicURIs = @($MAUApp.HistoricPackages.GetEnumerator() | ForEach-Object {
                ($_.Value.Location + $_.Value.BinaryUpdaterLocation + $_.Value.FullUpdaterLocation)
            } | Sort-Object -Unique) | Where-Object {$_ -notlike "*_to_*"}
            $packageUris = ($packageUris + $historicURIs) | Sort-Object -Unique
        }

        if ($IncludeHistoricDeltas -and $MAUApp.HistoricPackages.Count -gt 0) {
            $historicURIs = @($MAUApp.HistoricPackages.GetEnumerator() | ForEach-Object {
                ($_.Value.Location + $_.Value.BinaryUpdaterLocation + $_.Value.FullUpdaterLocation)
            } | Sort-Object -Unique) | Where-Object {$_ -like "*_to_*"}
            $packageUris = ($packageUris + $historicURIs) | Sort-Object -Unique
        }

        if ($DeltaToBuildLimiter.Count -gt 0 -or $DeltaFromBuildLimiter -gt 0) {
            # Filter delta packages by provided builds
            $pattern = '.*?([\d.]+)_to_([\d.]+).*'

            $packageUris = $packageUris | Where-Object {
                $_ -notmatch $pattern -or ($_ -match $pattern -and $DeltaFromBuildLimiter.Contains($Matches[1]) -or $DeltaToBuildLimiter.Contains($Matches[2]))
            }
        }

        # Convert URI strings into URI Objects
        $uris = @($packageUris | ForEach-Object {[uri]::new($_)})

        $dlPos = 0
        foreach ($uri in $uris) {
            Write-Verbose "$logPrefix Processing URI ($uri)"
            Write-Progress -Id 1 -ParentId 0 -Activity "Processing URIs - $($dlPos + 1) of $($uris.Count)" -Status "$uri" -PercentComplete $(if ($dlPos -eq 0) {0} else {($dlPos / $uris.Count * 100)})
            $dlPos++

            # Create and Send the head request
            $headRequest = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Head, $uri)
            $response = $httpClient.SendAsync($headRequest).GetAwaiter().GetResult()
            # Dispose of the head request
            $headRequest.Dispose()

            [PSCustomObject]@{
                AppName = $MAUApp.AppName
                LocationUri = $uri
                Payload = $uri.Segments[-1]
                SizeBytes = $response.Content.Headers.ContentLength
                LastModified = $response.Content.Headers.LastModified.DateTime
            }
        }
        Write-Progress -Id 1 -ParentId 0 -Activity "Processing URIs" -Completed

    })

    Write-Progress -Id 0 -Activity "Getting Download Jobs" -Completed

    # Dispose of the http client
    $httpClient.Dispose()

    return $downloadJobs
}