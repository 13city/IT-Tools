# Event Log Analysis Script

## Overview
Enhanced Windows Event Log analyzer that provides comprehensive analysis of system events with pattern detection, severity-based filtering, and detailed HTML reporting capabilities.

## Features
- Multi-source event log monitoring
- Pattern-based event analysis
- Configurable time ranges
- Severity-based filtering
- HTML report generation with color coding
- Comprehensive logging system
- Critical event pattern detection
- Multiple log source support

## Prerequisites
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Administrator privileges

## Parameters
- `LogPath` (string)
  - Path where logs and reports will be stored
  - Default: "C:\Logs\EventAnalysis"

- `TimeRange` (int)
  - Number of hours to look back for events
  - Default: 24

- `SeverityLevel` (int)
  - Minimum severity level to include (1-Critical, 2-Error, 3-Warning)
  - Default: 2

- `GenerateHTML` (switch)
  - Enable HTML report generation
  - Default: true

## Monitored Event Sources
The script monitors the following event logs:
1. Required Sources:
   - System
   - Application
   - Security

2. Optional Sources:
   - Microsoft-Windows-PowerShell/Operational
   - Microsoft-Windows-TaskScheduler/Operational
   - Microsoft-Windows-DNS-Client/Operational
   - Microsoft-Windows-GroupPolicy/Operational

## Critical Event Patterns
The script detects the following event patterns:

1. Service Failures
   - Event IDs: 7000, 7001, 7022, 7023, 7024, 7026, 7031, 7032, 7034
   - Indicates service start/stop failures and unexpected terminations

2. System Crashes
   - Event IDs: 1001, 1002, 1018, 1019
   - Indicates system crashes, blue screens, and unexpected shutdowns

3. Disk Issues
   - Event IDs: 7, 9, 11, 15, 55
   - Indicates disk errors, bad sectors, and file system issues

4. Security Issues
   - Event IDs: 4625, 4648, 4719, 4765, 4766, 4794, 4897, 4964
   - Indicates failed logins, policy changes, and security violations

5. Active Directory Issues
   - Event IDs: 1000, 1084, 1088, 1168, 2887
   - Indicates AD replication, authentication, and service issues

6. DNS Issues
   - Event IDs: 409, 411, 412, 501, 708
   - Indicates DNS resolution, update, and configuration issues

## Usage Examples

### Basic Usage
```powershell
.\EventLogAnalysis.ps1
```

### Custom Time Range
```powershell
.\EventLogAnalysis.ps1 -TimeRange 48
```

### Critical Events Only
```powershell
.\EventLogAnalysis.ps1 -SeverityLevel 1
```

### Custom Log Path
```powershell
.\EventLogAnalysis.ps1 -LogPath "D:\Logs\EventAnalysis"
```

### Text-Only Output
```powershell
.\EventLogAnalysis.ps1 -GenerateHTML:$false
```

## Output
The script generates two types of output:

1. Log File (text)
   - Timestamped entries
   - Severity levels (Info, Warning, Error)
   - Pattern matches
   - Error messages
   - Event counts

2. HTML Report (if enabled)
   - Color-coded severity levels
   - Pattern detection results
   - Event summaries
   - Detailed event information
   - Interactive tables

### HTML Report Sections
- Analysis Summary
- Event Log Summaries
  - Critical events count
  - Error events count
  - Warning events count
- Pattern Detection Results
- Recent Events (Last 50 per log)

## Exit Codes
- 0: Success with no critical/error events
- 1: Script execution error
- 2: Success but critical/error events found

## Error Handling
- Comprehensive try-catch blocks
- Detailed error logging
- Graceful handling of inaccessible logs
- Continued execution on non-critical failures

## Best Practices
1. Regular Monitoring
   - Schedule daily runs
   - Review HTML reports
   - Track pattern occurrences

2. Time Range Selection
   - Use shorter ranges (24h) for daily monitoring
   - Use longer ranges for investigations
   - Consider system performance for large ranges

3. Severity Level Usage
   - Use level 1 (Critical) for immediate attention
   - Use level 2 (Error) for daily monitoring
   - Use level 3 (Warning) for detailed analysis

4. Report Management
   - Archive reports regularly
   - Clean up old reports
   - Maintain report history for trending

## Customization
The script can be customized by:
1. Adding new event patterns
2. Modifying existing patterns
3. Adding new log sources
4. Customizing HTML report styling
5. Adjusting event filtering criteria

## Integration
This script works well with:
- Task Scheduler
- Monitoring systems
- SIEM solutions
- Compliance frameworks

## Performance Considerations
- Large time ranges may impact performance
- Multiple log sources increase processing time
- HTML report generation requires additional resources
- Consider available disk space for logs and reports

## Author
System Administrator

## Version
1.0

## Last Updated
2024
