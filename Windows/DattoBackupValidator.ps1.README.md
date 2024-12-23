# Datto Backup Validator

A comprehensive PowerShell script for validating Datto BCDR backups, performing test virtualizations, and ensuring backup integrity across your infrastructure.

## Features

- Validates all Datto BCDR devices and agents
- Performs automated test virtualizations
- Verifies backup integrity and age
- Sends notifications via email or Slack
- Generates detailed HTML reports
- Comprehensive logging
- Automated cleanup of test virtualizations

## Requirements

- PowerShell 5.1 or later
- Datto API access (API key and secret key)
- Network access to Datto API endpoints
- SMTP server (for email notifications)
- Slack webhook URL (for Slack notifications)

## Installation

1. Obtain Datto API credentials:
   - Log in to Datto Partner Portal
   - Navigate to Integrations > API
   - Generate API key and secret key

2. Configure permissions:
   - Ensure API access is enabled
   - Verify network connectivity to api.datto.com
   - Configure firewall rules if needed

3. Set up notification method:
   - Configure SMTP settings for email notifications
   - Or set up Slack webhook for Slack notifications

## Usage

### Basic Validation with Email Notifications
```powershell
.\DattoBackupValidator.ps1 `
    -DattoApiKey "your-api-key" `
    -DattoSecretKey "your-secret-key" `
    -NotificationMethod Email `
    -EmailTo "admin@company.com" `
    -EmailFrom "backup-alerts@company.com" `
    -SmtpServer "smtp.company.com"
```

### With Slack Notifications
```powershell
.\DattoBackupValidator.ps1 `
    -DattoApiKey "your-api-key" `
    -DattoSecretKey "your-secret-key" `
    -NotificationMethod Slack `
    -SlackWebhook "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### Disable Test Virtualizations
```powershell
.\DattoBackupValidator.ps1 `
    -DattoApiKey "your-api-key" `
    -DattoSecretKey "your-secret-key" `
    -NotificationMethod Email `
    -EmailTo "admin@company.com" `
    -TestVirtualizationEnabled $false
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| DattoApiKey | Yes | - | Datto API key |
| DattoSecretKey | Yes | - | Datto API secret key |
| NotificationMethod | Yes | - | Email or Slack |
| EmailTo | No* | - | Email recipients |
| EmailFrom | No* | - | From email address |
| SmtpServer | No* | - | SMTP server hostname |
| SlackWebhook | No* | - | Slack webhook URL |
| TestVirtualizationEnabled | No | $true | Enable test virtualizations |

*Required based on NotificationMethod

## Validation Checks

The script performs these validations:

1. Backup Status
   - Last successful backup time
   - Backup completion status
   - Error messages
   - Warning conditions

2. Test Virtualization (if enabled)
   - Automated virtualization in isolated network
   - VM startup verification
   - Basic functionality check
   - Automated cleanup

3. Backup Age
   - Identifies outdated backups (>24h)
   - Alerts on missed backup windows
   - Tracks backup frequency

## Notifications

Alerts are sent for:
- Failed backups
- Outdated backups
- Failed virtualizations
- API connection issues
- Script execution errors

## Reports

HTML reports include:
- Device and agent status
- Last backup times
- Virtualization test results
- Error details
- Warning conditions

## Logging

- Detailed logs in C:\Logs\DattoValidation
- Timestamp-based log files
- Color-coded console output
- Error tracking and reporting

## Best Practices

1. Schedule regular validation:
```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\DattoBackupValidator.ps1 -DattoApiKey 'key' -DattoSecretKey 'secret' -NotificationMethod Email -EmailTo 'admin@company.com'"
$trigger = New-ScheduledTaskTrigger -Daily -At 6AM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "DattoValidation" -Description "Daily Datto backup validation"
```

2. Monitor logs regularly
3. Keep API credentials secure
4. Review and adjust notification settings
5. Maintain email distribution lists

## Error Handling

The script includes comprehensive error handling for:
- API authentication failures
- Network connectivity issues
- Virtualization failures
- Resource constraints
- Notification delivery problems

## Troubleshooting

1. API Issues:
   - Verify API credentials
   - Check API endpoint accessibility
   - Review rate limits

2. Virtualization Failures:
   - Check resource availability
   - Verify network connectivity
   - Review Datto device logs

3. Notification Issues:
   - Verify SMTP/Slack settings
   - Test network connectivity
   - Check credentials

## Support

For issues and feature requests:
1. Check Datto portal status
2. Review script logs
3. Verify API access
4. Contact Datto support
