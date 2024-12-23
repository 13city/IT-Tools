# SqlServerDatabaseManager.ps1

### Purpose
Automates SQL Server database management tasks including backup, restoration, maintenance, and monitoring. This script provides comprehensive database administration capabilities for SQL Server instances.

### Features
- Automated database backups
- Database restoration
- Index maintenance
- Performance monitoring
- User management
- Always On availability groups management
- Storage management
- Database statistics collection
- Query performance optimization

### Requirements
- SQL Server 2016 or later
- PowerShell 5.1 or later
- SQL Server PowerShell module
- SQL Server Management Studio (optional)
- Appropriate SQL Server permissions
- Sufficient disk space for backups

### Usage
```powershell
.\SqlServerDatabaseManager.ps1 -Operation <operation> [parameters]

Operations:
  Backup       Create database backup
  Restore      Restore from backup
  Maintain     Run maintenance tasks
  Monitor      Show database statistics
  Index        Manage indexes
  Users        Manage database users
  AlwaysOn     Manage availability groups
```

### Common Operations

1. **Backup Management**
   ```powershell
   # Full database backup
   .\SqlServerDatabaseManager.ps1 -Operation Backup -Type Full -Database All
   
   # Single database backup
   .\SqlServerDatabaseManager.ps1 -Operation Backup -Type Full -Database "DatabaseName"
   
   # Transaction log backup
   .\SqlServerDatabaseManager.ps1 -Operation Backup -Type Log -Database "DatabaseName"
   ```

2. **Restore Operations**
   ```powershell
   # Full restore
   .\SqlServerDatabaseManager.ps1 -Operation Restore -Database "DatabaseName" -BackupFile "backup.bak"
   
   # Point-in-time restore
   .\SqlServerDatabaseManager.ps1 -Operation Restore -Database "DatabaseName" -PointInTime "2024-01-15T14:30:00"
   ```

3. **Maintenance Tasks**
   ```powershell
   # Index maintenance
   .\SqlServerDatabaseManager.ps1 -Operation Maintain -Task IndexOptimize
   
   # Statistics update
   .\SqlServerDatabaseManager.ps1 -Operation Maintain -Task UpdateStats
   ```

### Configuration
The script uses a JSON configuration file:
```json
{
    "SqlServer": {
        "Instance": "localhost",
        "Authentication": "Windows",
        "BackupPath": "D:\\SQLBackups",
        "RetentionDays": 30,
        "Compression": true
    },
    "Maintenance": {
        "IndexRebuildThreshold": 30,
        "UpdateStatsThreshold": 20,
        "CommandTimeout": 7200
    }
}
```

### Monitoring Features
- Database size tracking
- Performance counters
- Query performance metrics
- Blocking/deadlock detection
- Resource usage statistics
- Backup/restore progress
- Index fragmentation levels
- Buffer cache statistics

### Error Handling
- Validates SQL Server connectivity
- Checks backup space availability
- Verifies backup integrity
- Handles interrupted operations
- Provides detailed error logging
- Implements retry mechanisms

### Log Files
The script maintains logs in the following locations:
- Main log: `C:\SQLLogs\DatabaseManager.log`
- Backup log: `C:\SQLLogs\Backups.log`
- Maintenance log: `C:\SQLLogs\Maintenance.log`

### Security Features
- Windows authentication support
- SQL authentication support
- TDE backup handling
- Role-based access control
- Audit logging
- Backup encryption

### Best Practices
- Regular backup verification
- Maintain backup retention policy
- Monitor backup size growth
- Regular index maintenance
- Keep logs rotated
- Test restore procedures
- Monitor Always On health
- Regular security audits
- Check index fragmentation
- Analyze query performance
- Monitor TempDB usage
- Regular DBCC checks
