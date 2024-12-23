# Windows Server Performance Optimizer

This PowerShell script provides comprehensive server performance monitoring and optimization capabilities. It collects various performance metrics, generates detailed reports, and can perform system optimizations to improve performance.

## Features

- Real-time performance monitoring
- System resource analysis
- Disk space monitoring
- Network performance tracking
- Process monitoring
- Automated system optimization
- HTML report generation
- Customizable thresholds
- Remote server support

## Prerequisites

- Windows Server 2012 R2 or later
- PowerShell 5.1 or higher
- Administrative privileges
- WMI/CIM access
- Remote PowerShell enabled (for remote monitoring)

## Parameters

- `ComputerName`: Target server name (default: local computer)
- `ReportPath`: HTML report output path (default: Desktop)
- `MonitoringMinutes`: Duration to monitor in minutes (default: 60)
- `SampleInterval`: Seconds between samples (default: 5)
- `PerformOptimization`: Switch to enable optimization tasks
- `CPUThreshold`: CPU usage warning threshold (default: 80%)
- `MemoryThreshold`: Memory usage warning threshold (default: 85%)
- `DiskSpaceThreshold`: Disk space warning threshold (default: 90%)

## Usage Examples

```powershell
# Basic monitoring of local server
.\ServerPerformanceOptimizer.ps1

# Monitor remote server with custom duration
.\ServerPerformanceOptimizer.ps1 -ComputerName "SERVER01" -MonitoringMinutes 120

# Monitor and optimize with custom thresholds
.\ServerPerformanceOptimizer.ps1 -PerformOptimization -CPUThreshold 75 -MemoryThreshold 80

# Quick health check
.\ServerPerformanceOptimizer.ps1 -MonitoringMinutes 5 -SampleInterval 1
```

## Monitored Metrics

### System Information
- OS version and architecture
- Service pack level
- System uptime
- Hardware specifications
- Memory configuration

### Performance Metrics
- CPU utilization
- Memory usage
- Disk queue length
- Average response times
- System bottlenecks

### Disk Space
- Volume information
- Free space
- Usage trends
- Space allocation

### Process Analysis
- Top CPU consumers
- Memory usage
- Handle count
- Resource trends

### Network Statistics
- Interface throughput
- Bandwidth utilization
- Network errors
- Connection status

## Optimization Tasks

When `-PerformOptimization` is specified, the script can:
- Clear temporary files
- Stop unnecessary services
- Disable unneeded scheduled tasks
- Clean Windows Update cache
- Optimize system performance

## Report Sections

1. **System Overview**
   - Hardware specifications
   - OS information
   - Uptime statistics

2. **Performance Metrics**
   - CPU utilization
   - Memory usage
   - Disk activity
   - Performance counters

3. **Storage Analysis**
   - Disk space usage
   - Volume statistics
   - Free space trends

4. **Process Information**
   - Resource usage
   - Top consumers
   - Critical processes

5. **Network Performance**
   - Bandwidth usage
   - Interface statistics
   - Network health

6. **Optimization Results**
   - Tasks performed
   - System improvements
   - Recommendations

## Error Handling

The script includes comprehensive error handling:
- Connection failures
- Permission issues
- Resource access
- Remote execution
- Data collection errors

## Best Practices

1. **Monitoring Schedule**
   - Run during representative periods
   - Include peak usage times
   - Monitor consistently

2. **Optimization**
   - Test in non-production first
   - Schedule during maintenance windows
   - Document changes

3. **Thresholds**
   - Adjust based on workload
   - Consider application requirements
   - Monitor trends

## Troubleshooting

Common issues and solutions:

1. **Access Denied**
   - Verify administrative rights
   - Check remote access permissions
   - Enable required protocols

2. **Data Collection**
   - Verify WMI access
   - Check performance counters
   - Enable required services

3. **Optimization**
   - Review service dependencies
   - Check application requirements
   - Verify system restore points

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
  - Basic monitoring features
  - Optimization capabilities

## Acknowledgments

- Microsoft Windows Server team
- PowerShell community
- Contributing developers
