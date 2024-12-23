# SonicWALL Firewall Auditor

This PowerShell script audits Dell SonicWALL firewall configurations by connecting to the SonicWALL API. It analyzes access rules, NAT policies, and VPN configurations to identify security risks, redundancies, and compliance issues.

## Features

- Retrieves and analyzes access rules
- Audits NAT policies and VPN configurations
- Identifies redundant or conflicting rules
- Checks for security best practices violations
- Analyzes zone-based security policies
- Generates detailed HTML or CSV reports

## Requirements

- PowerShell 5.1 or later
- Network access to SonicWALL device
- Administrator credentials for SonicWALL
- HTTPS access to SonicWALL management interface

## Usage

```powershell
.\SonicWallFirewallAuditor.ps1 -Hostname "192.168.1.1" -Username "admin" -Password "password" -ReportFormat "HTML"
```

### Parameters

- `Hostname` (Required): IP address or hostname of the SonicWALL device
- `Username` (Required): Administrator username
- `Password` (Required): Administrator password
- `ReportFormat` (Optional): Output format for the report (HTML or CSV, defaults to HTML)

## Security Checks

The script performs the following security checks:

1. High-risk ports (21, 23, 445, 1433, 3389, 5900)
2. Rules without source restrictions
3. Missing rule descriptions
4. Redundant or conflicting rules
5. Zone-based policy violations
6. Disabled rules that should be removed
7. WAN access restrictions
8. DMZ security policies

## Report Format

### HTML Report
- Summary section with configuration statistics
- Detailed table of issues found
- Color-coded severity levels
- Responsive design for easy viewing

### CSV Report
- Complete audit data in CSV format
- Easy to import into spreadsheets
- Suitable for further analysis or integration

## Best Practices

- Regularly run audits to maintain security posture
- Review and act on high-severity issues immediately
- Document all rule changes
- Keep rule descriptions up to date
- Remove disabled rules that are no longer needed
- Follow zone-based security principles

## Error Handling

The script includes comprehensive error handling for:
- Authentication failures
- Network connectivity issues
- Invalid parameters
- API access issues

## Output

The script generates a timestamped report file in the specified format:
- HTML: `SonicWallAudit_YYYYMMDD_HHMMSS.html`
- CSV: `SonicWallAudit_YYYYMMDD_HHMMSS.csv`
