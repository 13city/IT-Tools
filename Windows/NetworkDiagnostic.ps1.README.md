# NetworkDiagnostic.ps1

### Purpose
Performs comprehensive network diagnostics and troubleshooting for Windows environments. This script provides detailed network analysis, connectivity testing, and performance monitoring capabilities.

### Features
- Network connectivity testing
- DNS resolution checks
- Port availability testing
- Network performance analysis
- Bandwidth monitoring
- Latency measurement
- Protocol analysis
- Network mapping
- Traffic monitoring

### Requirements
- Windows 10/11 or Windows Server
- PowerShell 5.1 or later
- Administrative privileges
- Network adapter access
- .NET Framework 4.7.2 or later
- Network monitoring tools

### Usage
```powershell
.\NetworkDiagnostic.ps1 [-Target <host>] [-Type <testType>] [-Duration <time>]

Parameters:
  -Target        Target host or network
  -Type          Test type (Basic/Advanced/Performance)
  -Duration      Test duration in minutes
```

### Diagnostic Operations

1. **Connectivity Tests**
   - Ping tests
   - Traceroute analysis
   - DNS resolution
   - Port scanning
   - Protocol testing
   - Gateway connectivity
   - VPN connection status

2. **Performance Analysis**
   - Bandwidth testing
   - Latency measurement
   - Packet loss detection
   - Network utilization
   - QoS verification
   - Throughput testing
   - Jitter analysis

3. **Network Services**
   - DNS service check
   - DHCP functionality
   - Active Directory connectivity
   - Network share access
   - Print service availability
   - Email server connectivity
   - Web service testing

4. **Security Checks**
   - Firewall status
   - Port security
   - Protocol security
   - Certificate validation
   - Network encryption
   - Access control
   - Security compliance

### Configuration
The script uses a JSON configuration file:
```json
{
    "TestSettings": {
        "DefaultTests": ["Ping", "DNS", "Ports"],
        "Timeout": 30,
        "RetryCount": 3,
        "PortList": [80, 443, 3389]
    },
    "Performance": {
        "SampleInterval": 5,
        "ThresholdLatency": 100,
        "MinBandwidth": 10
    },
    "Reporting": {
        "OutputPath": "C:\\NetworkReports",
        "DetailLevel": "Verbose",
        "SendEmail": true
    }
}
```

### Diagnostic Features
- Multi-protocol testing
- Performance baselining
- Historical comparison
- Real-time monitoring
- Automated remediation
- Alert generation
- Trend analysis

### Error Handling
- Connection timeouts
- DNS failures
- Port blocking
- Service unavailability
- Protocol errors
- Authentication failures
- Resource constraints

### Log Files
The script maintains logs in:
- Main log: `C:\Windows\Logs\NetworkDiagnostic.log`
- Report file: `C:\NetworkReports\<timestamp>_NetworkReport.html`
- Error log: `C:\Windows\Logs\NetworkErrors.log`

### Report Sections
Generated reports include:
- Connectivity Status
- Performance Metrics
- Error Summary
- Service Status
- Security Analysis
- Recommendations
- Historical Trends

### Best Practices
- Regular testing schedule
- Baseline maintenance
- Performance monitoring
- Error documentation
- Security validation
- Configuration backup
- Alert management
- Report archival
- Trend analysis
- Documentation updates
- Tool maintenance
- Staff training

### Integration Options
- Monitoring systems
- SIEM integration
- Email notifications
- Ticketing systems
- Performance monitors
- Network management tools
- Automation platforms

### Troubleshooting Tools
- Network packet capture
- Protocol analysis
- Bandwidth testing
- Latency monitoring
- DNS diagnostics
- Port scanning
- Service monitoring
- Traffic analysis
- Route tracing
- Performance counters
