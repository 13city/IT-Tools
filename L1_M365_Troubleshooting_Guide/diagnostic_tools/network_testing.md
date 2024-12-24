# Network Testing Tools Guide for Microsoft 365

## 1. Microsoft Network Assessment Tool

### 1.1 Overview
- Purpose: Assess network readiness for M365 services
- Capabilities: Tests connectivity, bandwidth, and latency
- Platform: Windows desktop application
- Download: https://www.microsoft.com/download/details.aspx?id=53885

### 1.2 Key Features
- Network performance testing
- Bandwidth measurement
- Port connectivity
- Latency checks
- Quality of Service testing

### 1.3 Required Tests
| Service | Test Type | Requirements |
|---------|-----------|--------------|
| Teams | Media | UDP 3478-3481 |
| Exchange | HTTPS | TCP 443 |
| SharePoint | HTTPS | TCP 443 |
| OneDrive | HTTPS | TCP 443 |

## 2. Network Monitor Tools

### 2.1 Wireshark
#### Usage Guide
1. Download and install Wireshark
2. Select network interface
3. Apply M365 filters:
   ```
   host outlook.office365.com or
   host teams.microsoft.com or
   host *.sharepoint.com
   ```
4. Analyze traffic patterns
5. Export results

#### Common Filters
```text
# Exchange Online traffic
host outlook.office365.com and tcp.port == 443

# Teams traffic
host teams.microsoft.com and udp.port >= 3478 and udp.port <= 3481

# SharePoint traffic
host *.sharepoint.com and tcp.port == 443
```

### 2.2 Fiddler
#### Configuration
1. Enable HTTPS decryption
2. Configure browser proxy
3. Set up custom rules
4. Monitor traffic
5. Analyze responses

#### Best Practices
- Filter M365 traffic
- Monitor response times
- Check SSL/TLS
- Review headers
- Track performance

## 3. Command-Line Tools

### 3.1 Network Testing Commands
```powershell
# Test connectivity
Test-NetConnection outlook.office365.com -Port 443

# Check DNS resolution
Resolve-DnsName outlook.office365.com

# Trace route
Test-NetConnection outlook.office365.com -TraceRoute

# Test latency
ping teams.microsoft.com -n 100
```

### 3.2 Port Testing
```powershell
# Test Teams ports
Test-NetConnection teams.microsoft.com -Port 443
Test-NetConnection teams.microsoft.com -Port 3478

# Test Exchange ports
Test-NetConnection outlook.office365.com -Port 443
Test-NetConnection smtp.office365.com -Port 587

# Test SharePoint ports
Test-NetConnection tenant.sharepoint.com -Port 443
```

## 4. Microsoft 365 Network Connectivity Test

### 4.1 Web-Based Tool
- URL: https://connectivity.office.com
- Tests all M365 services
- Provides detailed reports
- Suggests optimizations
- Monitors performance

### 4.2 Test Categories
1. Exchange connectivity
2. SharePoint access
3. Teams performance
4. General connectivity
5. Network metrics

## 5. Bandwidth Testing

### 5.1 Microsoft Tools
```powershell
# Network Testing Tool
Start-M365NetworkTest -Type Bandwidth

# Teams Network Assessment
Test-TeamsBandwidth -Duration 300
```

### 5.2 Third-Party Tools
- Ookla Speedtest
- Fast.com
- iPerf
- NetFlow Analyzer
- PRTG Network Monitor

## 6. DNS Testing Tools

### 6.1 DNS Lookup
```powershell
# Check DNS records
$domains = @(
    "outlook.office365.com",
    "teams.microsoft.com",
    "tenant.sharepoint.com"
)

foreach ($domain in $domains) {
    Write-Host "`nDNS Records for $domain:"
    Resolve-DnsName -Name $domain -Type A
    Resolve-DnsName -Name $domain -Type AAAA
    Resolve-DnsName -Name $domain -Type CNAME
}
```

### 6.2 DNS Propagation Tools
- DNSChecker
- WhatsMyDNS
- DNS Propagation Checker
- MXToolbox
- DNS Watch

## 7. SSL/TLS Testing

### 7.1 Certificate Validation
```powershell
# Check certificate
$url = "https://outlook.office365.com"
$req = [Net.HttpWebRequest]::Create($url)
try {
    $req.GetResponse() | Out-Null
    $cert = $req.ServicePoint.Certificate
    Write-Host "Certificate Details:"
    Write-Host "Issued To: $($cert.Subject)"
    Write-Host "Issued By: $($cert.Issuer)"
    Write-Host "Valid Until: $($cert.GetExpirationDateString())"
}
catch {
    Write-Host "Error: $_"
}
```

### 7.2 SSL/TLS Tools
- Qualys SSL Labs
- TestSSLServer
- OpenSSL
- DigiCert Tool
- SSL Checker

## 8. Network Path Analysis

### 8.1 Trace Route Tools
```powershell
# Visual trace route
$destinations = @(
    "outlook.office365.com",
    "teams.microsoft.com",
    "tenant.sharepoint.com"
)

foreach ($dest in $destinations) {
    Write-Host "`nTracing route to $dest:"
    Test-NetConnection $dest -TraceRoute
}
```

### 8.2 Path Analysis Tools
- PathPing
- WinMTR
- PingPlotter
- VisualRoute
- NetworkView

## 9. Performance Monitoring

### 9.1 Network Performance Monitor
```powershell
# Monitor network metrics
Get-Counter '\Network Interface(*)\Bytes Total/sec'
Get-Counter '\Network Interface(*)\Current Bandwidth'
Get-Counter '\TCPv4\Connections Established'
```

### 9.2 Performance Tools
- Performance Monitor
- Network Performance Monitor
- SolarWinds NPM
- PRTG
- Nagios

## 10. Proxy and Firewall Testing

### 10.1 Proxy Verification
```powershell
# Check proxy settings
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.GetProxy("https://outlook.office365.com")
```

### 10.2 Firewall Testing
- Port Scanner
- Telnet Client
- PSPing
- TCPView
- NetCat

## 11. Documentation Requirements

### 11.1 Test Documentation
- Network topology
- Test results
- Performance metrics
- Issue findings
- Recommendations

### 11.2 Regular Testing
- Weekly connectivity tests
- Monthly performance review
- Quarterly assessment
- Annual audit
- Continuous monitoring

## 12. Best Practices

### 12.1 Testing Guidelines
1. Test during peak hours
2. Document baseline metrics
3. Monitor trends
4. Regular testing schedule
5. Keep tools updated

### 12.2 Network Optimization
- Enable QoS
- Optimize routing
- Monitor bandwidth
- Regular maintenance
- Update documentation
