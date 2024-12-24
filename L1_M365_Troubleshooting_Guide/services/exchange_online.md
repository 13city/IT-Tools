# Exchange Online Troubleshooting Guide

## 1. Common Issues

### 1.1 Email Flow Issues
#### Symptoms
- Emails not being received
- Delayed email delivery
- NDR (Non-Delivery Reports)
- Spam filter issues
- Mail flow rules not working

#### Troubleshooting Steps
1. Check message trace
   ```powershell
   Get-MessageTrace -SenderAddress sender@domain.com -StartDate (Get-Date).AddHours(-24)
   ```
2. Verify mail flow rules
   ```powershell
   Get-TransportRule | Format-Table Name,State,Priority
   ```
3. Check spam filter policies
   ```powershell
   Get-HostedContentFilterPolicy
   ```

### 1.2 Connectivity Issues
#### Symptoms
- Cannot connect to Exchange Online
- Outlook keeps prompting for credentials
- Cannot access OWA (Outlook Web Access)
- Mobile device sync issues

#### Troubleshooting Steps
1. Verify service health in Admin Center
2. Check Autodiscover configuration
   ```powershell
   Test-OutlookWebServices -Identity user@domain.com
   ```
3. Test connectivity
   ```powershell
   Test-OutlookConnectivity -Protocol MAPI -TestCredential (Get-Credential)
   ```

### 1.3 Calendar Issues
#### Symptoms
- Calendar sharing problems
- Meeting scheduling failures
- Free/Busy information not updating
- Resource booking issues

#### Troubleshooting Steps
1. Check calendar permissions
   ```powershell
   Get-MailboxFolderPermission -Identity user@domain.com:\Calendar
   ```
2. Verify calendar processing settings
   ```powershell
   Get-CalendarProcessing -Identity room@domain.com
   ```

## 2. PowerShell Diagnostic Commands

### 2.1 Mailbox Diagnostics
```powershell
# Get mailbox statistics
Get-MailboxStatistics -Identity user@domain.com

# Check mailbox permissions
Get-MailboxPermission -Identity user@domain.com

# View mailbox features
Get-MailboxPlan | Format-List

# Check mailbox quota
Get-Mailbox -Identity user@domain.com | Format-List Name,ProhibitSendQuota,ProhibitSendReceiveQuota
```

### 2.2 Mail Flow Diagnostics
```powershell
# Test mail flow
Test-MessageFlow -Source "Source Server" -Destination user@domain.com

# Check message tracking
Search-MessageTrackingReport -Identity user@domain.com -StartDate (Get-Date).AddDays(-1)

# View transport rules
Get-TransportRule | Format-Table Name,State,Priority,Description
```

## 3. Common Resolution Steps

### 3.1 Mailbox Access Issues
1. Reset user's password
2. Clear Outlook profile and recreate
3. Check mailbox permissions
4. Verify license assignment
5. Check for holds or restrictions

### 3.2 Mail Flow Problems
1. Verify DNS records (MX, SPF, DKIM, DMARC)
2. Check transport rules
3. Review spam filter policies
4. Check for blocked senders/domains
5. Verify connectors configuration

### 3.3 Performance Issues
1. Check client version
2. Verify cached mode settings
3. Review mailbox size
4. Check network connectivity
5. Validate autodiscover settings

## 4. Preventive Measures

### 4.1 Regular Maintenance
- Monitor mailbox sizes
- Review mail flow rules
- Check retention policies
- Verify backup procedures
- Update client software

### 4.2 Monitoring Setup
- Configure alerts for:
  - Mailbox size thresholds
  - Mail flow issues
  - Authentication failures
  - Service health
  - Security incidents

### 4.3 Best Practices
- Implement email authentication (SPF, DKIM, DMARC)
- Regular security reviews
- Keep documentation updated
- Monitor license usage
- Regular compliance checks

## 5. Advanced Troubleshooting

### 5.1 Hybrid Environment Issues
- Check hybrid configuration
- Verify certificate status
- Test federation trust
- Review connector settings
- Check namespace configuration

### 5.2 Migration Issues
- Verify migration endpoint
- Check network bandwidth
- Monitor migration progress
- Review error reports
- Test pilot migrations

### 5.3 Security Issues
- Check audit logs
- Review sign-in logs
- Verify MFA settings
- Check conditional access
- Review security alerts

## 6. Required Permissions

### 6.1 Admin Roles
- Exchange Administrator
- Global Administrator
- Security Administrator
- Compliance Administrator
- Help Desk Administrator

### 6.2 PowerShell Permissions
```powershell
# Connect to Exchange Online PowerShell
Connect-ExchangeOnline -UserPrincipalName admin@domain.com

# View current role assignments
Get-ManagementRoleAssignment -RoleAssignee user@domain.com
```

## 7. Documentation Requirements

### 7.1 Incident Documentation
- Issue description
- Affected users/systems
- Troubleshooting steps taken
- Resolution steps
- Prevention measures

### 7.2 Change Documentation
- Change description
- Impact assessment
- Rollback plan
- Testing procedures
- Approval chain

## 8. Escalation Process

### 8.1 When to Escalate
- Service outages
- Data loss scenarios
- Security breaches
- Complex hybrid issues
- Performance degradation

### 8.2 Required Information
- Tenant ID
- Affected users
- Error messages
- Diagnostic logs
- Timeline of events
