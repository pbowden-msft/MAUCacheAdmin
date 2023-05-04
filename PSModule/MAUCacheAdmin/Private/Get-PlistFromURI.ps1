function Get-PlistObjectFromURI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Uri]
        $URI,
        [Parameter(Mandatory=$true)]
        [System.Net.Http.HttpClient]
        $HttpClient
    )
    $logPrefix = "$($MyInvocation.MyCommand):"
    Write-Verbose "$logPrefix Processing $URI"

    try {
        [xml]$xmlObject = $HttpClient.GetStringAsync($URI).GetAwaiter().GetResult()
    }
    catch [System.Net.Http.HttpRequestException] {
        # Use the StatusCode for dotnet 5+ and fall back to parsing the error string in older dotnets
        if ($_.Exception.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest -or $_.Exception.Message -like "*400 (Bad Request)*") {
            # Return null if no response was found ( EG -history.xml files are only on certain apps )
            # The MAU CDN does not return 404s, it always returns a 400 Bad Request when requesting a file that doesn't
            # so we assume that 400 = 404 in and hope the upstream caller handles this appropriately
            Write-Verbose "$logPrefix Received HTTP BadRequest (400) response from $URI"
            return $null
        }
        # Rethrow the exception if it was not handled
        throw
    }

    Write-Verbose "$logPrefix Converting XML object to Plist Object"
    return $xmlObject | ConvertFrom-Plist
}