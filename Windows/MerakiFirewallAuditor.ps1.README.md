# Meraki Firewall Auditor

This PowerShell script audits Cisco Meraki firewall configurations by connecting to the Meraki Dashboard API. It analyzes firewall rules, NAT policies, and VPN configurations to identify security risks, redundancies, and compliance issues.

## Features

- Retrieves and analyzes firewall rules across all networks in an organization
- Identifies redundant or conflicting rules
- Checks for security best practices violations
- Detects high-risk port usage
- Generates detailed HTML or CSV reports

## Requirements

- PowerShell 5.1 or later
- Meraki Dashboard API access
- Organization Administrator access in Meraki Dashboard

## Usage

```powershell
.\MerakiFirewallAuditor.ps1 -ApiKey "your-api-key" -OrganizationId "org-id" -ReportFormat "HTML"
```

### Parameters

- `ApiKey` (Required): Your Meraki Dashboard API key
- `OrganizationId` (Required): Your Meraki organization ID
- `ReportFormat` (Optional): Output format for the report (HTML or CSV, defaults to HTML)

## Security Checks

The script performs the following security checks:

1. High-risk ports (21, 23, 445, 1433, 3389, 5900)
2. Rules without source restrictions
3. Missing rule descriptions
4. Redundant or conflicting rules
5. Port conflicts across networks
6. Excessive open ports

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
- Remove or disable unused rules

## Error Handling

The script includes comprehensive error handling for:
- API authentication failures
- Network connectivity issues
- Invalid parameters
- API rate limiting

## Output

The script generates a timestamped report file in the specified format:
- HTML: `MerakiAudit_YYYYMMDD_HHMMSS.html`
- CSV: `MerakiAudit_YYYYMMDD_HHMMSS.csv`
