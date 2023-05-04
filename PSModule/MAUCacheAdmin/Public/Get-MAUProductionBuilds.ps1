function Get-MAUProductionBuilds {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    param (
    )

    $logPrefix = "$($MyInvocation.MyCommand):"

    # At the time of writting this, only the production CDN has a builds.txt file.
    $buildsURI = [Uri]::new("https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/builds.txt")

    Write-Verbose "$logPrefix Getting builds from $buildsURI"

    # Create a http client then get use the GetStringAsync method to get the build.txt content as a string
    $httpClient = [System.Net.Http.HttpClient]::new((Get-HttpClientHandler), $false)
    $builds = ($httpClient.GetStringAsync($buildsURI).GetAwaiter().GetResult() | FixLineBreaks).Split([System.Environment]::NewLine) # Unify line breaks for consistent splitting into a string array.
    $httpClient.Dispose()

    return $builds
}