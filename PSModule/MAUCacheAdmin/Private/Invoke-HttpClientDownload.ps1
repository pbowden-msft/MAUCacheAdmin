function Invoke-HttpClientDownload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Uri]
        $Uri,
        [Parameter(Mandatory=$true, ParameterSetName="OutFile")]
        [String]
        $OutFile,
        [Parameter(Mandatory=$true, ParameterSetName="Path")]
        [String]
        $Path,
        [switch]
        $UseRemoteLastModified,
        [switch]
        $Force
    )

    $logPrefix = "$($MyInvocation.MyCommand):"

    if ($PSCmdlet.ParameterSetName -eq "Path" -and -not (Test-Path -Path $Path)) {
        Throw "The target directory does not exist ($Path)"
    }

    try {
        $httpClient = [System.Net.Http.HttpClient]::new((Get-HttpClientHandler), $false)
        $response = $httpClient.GetAsync($Uri, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        if (!$response.IsSuccessStatusCode) {
            Throw "Status code: $($response.StatusCode)"
        }

        if ($PSCmdlet.ParameterSetName -eq "Path") {
            $targetFileName = if (![string]::IsNullOrEmpty($response.Content.Headers.ContentDisposition.FileName)) {
                $response.Content.Headers.ContentDisposition.FileName
            } else {
                $Uri.Segments[-1]
            }
            $targetPath = Join-Path -Path $Path -ChildPath $targetFileName
        } else {
            $targetPath = $OutFile
        }

        if (-not $Force -and (Test-Path -Path $targetPath)) {
            throw "The target file already exists ($targetPath)"
        }

        $targetSize = $response.Content.Headers.ContentLength
        $lastModified = $response.Content.Headers.LastModified.DateTime
        $lastNotified = [DateTime]::Now.AddMinutes(-1)

        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $fileStream = [System.IO.File]::Create($targetPath)
        $buffer = New-Object byte[] 256KB
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)

            # Delay the notifications to prevent CPU bottleneck on the download
            if (([System.DateTime]::Now - $lastNotified).TotalMilliseconds -gt 250) {
                $percent = [int]($fileStream.Length / $targetSize * 100 )
                Write-Progress -Activity "Downloading File" -Status "$($fileStream.Length) of $targetSize Bytes - $percent %" -CurrentOperation "Downloading $Uri to $targetPath" -PercentComplete $(if($percent -lt 1){1}else{$percent})
                $lastNotified = [System.DateTime]::Now
            }
        }
        $fileStream.Close()
        Write-Verbose "$logPrefix File downloaded successfully to: $targetPath"

        if ($UseRemoteLastModified) {
            $fileInfo = [System.IO.FileInfo]::new($targetPath)
            $fileInfo.LastWriteTimeUtc = $lastModified
        }
    }
    catch {
        Throw "Failed to download the file ($_)"
    }
    finally {
        Write-Progress -Activity "Downloading File" -Completed
        if ($null -ne $httpClient) { $httpClient.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
        if ($null -ne $fileStream) { $fileStream.Close(); $fileStream.Dispose() }
    }
}