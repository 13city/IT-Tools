# SQL Server Performance Monitor

This PowerShell script provides comprehensive monitoring and reporting capabilities for SQL Server instances. It collects various performance metrics, health indicators, and generates detailed HTML reports.

## Features

- Real-time performance monitoring
- Database health status checks
- Blocking detection and analysis
- Index fragmentation assessment
- Backup status verification
- SQL Server Agent job monitoring
- HTML report generation
- Customizable alert thresholds

## Prerequisites

- Windows PowerShell 5.1 or higher
- SQL Server PowerShell module (SQLPS or SqlServer)
- Administrative access to SQL Server
- Appropriate SQL Server permissions
- .NET Framework 4.5 or higher

## Parameters

- `ServerInstance`: SQL Server instance name (default: local)
- `DatabaseName`: Target database name (default: all databases)
- `ReportPath`: Path for HTML report (default: Desktop)
- `AlertThresholdCPU`: CPU usage alert threshold (default: 80%)
- `AlertThresholdMemory`: Memory usage alert threshold (default: 85%)
- `MonitoringDuration`: Duration to monitor in minutes (default: 60)
- `SampleInterval`: Seconds between samples (default: 5)

## Usage Examples

```powershell
# Monitor local instance with default settings
.\SQL-PerformanceMonitor.ps1

# Monitor specific remote instance
.\SQL-PerformanceMonitor.ps1 -ServerInstance "SQLSERVER01"

# Monitor specific database with custom thresholds
.\SQL-PerformanceMonitor.ps1 -ServerInstance "SQLSERVER01" -DatabaseName "ProductionDB" -AlertThresholdCPU 70 -AlertThresholdMemory 75

# Extended monitoring duration
.\SQL-PerformanceMonitor.ps1 -MonitoringDuration 120 -SampleInterval 10
```

## Monitored Metrics

### Server Information
- SQL Server version
- Edition details
- Service pack level
- Cluster status

### Database Status
- Database state
- Recovery model
- Log reuse wait status
- Compatibility level

### Performance Metrics
- CPU utilization
- Buffer cache hit ratio
- Page life expectancy
- Batch requests per second

### Blocking Analysis
- Blocked sessions
- Blocking sessions
- Wait types
- Query information

### Index Health
- Fragmentation levels
- Page counts
- Table information
- Recommended actions

### Backup Status
- Last full backup
- Last differential backup
- Last log backup
- Backup age warnings

### Job Status
- Job state
- Last run time
- Run duration
- Success/failure status

## Report Sections

1. **Server Overview**
   - Instance information
   - Version details
   - Configuration settings

2. **Database Health**
   - Status of all databases
   - Configuration details
   - Recovery models

3. **Performance Metrics**
   - CPU usage trends
   - Memory utilization
   - Cache statistics
   - Query metrics

4. **Blocking Information**
   - Current blocks
   - Historical blocking
   - Resource waits
   - Affected queries

5. **Index Analysis**
   - Fragmentation levels
   - Usage statistics
   - Maintenance needs

6. **Backup Information**
   - Backup history
   - Recovery points
   - SLA compliance

7. **Job Analysis**
   - Job execution history
   - Success rates
   - Duration trends

## Alert Thresholds

The script monitors several critical conditions:
- High CPU usage (configurable threshold)
- Memory pressure
- Blocking scenarios
- Backup freshness
- Job failures

## Error Handling

The script includes comprehensive error handling:
- Connection failures
- Permission issues
- Resource constraints
- Query timeouts
- Report generation errors

## Best Practices

1. **Monitoring Schedule**
   - Run during off-peak hours for baseline
   - Schedule regular monitoring
   - Retain historical reports

2. **Performance Impact**
   - Adjust sample intervals based on server load
   - Use appropriate thresholds
   - Monitor script resource usage

3. **Security**
   - Use least-privilege accounts
   - Secure report storage
   - Audit script access

## Troubleshooting

Common issues and solutions:

1. **Connection Failures**
   - Verify network connectivity
   - Check SQL Server service
   - Validate credentials

2. **Permission Issues**
   - Verify SQL permissions
   - Check Windows authentication
   - Review security logs

3. **Resource Constraints**
   - Adjust sampling frequency
   - Modify collection scope
   - Check server resources

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit pull request with:
   - Clear description
   - Test results
   - Documentation updates

## License

This script is released under the MIT License.

## Version History

- 1.0.0 (2024-01-20)
  - Initial release
  - Basic monitoring capabilities
  - HTML report generation

## Acknowledgments

- SQL Server community
- PowerShell community
- Contributing developers
