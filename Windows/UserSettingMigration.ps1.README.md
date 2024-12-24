# User Settings Migration Script

A PowerShell script for automating the migration of user settings, profiles, and preferences between Windows systems.

## Features

- Automated backup and restoration of user profiles
- Migration of application settings and preferences
- Support for common applications and Windows settings
- Detailed logging and validation
- Error handling and rollback capabilities

## Prerequisites

- Windows PowerShell 5.1 or higher
- Administrative privileges
- Network access to source and target systems
- Sufficient storage space for profile backups

## Parameters

```powershell
-SourceUser          # Source user profile name
-TargetUser          # Target user profile name
-SourceComputer      # Source computer name (default: local)
-TargetComputer      # Target computer name (default: local)
-IncludeAppData      # Switch to include AppData folders
-ExcludeFolders      # Array of folders to exclude
-BackupLocation      # Custom backup location path
-Validate            # Switch to perform validation checks
```

## Configuration

Create a configuration file named `UserSettingsMigration.config.json`:

```json
{
  "DefaultExclusions": [
    "AppData\\Local\\Temp",
    "AppData\\Local\\Microsoft\\Windows\\Temporary Internet Files"
  ],
  "ApplicationSettings": {
    "Office": true,
    "Chrome": true,
    "Firefox": true,
    "Outlook": true
  },
  "BackupRetention": 30,
  "CompressionLevel": "Optimal"
}
```

## Usage Examples

1. Basic profile migration:
```powershell
.\UserSettingMigration.ps1 -SourceUser "JohnDoe" -TargetUser "JDoe"
```

2. Remote system migration:
```powershell
.\UserSettingMigration.ps1 -SourceUser "JohnDoe" -SourceComputer "PC01" -TargetUser "JDoe" -TargetComputer "PC02"
```

3. Custom backup with specific exclusions:
```powershell
.\UserSettingMigration.ps1 -SourceUser "JohnDoe" -TargetUser "JDoe" -BackupLocation "D:\Backups" -ExcludeFolders @("Downloads", "Pictures")
```

## Error Handling

The script includes comprehensive error handling:
- Pre-migration validation checks
- Available space verification
- Network connectivity testing
- Permissions validation
- Automatic rollback on failure

## Logging

Logs are stored in:
```
C:\Windows\Logs\UserMigration\
```

Log files include:
- Migration operations
- Error messages
- Validation results
- Performance metrics
