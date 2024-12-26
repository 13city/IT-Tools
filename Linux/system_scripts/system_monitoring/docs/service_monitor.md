# Service Monitoring and Auto-Restart Script

## Overview
This script provides comprehensive monitoring of system services with automatic restart capabilities, detailed logging, and notifications. It can monitor multiple services simultaneously and attempts to restart them if they're found to be inactive.

## Features
- Monitor multiple system services
- Automatic service restart attempts
- Support for configuration file or command-line service list
- Color-coded console output
- Detailed logging with timestamps
- Slack notifications for issues
- Email notifications with detailed reports
- Silent mode for automated runs
- Comprehensive error handling

## Prerequisites
- systemd (script uses systemctl)
- `curl` for Slack notifications
- Local mail utility (`mail` command) for email notifications
- Proper permissions to manage services

## Installation
1. Ensure the script is executable:
   ```bash
   chmod +x service_monitor.sh
   ```

2. Set up environment variables for notifications:
   ```bash
   export SLACK_WEBHOOK_URL="your-webhook-url"
   export EMAIL_RECIPIENT="admin@example.com"
   ```

3. Create a services configuration file (optional):
   ```bash
   cp ../config/services.conf.template ../config/services.conf
   ```

## Usage
```bash
./service_monitor.sh [OPTIONS] [SERVICE...]
```

### Options
- `-h, --help`: Display help message
- `-s, --silent`: Run in silent mode (no console output)
- `-c, --config`: Use configuration file for service list

### Examples
```bash
# Monitor specific services
./service_monitor.sh httpd mysqld

# Use configuration file
./service_monitor.sh --config

# Silent mode with specific services
./service_monitor.sh --silent nginx php-fpm
```

## Configuration File
The script can read services from a configuration file (../config/services.conf):
```bash
# List one service per line
httpd
mysqld
nginx
php-fpm
```

## Output
The script provides:
1. Real-time console output with color coding
2. Log file in ../logs/service_monitor_YYYYMMDD.log
3. Slack notifications for service issues
4. Email notifications with detailed reports

## Exit Codes
- 0: Success (all services running or successfully restarted)
- 1: Error (service not found, restart failed, etc.)

## Logging
Logs are stored in the ../logs directory with the format:
```
service_monitor_YYYYMMDD.log
```

Each log entry includes:
- Timestamp
- Service status
- Restart attempts
- Error messages (if any)

## Notifications
### Slack
- Sends alerts when services are down or restarted
- Includes service names and status
- Shows restart attempt results

### Email
- Sends detailed reports of service issues
- Includes service status details
- Lists restart attempts and results

## Security Considerations
- Script requires appropriate permissions to manage services
- Webhook URLs and email addresses should be properly secured
- Consider running with restricted service management capabilities

## Troubleshooting
1. If notifications aren't working:
   - Verify environment variables are set
   - Check network connectivity
   - Verify curl is installed for Slack notifications
   - Ensure mail utility is configured for email notifications

2. If service management fails:
   - Verify script is run with appropriate privileges
   - Check systemd is available and running
   - Verify service names are correct

3. If configuration file isn't working:
   - Check file exists and is readable
   - Verify service names are valid
   - Check for proper file format

## Maintenance
- Review and rotate log files periodically
- Update Slack webhook URL if changed
- Verify email configuration remains valid
- Keep service list up to date

## Best Practices
1. Use configuration file for consistent service monitoring
2. Run in silent mode when used in automated tasks
3. Review logs regularly for patterns
4. Test notifications periodically
5. Keep documentation of monitored services
