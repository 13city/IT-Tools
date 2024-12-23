# Active Directory Health Monitor

This PowerShell script provides comprehensive monitoring and maintenance capabilities for Active Directory environments. It performs various health checks, generates detailed reports, and optionally fixes common issues.

## Features

- Domain Controller service monitoring
- AD replication status checks
- FSMO roles verification
- DNS health assessment
- Database and log file analysis
- Account status monitoring
- Group Policy verification
- Automated issue remediation
- HTML report generation

## Prerequisites

- Windows Server with AD DS role
- PowerShell 5.1 or higher
- Active Directory PowerShell module
- DNS Server PowerShell module
- Domain Admin or Enterprise Admin privileges
- Remote PowerShell enabled on target DCs

## Parameters

- `DomainController`: Target DC name (default: local computer)
- `ReportPath`: HTML report output path (default: Desktop)
- `MaxPasswordAge`: Maximum password age in days (default: 90)
- `InactiveDays`: Days to consider account inactive (default: 30)
- `FixIssues`: Switch to enable automatic issue remediation

## Usage Examples

```powershell
# Basic health check of local DC
.\AD-HealthMonitor.ps1

# Monitor specific DC with custom report path
.\AD-HealthMonitor.ps1 -DomainController "DC01" -ReportPath "C:\Reports\AD-Health.html"

# Check and fix issues automatically
.\AD-HealthMonitor.ps1 -FixIssues

# Custom thresholds for account monitoring
.\AD-HealthMonitor.ps1 -MaxPasswordAge 60 -InactiveDays 45
```

## Monitored Components

### Domain Controller Health
- NTDS service
- DFSR service
- DNS Server service
- Kerberos KDC
- NetLogon
- LDAP connectivity

### Replication Status
- Partner status
- Last successful replication
- Replication errors
- Consecutive failures

### FSMO Roles
- Schema Master
- Domain Naming Master
- RID Master
- PDC Emulator
- Infrastructure Master

### DNS Health
- Service status
- Zone configuration
- SRV records
- Record counts

### Database Status
- NTDS.dit size
- Log file count
- Available disk space
- Database integrity

### Account Issues
- Expired accounts
- Locked accounts
- Password expiration
- Inactive accounts

### Group Policy
- GPO status
- Version information
- Modification times
- Link status

## Report Sections

1. **Domain Controller Health**
   - Service status overview
   - Critical service alerts
   - Connectivity status

2. **Replication Health**
   - Partner status matrix
   - Error indicators
   - Timing metrics

3. **FSMO Roles**
   - Role distribution
   - Holder verification
   - Transfer status

4. **DNS Status**
   - Zone health
   - Record verification
   - Service metrics

5. **Database Information**
   - Size metrics
   - Growth trends
   - Space utilization

6. **Account Status**
   - Problem accounts
   - Security issues
   - Compliance status

7. **Group Policy**
   - Policy inventory
   - Version control
   - Application status

## Automated Remediation

When `-FixIssues` is specified, the script can:
- Unlock locked accounts
- Enable disabled accounts
- Reset password expiration
- Clear replication errors
- Fix DNS record issues

## Error Handling

The script includes comprehensive error handling:
- Connection failures
- Permission issues
- Service problems
- Resource constraints
- Replication errors

## Best Practices

1. **Scheduling**
   - Run during off-peak hours
   - Schedule regular checks
   - Maintain report history

2. **Permissions**
   - Use dedicated service account
   - Apply least privilege
   - Audit access

3. **Monitoring**
   - Review reports regularly
   - Track trends
   - Set up alerts

## Troubleshooting

Common issues and solutions:

1. **Access Denied**
   - Verify account permissions
   - Check group membership
   - Review security logs

2. **Connectivity Issues**
   - Check network connectivity
   - Verify DNS resolution
   - Test RPC connectivity

3. **Report Generation**
   - Check disk space
   - Verify write permissions
   - Review error logs

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit pull request with:
   - Clear description
   - Test results
   - Documentation updates

## License

This script is released under the MIT License.

## Version History

- 1.0.0 (2024-01-20)
  - Initial release
  - Basic monitoring features
  - HTML report generation

## Acknowledgments

- Microsoft Active Directory team
- PowerShell community
- Contributing developers
