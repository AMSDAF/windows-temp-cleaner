# Windows Temp Cleaner

A lightweight PowerShell utility that automatically removes old temporary files from Windows.

Windows Temp Cleaner scans temporary directories, removes files that have not been used for a defined period, skips protected or unavailable files, and can run automatically every week through Windows Task Scheduler.

The project provides two editions with different cleanup strategies:

- **Personal** — designed for regular personal computers.
- **Enterprise** — designed for workstations and business environments where a more conservative cleanup policy is preferred.

## Features

- Cleans temporary files from all detected Windows user profiles
- Cleans `C:\Windows\Temp`
- Automatically detects user TEMP directories even when running as `SYSTEM`
- Supports safe Dry Run testing
- Skips files that are locked, protected, or unavailable
- Avoids junctions, symbolic links, and other reparse points
- Protects known application-managed temporary paths
- Optional weekly automatic cleanup through Windows Task Scheduler
- Runs with `SYSTEM` privileges when installed
- Automatically runs after a missed scheduled execution
- Keeps only the latest cleanup log
- Includes simple installation and uninstallation scripts
- No external dependencies

## Editions

### Personal

The Personal edition is intended for regular Windows computers where freeing unused temporary storage is the main goal.

It considers files eligible when they have not been modified for more than **7 days**.

It includes:

- all detected user `%TEMP%` directories
- `C:\Windows\Temp`
- basic application-managed path exclusions
- protection against locked files and reparse points
- weekly automatic cleanup when installed

**Recommended for:**

- personal desktops
- personal notebooks
- gaming computers
- development machines
- computers without critical business workloads

### Enterprise

The Enterprise edition uses a more conservative cleanup policy intended for company workstations.

Files are only considered eligible when both their **Last Write Time** and **Last Access Time** are older than **14 days**.

It also includes additional exclusions for application-managed temporary data associated with software such as OneDrive, Microsoft Office, Outlook, and Teams.

The goal of the Enterprise edition is not to remove the maximum possible amount of data. Its priority is reducing unnecessary temporary files while minimizing interference with business applications, synchronization processes, and user workflows.

**Recommended for:**

- company workstations
- shared computers
- Microsoft 365 environments
- computers using OneDrive
- machines containing business-critical files
- environments where cleanup safety is more important than maximum storage recovery

> [!TIP]
> If you are unsure which edition to use, choose **Enterprise**. It is intentionally more conservative.

## Personal vs Enterprise

| Feature | Personal | Enterprise |
| --- | --- | --- |
| User TEMP directories | Yes | Yes |
| `C:\Windows\Temp` | Yes | Yes |
| Multiple Windows users | Yes | Yes |
| Minimum file age | 7 days | 14 days |
| Last Write Time checked | Yes | Yes |
| Last Access Time checked | No | Yes |
| Application exclusions | Standard | Extended |
| Locked files skipped | Yes | Yes |
| Reparse points protected | Yes | Yes |
| Dry Run | Yes | Yes |
| Weekly automatic cleanup | Yes | Yes |
| Primary goal | Storage cleanup | Conservative cleanup |

## Project Structure

```text
windows-temp-cleaner/
├── personal/
│   ├── cleanup.ps1
│   ├── install.ps1
│   ├── install.bat
│   ├── uninstall.ps1
│   └── uninstall.bat
│
├── enterprise/
│   ├── cleanup.ps1
│   ├── install.ps1
│   ├── install.bat
│   ├── uninstall.ps1
│   └── uninstall.bat
│
├── README.md
└── LICENSE
```

## Installation

First, choose either the `personal` or `enterprise` directory.

### Recommended: BAT Installer

The easiest way to install Windows Temp Cleaner is using:

```text
install.bat
```

Run `install.bat` and accept the Windows administrator prompt.

The installer will:

1. create the installation directory
2. copy the cleanup script
3. create a Windows Scheduled Task
4. configure the cleaner to run once a week
5. run the task with `SYSTEM` privileges

No terminal commands are required.

### PowerShell Installation

You can also run the PowerShell installer directly.

Open PowerShell as Administrator, navigate to the selected edition and run:

```powershell
.\install.ps1
```

The Personal edition installs to:

```text
C:\ProgramData\WindowsTempCleaner
```

The Enterprise edition installs to:

```text
C:\ProgramData\WindowsTempCleanerEnterprise
```

## Automatic Cleanup

When installed, Windows Temp Cleaner creates a scheduled task that runs every:

```text
Sunday at 12:00 PM
```

If the computer is turned off at the scheduled time, Windows Task Scheduler will start the cleanup when the machine becomes available again.

The Personal task is named:

```text
Windows Temp Cleaner
```

The Enterprise task is named:

```text
Windows Temp Cleaner - Enterprise
```

## Manual Usage

Installation is optional.

You can run `cleanup.ps1` directly whenever you want.

Open PowerShell as Administrator and navigate to the edition directory.

### Dry Run

Before deleting anything, you can inspect what the cleaner considers eligible:

```powershell
.\cleanup.ps1 -DryRun
```

Example:

```text
Windows Temp Cleaner
====================

Mode: DRY RUN
Files older than: 7 days

Scanning:
  C:\Users\User\AppData\Local\Temp
  C:\WINDOWS\Temp

Eligible files: 136
Excluded files: 2
Potential space: 200.74 MB

No files were deleted.
```

Dry Run never deletes files.

### Cleanup

To perform the cleanup:

```powershell
.\cleanup.ps1
```

The cleaner reports:

- eligible files
- excluded files
- deleted files
- skipped files
- space freed

## Logs

Automatic cleanup keeps only the latest execution log.

Personal:

```text
C:\ProgramData\WindowsTempCleaner\latest.log
```

Enterprise:

```text
C:\ProgramData\WindowsTempCleanerEnterprise\latest.log
```

The previous log is overwritten during the next cleanup, preventing log files from accumulating over time.

## Uninstallation

### Recommended

Run:

```text
uninstall.bat
```

and accept the administrator prompt.

### PowerShell

Alternatively, open PowerShell as Administrator and run:

```powershell
.\uninstall.ps1
```

The uninstaller removes:

- the scheduled task
- the installed cleanup script
- the Windows Temp Cleaner installation directory
- the latest cleanup log

The original repository files are not removed.

## Safety

Windows Temp Cleaner is intentionally limited to known Windows temporary directories.

The cleaner:

- only scans explicitly discovered user TEMP directories and `C:\Windows\Temp`
- validates user profile TEMP paths before using them
- does not follow or remove reparse points
- skips files that Windows does not allow it to remove
- ignores known application-managed temporary paths
- only removes files older than the configured retention period

The Enterprise edition adds stricter retention rules and additional application exclusions.

No cleanup utility can guarantee compatibility with every application or environment. Test the cleaner using `-DryRun` and validate it on a limited number of machines before organization-wide deployment.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or later
- Administrator privileges for installation and system-level cleanup

No external PowerShell modules or third-party dependencies are required.

## License

This project is open source and available under the [MIT License](LICENSE).