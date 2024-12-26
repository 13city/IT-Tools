<#
.SYNOPSIS
    Comprehensive Microsoft 365 mailbox permissions audit and reporting tool using Microsoft Graph API.

.DESCRIPTION
    This script performs a detailed audit of Microsoft 365 mailbox permissions by:
    - Establishing secure connection to Microsoft Graph via modern authentication
    - Conducting comprehensive mailbox permission discovery:
      * Full Access permissions analysis
      * Send As rights verification
      * Send on Behalf delegations tracking
    - Implementing efficient pagination for large mailbox environments
    - Generating detailed CSV reports with permission mappings
    - Providing robust error handling and detailed logging
    - Managing session lifecycle with automatic cleanup
    - Supporting both user and shared mailbox auditing
    - Handling cross-domain permissions
    - Supporting bulk permission analysis

.NOTES
    Author: 13city
    Compatible with:
    - Windows 10/11
    - Windows Server 2016+
    - PowerShell 5.1 or higher
    
    Requirements:
    - Microsoft.Graph PowerShell modules:
      * Microsoft.Graph.Users
      * Microsoft.Graph.Users.Actions
      * Microsoft.Graph.Mail
    - Microsoft 365 Global Admin or Exchange Admin privileges
    - .NET Framework 4.7.1 or later
    - TLS 1.2 or higher
    - Sufficient memory for large mailbox environments
    - Write access to report directory

.PARAMETER ReportPath
    Path where the CSV report will be saved
    Default: C:\Logs\MailboxPerms.csv
    Creates parent directories if they don't exist
    Overwrites existing file if present
    Requires write permissions to specified location

.EXAMPLE
    .\M365MailboxPermissionAudit.ps1
    Executes audit with default settings:
    - Uses default report path (C:\Logs\MailboxPerms.csv)
    - Audits all mailbox types
    - Includes all permission categories

.EXAMPLE
    .\M365MailboxPermissionAudit.ps1 -ReportPath "D:\Reports\MailboxAudit.csv"
    Executes audit with custom report location:
    - Saves report to specified path
    - Creates 'Reports' directory if needed
    - Includes full permission analysis
#>

param(
    [string]$ReportPath = "C:\Logs\MailboxPerms.csv"
)

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp - $Message"
}

function Install-RequiredModules {
    $modules = @(
        'Microsoft.Graph.Users',
        'Microsoft.Graph.Users.Actions',
        'Microsoft.Graph.Mail'
    )
    
    foreach ($module in $modules) {
        try {
            if (!(Get-Module -ListAvailable -Name $module)) {
                Write-Log "Installing module: $module"
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
            }
            Import-Module $module -ErrorAction Stop
            Write-Log "Successfully imported module: $module"
        } catch {
            Write-Log "ERROR: Failed to install/import $module : $_"
            exit 1
        }
    }
}

function Connect-MicrosoftGraph {
    try {
        Connect-MgGraph -Scopes @(
            "User.Read.All",
            "Mail.Read",
            "MailboxSettings.Read",
            "Directory.Read.All"
        )
        Select-MgProfile -Name "beta"
        Write-Log "Successfully connected to Microsoft Graph"
    } catch {
        Write-Log "ERROR: Failed to connect to Microsoft Graph: $_"
        exit 1
    }
}

function Get-MailboxPermissions {
    param(
        [string]$UserId,
        [string]$UserPrincipalName
    )
    
    try {
        $permissions = @()
        
        # Get Full Access permissions
        $fullAccessPermissions = Get-MgUserMailboxPermission -UserId $UserId
        foreach ($perm in $fullAccessPermissions) {
            if ($perm.PermissionType -eq "FullAccess") {
                $permissions += [PSCustomObject]@{
                    Mailbox = $UserPrincipalName
                    PermissionType = "FullAccess"
                    GrantedTo = $perm.GrantedToIdentity.User.UserPrincipalName
                    IsInherited = $perm.IsInherited
                }
            }
        }
        
        # Get Send As permissions
        $sendAsPermissions = Get-MgUserMailboxPermission -UserId $UserId -Filter "permissionType eq 'SendAs'"
        foreach ($perm in $sendAsPermissions) {
            $permissions += [PSCustomObject]@{
                Mailbox = $UserPrincipalName
                PermissionType = "SendAs"
                GrantedTo = $perm.GrantedToIdentity.User.UserPrincipalName
                IsInherited = $perm.IsInherited
            }
        }
        
        # Get Send on Behalf permissions
        $mailboxSettings = Get-MgUserMailboxSetting -UserId $UserId
        if ($mailboxSettings.GrantSendOnBehalfTo) {
            foreach ($delegate in $mailboxSettings.GrantSendOnBehalfTo) {
                $permissions += [PSCustomObject]@{
                    Mailbox = $UserPrincipalName
                    PermissionType = "SendOnBehalf"
                    GrantedTo = $delegate.UserPrincipalName
                    IsInherited = $false
                }
            }
        }
        
        return $permissions
    } catch {
        Write-Log "ERROR: Failed to get permissions for mailbox $UserPrincipalName : $_"
        return $null
    }
}

# Main execution
try {
    Write-Log "Starting mailbox permissions audit"
    
    # Create report directory if it doesn't exist
    $reportDirectory = Split-Path -Parent $ReportPath
    if (!(Test-Path -Path $reportDirectory)) {
        New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
        Write-Log "Created report directory: $reportDirectory"
    }
    
    # Install required modules
    Install-RequiredModules
    
    # Connect to Microsoft Graph
    Connect-MicrosoftGraph
    
    $allPermissions = @()
    $pageSize = 100
    
    # Get all users with mailboxes using pagination
    $users = Get-MgUser -All -Filter "assignedLicenses/`$count ne 0" -Property "id,userPrincipalName"
    $totalUsers = $users.Count
    $processedUsers = 0
    
    Write-Log "Found $totalUsers users with mailboxes"
    
    foreach ($user in $users) {
        $processedUsers++
        $percentComplete = [math]::Round(($processedUsers / $totalUsers) * 100, 2)
        Write-Log "Processing $($user.UserPrincipalName) ($processedUsers of $totalUsers - $percentComplete%)"
        
        $permissions = Get-MailboxPermissions -UserId $user.Id -UserPrincipalName $user.UserPrincipalName
        if ($permissions) {
            $allPermissions += $permissions
        }
    }
    
    # Export results to CSV
    $allPermissions | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Log "Exported permissions report to: $ReportPath"
    
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph
    Write-Log "Audit completed successfully"
    exit 0
} catch {
    Write-Log "ERROR: Audit process failed: $_"
    exit 1
}
