# Comprehensive Health Monitoring Script

A PowerShell script providing enterprise-wide health monitoring across multiple systems and services, with integrated reporting and alerting capabilities.

## Features

- Multi-system health monitoring
- Service availability tracking
- Resource utilization analysis
- Performance metrics collection
- Integrated alert management
- Comprehensive reporting
- Trend analysis
- Cross-platform monitoring
- Custom monitoring templates
- Automated response actions

## Prerequisites

- PowerShell 5.1 or higher
- Administrative privileges
- Network access to monitored systems
- Required PowerShell modules:
  - PSWindowsUpdate
  - ActiveDirectory
  - SqlServer
  - VMware.PowerCLI (if monitoring VMware)
  - AWS.Tools.EC2 (if monitoring AWS)

## Parameters

```powershell
-MonitoringTargets  # Array of systems to monitor
-ServicesList       # Critical services to track
-AlertThresholds    # Custom alert thresholds
-MonitoringTemplate # Predefined monitoring template
-ReportingInterval  # Interval in minutes
-OutputFormat       # Report format (HTML/PDF/JSON)
-EnableRemediation  # Enable automated fixes
```

## Configuration

Create a configuration file named `ComprehensiveMonitoring.config.json`:

```json
{
  "Monitoring": {
    "Systems": {
      "Windows": {
        "Services": ["DNS", "DHCP", "AD DS"],
        "Performance": ["CPU", "Memory", "Disk", "Network"],
        "EventLogs": ["System", "Application", "Security"]
      },
      "Infrastructure": {
        "Network": ["Switches", "Routers", "Firewalls"],
        "Storage": ["SANs", "NAS"],
        "Virtualization": ["Hyper-V", "VMware"]
      },
      "Applications": {
        "Databases": ["SQL Server", "Oracle"],
        "Web": ["IIS", "Apache"],
        "Email": ["Exchange", "SMTP"]
      }
    },
    "Thresholds": {
      "Critical": {
        "CPU": 90,
        "Memory": 95,
        "Disk": 90,
        "ServiceResponse": 5
      },
      "Warning": {
        "CPU": 80,
        "Memory": 85,
        "Disk": 80,
        "ServiceResponse": 3
      }
    }
  }
}
```

## Usage Examples

1. Basic system monitoring:
```powershell
.\ComprehensiveHealthMonitoring.ps1 -MonitoringTargets @("DC01", "SQL01", "WEB01")
```

2. Custom service monitoring:
```powershell
.\ComprehensiveHealthMonitoring.ps1 -MonitoringTargets "APP01" -ServicesList @("CustomApp", "WorkerService")
```

3. Infrastructure monitoring:
```powershell
.\ComprehensiveHealthMonitoring.ps1 -MonitoringTemplate "Infrastructure" -ReportingInterval 30
```

## Monitoring Categories

### System Health
- CPU utilization
- Memory usage
- Disk performance
- Network throughput
- Service status
- Event logs

### Infrastructure
- Network device health
- Storage system status
- Virtualization platform
- Backup systems
- Security appliances

### Application Performance
- Response times
- Transaction rates
- Error rates
- Queue lengths
- Connection pools
- Cache efficiency

## Reporting

Reports are generated in the specified format and include:
- Executive summary
- System health metrics
- Service availability
- Performance trends
- Resource utilization
- Alert history
- Remediation actions
- Capacity planning

## Logging

Logs are stored in:
```
C:\Windows\Logs\HealthMonitoring\
```

Log structure:
- System health logs
- Service monitoring logs
- Performance metrics
- Alert notifications
- Remediation actions
- Audit trail
