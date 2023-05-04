function ConvertFrom-AppPackageDictionary {
    [OutputType('System.Object[]')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Collections.Specialized.OrderedDictionary[]]
        $AppPackageDictionaries
    )

    $logPrefix = "$($MyInvocation.MyCommand):"
    Write-Verbose "$logPrefix Processing $($AppPackageDictionaries.Count) App Packages"

    # Cast the OrderedDictionary objects to a PSCustomObject
    $appPackageObjects = @($AppPackageDictionaries | Foreach-Object {[PSCustomObject]$_})

    Write-Verbose "$logPrefix Returning $($appPackageObjects.Count) converted objects"
    return $appPackageObjects
}