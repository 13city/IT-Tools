<#
.SYNOPSIS
   Checks for specific hotfixes on remote servers and optionally installs them.

.DESCRIPTION
   - Queries WMI for installed hotfixes on multiple servers.
   - Compares against a required list of KBs.
   - Creates a compliance report.
   - Can optionally attempt to install missing hotfixes (requires a path or WSUS approach).

.NOTES
   Requires: PSRemoting, valid credentials
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
