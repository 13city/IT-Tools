# Data Recovery Guide for Microsoft 365

## 1. Initial Assessment

### 1.1 Data Loss Identification
#### Immediate Steps
1. Identify affected data
2. Determine loss scope
3. Document time of loss
4. Review access logs
5. Start recovery log

#### Loss Categories
| Type | Description | Priority | Recovery Method |
|------|-------------|----------|-----------------|
| Accidental Deletion | User deleted content | High | Recycle bin |
| Corruption | Data integrity issues | Critical | Backup restore |
| Ransomware | Encrypted files | Critical | Point-in-time recovery |
| Sync Issues | File sync problems | Medium | Version history |
| Hardware Failure | Device issues | High | Cloud recovery |

### 1.2 Impact Analysis
1. Number of affected users
2. Business impact
3. Data criticality
4. Compliance implications
5. Recovery timeline

## 2. Exchange Online Recovery

### 2.1 Mailbox Item Recovery
```powershell
# Check deleted item retention
Get-Mailbox -Identity user@domain.com | Select RetainDeletedItemsFor

# Restore deleted items
Search-Mailbox -Identity user@domain.com -SearchQuery "subject:'Important Document'" -TargetMailbox recovery@domain.com

# Restore deleted mailbox
New-MailboxRestoreRequest -SourceMailbox "user@domain.com" -TargetMailbox "user@domain.com"
```

### 2.2 Recovery Steps
1. Check Recoverable Items folder
2. Use eDiscovery if needed
3. Restore from backup
4. Verify mail flow
5. Test recovered items

## 3. SharePoint/OneDrive Recovery

### 3.1 File Recovery
```powershell
# Check recycle bin items
Get-SPODeletedItem -SiteUrl https://tenant.sharepoint.com/sites/site

# Restore items
Restore-SPODeletedItem -SiteUrl https://tenant.sharepoint.com/sites/site -ItemUrl "/documents/file.docx"

# Check version history
Get-SPOFileVersion -SiteUrl https://tenant.sharepoint.com/sites/site -FileUrl "/documents/file.docx"
```

### 3.2 Site Collection Recovery
1. Check site collection recycle bin
2. Review version history
3. Use backup if available
4. Test restored content
5. Verify permissions

## 4. Teams Data Recovery

### 4.1 Teams Chat Recovery
```powershell
# Check compliance search
New-ComplianceSearch -Name "TeamsChat" -ExchangeLocation user@domain.com -ContentMatchQuery "kind:im"

# Export chat history
New-ComplianceSearchAction -SearchName "TeamsChat" -Export

# Restore team
Restore-Team -GroupId "group-id"
```

### 4.2 Teams Files Recovery
1. Check SharePoint recycle bin
2. Review version history
3. Restore from backup
4. Verify file access
5. Test sharing

## 5. Recovery Tools

### 5.1 Microsoft Tools
- eDiscovery
- Content Search
- Audit Log Search
- Backup Admin Center
- Security & Compliance Center

### 5.2 PowerShell Commands
```powershell
# Search audit log
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -Operations FileDeleted

# Review retention policies
Get-RetentionPolicy

# Check backup status
Get-SPOSiteBackupInformation -SiteUrl https://tenant.sharepoint.com/sites/site
```

## 6. Prevention Measures

### 6.1 Backup Configuration
- Regular backups
- Point-in-time recovery
- Retention policies
- Version control
- Audit logging

### 6.2 Security Settings
1. Enable MFA
2. Configure DLP
3. Set retention policies
4. Enable auditing
5. Configure alerts

## 7. Documentation Requirements

### 7.1 Recovery Documentation
- Incident details
- Recovery steps
- Timeline
- Affected data
- Resolution

### 7.2 Compliance Records
- Audit logs
- Recovery reports
- User notifications
- Incident reports
- Resolution proof

## 8. Recovery Procedures

### 8.1 Standard Recovery
1. Check recycle bin
2. Review version history
3. Use backup restore
4. Verify recovery
5. Document process

### 8.2 Emergency Recovery
1. Stop data loss
2. Isolate affected items
3. Begin recovery
4. Test restoration
5. Monitor progress

## 9. Communication Plan

### 9.1 User Communication
```text
Subject: Data Recovery in Progress - [Service]

Impact: [Description of data loss]
Status: Recovery initiated
Timeline: [Expected recovery time]
Actions Required:
1. [User actions needed]
2. [Temporary workarounds]
3. [How to verify recovery]

We will provide updates on progress.
```

### 9.2 Stakeholder Updates
1. Initial notification
2. Progress updates
3. Recovery confirmation
4. Final report
5. Lessons learned

## 10. Testing and Validation

### 10.1 Recovery Testing
- File integrity
- Permission structure
- Application functionality
- User access
- Data consistency

### 10.2 Validation Steps
1. Verify data completeness
2. Check permissions
3. Test functionality
4. Document results
5. User confirmation

## 11. Compliance and Legal

### 11.1 Compliance Requirements
- Data protection laws
- Industry regulations
- Corporate policies
- Audit requirements
- Retention rules

### 11.2 Legal Considerations
1. Chain of custody
2. Evidence preservation
3. Legal holds
4. Documentation
5. Notifications

## 12. Post-Recovery Actions

### 12.1 Review Process
- Document lessons learned
- Update procedures
- Improve prevention
- Train users
- Test recovery

### 12.2 Prevention Updates
1. Review policies
2. Update backups
3. Enhance monitoring
4. Improve security
5. User training

## 13. Recovery Time Guidelines

### 13.1 Service RTOs
| Service | Recovery Time | Method | Priority |
|---------|--------------|---------|----------|
| Email | 1-4 hours | Native tools | Critical |
| Files | 2-8 hours | Backup restore | High |
| Teams | 2-6 hours | Site recovery | High |
| SharePoint | 4-12 hours | Backup restore | Medium |

### 13.2 Recovery Priorities
1. Critical business data
2. User productivity files
3. Historical records
4. System configurations
5. Optional content

## 14. Backup Verification

### 14.1 Regular Checks
- Backup completion
- Data integrity
- Recovery testing
- Storage capacity
- Retention compliance

### 14.2 Testing Schedule
1. Daily backup checks
2. Weekly recovery tests
3. Monthly full restore
4. Quarterly DR test
5. Annual review
