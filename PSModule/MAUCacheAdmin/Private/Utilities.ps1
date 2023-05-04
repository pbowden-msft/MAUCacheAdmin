filter FixLineBreaks {
    if ($PSVersionTable.PSVersion -gt [Version]::new("6.0.0")) {
        [Regex]::Replace($_, "`r?`n", [Environment]::NewLine)
    } else {
        [Regex]::Replace($_, "(\\r\\n|\\r|\\n)", [Environment]::NewLine)
    }
}