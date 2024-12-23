<#
.SYNOPSIS
    Security misconfiguration checker for Windows 10/11 desktops.

.DESCRIPTION
    - Checks local account policies (password policy, lockout policy).
    - Verifies firewall status.
    - Reports if RDP is enabled.
    - Logs any findings to a text file.

.NOTES
    Execute via RMM or Task Scheduler
#>

param(
    [string]$LogPath = "C:\SecurityLogs"
)

if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath | Out-Null
}

$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile   = Join-Path $LogPath "WinDesktopSecurityCheck-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting Windows Desktop Security Check ====="

    # 1. Check Password Policy
    Write-Log "Checking Password Policy..."
    # Using net accounts to gather policy info (works on desktops).
    $netAccountsOutput = net accounts
    Write-Log "Password Policy Output:`r`n$netAccountsOutput"

    # 2. Check Local Account Lockout Policy
    Write-Log "Checking Lockout Policy..."
    # Typically also shown in net accounts or secpol.msc
    # net accounts includes "Lockout threshold" etc.
    # Additional checks can be added if needed.

    # 3. Check Firewall Status
    Write-Log "Checking Windows Firewall Status..."
    $firewallProfiles = "DomainProfile","PrivateProfile","PublicProfile"
    foreach ($profile in $firewallProfiles) {
        $status = (Get-NetFirewallProfile -Profile $profile).Enabled
        Write-Log "$profile Firewall Enabled: $status"
        if (-not $status) {
            Write-Log "WARNING: $profile firewall is disabled!"
        }
    }

    # 4. Check if RDP (Remote Desktop) is enabled
    Write-Log "Checking if RDP is enabled..."
    $rdpRegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    $fDenyTSConnections = Get-ItemPropertyValue -Path $rdpRegKey -Name "fDenyTSConnections" -ErrorAction SilentlyContinue
    if ($fDenyTSConnections -eq 0) {
        Write-Log "WARNING: RDP is enabled. Ensure it's required or restrict access."
    } else {
        Write-Log "RDP is disabled."
    }

    Write-Log "===== Windows Desktop Security Check Completed ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
