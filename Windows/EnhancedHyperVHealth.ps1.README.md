# Enhanced Hyper-V Health Monitoring Script

An advanced PowerShell script providing detailed health monitoring and management capabilities for Hyper-V environments with enhanced metrics and reporting.

## Features

- Advanced performance monitoring
- Predictive resource analysis
- Cluster health assessment
- Storage optimization checks
- Network performance analysis
- Automated issue resolution
- Capacity planning tools
- Integration with monitoring platforms
- Custom alert thresholds
- Trend analysis reporting

## Prerequisites

- Windows Server with Hyper-V role
- PowerShell 5.1 or higher
- Hyper-V PowerShell module
- Failover Clustering module (for cluster monitoring)
- Administrative privileges
- Network access to Hyper-V hosts

## Parameters

```powershell
-ClusterName       # Hyper-V cluster name
-Nodes             # Array of nodes to monitor
-DetailLevel       # Monitoring detail level (Basic/Advanced/Expert)
-AutoRemediate     # Enable automatic issue resolution
-PredictiveAnalysis # Enable predictive analysis
-ReportFormat      # Output format (HTML/CSV/JSON)
-CustomThresholds  # Path to custom thresholds file
-MonitoringInterval # Interval in minutes
```

## Configuration

Create a configuration file named `EnhancedHyperVHealth.config.json`:

```json
{
  "Monitoring": {
    "DetailLevels": {
      "Basic": {
        "Interval": 15,
        "Metrics": ["CPU", "Memory", "Storage"]
      },
      "Advanced": {
        "Interval": 5,
        "Metrics": ["CPU", "Memory", "Storage", "Network", "IOPS"]
      },
      "Expert": {
        "Interval": 1,
        "Metrics": ["CPU", "Memory", "Storage", "Network", "IOPS", "Latency", "Throughput"]
      }
    },
    "Thresholds": {
      "Performance": {
        "CPU": {
          "Warning": 80,
          "Critical": 90
        },
        "Memory": {
          "Warning": 85,
          "Critical": 95
        },
        "Storage": {
          "Warning": 85,
          "Critical": 90
        }
      }
    },
    "AutoRemediation": {
      "Enabled": true,
      "Actions": {
        "HighCPU": "OptimizeWorkload",
        "LowMemory": "AdjustDynamicMemory",
        "StorageSpace": "CleanupSnapshots"
      }
    }
  }
}
```

## Usage Examples

1. Basic cluster monitoring:
```powershell
.\EnhancedHyperVHealth.ps1 -ClusterName "Production-HV" -DetailLevel Basic
```

2. Advanced monitoring with remediation:
```powershell
.\EnhancedHyperVHealth.ps1 -ClusterName "Production-HV" -DetailLevel Advanced -AutoRemediate
```

3. Expert monitoring with predictive analysis:
```powershell
.\EnhancedHyperVHealth.ps1 -ClusterName "Production-HV" -DetailLevel Expert -PredictiveAnalysis
```

## Advanced Features

### Predictive Analysis
- Resource utilization forecasting
- Capacity planning recommendations
- Performance trend analysis
- Bottleneck prediction
- Growth rate calculations

### Auto-Remediation
- Automatic snapshot cleanup
- Dynamic memory adjustment
- Storage optimization
- Network queue management
- Performance bottleneck resolution

### Reporting

Generated reports include:
- Cluster health overview
- Node performance metrics
- VM resource utilization
- Storage performance analysis
- Network statistics
- Predictive analytics
- Remediation actions taken
- Capacity planning recommendations

## Logging

Logs are stored in:
```
C:\Windows\Logs\HyperV\Enhanced\
```

Log categories:
- Operational logs
- Performance metrics
- Remediation actions
- Predictive analysis
- Error tracking
- Configuration changes
