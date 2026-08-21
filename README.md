# Windows Temp Cleaner

A lightweight PowerShell utility that automatically removes old temporary files from Windows.

I built this after manually cleaning a company laptop and finding **2.3 GB of accumulated temporary files**. Instead of repeating the same cleanup on every machine, I decided to automate it.

The goal is simple: **install it once and let Windows handle the cleanup automatically.**

## Features

* Automatically removes old temporary files
* Cleans the current user's `%TEMP%` directory
* Cleans `C:\Windows\Temp`
* Only removes files older than **7 days**
* Skips files that are currently in use or protected
* Runs automatically once a week using Windows Task Scheduler
* Keeps only the latest execution log
* Includes automatic installation and removal scripts
* No external dependencies
* No background application constantly running
* Open source and easy to audit

## Project Structure

```text
windows-temp-cleaner/
├── cleanup.ps1
├── install.ps1
├── uninstall.ps1
├── README.md
└── LICENSE
```

### `cleanup.ps1`

Contains the cleanup logic.

It scans the configured temporary directories and removes eligible files older than 7 days. Files that are locked, protected, or currently being used are skipped.

### `install.ps1`

Installs Windows Temp Cleaner on the machine and creates the scheduled task responsible for running the cleanup automatically every week.

### `uninstall.ps1`

Removes the scheduled task and the files installed by Windows Temp Cleaner.

## Installation

Clone or download this repository.

Open PowerShell as Administrator, navigate to the project directory, and run:

```powershell
.\install.ps1
```

The installer will configure the cleanup task automatically.

After installation, no manual execution should be necessary.

## Manual Cleanup

You can also run the cleaner manually:

```powershell
.\cleanup.ps1
```

Administrator privileges may be required to clean system-level temporary directories such as:

```text
C:\Windows\Temp
```

## What Gets Deleted?

By default, Windows Temp Cleaner targets:

```text
%TEMP%
C:\Windows\Temp
```

Only items older than **7 days** are considered for removal.

Files that cannot be safely removed because they are locked, protected, or currently in use are skipped.

The tool does **not** clean directories such as:

```text
Downloads
Documents
Desktop
Pictures
```

## Logging

Windows Temp Cleaner keeps a small log containing information about the latest cleanup, such as:

* execution date
* number of files removed
* disk space freed

The previous log is overwritten on each execution, preventing logs from accumulating over time.

Because creating several megabytes of logs for a tool designed to remove unnecessary files would be slightly counterproductive.

## Uninstallation

Open PowerShell as Administrator and run:

```powershell
.\uninstall.ps1
```

This removes the scheduled task and the files installed by Windows Temp Cleaner.

## Safety

This project intentionally uses a conservative cleanup strategy.

It:

* only targets known temporary directories
* ignores recently modified files
* skips locked or protected files
* does not recursively clean arbitrary user directories
* does not require third-party software

Even so, review the scripts before running them, especially in production or corporate environments.

Testing on a limited number of machines before a wider deployment is recommended.

## Requirements

* Windows 10 or Windows 11
* PowerShell 5.1 or newer
* Administrator privileges for installation and system-level cleanup

## Why?

Temporary files are easy to forget about and can accumulate over time.

This project exists because manually cleaning the same directories across multiple computers is repetitive work, and repetitive work is usually a decent excuse to automate something.

## License

This project is open source and available under the [MIT License](LICENSE).
