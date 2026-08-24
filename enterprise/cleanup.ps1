param(
    [switch]$DryRun
)

$ErrorActionPreference = "SilentlyContinue"

$DaysOld = 14
$CutoffDate = (Get-Date).AddDays(-$DaysOld)

$InstallDirectory = "C:\ProgramData\WindowsTempCleanerEnterprise"
$LogFile = Join-Path $InstallDirectory "latest.log"

# Enterprise mode is intentionally conservative with application-managed data.
$ExcludedPathPatterns = @(
    "*\OneDrive\*",
    "*\OneDriveTemp\*",
    "*\OfficeFileCache\*",
    "*\Microsoft Office\*",
    "*\Microsoft\Office\*",
    "*\Microsoft\OneDrive\*",
    "*\Microsoft\Teams\*",
    "*\Teams\*",
    "*\Outlook\*",
    "*\Microsoft\Outlook\*"
)

$EligibleFiles = 0
$DeletedFiles = 0
$SkippedFiles = 0
$ExcludedFiles = 0

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

function Test-IsExcludedPath {
    param(
        [string]$Path
    )

    foreach ($Pattern in $ExcludedPathPatterns) {
        if ($Path -like $Pattern) {
            return $true
        }
    }

    return $false
}

# Scheduled tasks run as SYSTEM, so $env:TEMP would not point
# to the temporary folders of the actual Windows users.
function Get-UserTempDirectories {
    $ProfileRegistryPath =
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

    $TempDirectories = @()

    $Profiles = Get-ChildItem `
        -Path $ProfileRegistryPath `
        -ErrorAction SilentlyContinue

    foreach ($UserProfile in $Profiles) {
        try {
            $ProfileData = Get-ItemProperty `
                -LiteralPath $UserProfile.PSPath `
                -ErrorAction Stop

            $ProfilePath = $ProfileData.ProfileImagePath

            if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
                continue
            }

            $ProfilePath =
                [Environment]::ExpandEnvironmentVariables($ProfilePath)

            # Ignore Windows internal and service profiles.
            if ($ProfilePath -like "$env:SystemRoot\*") {
                continue
            }

            if (-not (Test-Path -LiteralPath $ProfilePath)) {
                continue
            }

            $UserTempPath = Join-Path `
                $ProfilePath `
                "AppData\Local\Temp"

            if (-not (Test-Path -LiteralPath $UserTempPath)) {
                continue
            }

            $ResolvedProfile = (
                Resolve-Path -LiteralPath $ProfilePath
            ).Path.TrimEnd("\")

            $ResolvedTemp = (
                Resolve-Path -LiteralPath $UserTempPath
            ).Path.TrimEnd("\")

            $ExpectedTemp = Join-Path `
                $ResolvedProfile `
                "AppData\Local\Temp"

            if ($ResolvedTemp -ne $ExpectedTemp) {
                continue
            }

            $TempDirectories += $ResolvedTemp
        }
        catch {
            continue
        }
    }

    return $TempDirectories | Sort-Object -Unique
}

$TempPaths = @()

foreach ($UserTemp in (Get-UserTempDirectories)) {
    $TempPaths += $UserTemp
}

$WindowsTemp = Join-Path $env:SystemRoot "Temp"

if (Test-Path -LiteralPath $WindowsTemp) {
    $TempPaths += (
        Resolve-Path -LiteralPath $WindowsTemp
    ).Path
}

$TempPaths = $TempPaths | Sort-Object -Unique

Write-Host ""
Write-Host "Windows Temp Cleaner - Enterprise"
Write-Host "================================="
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
            $_.LastWriteTime -lt $CutoffDate -and
            $_.LastAccessTime -lt $CutoffDate
        }

    foreach ($File in $Files) {
        if (Test-IsExcludedPath -Path $File.FullName) {
            $ExcludedFiles++
            continue
        }

        # Reparse points can redirect outside the intended Temp directory.
        if (
            $File.Attributes -band
            [IO.FileAttributes]::ReparsePoint
        ) {
            $ExcludedFiles++
            continue
        }

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

        $Directories = Get-ChildItem `
            -LiteralPath $Path `
            -Directory `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue |
            Sort-Object {
                $_.FullName.Length
            } -Descending

        foreach ($Directory in $Directories) {
            if (Test-IsExcludedPath -Path $Directory.FullName) {
                continue
            }

            if (
                $Directory.Attributes -band
                [IO.FileAttributes]::ReparsePoint
            ) {
                continue
            }

            try {
                $Children = Get-ChildItem `
                    -LiteralPath $Directory.FullName `
                    -Force `
                    -ErrorAction Stop

                if (-not $Children) {
                    Remove-Item `
                        -LiteralPath $Directory.FullName `
                        -Force `
                        -ErrorAction Stop
                }
            }
            catch {
                # Protected, in use, or already removed.
            }
        }
    }
}

Write-Host "Eligible files: $EligibleFiles"
Write-Host "Excluded files: $ExcludedFiles"
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
Windows Temp Cleaner - Enterprise

Last cleanup: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Files older than: $DaysOld days

Directories scanned:
$($TempPaths -join "`r`n")

Eligible files: $EligibleFiles
Excluded files: $ExcludedFiles
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
        # Logging should never prevent cleanup from completing.
    }
}

Write-Host ""