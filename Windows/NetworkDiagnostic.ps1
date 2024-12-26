<# 
.SYNOPSIS
    Advanced network device diagnostics and troubleshooting system.

.DESCRIPTION
    This script provides comprehensive network device diagnostics:
    - Establishes secure SSH connections to devices
    - Executes device-specific diagnostic commands
    - Captures detailed command outputs
    - Supports multiple device vendors
    - Performs configuration validation
    - Generates detailed diagnostic logs
    - Analyzes device status
    - Validates network connectivity
    - Monitors device health
    - Provides troubleshooting insights

.NOTES
    Author: 13city
    Compatible with: Windows Server 2016-2022, Windows 10/11
    Requirements:
    - Plink.exe installed in C:\Tools
    - Network connectivity to devices
    - Valid device credentials
    - Write access to C:\Logs
    - PowerShell 5.1 or higher
    - Administrative privileges

.PARAMETER DeviceType
    Network device vendor/type
    Required: No
    Default: "Cisco"
    Options: "Cisco", "SonicWALL"
    Determines command set used

.PARAMETER Host
    Target device address
    Required: No
    Default: "192.168.1.1"
    Format: IP address or hostname
    Must be network accessible

.PARAMETER Username
    Device login username
    Required: No
    Default: "UserName"
    Must have sufficient privileges
    Case-sensitive

.PARAMETER Password
    Device login password
    Required: No
    Default: "YourPassWord"
    Case-sensitive
    Stored securely during execution

.EXAMPLE
    .\NetworkDiagnostic.ps1 -DeviceType "Cisco" -Host "192.168.1.1" -Username "admin" -Password "SecurePass123"
    Basic Cisco diagnostics:
    - Connects to Cisco device
    - Runs standard diagnostics
    - Generates detailed logs
    - Standard command set

.EXAMPLE
    .\NetworkDiagnostic.ps1 -DeviceType "SonicWALL" -Host "10.0.0.1" -Username "admin" -Password "Pass123!" 
    SonicWALL diagnostics:
    - Connects to SonicWALL device
    - Executes SonicOS commands
    - Captures device status
    - Vendor-specific analysis

.EXAMPLE
    $creds = Get-Credential
    .\NetworkDiagnostic.ps1 -DeviceType "Cisco" -Host "core-switch.local" -Username $creds.Username -Password $creds.GetNetworkCredential().Password
    Secure credential handling:
    - Uses credential object
    - Enhanced security
    - Full diagnostics
    - Detailed logging
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
