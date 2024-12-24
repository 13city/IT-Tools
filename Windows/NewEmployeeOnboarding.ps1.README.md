# New Employee Onboarding Script

A PowerShell script that automates the new employee onboarding process, including account creation, permissions setup, and resource provisioning.

## Features

- Active Directory account creation
- Microsoft 365 license assignment
- Security group membership management
- File share permissions setup
- Software installation automation
- Email configuration
- Resource provisioning tracking

## Prerequisites

- Windows PowerShell 5.1 or higher
- Active Directory PowerShell module
- Microsoft 365 PowerShell modules
- Administrative privileges
- Required licenses and resources available

## Parameters

```powershell
-EmployeeName       # Full name of the new employee
-Department         # Department name
-Title             # Job title
-Manager           # Manager's username
-Location          # Office location
-StartDate         # Employment start date
-LicenseType       # M365 license type
-CustomGroups      # Additional security groups
```

## Configuration

Create a configuration file named `OnboardingConfig.json`:

```json
{
  "DefaultGroups": [
    "All Users",
    "VPN Users",
    "Cloud Storage"
  ],
  "SoftwarePackages": {
    "Office365": true,
    "Zoom": true,
    "Chrome": true
  },
  "FileShares": [
    "\\\\server\\department",
    "\\\\server\\common"
  ],
  "EmailSettings": {
    "AutoReplyEnabled": false,
    "SignatureTemplate": "templates\\signature.html",
    "MailboxQuota": 50
  }
}
```

## Usage Examples

1. Basic onboarding:
```powershell
.\NewEmployeeOnboarding.ps1 -EmployeeName "John Doe" -Department "IT" -Title "Systems Engineer" -Manager "jsmith"
```

2. Onboarding with custom options:
```powershell
.\NewEmployeeOnboarding.ps1 -EmployeeName "Jane Smith" -Department "Sales" -Title "Account Manager" -Manager "rwilson" -LicenseType "E3" -CustomGroups @("Sales Team", "CRM Users")
```

3. Scheduled onboarding:
```powershell
.\NewEmployeeOnboarding.ps1 -EmployeeName "Mike Johnson" -Department "HR" -Title "HR Specialist" -StartDate "2024-01-15" -Location "NYC"
```

## Validation Checks

The script performs various validation checks:
- License availability
- Group existence
- Manager validation
- Resource availability
- Naming convention compliance

## Logging

Logs are stored in:
```
C:\Windows\Logs\Onboarding\
```

Log files include:
- Account creation details
- License assignments
- Group memberships
- Resource provisioning status
- Error messages
