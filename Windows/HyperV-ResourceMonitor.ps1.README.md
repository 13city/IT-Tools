# Hyper-V Resource Monitor

A comprehensive PowerShell script for monitoring Hyper-V virtual machines, detecting resource contention, and providing actionable remediation steps.

## Features

- Real-time monitoring of VM resource usage (CPU, memory)
- Network health and bandwidth usage analysis
- Storage health verification including fragmentation and space monitoring
- Snapshot management and monitoring
- Detailed remediation suggestions for identified issues
- Email alerting for critical issues
- Comprehensive logging
- Support for both local and remote Hyper-V hosts

## Requirements

- Windows Server with Hyper-V role installed
- PowerShell 5.1 or later
- Administrator privileges
- Hyper-V PowerShell module installed
- SMTP server access (if email alerts are enabled)

## Parameters

- `HostName` (Optional): The Hyper-V host to monitor. Default is localhost.
- `LogPath` (Optional): Path where log files will be stored. Default is "C:\Logs\HyperV"
- `CpuThreshold` (Optional): CPU usage threshold percentage that triggers alerts. Default is 90.
- `MemoryThreshold` (Optional): Memory usage threshold percentage that triggers alerts. Default is 85.
- `SnapshotAgeThreshold` (Optional): Maximum age in days for snapshots before triggering alerts. Default is 7.
- `EmailAlert` (Optional): Switch to enable email alerts.
- `SmtpServer` (Optional): SMTP server for sending alerts.
- `EmailFrom` (Optional): Email address to send alerts from.
- `EmailTo` (Optional): Email address to send alerts to.

## Usage Examples

1. Basic local monitoring:
```powershell
.\HyperV-ResourceMonitor.ps1
```

2. Monitor remote host with custom thresholds:
```powershell
.\HyperV-ResourceMonitor.ps1 -HostName "HyperV01" -CpuThreshold 85 -MemoryThreshold 80
```

3. Enable email alerts:
```powershell
.\HyperV-ResourceMonitor.ps1 -EmailAlert -SmtpServer "smtp.company.com" -EmailFrom "hyperv@company.com" -EmailTo "admin@company.com"
```

## Monitored Issues

The script checks for various potential issues including:

1. Resource Contention
   - High CPU usage (above threshold)
   - High memory usage (above threshold)
   - Network bandwidth bottlenecks

2. Storage Issues
   - VHD fragmentation levels
   - Low free space in dynamic disks
   - High disk activity
   - Storage performance bottlenecks

3. Snapshot Management
   - Old snapshots exceeding age threshold
   - Large snapshots consuming excessive space
   - Snapshot chain depth issues

4. Network Health
   - Adapter status issues
   - Bandwidth usage problems
   - Network configuration issues

## Remediation

For each detected issue, the script provides specific remediation steps including:

- Immediate actions to resolve the issue
- Long-term recommendations for prevention
- Best practices for configuration
- Suggested monitoring improvements

## Logging

The script maintains detailed logs of all operations and findings:

- All checks and their results
- Detected issues and their severity
- Remediation steps provided
- Script execution status and any errors
- Email alert status (if enabled)

Logs are stored in the specified LogPath (default: C:\Logs\HyperV) with timestamp-based filenames.

## Best Practices

1. Regular Monitoring
   - Schedule the script to run at regular intervals
   - Review logs periodically for patterns
   - Adjust thresholds based on your environment

2. Email Alerts
   - Configure email alerts for critical environments
   - Use distribution lists for team notification
   - Set up email rules for proper prioritization

3. Threshold Tuning
   - Start with default thresholds
   - Adjust based on your workload patterns
   - Document any threshold changes

## Troubleshooting

1. Permission Issues
   - Ensure running with administrator privileges
   - Check remote PowerShell permissions if monitoring remote hosts
   - Verify Hyper-V management permissions

2. Email Alert Issues
   - Verify SMTP server connectivity
   - Check firewall rules for SMTP traffic
   - Validate email addresses and permissions

3. Performance Impact
   - Script is designed to be lightweight
   - Adjust monitoring frequency as needed
   - Consider resource usage during checks
