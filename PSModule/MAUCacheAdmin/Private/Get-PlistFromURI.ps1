function Get-PlistObjectFromURI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Uri]
        $URI,
        [Parameter(Mandatory=$true)]
        [System.Net.Http.HttpClient]
        $HttpClient,
        [Switch]
        $Optional
    )
    $logPrefix = "$($MyInvocation.MyCommand):"
    Write-Verbose "$logPrefix Processing $URI"

    try {
        [xml]$xmlObject = $HttpClient.GetStringAsync($URI).GetAwaiter().GetResult()
    }
    catch [System.Net.Http.HttpRequestException] {
        # Return null if $Optional is set
        if ($Optional) {
            # Return null if no response was found ( EG -history.xml files are only on certain apps ).
            # The MAU CDN does not consistently return 404s, seems to also return 400 Bad Request sometimes when requesting a file that doesn't exist
            # so we don't bother checking the response code and just assume if there is a request exception and its Optional, we return null.
            Write-Verbose "$logPrefix Request for $URI Returned $($_.Exception.Message)"
            return $null
        }
        # Rethrow the exception if it was not handled
        throw
    }

    Write-Verbose "$logPrefix Converting XML object to Plist Object"
    return $xmlObject | ConvertFrom-Plist
}