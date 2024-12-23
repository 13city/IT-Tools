# Hyper-V Health Check Script

This PowerShell script performs comprehensive health checks on Hyper-V hosts and virtual machines, generating a detailed HTML report of the findings.

## Features

- Service Status Monitoring
- VM Health Metrics
- Storage Health Analysis
- Network Configuration Check
- Event Log Analysis
- HTML Report Generation

## Prerequisites

- Windows Server with Hyper-V role installed
- PowerShell 5.1 or higher
- Administrative privileges
- Hyper-V PowerShell module

## Parameters

- `VMHost`: The Hyper-V host to check (default: local computer)
- `ReportPath`: Path where the HTML report will be saved (default: Desktop)
- `DaysToAnalyze`: Number of days of event logs to analyze (default: 7)

## Usage

```powershell
# Run with default parameters
.\HyperV-HealthCheck.ps1

# Specify custom parameters
.\HyperV-HealthCheck.ps1 -VMHost "HyperV-Host01" -ReportPath "C:\Reports\HealthCheck.html" -DaysToAnalyze 14
```

## Report Sections

1. **Service Health**
   - Status of critical Hyper-V services
   - Service start types
   - Running state

2. **VM Health**
   - Current state of each VM
   - CPU and memory utilization
   - Uptime statistics
   - Integration services version
   - Replication health status

3. **Storage Health**
   - VHD file details
   - Storage capacity and usage
   - Fragmentation levels
   - Parent/Child VHD relationships

4. **Network Health**
   - Virtual switch configuration
   - Connected VMs per switch
   - Bandwidth usage statistics
   - Network adapter settings

5. **Event Analysis**
   - Critical and warning events
   - Service-related events
   - Performance events
   - Security events

## Output

The script generates an HTML report with formatted tables and styling for easy reading. The report includes:
- Color-coded status indicators
- Sortable tables
- Timestamp of report generation
- Detailed metrics for each section

## Error Handling

The script includes comprehensive error handling:
- Graceful handling of missing services
- Detailed error messages
- Continued execution even if individual components fail
- Error logging in the final report

## Best Practices

1. Run the script during off-peak hours for accurate performance metrics
2. Review reports regularly (recommended weekly)
3. Keep historical reports for trend analysis
4. Run with elevated privileges to ensure full access to all metrics

## Troubleshooting

Common issues and solutions:

1. **Access Denied Errors**
   - Ensure you're running PowerShell as Administrator
   - Verify your account has proper Hyper-V management permissions

2. **Missing Data in Report**
   - Check if Hyper-V services are running
   - Verify WMI service is operational
   - Ensure proper network connectivity to remote hosts

3. **Report Generation Failures**
   - Check write permissions to the output directory
   - Verify sufficient disk space
   - Ensure no file locks on existing reports

## Contributing

Feel free to submit issues and enhancement requests. Follow these steps:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## License

This script is released under the MIT License. See the LICENSE file for details.

## Author

[Your Organization/Name]

## Version History

- 1.0.0 (2024-01-20)
  - Initial release
  - Basic health monitoring
  - HTML report generation

## Acknowledgments

- Microsoft Hyper-V Team documentation
- PowerShell Community
- Various contributors and testers
