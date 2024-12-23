# Windows Server Security Check Script

## Overview
Enhanced security misconfiguration checker for Windows Server 2016, 2019, and 2022. This script performs comprehensive security audits and generates detailed HTML reports of findings.

## Features
- Domain membership and local account verification
- Password policy and security settings validation
- Critical services monitoring with compliance checks
- Certificate validation and expiration monitoring
- Windows Features status verification
- Network share permissions auditing
- Scheduled tasks analysis
- Local administrator group membership monitoring
- Detailed HTML report generation with color-coded findings
- Comprehensive logging with severity levels

## Prerequisites
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Administrator privileges
- Required PowerShell modules:
  - ActiveDirectory (for domain-joined servers)
  - DnsServer (for DNS checks)
  - DhcpServer (for DHCP checks)

## Parameters
- `LogPath` (string)
  - Path where logs and reports will be stored
  - Default: "C:\SecurityLogs"

- `GenerateHTML` (switch)
  - Enable HTML report generation
  - Default: true

- `IncludeCertificates` (switch)
  - Include certificate validation in checks
  - Default: true

- `CheckShares` (switch)
  - Enable network share auditing
  - Default: true

## Usage Examples

### Basic Usage
```powershell
.\WinServerSecurityCheck.ps1
```

### Custom Log Path
```powershell
.\WinServerSecurityCheck.ps1 -LogPath "D:\Audit\Logs"
```

### Skip Certificate Checks
```powershell
.\WinServerSecurityCheck.ps1 -IncludeCertificates:$false
```

### Text-Only Output (No HTML)
```powershell
.\WinServerSecurityCheck.ps1 -GenerateHTML:$false
```

## Output
The script generates two types of output:
1. Log file (text)
   - Timestamped entries
   - Severity levels (Info, Warning, Error)
   - Detailed error messages and findings

2. HTML Report (if enabled)
   - Color-coded findings
   - Organized sections for each check type
   - Interactive tables
   - Visual indicators for issues

### Report Sections
- System Information
- Domain Status
- Service Status
- Certificate Status (if enabled)
- Network Shares (if enabled)
- Local Administrators
- Windows Features
- Scheduled Tasks

## Exit Codes
- 0: Success
- 1: Error during execution
- 2: Completed with critical/error findings

## Monitored Services
The script checks the following critical services:
- Windows Update (wuauserv)
- Windows Defender (WinDefend)
- Windows Event Log (EventLog)
- Task Scheduler (Schedule)
- Background Intelligent Transfer (BITS)
- Cryptographic Services (CryptSvc)

## Security Checks
1. Domain Status
   - Domain membership
   - Domain controller role
   - Domain name verification

2. Service Status
   - Running state
   - Startup type
   - Configuration compliance

3. Certificate Status
   - Expired certificates
   - Certificates expiring within 30 days
   - Certificate store health

4. Network Shares
   - Share permissions
   - Everyone access warnings
   - Path validation

5. Local Administrators
   - Non-default admin accounts
   - Source verification
   - Group membership audit

6. Scheduled Tasks
   - System-level tasks
   - Failed task detection
   - Suspicious configurations

## Best Practices
1. Run regularly as part of maintenance
2. Review HTML reports for visual indicators
3. Address warnings and errors promptly
4. Maintain logs for compliance
5. Use with other security tools

## Error Handling
- Comprehensive try-catch blocks
- Detailed error logging
- Graceful degradation for optional checks
- Continued execution on non-critical failures

## Customization
The script can be customized by:
1. Modifying the `$criticalServices` hashtable
2. Adjusting warning thresholds
3. Adding custom checks
4. Modifying HTML report styling

## Integration
This script works well with:
- Task Scheduler
- RMM platforms
- Monitoring solutions
- Compliance frameworks

## Author
System Administrator

## Version
1.0

## Last Updated
2024
