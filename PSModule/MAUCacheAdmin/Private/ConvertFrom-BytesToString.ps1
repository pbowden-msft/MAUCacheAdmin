function ConvertFrom-BytesToString {
    [OutputType('System.String')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Int64]
        $Bytes
    )

    if ($Bytes -lt 1) {
        return "0 Bytes"
    }
    if ($Bytes -lt 1MB) {
        return "$([Math]::Round($Bytes / 1KB, 2)) KB"
    }
    if ($Bytes -lt 1GB) {
        return "$([Math]::Round($Bytes / 1MB, 2)) MB"
    }
    if ($Bytes -lt 1TB) {
        return "$([Math]::Round($Bytes / 1GB, 2)) GB"
    }
    if ($Bytes -lt 1PB) {
        return "$([Math]::Round($Bytes / 1TB, 2)) TB"
    }

    return "$([Math]::Round($Bytes / 1PB, 2)) PB"

}