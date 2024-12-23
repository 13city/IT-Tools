<# 
.SYNOPSIS
  Cleans up temporary files, rotates logs, and checks disk space.

.DESCRIPTION
  This script:
  - Removes old temporary files.
  - Rotates Windows logs older than a certain age.
  - Checks available disk space.
  - Logs all actions to a central log file.

.NOTES
  Compatible with: Windows Server 2012 R2, 2016, 2019, 2022, Windows 10/11

.PARAMETER LogPath
  Directory where the script writes its log.

.EXAMPLE
  .\SystemCleanupAndMaintenance.ps1 -LogPath "C:\Logs"
#>

param (
    [string]$LogPath = "C:\Logs"
)

# Create log directory if missing
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath | Out-Null
}

$scriptName    = "SystemCleanupAndMaintenance"
$timeStamp     = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile       = Join-Path $LogPath "$scriptName-$timeStamp.log"

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $logEntry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

try {
    Write-Log "===== Starting System Cleanup & Maintenance Script ====="

    # 1. Clean up temp files
    $tempPaths = @($env:TEMP, "C:\Windows\Temp")
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            Write-Log "Cleaning temp folder: $path"
            Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Log "Temp folder not found: $path (Skipping)"
        }
    }

    # 2. Rotate old logs (older than 30 days)
    $logLocations = @("C:\Logs", "C:\inetpub\logs\LogFiles")
    foreach ($loc in $logLocations) {
        if (Test-Path $loc) {
            Write-Log "Rotating logs in $loc older than 30 days."
            Get-ChildItem -Path $loc -Recurse -Include *.log -ErrorAction SilentlyContinue | 
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | 
            Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }

    # 3. Check disk space
    $drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($drive in $drives) {
        $freeGB = [Math]::Round($drive.FreeSpace / 1GB, 2)
        $sizeGB = [Math]::Round($drive.Size / 1GB, 2)
        Write-Log "Drive $($drive.DeviceID) - Free: $freeGB GB / Total: $sizeGB GB"
        if ($freeGB -lt 5) {
            Write-Log "WARNING: Drive $($drive.DeviceID) has less than 5GB free."
        }
    }

    Write-Log "===== System Cleanup & Maintenance Completed Successfully ====="
} 
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
finally {
    # In Datto RMM, final exit codes can be captured to indicate success/failure
    exit 0
}
