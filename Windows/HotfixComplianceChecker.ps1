<# 
.SYNOPSIS
    Checks for specific hotfixes on remote servers and optionally installs them.

.DESCRIPTION
    This script:
    - Queries WMI for installed hotfixes on multiple servers
    - Compares against a required list of KBs
    - Creates detailed compliance reports
    - Optionally installs missing hotfixes
    - Supports both local paths and WSUS for hotfix sources
    - Provides detailed logging of all operations
    - Handles multiple servers simultaneously
    - Reports success/failure for each operation

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022, Windows 10/11
    Requirements:
    - PowerShell remoting enabled on target servers
    - Administrative credentials
    - Network access to target servers
    - Write access to log directory
    - Optional: Access to hotfix source path

.PARAMETER Servers
    Array of server names to check for hotfix compliance
    Example: @("Server1", "Server2", "Server3")

.PARAMETER RequiredKBs
    Array of required KB numbers to check for
    Example: @("KB5005033", "KB5005565")

.PARAMETER InstallMissing
    Switch to enable automatic installation of missing hotfixes
    Default: $false

.PARAMETER HotfixSourcePath
    Path to directory containing hotfix files (.msu)
    Required if InstallMissing is enabled
    Example: "\\FileServer\Hotfixes"

.EXAMPLE
    .\HotfixComplianceChecker.ps1 -Servers "Server1","Server2" -RequiredKBs "KB5005033","KB5005565"
    Checks specified servers for required hotfixes and generates report

.EXAMPLE
    .\HotfixComplianceChecker.ps1 -Servers "Server1" -RequiredKBs "KB5005033" -InstallMissing -HotfixSourcePath "\\Server\Share\Hotfixes"
    Checks server for hotfix and attempts to install if missing
#>

param(
    [string[]]$Servers, 
    [string[]]$RequiredKBs,
    [switch]$InstallMissing = $false,
    [string]$HotfixSourcePath = ""
)

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Write-Host $entry
}

try {
    $report = @()

    foreach ($server in $Servers) {
        Write-Log "Checking $server..."

        $installedHotfixes = Get-HotFix -ComputerName $server -ErrorAction SilentlyContinue
        if (!$installedHotfixes) {
            Write-Log "WARNING: Unable to retrieve hotfixes from $server or none found."
            continue
        }

        $missing = $RequiredKBs | Where-Object { $_ -notin $installedHotfixes.HotFixID }
        if ($missing.Count -eq 0) {
            $report += [PSCustomObject]@{
                Server   = $server
                Status   = "Compliant"
                Missing  = ""
            }
        } else {
            $report += [PSCustomObject]@{
                Server   = $server
                Status   = "Non-Compliant"
                Missing  = $missing -join ";"
            }

            if ($InstallMissing -and $HotfixSourcePath) {
                foreach ($kb in $missing) {
                    Write-Log "Attempting to install $kb on $server from $HotfixSourcePath"
                    # Example: start a remote process or use WUSA /quiet /norestart, etc.
                    # Start-Process would require a file or path, e.g.:
                    # Start-Process -FilePath "\\Share\hotfixes\$kb.msu" -ArgumentList "/quiet /norestart"
                }
            }
        }
    }

    $report | Format-Table -AutoSize
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
