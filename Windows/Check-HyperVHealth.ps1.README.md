# Hyper-V Health Check Script

A PowerShell script for comprehensive health monitoring of Hyper-V environments, focusing on core health metrics and performance indicators.

## Features

- VM status monitoring
- Resource utilization tracking
- Storage health checks
- Network connectivity validation
- Backup status verification
- Performance metrics collection
- Snapshot management

## Prerequisites

- Windows Server with Hyper-V role
- PowerShell 5.1 or higher
- Hyper-V PowerShell module
- Administrative privileges
- Network access to Hyper-V hosts

## Parameters

```powershell
-ComputerName      # Hyper-V host to check
-Credential        # Credentials for remote access
-AlertThreshold    # Resource threshold for alerts
-CheckInterval     # Monitoring interval in minutes
-ReportPath        # Custom report save location
-EmailAlert        # Switch to enable email alerts
```

## Configuration

Create a configuration file named `HyperVHealth.config.json`:

```json
{
  "Thresholds": {
    "CPU": 80,
    "Memory": 85,
    "Storage": 90,
    "Network": 70
  },
  "Monitoring": {
    "Interval": 5,
    "RetentionDays": 30
  },
  "Notifications": {
    "Email": {
      "Enabled": true,
      "Recipients": ["it-alerts@domain.com"]
    },
    "AlertLevels": {
      "Critical": 90,
      "Warning": 75,
      "Info": 60
    }
  }
}
```

## Usage Examples

1. Basic health check:
```powershell
.\Check-HyperVHealth.ps1 -ComputerName "HyperV01"
```

2. Continuous monitoring with alerts:
```powershell
.\Check-HyperVHealth.ps1 -ComputerName "HyperV01" -CheckInterval 15 -EmailAlert
```

3. Custom thresholds and reporting:
```powershell
.\Check-HyperVHealth.ps1 -ComputerName "HyperV01" -AlertThreshold 75 -ReportPath "D:\Reports"
```

## Health Checks

The script performs these key health checks:
- VM operational status
- Resource utilization
- Storage performance
- Network connectivity
- Backup completion
- Snapshot age and size
- Replication status

## Reporting

Reports include:
- Overall health status
- Resource utilization trends
- Performance bottlenecks
- Storage capacity analysis
- Network performance metrics
- Backup status summary

## Logging

Logs are stored in:
```
C:\Windows\Logs\HyperV\
```

Log files contain:
- Health check results
- Performance metrics
- Alert notifications
- Error messages
- Action recommendations
