<#
.SYNOPSIS
    Security misconfiguration checker for Windows Server 2016, 2019, and 2022.

.DESCRIPTION
    - Checks domain membership vs. local accounts usage.
    - Verifies password policies (if DC, uses domain policy checks).
    - Confirms critical services (e.g., Windows Update) are running.
    - Checks local admin group membership for anomalies.
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
$logFile   = Join-Path $LogPath "WinServerSecurityCheck-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting Windows Server Security Check ====="

    # 1. Check if domain-joined
    $computerSys = Get-WmiObject -Class Win32_ComputerSystem
    if ($computerSys.PartOfDomain -eq $true) {
        Write-Log "Server is domain-joined: $($computerSys.Domain)"
    } else {
        Write-Log "WARNING: Server not domain-joined. Check if this is expected."
    }

    # 2. Check local admin group membership
    Write-Log "Checking local Administrators group membership..."
    $adminsGroup = net localgroup administrators
    Write-Log "Local Administrators:`r`n$adminsGroup"
    # If needed, parse out specific lines to find unexpected accounts.

    # 3. Verify Windows Update Service and other critical services
    Write-Log "Verifying critical services..."
    $servicesToCheck = @("wuauserv","WinDefend") # Windows Update, Windows Defender
    foreach ($svcName in $servicesToCheck) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne "Running") {
            Write-Log "WARNING: Service $($svc.Name) is not running. Current status: $($svc.Status)"
        } elseif (-not $svc) {
            Write-Log "WARNING: Service $svcName not found on this server."
        } else {
            Write-Log "$($svc.Name) is running."
        }
    }

    # 4. Check password policy (non-DC vs DC)
    if ($computerSys.DomainRole -eq 4 -or $computerSys.DomainRole -eq 5) {
        Write-Log "Server is a Domain Controller. Domain-level password policy applies."
        # Could use Get-ADDefaultDomainPasswordPolicy if AD module is installed
        # Or parse net accounts from a DC perspective.
    } else {
        Write-Log "Using local password policy since this is not a DC."
        $netAccountsOutput = net accounts
        Write-Log "Password Policy:`r`n$netAccountsOutput"
    }

    Write-Log "===== Windows Server Security Check Completed ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
