# Veeam Backup Validator

A comprehensive PowerShell script for validating Veeam backups, performing test restores, and ensuring backup integrity across your infrastructure.

## Features

- Validates all Veeam backup jobs
- Performs automated test restores in sandbox environment
- Verifies restored VM functionality
- Sends notifications via email or Slack
- Generates detailed HTML reports
- Comprehensive logging
- Automated cleanup of test VMs

## Requirements

- PowerShell 5.1 or later
- Veeam Backup & Replication 10.0 or later
- Veeam.Backup.PowerShell module
- Administrator access to Veeam server
- Hypervisor access for test restores
- SMTP server (for email notifications)
- Slack webhook URL (for Slack notifications)

## Installation

1. Install required PowerShell module:
```powershell
Install-Module -Name Veeam.Backup.PowerShell -Force
```

2. Configure permissions:
   - Veeam administrator access
   - Hypervisor permissions for test restores
   - Network access for notifications

3. Set up isolated network for test restores:
   - Create dedicated network switch
   - Configure appropriate VLAN if needed
   - Ensure no production network access

## Usage

### Basic Validation
```powershell
.\VeeamBackupValidator.ps1 -VBRServer "veeam-01" `
    -NotificationMethod Email `
    -EmailTo "admin@company.com" `
    -EmailFrom "veeam-alerts@company.com" `
    -SmtpServer "smtp.company.com"
```

### With Slack Notifications
```powershell
.\VeeamBackupValidator.ps1 -VBRServer "veeam-01" `
    -NotificationMethod Slack `
    -SlackWebhook "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### Disable Test Restores
```powershell
.\VeeamBackupValidator.ps1 -VBRServer "veeam-01" `
    -NotificationMethod Email `
    -EmailTo "admin@company.com" `
    -TestRestoreEnabled $false
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| VBRServer | Yes | - | Veeam B&R server hostname |
| Credential | No | Prompt | Credentials for authentication |
| NotificationMethod | Yes | - | Email or Slack |
| EmailTo | No* | - | Email recipients |
| EmailFrom | No* | - | From email address |
| SmtpServer | No* | - | SMTP server hostname |
| SlackWebhook | No* | - | Slack webhook URL |
| TestRestoreEnabled | No | $true | Enable test restores |
| SandboxNetwork | No | "Isolated" | Network for test VMs |

*Required based on NotificationMethod

## Validation Checks

The script performs these validations:

1. Backup Job Status
   - Last successful backup time
   - Job completion status
   - Error messages
   - Warning conditions

2. Test Restore (if enabled)
   - Restore to isolated environment
   - VM power-on verification
   - Basic functionality check
   - Automated cleanup

3. Backup Age
   - Identifies outdated backups (>24h)
   - Alerts on missed backup windows
   - Tracks backup frequency

## Notifications

Alerts are sent for:
- Failed backup jobs
- Outdated backups
- Failed test restores
- Connection issues
- Script execution errors

## Reports

HTML reports include:
- Job status summary
- Last backup times
- Test restore results
- Error details
- Warning conditions

## Logging

- Detailed logs in C:\Logs\VeeamValidation
- Timestamp-based log files
- Color-coded console output
- Error tracking and reporting

## Best Practices

1. Schedule regular validation:
```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\VeeamBackupValidator.ps1 -VBRServer 'veeam-01' -NotificationMethod Email -EmailTo 'admin@company.com'"
$trigger = New-ScheduledTaskTrigger -Daily -At 6AM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "VeeamValidation" -Description "Daily Veeam backup validation"
```

2. Monitor logs regularly
3. Maintain isolated network for test restores
4. Keep Veeam PowerShell module updated
5. Review and adjust notification settings

## Error Handling

The script includes comprehensive error handling for:
- Connection failures
- Authentication issues
- Restore failures
- Network problems
- Resource constraints

## Troubleshooting

1. Connection Issues:
   - Verify Veeam server accessibility
   - Check credentials
   - Confirm PowerShell module installation

2. Test Restore Failures:
   - Verify sandbox network configuration
   - Check available resources
   - Review Veeam server logs

3. Notification Issues:
   - Verify SMTP/Slack settings
   - Test network connectivity
   - Check credentials

## Support

For issues and feature requests:
1. Check Veeam server logs
2. Review script logs
3. Verify permissions
4. Contact your Veeam administrator
