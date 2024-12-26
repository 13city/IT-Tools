# Security Incident Response Guide for Microsoft 365

## 1. Initial Response

### 1.1 Incident Detection
#### Immediate Steps
1. Identify incident type
2. Assess severity
3. Document initial findings
4. Start incident log
5. Alert security team

#### Incident Categories
| Type | Description | Priority | Response |
|------|-------------|----------|----------|
| Account Compromise | Unauthorized access | Critical | Account lockdown |
| Data Breach | Data exposure | Critical | Access restriction |
| Malware | System infection | High | Isolation |
| Phishing | Email attacks | High | Mail flow rules |
| Policy Violation | Security bypass | Medium | Policy enforcement |

### 1.2 Initial Containment
```powershell
# Block user account
Set-MsolUser -UserPrincipalName user@domain.com -BlockCredential $true

# Revoke sessions
Revoke-AzureADUserAllRefreshToken -ObjectId "user-id"

# Enable security alerts
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
```

## 2. Account Compromise Response

### 2.1 Immediate Actions
```powershell
# Reset password
Reset-MsolPassword -UserPrincipalName user@domain.com -NewPassword "TempPass123!"

# Check sign-in logs
Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq 'user@domain.com'"

# Review MFA status
Get-MsolUser -UserPrincipalName user@domain.com | Select-Object StrongAuthenticationRequirements
```

### 2.2 Investigation Steps
1. Review authentication logs
2. Check device access
3. Audit mailbox rules
4. Review permissions
5. Check forwarding rules

## 3. Data Breach Response

### 3.1 Data Assessment
```powershell
# Check sharing permissions
Get-SPOSite | Get-SPOSiteGroup

# Review external access
Get-SPOExternalUser -SiteUrl https://tenant.sharepoint.com/sites/site

# Audit file access
Search-UnifiedAuditLog -Operations FileAccessed,FileDownloaded
```

### 3.2 Containment Steps
1. Block external sharing
2. Revoke links
3. Enable alerts
4. Document exposure
5. Notify stakeholders

## 4. Malware Response

### 4.1 Detection and Analysis
```powershell
# Check email threats
Get-MailDetailATPReport

# Review quarantine
Get-QuarantineMessage

# Check ATP detections
Get-ATPDetection
```

### 4.2 Containment Actions
1. Isolate affected systems
2. Block malicious content
3. Update protection
4. Scan systems
5. Monitor activity

## 5. Investigation Tools

### 5.1 Microsoft Tools
- Security & Compliance Center
- Azure AD Identity Protection
- Microsoft Defender ATP
- Cloud App Security
- Advanced Threat Analytics

### 5.2 PowerShell Commands
```powershell
# Review audit logs
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)

# Check security alerts
Get-AlertPolicy

# Review compliance status
Get-ComplianceSearch
```

## 6. Evidence Collection

### 6.1 Required Data
- Audit logs
- Email traces
- Access logs
- System logs
- Network logs

### 6.2 Collection Methods
```powershell
# Export audit logs
$logs = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
$logs | Export-Csv -Path "AuditLogs.csv"

# Export mail trace
Get-MessageTrace | Export-Csv -Path "MailTrace.csv"
```

## 7. Communication Plan

### 7.1 Internal Communication
```text
Subject: Security Incident Alert - [Incident Type]

Severity: [Level]
Impact: [Description]
Status: Investigation in progress
Required Actions:
1. [Immediate steps]
2. [Precautions]
3. [Reporting procedures]

Updates will follow every [timeframe].
```

### 7.2 External Communication
1. Legal team notification
2. Regulatory reporting
3. Customer notification
4. PR statement
5. Law enforcement

## 8. Remediation Steps

### 8.1 Account Security
1. Reset credentials
2. Enable MFA
3. Review permissions
4. Update policies
5. Monitor activity

### 8.2 System Security
1. Update protection
2. Patch systems
3. Review configs
4. Test security
5. Monitor alerts

## 9. Prevention Measures

### 9.1 Security Controls
- Enable MFA
- Implement Conditional Access
- Configure DLP
- Enable ATP
- Set up alerts

### 9.2 Policy Updates
1. Review security policies
2. Update compliance rules
3. Enhance monitoring
4. Improve controls
5. Document changes

## 10. Documentation Requirements

### 10.1 Incident Documentation
- Timeline
- Actions taken
- Evidence collected
- Impact assessment
- Resolution steps

### 10.2 Compliance Records
- Incident reports
- Response actions
- Communication logs
- Evidence chain
- Resolution proof

## 11. Post-Incident Actions

### 11.1 Review Process
- Incident analysis
- Response evaluation
- Policy updates
- Training needs
- Documentation updates

### 11.2 Improvements
1. Update procedures
2. Enhance monitoring
3. Strengthen controls
4. Train users
5. Test response

## 12. Security Hardening

### 12.1 Account Security
```powershell
# Enable modern auth
Set-OrganizationConfig -OAuth2ClientProfileEnabled $true

# Configure MFA
$mfa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$mfa.RelyingParty = "*"
$mfa.State = "Enabled"
Set-MsolUser -UserPrincipalName user@domain.com -StrongAuthenticationRequirements $mfa
```

### 12.2 Tenant Security
1. Enable security defaults
2. Configure Conditional Access
3. Implement Zero Trust
4. Enable logging
5. Regular reviews

## 13. Training Requirements

### 13.1 Security Team
- Incident response
- Tool usage
- Investigation techniques
- Evidence handling
- Communication

### 13.2 End Users
- Security awareness
- Incident reporting
- Safe practices
- Policy compliance
- Response procedures

## 14. Compliance Requirements

### 14.1 Regulatory
- Data protection
- Breach notification
- Evidence preservation
- Documentation
- Reporting

### 14.2 Internal
1. Policy compliance
2. Audit requirements
3. Documentation
4. Training
5. Reviews
