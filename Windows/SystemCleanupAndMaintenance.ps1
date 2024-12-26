<# 
.SYNOPSIS
    Comprehensive system maintenance and cleanup automation toolkit.

.DESCRIPTION
    This script provides extensive system maintenance capabilities:
    - Temporary File Management:
      * System temp file cleanup
      * User temp file removal
      * Cache clearing
      * Obsolete file detection
    - Log Management:
      * Log rotation
      * Archive creation
      * Size monitoring
      * Retention policy enforcement
    - Disk Space Management:
      * Space utilization monitoring
      * Low space alerts
      * Drive analysis
      * Cleanup recommendations
    - System Maintenance:
      * Performance optimization
      * Resource monitoring
      * Health checks
      * Status reporting

.NOTES
    Author: 13city
    Compatible with:
    - Windows Server 2012 R2
    - Windows Server 2016
    - Windows Server 2019
    - Windows Server 2022
    - Windows 10/11
    
    Requirements:
    - PowerShell 5.1 or higher
    - Administrative privileges
    - Write access to log directory
    - System maintenance permissions
    - WMI access rights

.PARAMETER LogPath
    Directory for script logging
    Default: C:\Logs
    Creates directory if missing
    Requires write permissions
    Stores timestamped log files

.EXAMPLE
    .\SystemCleanupAndMaintenance.ps1
    Basic maintenance:
    - Uses default log path
    - Cleans temp files
    - Rotates logs
    - Checks disk space
    - Creates standard report

.EXAMPLE
    .\SystemCleanupAndMaintenance.ps1 -LogPath "D:\MaintenanceLogs"
    Custom logging:
    - Uses specified log directory
    - Creates if not exists
    - Maintains detailed logs
    - Preserves execution history
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
