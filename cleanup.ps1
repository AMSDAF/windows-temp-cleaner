param(
    [switch]$DryRun
)

$ErrorActionPreference = "SilentlyContinue"

$DaysOld = 7
$CutoffDate = (Get-Date).AddDays(-$DaysOld)

$TempPaths = @(
    $env:TEMP,
    "C:\Windows\Temp"
)

$InstallDirectory = "C:\ProgramData\WindowsTempCleaner"
$LogFile = Join-Path $InstallDirectory "latest.log"

$EligibleFiles = 0
$DeletedFiles = 0
$SkippedFiles = 0

$PotentialBytes = [long]0
$FreedBytes = [long]0

function Format-FileSize {
    param(
        [long]$Bytes
    )

    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }

    if ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }

    if ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }

    return "$Bytes bytes"
}

Write-Host ""
Write-Host "Windows Temp Cleaner"
Write-Host "===================="
Write-Host ""

if ($DryRun) {
    Write-Host "Mode: DRY RUN"
}
else {
    Write-Host "Mode: CLEANUP"
}

Write-Host "Files older than: $DaysOld days"
Write-Host ""
Write-Host "Scanning:"

foreach ($Path in $TempPaths) {
    Write-Host "  $Path"
}

Write-Host ""

foreach ($Path in $TempPaths) {

    if (-not (Test-Path -LiteralPath $Path)) {
        continue
    }

    $Files = Get-ChildItem `
        -LiteralPath $Path `
        -File `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.LastWriteTime -lt $CutoffDate
        }

    foreach ($File in $Files) {

        $EligibleFiles++
        $PotentialBytes += $File.Length

        if ($DryRun) {
            continue
        }

        try {
            $FileSize = $File.Length

            Remove-Item `
                -LiteralPath $File.FullName `
                -Force `
                -ErrorAction Stop

            $DeletedFiles++
            $FreedBytes += $FileSize
        }
        catch {
            $SkippedFiles++
        }
    }
}

if (-not $DryRun) {

    foreach ($Path in $TempPaths) {

        if (-not (Test-Path -LiteralPath $Path)) {
            continue
        }

        Get-ChildItem `
            -LiteralPath $Path `
            -Directory `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            ForEach-Object {

                try {
                    if (-not (Get-ChildItem -LiteralPath $_.FullName -Force)) {
                        Remove-Item `
                            -LiteralPath $_.FullName `
                            -Force `
                            -ErrorAction Stop
                    }
                }
                catch {
                    # Directory is protected, in use, or no longer exists.
                }
            }
    }
}

Write-Host "Eligible files: $EligibleFiles"
Write-Host "Potential space: $(Format-FileSize $PotentialBytes)"

if ($DryRun) {

    Write-Host ""
    Write-Host "No files were deleted."
}
else {

    Write-Host "Deleted files: $DeletedFiles"
    Write-Host "Skipped files: $SkippedFiles"
    Write-Host "Space freed: $(Format-FileSize $FreedBytes)"

    try {

        if (-not (Test-Path -LiteralPath $InstallDirectory)) {
            New-Item `
                -ItemType Directory `
                -Path $InstallDirectory `
                -Force | Out-Null
        }

        $LogContent = @"
Windows Temp Cleaner

Last cleanup: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Files older than: $DaysOld days
Eligible files: $EligibleFiles
Deleted files: $DeletedFiles
Skipped files: $SkippedFiles
Space freed: $(Format-FileSize $FreedBytes)
"@

        Set-Content `
            -LiteralPath $LogFile `
            -Value $LogContent `
            -Encoding UTF8
    }
    catch {
        # Cleanup should not fail just because the log could not be written.
    }
}

Write-Host ""