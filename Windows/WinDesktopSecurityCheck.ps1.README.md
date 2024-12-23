# WinDesktopSecurityCheck.ps1

### Purpose
Performs comprehensive security assessment of Windows desktop environments, checking for common security misconfigurations, vulnerabilities, and compliance issues. This script helps maintain security standards across Windows workstations.

### Features
- Windows security settings audit
- Antivirus status verification
- Firewall configuration check
- User account security analysis
- System update status
- Application security check
- Security policy compliance
- Privacy settings verification
- BitLocker status check

### Requirements
- Windows 10/11 Professional or Enterprise
- PowerShell 5.1 or later
- Administrative privileges
- Windows Defender (for AV checks)
- .NET Framework 4.7.2 or later

### Usage
```powershell
.\WinDesktopSecurityCheck.ps1 [-Report] [-Fix] [-Compliance <profile>]

Parameters:
  -Report        Generate detailed HTML report
  -Fix          Attempt to fix found issues
  -Compliance   Check against specific compliance profile
```

### Security Checks Performed

1. **System Security**
   - Windows Update status
   - Security patch level
   - System integrity
   - Boot configuration
   - BitLocker encryption status
   - Secure Boot status

2. **User Account Security**
   - Password policies
   - Account permissions
   - Admin account status
   - Guest account status
   - User rights assignments
   - Login restrictions

3. **Network Security**
   - Firewall status
   - Network sharing
   - Remote access settings
   - Network protocol security
   - Wi-Fi security
   - VPN configurations

4. **Application Security**
   - Installed software audit
   - Application updates
   - Microsoft Store apps
   - Browser security settings
   - Application control policies
   - Script execution policies

### Configuration
The script uses a JSON configuration file:
```json
{
    "SecurityChecks": {
        "SystemUpdates": true,
        "UserAccounts": true,
        "Firewall": true,
        "Antivirus": true,
        "BitLocker": true,
        "NetworkSharing": true
    },
    "Reporting": {
        "OutputPath": "C:\\SecurityReports",
        "SendEmail": false,
        "DetailLevel": "Verbose"
    }
}
```

### Report Sections
The security report includes:
- Executive Summary
- Critical Findings
- System Information
- Security Settings
- Compliance Status
- Remediation Steps
- Technical Details
- Recommendations

### Error Handling
- Validates administrative rights
- Checks system compatibility
- Logs all operations
- Handles access denied scenarios
- Reports check failures
- Provides error solutions

### Log Files
The script maintains logs in:
- Main log: `C:\Windows\Logs\SecurityCheck.log`
- Report file: `C:\SecurityReports\<timestamp>_SecurityReport.html`
- Error log: `C:\Windows\Logs\SecurityCheckErrors.log`

### Security Features
- Safe read-only operations
- Encrypted report options
- Secure logging practices
- No sensitive data exposure
- Audit trail maintenance
- Compliance tracking

### Compliance Profiles
Built-in compliance checks for:
- CIS Benchmarks
- NIST Guidelines
- HIPAA Requirements
- Corporate Standards
- Industry Best Practices
- Custom Profiles

### Best Practices
- Run weekly security checks
- Review all findings
- Document exceptions
- Maintain baseline
- Update compliance profiles
- Monitor trends
- Address critical issues
- Keep reports archived
- Regular policy updates
- User awareness training
- Incident response planning
- Regular tool updates
