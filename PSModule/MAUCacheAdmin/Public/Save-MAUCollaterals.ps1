function Save-MAUCollaterals {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $MAUApps,
        [Parameter(Mandatory=$true)]
        [string]
        $CachePath
    )

    $logPrefix = "$($MyInvocation.MyCommand):"

    # Validate provided paths exist
    if (-not (Test-Path -Path $CachePath)) {
        throw "The target Cache Path does not exist ($CachePath)"
    }

    $collateralPath = Join-Path -Path $CachePath -ChildPath "collateral"
    $null = New-Item -Path $collateralPath -ItemType Directory -Force

    foreach ($mauApp in $MAUApps) {
        $ver = $mauApp.VersionInfo.Version
        $verDir = Join-Path -Path $collateralPath -ChildPath $ver
        $null = New-Item -Path $verDir -ItemType Directory -Force

        Write-Verbose "$logPrefix Saving $($mauApp.AppID) collaterals to $verDir"

        $collateralURIs = @($mauApp.CollateralURIs.AppXML, $mauApp.CollateralURIs.CAT, $mauApp.CollateralURIs.ChkXml) | Where-Object {$null -ne $_}
        $collateralURIs | Foreach-Object {Invoke-HttpClientDownload -Uri $_ -Path $verDir -UseRemoteLastModified -Force}
    }
}