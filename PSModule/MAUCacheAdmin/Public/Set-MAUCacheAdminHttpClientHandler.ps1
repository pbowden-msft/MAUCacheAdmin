function Set-MAUCacheAdminHttpClientHandler {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Net.Http.HttpClientHandler]
        $Handler
    )

    $Script:HttpClientHandler = $Handler
}