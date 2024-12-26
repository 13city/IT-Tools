<# 
.SYNOPSIS
    Advanced Intune and Windows management state analysis and remediation toolkit.

.DESCRIPTION
    This script provides comprehensive system management state analysis:
    - Validates drive ownership and permissions
    - Checks BitLocker encryption status
    - Verifies Intune enrollment state
    - Analyzes Azure AD join status
    - Examines provisioning packages
    - Tests drive write capabilities
    - Provides detailed logging
    - Suggests remediation steps
    - Monitors management extensions
    - Validates security configurations

.NOTES
    Author: 13city
    Compatible with: Windows 10/11, Windows Server 2016-2022
    Requirements:
    - Administrative rights
    - PowerShell 5.1 or higher
    - Write access to C:\Windows\Temp
    - Network connectivity for Azure AD checks
    - BitLocker PowerShell module
    - DISM capabilities

.PARAMETER None
    This script does not accept parameters but requires administrative privileges
    Automatically analyzes all fixed drives except C:
    Creates timestamped logs in C:\Windows\Temp

.EXAMPLE
    .\IntuneWindowsStateManagement.ps1
    Full system analysis:
    - Checks all non-system drives
    - Validates management state
    - Generates detailed report
    - Provides remediation steps

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File IntuneWindowsStateManagement.ps1
    Bypass execution run:
    - Ensures script execution
    - Full system analysis
    - Comprehensive logging
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

# Error handling and logging setup
$ErrorActionPreference = "Continue"
$logFile = "C:\Windows\Temp\management_check_$(Get-Date -Format 'yyyy-MM-dd-HH-mm').log"

function Write-LogMessage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-DriveOwnershipStatus {
    param (
        [string]$driveLetter
    )
    
    try {
        $acl = Get-Acl "${driveLetter}:\"
        Write-LogMessage "Drive $driveLetter ownership: $($acl.Owner)"
        
        # Check if Administrators have full control
        $adminAccess = $acl.Access | Where-Object { $_.IdentityReference -like "*Administrators*" }
        if ($adminAccess) {
            Write-LogMessage "Administrators group has access rights: $($adminAccess.FileSystemRights)"
        } else {
            Write-LogMessage "WARNING: Administrators group not found in ACL" -Type "WARN"
        }
    } catch {
        Write-LogMessage "Error checking drive $driveLetter ownership: $_" -Type "ERROR"
    }
}

function Get-BitLockerStatus {
    param (
        [string]$driveLetter
    )
    
    try {
        $bitlockerStatus = Get-BitLockerVolume -MountPoint "${driveLetter}:"
        Write-LogMessage "BitLocker Status for drive $driveLetter`: $($bitlockerStatus.ProtectionStatus)"
        return $bitlockerStatus
    } catch {
        Write-LogMessage "Error checking BitLocker status: $_" -Type "ERROR"
    }
}

function Get-IntuneStatus {
    try {
        # Check MDM enrollment
        $mdmEnrollment = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Enrollments\" -ErrorAction SilentlyContinue
        
        if ($mdmEnrollment) {
            Write-LogMessage "Found MDM enrollment entries:" -Type "WARN"
            foreach ($entry in $mdmEnrollment) {
                Write-LogMessage "Enrollment: $($entry.PSChildName)" -Type "WARN"
            }
        } else {
            Write-LogMessage "No MDM enrollment entries found"
        }

        # Check for Intune Management Extension
        $intuneService = Get-Service -Name "IntuneManagementExtension" -ErrorAction SilentlyContinue
        if ($intuneService) {
            Write-LogMessage "Intune Management Extension service status: $($intuneService.Status)" -Type "WARN"
        } else {
            Write-LogMessage "Intune Management Extension service not found"
        }
    } catch {
        Write-LogMessage "Error checking Intune status: $_" -Type "ERROR"
    }
}

function Get-AzureADJoinStatus {
    try {
        $dsregStatus = dsregcmd /status
        $joinStatus = $dsregStatus | Select-String "AzureAdJoined|EnterpriseJoined"
        
        foreach ($status in $joinStatus) {
            Write-LogMessage $status
            if ($status -match "YES") {
                Write-LogMessage "Device still shows enterprise/Azure AD join status" -Type "WARN"
            }
        }
    } catch {
        Write-LogMessage "Error checking Azure AD join status: $_" -Type "ERROR"
    }
}

function Get-ProvisioningPackages {
    try {
        $packages = dism /online /get-provisioningpackages
        if ($packages -match "Provisioning package") {
            Write-LogMessage "Found provisioning packages:" -Type "WARN"
            Write-LogMessage $packages
        } else {
            Write-LogMessage "No provisioning packages found"
        }
    } catch {
        Write-LogMessage "Error checking provisioning packages: $_" -Type "ERROR"
    }
}

function Get-DriveWriteStatus {
    param (
        [string]$driveLetter
    )
    
    try {
        $testFile = "${driveLetter}:\write_test_$(Get-Random).tmp"
        [io.file]::OpenWrite($testFile).close()
        Remove-Item -Path $testFile -Force
        Write-LogMessage "Drive $driveLetter is writable"
    } catch {
        Write-LogMessage "Drive $driveLetter appears to be read-only or write-protected: $_" -Type "ERROR"
    }
}

# Main execution
Write-LogMessage "Starting management state check..."

if (-not (Test-AdminPrivileges)) {
    Write-LogMessage "This script requires administrator privileges to run properly" -Type "ERROR"
    exit 1
}

# Get all fixed drives except C:
$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -ne "C:" }

foreach ($drive in $drives) {
    $driveLetter = $drive.DeviceID.TrimEnd(":")
    Write-LogMessage "Checking drive $($drive.DeviceID)..."
    Get-DriveOwnershipStatus -driveLetter $driveLetter
    Get-BitLockerStatus -driveLetter $driveLetter
    Get-DriveWriteStatus -driveLetter $driveLetter
}

Get-IntuneStatus
Get-AzureADJoinStatus
Get-ProvisioningPackages

Write-LogMessage "Check complete. Log file saved to: $logFile"

# Output potential fixes if issues were found
Write-LogMessage "`nPotential fixes if issues were found:"
Write-LogMessage "1. To take ownership of a drive (run as admin):"
Write-LogMessage "   takeown /f D: /r /d y"
Write-LogMessage "   icacls D: /grant administrators:F /t"
Write-LogMessage "2. To remove provisioning packages, use:"
Write-LogMessage "   DISM /Online /Remove-ProvisioningPackage /PackageName:'package-name'"
Write-LogMessage "3. Check Group Policy and registry for persistent management policies"
Write-LogMessage "4. Consider using Windows Media Creation Tool for in-place upgrade if issues persist"
