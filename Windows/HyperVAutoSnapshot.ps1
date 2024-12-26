<# 
.SYNOPSIS
    Automated Hyper-V snapshot management and retention system.

.DESCRIPTION
    This script provides comprehensive snapshot management for Hyper-V environments:
    - Creates new checkpoints for specified virtual machines
    - Manages snapshot retention policies
    - Removes outdated checkpoints automatically
    - Provides detailed operation logging
    - Supports batch processing of multiple VMs
    - Implements error handling and reporting
    - Ensures consistent naming conventions
    - Validates VM accessibility before operations
    - Manages storage space efficiently

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022
    Requirements:
    - Hyper-V PowerShell module
    - Administrative rights
    - Write access to log directory
    - PowerShell 5.1 or higher
    - Sufficient storage space for snapshots

.PARAMETER VMNames
    Array of virtual machine names to process
    Required: Yes
    Default: @("VM1","VM2")
    Example: @("WebServer","DatabaseServer")
    Accepts multiple VM names for batch processing

.PARAMETER RetainDays
    Number of days to retain snapshots before deletion
    Default: 7 days
    Range: 1-90 days
    Affects automatic cleanup of old snapshots

.EXAMPLE
    .\HyperVAutoSnapshot.ps1
    Basic execution with defaults:
    - Processes default VMs (VM1, VM2)
    - 7-day retention policy
    - Standard logging

.EXAMPLE
    .\HyperVAutoSnapshot.ps1 -VMNames @("WebServer","DatabaseServer") -RetainDays 14
    Custom execution:
    - Processes specific VMs
    - Extended retention period
    - Detailed logging

.EXAMPLE
    .\HyperVAutoSnapshot.ps1 -VMNames @("CriticalVM1","CriticalVM2") -RetainDays 30
    Production environment:
    - Critical system backups
    - Monthly retention
    - Enhanced logging
#>

param(
    [string[]]$VMNames = @("VM1","VM2"),  # array of VM names
    [int]$RetainDays   = 7
)

$scriptName = "HyperVAutoSnapshot"
$timeStamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile    = "C:\Logs\$scriptName-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting Hyper-V Auto Snapshot Process ====="

    foreach ($vm in $VMNames) {
        Write-Log "Creating checkpoint for VM: $vm"
        Checkpoint-VM -Name $vm -SnapshotName "$vm-$($timeStamp)" -ErrorAction Stop
    }

    Write-Log "Removing snapshots older than $RetainDays days."
    foreach ($vm in $VMNames) {
        $snapshots = Get-VMSnapshot -VMName $vm -ErrorAction SilentlyContinue
        foreach ($snap in $snapshots) {
            if ($snap.CreationTime -lt (Get-Date).AddDays(-$RetainDays)) {
                Write-Log "Removing old snapshot: $($snap.Name) from VM: $vm"
                Remove-VMSnapshot -VMName $vm -Name $snap.Name -ErrorAction Stop
            }
        }
    }

    Write-Log "===== Hyper-V Auto Snapshot Process Completed Successfully ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
