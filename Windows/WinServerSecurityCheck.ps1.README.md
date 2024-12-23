# WinServerSecurityCheck.ps1

### Purpose
Performs comprehensive security assessment of Windows Server environments, checking for common security misconfigurations, vulnerabilities, and compliance issues. This script helps maintain security standards across Windows Server deployments.

### Features
- Windows Server security settings audit
- Server role-specific security checks
- Active Directory security assessment
- IIS security configuration check
- SQL Server security verification
- Network service security
- Compliance verification
- Remote access security
- Backup configuration check

### Requirements
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Administrative privileges
- Server role-specific tools
- .NET Framework 4.7.2 or later

### Usage
```powershell
.\WinServerSecurityCheck.ps1 [-Roles <roles>] [-Report] [-Fix] [-Compliance <profile>]

Parameters:
  -Roles        Specify server roles to check
  -Report       Generate detailed HTML report
  -Fix         Attempt to fix found issues
  -Compliance  Check against specific compliance profile
```

### Security Checks Performed

1. **Base Server Security**
   - Windows Update status
   - Security patch level
   - System integrity
   - Service configurations
   - Event log settings
   - Server hardening status

2. **Role-Specific Security**
   - Active Directory security (if DC)
   - IIS security configuration
   - SQL Server security settings
   - Exchange Server security
   - File server security
   - Remote access services

3. **Network Security**
   - Windows Firewall rules
   - Network protocol security
   - Remote management settings
   - SSL/TLS configuration
   - IPSec policies
   - Port security

4. **Access Control**
   - Administrative access
   - Service accounts
   - Privileged groups
   - Password policies
   - Login restrictions
   - User rights assignment

### Configuration
The script uses a JSON configuration file:
```json
{
    "ServerRoles": {
        "ActiveDirectory": true,
        "IIS": true,
        "SQLServer": false,
        "FileServer": true
    },
    "SecurityChecks": {
        "SystemUpdates": true,
        "Services": true,
        "Firewall": true,
        "EventLogs": true
    },
    "Reporting": {
        "OutputPath": "C:\\SecurityReports",
        "SendEmail": true,
        "DetailLevel": "Verbose"
    }
}
```

### Report Sections
The security report includes:
- Executive Summary
- Critical Findings
- Role-Specific Issues
- System Security Status
- Compliance Status
- Remediation Steps
- Technical Details
- Recommendations

### Error Handling
- Validates administrative rights
- Checks role prerequisites
- Logs all operations
- Handles access denied scenarios
- Reports check failures
- Provides error solutions

### Log Files
The script maintains logs in:
- Main log: `C:\Windows\Logs\ServerSecurityCheck.log`
- Report file: `C:\SecurityReports\<timestamp>_ServerSecurityReport.html`
- Error log: `C:\Windows\Logs\ServerSecurityErrors.log`

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
- PCI DSS Standards
- SOX Requirements
- Custom Profiles

### Best Practices
- Run daily security checks
- Review all findings
- Document exceptions
- Maintain baseline
- Update compliance profiles
- Monitor trends
- Address critical issues
- Keep reports archived
- Regular policy updates
- Staff training
- Incident response planning
- Regular tool updates
- Role-specific audits
- Backup verification
