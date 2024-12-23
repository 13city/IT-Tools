# Windows Server Backup Validator

A comprehensive PowerShell script for validating Windows Server Backup jobs, performing test restores, and ensuring backup integrity.

## Features

- Validates Windows Server Backup status
- Performs backup integrity checks
- Executes test restores of random files
- Verifies restored file integrity
- Sends notifications via email or Slack
- Generates detailed HTML reports
- Comprehensive logging
- Automated cleanup of test restores

## Requirements

- PowerShell 5.1 or later
- Windows Server Backup feature installed
- Administrator privileges
- SMTP server (for email notifications)
- Slack webhook URL (for Slack notifications)

## Installation

1. Install Windows Server Backup feature:
```powershell
Install-WindowsFeature Windows-Server-Backup
```

2. Configure permissions:
   - Run as administrator
   - Ensure access to backup location
   - Configure test restore location

3. Set up notification method:
   - Configure SMTP settings for email notifications
   - Or set up Slack webhook for Slack notifications

## Usage

### Basic Validation with Email Notifications
```powershell
.\WindowsServerBackupValidator.ps1 `
    -BackupTarget "E:\Backups" `
    -NotificationMethod Email `
    -EmailTo "admin@company.com" `
    -EmailFrom "backup-alerts@company.com" `
    -SmtpServer "smtp.company.com"
```

### With Slack Notifications
```powershell
.\WindowsServerBackupValidator.ps1 `
    -BackupTarget "E:\Backups" `
    -NotificationMethod Slack `
    -SlackWebhook "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### Custom Test Restore Path
```powershell
.\WindowsServerBackupValidator.ps1 `
    -BackupTarget "E:\Backups" `
    -TestRestorePath "D:\TestRestore" `
    -NotificationMethod Email `
    -EmailTo "admin@company.com"
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| BackupTarget | Yes | - | Path to backup location |
| TestRestorePath | No | D:\TestRestore | Path for test restores |
| NotificationMethod | Yes | - | Email or Slack |
| EmailTo | No* | - | Email recipients |
| EmailFrom | No* | - | From email address |
| SmtpServer | No* | - | SMTP server hostname |
| SlackWebhook | No* | - | Slack webhook URL |
| TestRestoreEnabled | No | $true | Enable test restores |

*Required based on NotificationMethod

## Validation Checks

The script performs these validations:

1. Backup Status
   - Last successful backup time
   - Full and incremental backup times
   - Backup size
   - Age verification (>24h = outdated)

2. Integrity Check
   - Volume-level integrity verification
   - Backup set validation
   - Catalog consistency

3. Test Restore
   - Random file selection
   - Restore verification
   - File integrity validation
   - Automated cleanup

## Notifications

Alerts are sent for:
- Failed backups
- Outdated backups
- Integrity check failures
- Test restore failures
- Script execution errors

## Reports

HTML reports include:
- Backup status summary
- Integrity check results
- Test restore outcomes
- Error details
- Warning conditions

## Logging

- Detailed logs in C:\Logs\WSBValidation
- Timestamp-based log files
- Color-coded console output
- Error tracking and reporting

## Best Practices

1. Schedule regular validation:
```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\WindowsServerBackupValidator.ps1 -BackupTarget 'E:\Backups' -NotificationMethod Email -EmailTo 'admin@company.com'"
$trigger = New-ScheduledTaskTrigger -Daily -At 6AM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "WSBValidation" -Description "Daily Windows Server Backup validation"
```

2. Monitor logs regularly
3. Keep sufficient space for test restores
4. Review and adjust notification settings
5. Maintain email distribution lists

## Error Handling

The script includes comprehensive error handling for:
- Backup access failures
- Integrity check errors
- Test restore failures
- Disk space issues
- Notification delivery problems

## Troubleshooting

1. Backup Access Issues:
   - Verify backup location accessibility
   - Check permissions
   - Review Windows Server Backup logs

2. Test Restore Failures:
   - Check available disk space
   - Verify test restore path permissions
   - Review file selection criteria

3. Notification Issues:
   - Verify SMTP/Slack settings
   - Test network connectivity
   - Check credentials

## Support

For issues and feature requests:
1. Check Windows Server Backup logs
2. Review script logs
3. Verify permissions
4. Contact system administrator
