# Set Module wide error action preference
$Script:ErrorActionPreference = 'Stop'

# Get public and private function definition files.
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)

# Dot source the files.
foreach ($import in @($Public + $Private)) {
    try {
        Write-Verbose "Importing $($import.FullName)"
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export all of the public functions making them available to the user
foreach ($file in $Public) {
    Export-ModuleMember -Function $file.BaseName
}