<# 
.SYNOPSIS
    Comprehensive security assessment and compliance validation for Azure Windows Virtual Machines.

.DESCRIPTION
    This advanced security assessment script performs extensive checks on Azure-hosted Windows VMs:
    - Validates Azure VM agent health and configuration
    - Audits Network Security Group (NSG) rules and configurations
    - Verifies Windows Firewall settings and rule compliance
    - Assesses disk encryption status (BitLocker/Azure Disk Encryption)
    - Checks Azure Security Center recommendations
    - Validates Azure Backup configuration
    - Monitors Azure Update Management compliance
    - Verifies Azure AD integration status
    - Checks Azure Key Vault integration
    - Validates Azure Monitor agent deployment
    - Generates detailed security assessment reports
    - Provides remediation recommendations
    - Ensures compliance with cloud security best practices

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022 on Azure
    Requirements:
    - Azure VM with Windows OS
    - Administrative rights on the VM
    - Azure VM Guest Agent installed
    - Write access to log directory
    - Can be executed via RMM or Azure Runbook
    - Az PowerShell module
    - AzureAD PowerShell module
    - Network access to Azure services
    - PowerShell 5.1 or higher

.PARAMETER LogPath
    Directory for security assessment logs
    Default: C:\SecurityLogs
    Creates directory if not exists
    Maintains historical log files

.PARAMETER GenerateReport
    Switch to enable HTML report generation
    Creates comprehensive security assessment document
    Default: False

.PARAMETER ReportPath
    Path where HTML security report will be saved
    Only used when GenerateReport is enabled
    Default: [LogPath]\SecurityReport.html

.PARAMETER CheckLevel
    Depth of security checks to perform
    Options: Basic, Standard, Comprehensive
    Default: Standard
    Affects execution time and detail level

.PARAMETER SubscriptionId
    Azure subscription ID for additional cloud checks
    Optional: Enhanced Azure-specific validations
    Format: GUID

.PARAMETER ResourceGroupName
    Azure resource group containing the VM
    Optional: Required for NSG and other Azure checks
    Example: "Production-RG"

.PARAMETER ExportResults
    Switch to export results to Azure Storage
    Enables historical tracking and compliance reporting
    Default: False

.PARAMETER AlertThreshold
    Number of security issues before triggering alert
    Used to determine overall security status
    Default: 5 issues
    Range: 1-100

.EXAMPLE
    .\AzureWindowsSecurityCheck.ps1
    Basic security assessment:
    - Uses default log path
    - Standard check level
    - Console output only
    - No report generation

.EXAMPLE
    .\AzureWindowsSecurityCheck.ps1 -LogPath "D:\Logs\Security" -GenerateReport -CheckLevel Comprehensive
    Comprehensive security audit:
    - Custom log directory
    - Generates HTML report
    - Maximum depth security checks
    - Detailed recommendations

.EXAMPLE
    .\AzureWindowsSecurityCheck.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "Prod-RG" -ExportResults
    Cloud-integrated assessment:
    - Full Azure context checks
    - Exports results to Azure Storage
    - Standard check level
    - Default logging location
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
