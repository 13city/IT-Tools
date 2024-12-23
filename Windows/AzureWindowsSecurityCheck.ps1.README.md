# AzureWindowsSecurityCheck.ps1

### Purpose
Performs comprehensive security assessment of Azure-hosted Windows environments, checking for cloud-specific security configurations, compliance requirements, and Azure best practices. This script helps maintain security standards across Azure Windows deployments.

### Features
- Azure-specific security checks
- Cloud service configuration audit
- Network security group verification
- Azure AD integration checks
- Storage security assessment
- Key Vault access review
- Azure backup verification
- Compliance monitoring
- Cost optimization checks

### Requirements
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Az PowerShell module
- Azure AD PowerShell module
- Administrative privileges
- Azure subscription access
- Appropriate RBAC permissions

### Usage
```powershell
.\AzureWindowsSecurityCheck.ps1 [-Subscription <id>] [-ResourceGroup <name>] [-Report] [-Fix]

Parameters:
  -Subscription   Azure subscription ID
  -ResourceGroup  Target resource group
  -Report         Generate detailed HTML report
  -Fix           Attempt to fix found issues
```

### Security Checks Performed

1. **Azure Platform Security**
   - Azure Security Center status
   - Azure Defender status
   - Azure Monitor configuration
   - Azure Policy compliance
   - Resource locks
   - Management group settings

2. **Identity and Access**
   - Azure AD integration
   - Managed identities
   - RBAC assignments
   - Service principals
   - Conditional access
   - MFA enforcement

3. **Network Security**
   - NSG configurations
   - Azure Firewall settings
   - Virtual network security
   - Load balancer security
   - Private endpoints
   - Service endpoints

4. **Data Security**
   - Storage account encryption
   - Key Vault access policies
   - Disk encryption
   - Backup configurations
   - Recovery services
   - Data retention policies

### Configuration
The script uses a JSON configuration file:
```json
{
    "AzureChecks": {
        "SecurityCenter": true,
        "NetworkSecurity": true,
        "IdentityAccess": true,
        "DataProtection": true
    },
    "Compliance": {
        "Standards": ["ISO27001", "PCI-DSS", "HIPAA"],
        "CustomPolicies": true
    },
    "Reporting": {
        "OutputPath": "C:\\AzureReports",
        "SendEmail": true,
        "DetailLevel": "Verbose"
    }
}
```

### Report Sections
The security report includes:
- Executive Summary
- Azure-Specific Findings
- Resource Security Status
- Compliance Status
- Cost Optimization
- Remediation Steps
- Technical Details
- Cloud Best Practices

### Error Handling
- Validates Azure connectivity
- Checks permissions
- Logs all operations
- Handles API throttling
- Reports check failures
- Provides error solutions

### Log Files
The script maintains logs in:
- Main log: `C:\Windows\Logs\AzureSecurityCheck.log`
- Report file: `C:\AzureReports\<timestamp>_AzureSecurityReport.html`
- Error log: `C:\Windows\Logs\AzureSecurityErrors.log`

### Security Features
- Safe read-only operations
- Encrypted report options
- Secure credential handling
- No sensitive data exposure
- Audit trail maintenance
- Compliance tracking

### Compliance Profiles
Built-in compliance checks for:
- Azure Security Benchmark
- CIS Azure Foundations
- NIST Guidelines
- PCI DSS Requirements
- HIPAA Standards
- ISO 27001 Controls

### Best Practices
- Run daily security checks
- Review Azure Advisor
- Monitor Security Center
- Document exceptions
- Maintain baseline
- Update compliance profiles
- Monitor costs
- Address critical issues
- Keep reports archived
- Regular policy updates
- Staff cloud training
- Incident response planning
- Regular tool updates
- Resource tagging
- Backup verification
- Disaster recovery testing
