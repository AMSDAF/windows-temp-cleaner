#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$InstallDirectory = "C:\ProgramData\WindowsTempCleaner"
$TaskName = "Windows Temp Cleaner"

Write-Host ""
Write-Host "Windows Temp Cleaner Uninstaller"
Write-Host "================================"
Write-Host ""

$ExistingTask = Get-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Host "Removing scheduled task..."

    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false
}
else {
    Write-Host "Scheduled task not found."
}

if (Test-Path -LiteralPath $InstallDirectory) {

    Write-Host "Removing installed files..."

    Remove-Item `
        -LiteralPath $InstallDirectory `
        -Recurse `
        -Force
}
else {
    Write-Host "Installation directory not found."
}

Write-Host ""
Write-Host "Windows Temp Cleaner was removed successfully."
Write-Host ""