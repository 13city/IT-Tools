# Problem Identification Framework

## Table of Contents
1. [Initial Assessment](#initial-assessment)
2. [Information Gathering](#information-gathering)
3. [Impact Analysis](#impact-analysis)
4. [Problem Classification](#problem-classification)
5. [Documentation Requirements](#documentation-requirements)

## Initial Assessment

### 1.1 First Response Questions
1. **What is the exact error message or symptom?**
   - Capture screenshots
   - Document error codes
   - Note any patterns
   - Record timing of issues
   - Identify reproducible steps

2. **Who is affected?**
   - Single user
   - Multiple users
   - Specific groups
   - Entire organization
   - External users

3. **When did the issue start?**
   - First occurrence
   - Frequency
   - Duration
   - Pattern recognition
   - Related events

4. **What has changed recently?**
   - System updates
   - Policy changes
   - Network modifications
   - Security updates
   - User changes

### 1.2 Service Status Verification
1. **Check Microsoft 365 Service Health**
   ```powershell
   # PowerShell check
   Get-M365ServiceHealth
   ```
   - [Service Health Dashboard](https://admin.microsoft.com/Adminportal/Home#/servicehealth)
   - [Azure Status](https://status.azure.com)
   - [Office 365 Status](https://status.office365.com)

2. **Network Connectivity**
   ```powershell
   # Basic connectivity test
   Test-NetConnection outlook.office365.com -Port 443
   Test-NetConnection teams.microsoft.com -Port 443
   ```

## Information Gathering

### 2.1 Required Information
1. **User Details**
   - UPN
   - Department
   - Location
   - Device
   - Access method

2. **Environment Information**
   - Client version
   - Browser type
   - Operating system
   - Network connection
   - VPN status

3. **Error Details**
   - Error messages
   - Event logs
   - Network traces
   - Browser console
   - Application logs

### 2.2 Data Collection Methods
```powershell
# Collect basic system info
$systemInfo = @{
    "OS Version" = (Get-WmiObject Win32_OperatingSystem).Version
    "PowerShell Version" = $PSVersionTable.PSVersion
    "Network Connectivity" = Test-NetConnection outlook.office365.com -Port 443
    "DNS Resolution" = Resolve-DnsName outlook.office365.com
}
```

## Impact Analysis

### 3.1 Business Impact Assessment
1. **Severity Levels**
   | Level | Description | Response Time | Escalation |
   |-------|-------------|---------------|------------|
   | P1 | Service Down | Immediate | Yes |
   | P2 | Major Impact | 30 mins | Maybe |
   | P3 | Minor Impact | 2 hours | No |
   | P4 | Question | 24 hours | No |

2. **Impact Categories**
   - Productivity loss
   - Financial impact
   - Customer facing
   - Compliance risk
   - Security risk

### 3.2 Scope Definition
1. **Affected Services**
   - Exchange Online
   - SharePoint
   - Teams
   - OneDrive
   - Azure AD

2. **User Impact**
   - Number of users
   - Departments
   - Locations
   - Business functions
   - External parties

## Problem Classification

### 4.1 Issue Categories
1. **Authentication**
   - Sign-in problems
   - MFA issues
   - Password reset
   - Token errors
   - SSO failures

2. **Connectivity**
   - Network issues
   - DNS problems
   - Proxy errors
   - Firewall blocks
   - Bandwidth constraints

3. **Performance**
   - Slow response
   - Timeouts
   - Application lag
   - Resource usage
   - Capacity issues

4. **Security**
   - Account compromise
   - Data breach
   - Policy violation
   - Compliance issue
   - Access problems

### 4.2 Classification Matrix
| Category | Symptoms | Initial Checks | Tools |
|----------|----------|----------------|-------|
| Authentication | Sign-in failure | Azure AD status | IdFix |
| Connectivity | Cannot access | Network test | Network Monitor |
| Performance | Slow response | Resource usage | Performance Monitor |
| Security | Suspicious activity | Audit logs | Security Center |

## Documentation Requirements

### 5.1 Initial Documentation
1. **Problem Report**
   - Description
   - Timeline
   - Impact
   - Steps taken
   - Current status

2. **Environment Details**
   - System info
   - Configurations
   - Recent changes
   - Related incidents
   - Affected components

### 5.2 Ongoing Documentation
1. **Investigation Log**
   - Actions taken
   - Results
   - Findings
   - Next steps
   - Blockers

2. **Communication Log**
   - Updates sent
   - Responses received
   - Escalations
   - Notifications
   - Status reports

## Best Practices

### 6.1 Problem Identification
1. Gather complete information
2. Verify symptoms
3. Document everything
4. Check recent changes
5. Identify patterns

### 6.2 Analysis Methods
1. Systematic approach
2. Use available tools
3. Follow procedures
4. Maintain documentation
5. Regular updates

## Tools and Resources

### 7.1 Microsoft Tools
- Microsoft Admin Center
- Azure AD Portal
- Exchange Admin Center
- Security & Compliance
- Support and Recovery Assistant

### 7.2 PowerShell Modules
```powershell
# Required modules
Install-Module -Name ExchangeOnlineManagement
Install-Module -Name Microsoft.Online.SharePoint.PowerShell
Install-Module -Name MicrosoftTeams
Install-Module -Name AzureAD
