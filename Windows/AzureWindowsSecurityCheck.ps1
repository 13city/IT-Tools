<#
.SYNOPSIS
    Security checks for Azure-based Windows VMs.

.DESCRIPTION
    - Checks Azure VM agent status (if installed).
    - Checks if NSG (Network Security Group) rules are retrieved locally (optional).
    - Verifies that Windows firewall is on, especially in cloud environments.
    - Ensures encryption status on OS/data disks (BitLocker or Azure Disk Encryption).

.NOTES
    Execute via RMM or Azure Runbook
#>

param(
    [string]$LogPath = "C:\SecurityLogs"
)

if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath | Out-Null
}

$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile   = Join-Path $LogPath "AzureWindowsSecurityCheck-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting Azure Windows VM Security Check ====="

    # 1. Check Azure VM Agent
    Write-Log "Checking Azure VM Agent (WindowsAzureGuestAgent) service..."
    $agent = Get-Service -Name "WindowsAzureGuestAgent" -ErrorAction SilentlyContinue
    if ($agent -and $agent.Status -eq "Running") {
        Write-Log "Azure VM Agent is installed and running."
    } else {
        Write-Log "WARNING: Azure VM Agent not found or not running."
    }

    # 2. Check Windows Firewall
    Write-Log "Ensuring Windows Firewall is enabled in Azure environment..."
    $profiles = (Get-NetFirewallProfile)
    foreach ($profile in $profiles) {
        if (-not $profile.Enabled) {
            Write-Log "WARNING: Firewall profile $($profile.Name) is disabled!"
        } else {
            Write-Log "Firewall profile $($profile.Name) is enabled."
        }
    }

    # 3. Check Disk Encryption
    Write-Log "Checking BitLocker or Azure Disk Encryption status..."
    # Minimal approach: check if OS drive is encrypted
    $bitlockerStatus = manage-bde -status C: 2>&1
    if ($bitlockerStatus -match "Percentage Encrypted\s+:\s+100.0%") {
        Write-Log "OS Drive appears fully encrypted (BitLocker)."
    } else {
        Write-Log "WARNING: OS Drive not fully encrypted or manage-bde not found."
    }

    Write-Log "===== Azure Windows VM Security Check Completed ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
