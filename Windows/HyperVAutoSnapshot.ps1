<# 
.SYNOPSIS
  Creates a snapshot (Checkpoint) for specified Hyper-V VMs, then removes old snapshots older than X days.

.DESCRIPTION
  Helps maintain up-to-date checkpoints, ensuring short-term rollback options.

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
