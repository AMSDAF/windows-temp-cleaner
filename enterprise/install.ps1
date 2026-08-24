#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$InstallDirectory = "C:\ProgramData\WindowsTempCleanerEnterprise"
$InstalledScript = Join-Path $InstallDirectory "cleanup.ps1"
$SourceScript = Join-Path $PSScriptRoot "cleanup.ps1"

$TaskName = "Windows Temp Cleaner - Enterprise"

$TaskDay = "Sunday"
$TaskTime = "12:00PM"

Write-Host ""
Write-Host "Windows Temp Cleaner - Enterprise Installer"
Write-Host "==========================================="
Write-Host ""

if (-not (Test-Path -LiteralPath $SourceScript)) {
    Write-Host "Error: cleanup.ps1 was not found."
    Write-Host "Make sure install.ps1 and cleanup.ps1 are in the same folder."
    exit 1
}

Write-Host "Creating installation directory..."

if (-not (Test-Path -LiteralPath $InstallDirectory)) {
    New-Item `
        -ItemType Directory `
        -Path $InstallDirectory `
        -Force | Out-Null
}

Write-Host "Installing cleanup script..."

Copy-Item `
    -LiteralPath $SourceScript `
    -Destination $InstalledScript `
    -Force

$ExistingTask = Get-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Host "Updating existing scheduled task..."

    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false
}

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$InstalledScript`""

$Trigger = New-ScheduledTaskTrigger `
    -Weekly `
    -DaysOfWeek $TaskDay `
    -At $TaskTime

$Settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Write-Host "Creating weekly scheduled task..."

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Description "Conservatively removes old temporary files using enterprise safety rules." `
    -Force | Out-Null

Write-Host ""
Write-Host "Enterprise installation completed successfully."
Write-Host ""
Write-Host "Installed at:"
Write-Host "  $InstallDirectory"
Write-Host ""
Write-Host "Scheduled task:"
Write-Host "  $TaskName"
Write-Host ""
Write-Host "Schedule:"
Write-Host "  Every $TaskDay at $TaskTime"
Write-Host ""
Write-Host "If the computer is off at the scheduled time,"
Write-Host "the task will run when Windows becomes available."
Write-Host ""