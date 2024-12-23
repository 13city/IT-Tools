# SQL Database Health Manager

A comprehensive PowerShell script for managing SQL Server database health, performing maintenance tasks, and automating database rebuilds when necessary.

## Features

- Database corruption detection using DBCC CHECKDB
- Index fragmentation analysis and automatic rebuilding
- Backup schedule validation
- Performance metrics monitoring
- Automated maintenance tasks
- Email notifications for critical issues
- Detailed logging
- Support for multiple databases
- Online and offline index rebuilding capabilities
- Threshold-based maintenance triggers

## Requirements

- PowerShell 5.1 or later
- SqlServer PowerShell module
- SQL Server Management Studio (SSMS) or appropriate client tools
- SQL Server instance with appropriate permissions
- SMTP server for email notifications

## Prerequisites

1. Install the SqlServer module:
```powershell
Install-Module -Name SqlServer -Force -AllowClobber
```

2. SQL Server permissions:
- CONTROL SERVER permission
- db_owner on target databases
- VIEW SERVER STATE permission
- VIEW ANY DEFINITION permission

3. Configure email settings:
- SMTP server access
- Email account for sending notifications
- Distribution list or email address for receiving alerts

## Usage

### Basic Usage
```powershell
.\SQL-DatabaseHealthManager.ps1 -ServerInstance "SQLSERVER01" -DatabaseName "*" -EmailTo "dba@company.com" -EmailFrom "sql-alerts@company.com" -SmtpServer "smtp.company.com"
```

### Specific Database with Custom Threshold
```powershell
.\SQL-DatabaseHealthManager.ps1 -ServerInstance "SQLSERVER01" -DatabaseName "ProductionDB" -RebuildThreshold 20 -EmailTo "dba@company.com" -EmailFrom "sql-alerts@company.com" -SmtpServer "smtp.company.com"
```

### Custom Log Path
```powershell
.\SQL-DatabaseHealthManager.ps1 -ServerInstance "SQLSERVER01" -DatabaseName "*" -LogPath "D:\SQLLogs" -EmailTo "dba@company.com" -EmailFrom "sql-alerts@company.com" -SmtpServer "smtp.company.com"
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| ServerInstance | Yes | - | SQL Server instance name |
| DatabaseName | No | * | Target database name (use * for all databases) |
| EmailTo | Yes | - | Email address for notifications |
| EmailFrom | Yes | - | From email address for notifications |
| SmtpServer | Yes | - | SMTP server for sending notifications |
| RebuildThreshold | No | 30 | Fragmentation percentage threshold for index rebuild |
| LogPath | No | C:\Logs\SQL | Path for log files |

## Health Checks

The script performs the following health checks:

1. Database Corruption
   - Runs DBCC CHECKDB on each database
   - Verifies database integrity
   - Reports any corruption issues

2. Index Fragmentation
   - Analyzes index fragmentation levels
   - Identifies indexes above rebuild threshold
   - Performs online rebuild when possible
   - Falls back to offline rebuild if necessary

3. Backup Validation
   - Checks for recent full backups
   - Validates differential and log backups
   - Alerts on missing or old backups

## Notifications

The script sends email notifications for:
- Connection failures
- Database corruption detection
- High fragmentation levels
- Failed rebuild attempts
- Missing or failed backups
- Script execution errors

## Logging

- Detailed logs are created in the specified log path
- Timestamp-based log files
- Color-coded console output
- Different severity levels (INFO, WARNING, ERROR)

## Best Practices

1. Schedule regular runs:
   ```powershell
   # Example scheduled task creation
   $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\SQL-DatabaseHealthManager.ps1 -ServerInstance 'SQLSERVER01' -EmailTo 'dba@company.com' -EmailFrom 'sql-alerts@company.com' -SmtpServer 'smtp.company.com'"
   $trigger = New-ScheduledTaskTrigger -Daily -At 2am
   Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SQL Health Check" -Description "Daily SQL Server health check and maintenance"
   ```

2. Monitor log files regularly
3. Review and adjust RebuildThreshold based on performance requirements
4. Keep the SqlServer module updated
5. Maintain email notification distribution lists

## Error Handling

The script includes comprehensive error handling for:
- Connection failures
- Permission issues
- Failed database operations
- Email notification failures
- Logging errors

## Troubleshooting

1. Connection Issues:
   - Verify SQL Server instance name
   - Check network connectivity
   - Confirm SQL Server authentication

2. Permission Issues:
   - Verify SQL Server permissions
   - Check Windows authentication
   - Review SQL Server logs

3. Email Notification Issues:
   - Verify SMTP server settings
   - Check email addresses
   - Test SMTP connectivity

## Support

For issues and feature requests, please:
1. Check the error logs
2. Review SQL Server logs
3. Verify permissions
4. Contact your database administrator
