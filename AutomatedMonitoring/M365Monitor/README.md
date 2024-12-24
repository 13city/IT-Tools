# M365 Monitoring Solution

A comprehensive monitoring solution for Microsoft 365 services that focuses on problem detection, Slack integration, and automated support guidance.

## Features

### Core Capabilities
- Real-time problem detection across M365 services
- Slack channel integration with severity-based routing
- Automated support guidance and resolution steps
- Early warning system for potential issues

### Monitored Services

#### Exchange Online
- Mail flow monitoring (transport delays, NDR patterns, queue buildups)
- Mailbox health checks (storage, corruption, permissions)
- Compliance monitoring (retention, holds, eDiscovery)

#### SharePoint Online
- Site health monitoring (storage, permissions, features)
- Content problem detection (large files, checkouts, versions)
- Performance monitoring (page loads, database errors, throttling)

#### Microsoft Teams
- Meeting quality monitoring (audio/video issues)
- Team health checks (storage, apps, guest access)
- Administrative monitoring (policies, licenses, integrations)

## Prerequisites

- PowerShell 7.0 or later
- Required PowerShell modules:
  - Microsoft.Graph.Authentication (2.0.0+)
  - ExchangeOnlineManagement (3.0.0+)
  - MicrosoftTeams (5.0.0+)
  - PnP.PowerShell (2.0.0+)

## Setup

1. Install required PowerShell modules:
   ```powershell
   Install-Module -Name Microsoft.Graph.Authentication -MinimumVersion 2.0.0
   Install-Module -Name ExchangeOnlineManagement -MinimumVersion 3.0.0
   Install-Module -Name MicrosoftTeams -MinimumVersion 5.0.0
   Install-Module -Name PnP.PowerShell -MinimumVersion 2.0.0
   ```

2. Register an Azure AD application:
   - Go to Azure Portal > Azure Active Directory > App registrations
   - Create a new registration
   - Add required API permissions:
     - Microsoft Graph API permissions
     - Exchange Online API permissions
     - SharePoint Online API permissions
     - Teams API permissions
   - Generate a certificate for authentication
   - Note the Application (client) ID and Tenant ID

3. Configure Slack integration:
   - Create a Slack app in your workspace
   - Add Incoming Webhooks feature
   - Create webhooks for different alert channels
   - Note the webhook URLs

4. Update configuration:
   - Copy `config/config.json`
   - Fill in the following required values:
     - `authentication.clientId`
     - `authentication.tenantId`
     - `authentication.certificateThumbprint`
     - `slack.webhookUrl`
   - Adjust monitoring thresholds and intervals as needed

## Usage

1. Validate configuration:
   ```powershell
   .\src\Monitor-M365.ps1 -ValidateOnly
   ```

2. Start monitoring:
   ```powershell
   .\src\Monitor-M365.ps1
   ```

## Alert Levels

- **Critical**: Immediate attention required, service impact
  - Channel: #m365-critical
  - Notification: @m365-oncall team
  - Example: Mail queue buildup, storage critical

- **High**: Significant issue requiring prompt attention
  - Channel: #m365-high
  - Notification: @m365-support team
  - Example: Performance degradation, compliance risks

- **Medium**: Notable issue requiring investigation
  - Channel: #m365-medium
  - Example: Permission inheritance issues, guest access problems

- **Low**: Informational or potential future issues
  - Channel: #m365-low
  - Example: Storage warnings, configuration drift

## Alert Format

Each alert includes:
- Title and severity indicator
- Problem description
- Affected services/users
- Impact assessment
- Step-by-step resolution guide
- Required permissions
- Relevant PowerShell commands
- Business context

## Logging

Logs are stored in the `logs` directory with daily rotation:
- Format: `monitor-YYYYMMDD.log`
- Contains detailed operation logs
- Includes error traces and debugging information

## Maintenance

1. Regular tasks:
   - Review and adjust thresholds
   - Update PowerShell modules
   - Verify API permissions
   - Check certificate expiration
   - Test Slack integration

2. Troubleshooting:
   - Check daily logs
   - Verify service connectivity
   - Review alert patterns
   - Monitor rate limiting

## Contributing

1. Code structure:
   - `src/core/`: Core monitoring engine
   - `src/monitors/`: Service-specific monitors
   - `config/`: Configuration files
   - `logs/`: Operation logs

2. Adding monitors:
   - Create new monitor class
   - Implement RunChecks method
   - Add to main monitoring loop
   - Update configuration schema

## Support

For issues and feature requests:
1. Check logs for detailed error information
2. Verify configuration settings
3. Ensure required permissions
4. Review service status
5. Check PowerShell module versions

## License

This project is licensed under the MIT License - see the LICENSE file for details.
