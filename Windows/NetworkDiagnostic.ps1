<# 
.SYNOPSIS
  Automated network diagnostic for Cisco or SonicWALL devices using SSH.

.DESCRIPTION
  - Uses Plink (PuTTY command-line) to run commands.
  - Captures outputs for analysis.
#>

param(
    [string]$DeviceType = "Cisco",  # Cisco or SonicWALL
    [string]$Host       = "192.168.1.1",
    [string]$Username   = "UserName",
    [string]$Password   = "YourPassWord"
)

$scriptName = "NetworkDiagnostic"
$timeStamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile    = "C:\Logs\$scriptName-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting Network Diagnostic ($DeviceType) on $Host ====="

    $plinkPath = "C:\Tools\plink.exe"  # Ensure Plink is installed in this directory
    if (!(Test-Path $plinkPath)) {
        Write-Log "ERROR: Plink not found at $plinkPath. Cannot proceed."
        exit 1
    }

    switch ($DeviceType) {
        "Cisco" {
            $commands = @(
                "terminal length 0",
                "show version",
                "show ip interface brief",
                "show running-config | i route|ip route",
                "show log | last 50"
            )
        }
        "SonicWALL" {
            # Example commands may differ depending on SonicOS version
            $commands = @(
                "show status",
                "show network",
                "show log tail 50"
            )
        }
        Default {
            Write-Log "Unknown device type specified: $DeviceType"
            exit 1
        }
    }

    foreach ($cmd in $commands) {
        Write-Log "Running command: $cmd"
        $output = & $plinkPath -ssh $Host -l $Username -pw $Password -batch $cmd
        $output | Out-File -Append $logFile
    }

    Write-Log "===== Network Diagnostic Completed Successfully ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
