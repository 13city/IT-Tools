# Microsoft 365 Mailbox Permission Audit Script

## Overview
This PowerShell script performs a comprehensive audit of Microsoft 365 mailbox permissions using the Microsoft Graph API. It generates detailed reports of mailbox access rights, including Full Access permissions, Send As rights, and Send on Behalf delegations.

## Features
- Uses modern Microsoft Graph API for all operations
- Supports both user and shared mailbox auditing
- Implements efficient pagination for large environments
- Provides detailed logging and error handling
- Generates CSV reports with permission mappings
- Handles cross-domain permissions
- Supports bulk permission analysis

## Requirements
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher
- Microsoft.Graph PowerShell modules:
  * Microsoft.Graph.Users
  * Microsoft.Graph.Users.Actions
  * Microsoft.Graph.Mail
- Microsoft 365 Global Admin or Exchange Admin privileges
- .NET Framework 4.7.1 or later
- TLS 1.2 or higher

## Installation
1. Ensure you have the required PowerShell modules installed:
```powershell
Install-Module -Name Microsoft.Graph.Users
Install-Module -Name Microsoft.Graph.Users.Actions
Install-Module -Name Microsoft.Graph.Mail
```

2. Download the script to your preferred location

## Usage
```powershell
# Run with default settings (saves report to C:\Logs\MailboxPerms.csv)
.\M365MailboxPermissionAudit.ps1

# Run with custom report path
.\M365MailboxPermissionAudit.ps1 -ReportPath "D:\Reports\MailboxAudit.csv"
```

## Output
The script generates a CSV report containing:
- Mailbox identifier
- Permission type (FullAccess, SendAs, SendOnBehalf)
- Granted to user/group
- Inheritance status

## Notes
- The script automatically creates the report directory if it doesn't exist
- Uses modern authentication with Microsoft Graph
- Implements best practices for large-scale permission auditing
- Provides detailed progress tracking during execution

## Author
13city

## Version
3.0

## Last Updated
2024-01-20
