function Get-HttpClientHandler {
    if ($null -eq $Script:HttpClientHandler) {
        # Set default HTTP Client Handler if one has not been defined
        $Script:HttpClientHandler = [System.Net.Http.HttpClientHandler]::new()
    }

    return $Script:HttpClientHandler
}