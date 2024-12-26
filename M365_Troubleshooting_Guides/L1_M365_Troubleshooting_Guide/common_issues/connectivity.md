# Connectivity Troubleshooting Guide for Microsoft 365

## 1. Initial Assessment

### 1.1 Client Questions
1. "Can you describe what happens when you try to access Microsoft 365 services?"
   - Helps identify if it's a complete outage or partial connectivity issue
   - Reveals any error messages the client might be seeing

2. "Which Microsoft 365 applications are you having trouble accessing?"
   - Helps determine if it's service-specific or a broader issue
   - Examples: Outlook, Teams, SharePoint, OneDrive

3. "When did you first notice this issue?"
   - Helps establish timeline
   - Can be correlated with recent changes or updates

4. "Are you able to access other websites or internet services?"
   - Helps isolate if it's a Microsoft 365-specific issue or general internet connectivity

### 1.2 Environment Assessment
1. Location Information
   - Office location
   - Home network
   - Public WiFi
   - Mobile data

2. Device Information
   - Company device vs personal device
   - Device management status
   - Security software present

3. Configuration History
   - Previous working status
   - Recent changes
   - Updates or modifications

### 1.3 Scope Determination
1. User Impact
   - Single user
   - Multiple users
   - Department-wide
   - Organization-wide

2. Service Impact
   - Specific service (e.g., Teams only)
   - Multiple services
   - All Microsoft 365 services

## 2. Network Diagnostics

### 2.1 Basic Connectivity Tests
```powershell
# Test basic connectivity
Test-NetConnection outlook.office365.com -Port 443
Test-NetConnection teams.microsoft.com -Port 443
Test-NetConnection login.microsoftonline.com -Port 443
```

### 2.2 DNS Resolution
```powershell
# Verify DNS resolution
Resolve-DnsName outlook.office365.com
Resolve-DnsName teams.microsoft.com
Resolve-DnsName login.microsoftonline.com
```

### 2.3 Network Requirements
1. Required Ports
   - TCP 443 (HTTPS)
   - TCP 80 (HTTP)
   - UDP 3478-3481 (Teams/Skype)

2. Bandwidth Requirements
   - Teams: 1.5 Mbps per HD stream
   - SharePoint: 0.5-1.0 Mbps per user
   - Exchange Online: 0.4 Mbps per user

## 3. Common Issues and Solutions

### 3.1 Proxy/Firewall Issues
1. Check Proxy Configuration
```powershell
# Get proxy settings
netsh winhttp show proxy
```

2. Required Exclusions
   - *.microsoft.com
   - *.office.com
   - *.office365.com
   - *.sharepoint.com
   - *.teams.microsoft.com

3. SSL Inspection
   - Verify SSL inspection bypass for Microsoft endpoints
   - Check for certificate errors

### 3.2 Client-Side Issues
1. Network Adapter
```powershell
# Reset network adapter
netsh winsock reset
netsh int ip reset
ipconfig /flushdns
```

2. Browser Cache
   - Clear browser cache
   - Reset browser settings
   - Try InPrivate/Incognito mode

3. Office Cache
   - Clear Office cache
   - Reset Office activation
   - Repair Office installation

## 4. Advanced Diagnostics

### 4.1 Network Path Analysis
```powershell
# Trace route to service
Test-NetConnection outlook.office365.com -TraceRoute
```

### 4.2 Performance Testing
1. Network Speed Test
   - Microsoft 365 Network Connectivity Test
   - Speed.io
   - Ookla Speedtest

2. Latency Check
```powershell
# Check latency
ping outlook.office365.com -n 50
```

### 4.3 Certificate Validation
```powershell
# Check certificate
$url = "https://outlook.office365.com"
$req = [Net.HttpWebRequest]::Create($url)
$req.GetResponse().ServerCertificate
```

## 5. Service-Specific Checks

### 5.1 Exchange Online
1. Connectivity Test
```powershell
Test-OutlookConnectivity -Protocol MAPI
```

2. AutoDiscover Test
```powershell
Test-OutlookAutoDiscover -EmailAddress user@domain.com
```

### 5.2 SharePoint Online
1. Site Connectivity
```powershell
Invoke-WebRequest -Uri "https://tenant.sharepoint.com" -UseDefaultCredentials
```

2. Network Requirements
   - Check ULS logs
   - Verify OneDrive sync status

### 5.3 Teams
1. Media Requirements
   - UDP ports 3478-3481
   - Verify QoS settings
   - Check firewall rules

2. Client Diagnostics
   - Teams Network Assessment Tool
   - Call Quality Dashboard

## 6. Documentation Requirements

### 6.1 Issue Documentation
- Error messages
- Network traces
- Test results
- Client environment
- Resolution steps

### 6.2 Environment Details
- Network configuration
- Proxy settings
- Firewall rules
- Client settings
- Recent changes

## 7. Preventive Measures

### 7.1 Monitoring
1. Set up alerts for:
   - Service health
   - Network performance
   - Client connectivity
   - Authentication issues

2. Regular testing of:
   - Network paths
   - DNS resolution
   - Certificate validation
   - Proxy configuration

### 7.2 Best Practices
1. Network Configuration
   - Implement QoS
   - Configure split tunneling
   - Optimize proxy settings
   - Regular firewall review

2. Client Configuration
   - Keep clients updated
   - Regular cache clearing
   - Certificate management
   - Security software optimization

## 8. Escalation Procedures

### 8.1 When to Escalate
- Multiple users affected
- Service degradation
- Complex network issues
- Security concerns
- Performance problems

### 8.2 Required Information
- Network traces
- Error logs
- Test results
- Environment details
- Timeline of issues

## 9. Additional Resources

### 9.1 Microsoft Tools
- Microsoft 365 Network Connectivity Test
- Microsoft Remote Connectivity Analyzer
- Microsoft Support and Recovery Assistant
- Office 365 Network Assessment Tool
- Teams Network Assessment Tool

### 9.2 Documentation
- Microsoft 365 Network Connectivity Principles
- Office 365 URLs and IP Ranges
- Network Planning Guide
- Teams Network Guide
- Exchange Connectivity Guide
