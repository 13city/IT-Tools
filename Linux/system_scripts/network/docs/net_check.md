# Network Connectivity Check Script

## Overview
This script provides comprehensive network connectivity testing with detailed reporting and notifications. It performs DNS resolution, ping tests, port checks, and traceroute analysis for specified hosts.

## Features
- Multiple host connectivity testing
- DNS resolution checks
- Ping connectivity tests with configurable retries
- Port availability checks
- Traceroute analysis
- Color-coded console output
- Detailed logging with timestamps
- Slack notifications for issues
- Email notifications with detailed reports
- Configuration file support
- Comprehensive error handling

## Prerequisites
- `ping` command
- `traceroute` command
- `nc` (netcat) command
- `dig` command
- `curl` for Slack notifications
- Local mail utility (`mail` command) for email notifications

## Installation
1. Ensure the script is executable:
   ```bash
   chmod +x net_check.sh
   ```

2. Set up environment variables for notifications:
   ```bash
   export SLACK_WEBHOOK_URL="your-webhook-url"
   export EMAIL_RECIPIENT="admin@example.com"
   ```

3. Create a hosts configuration file (optional):
   ```bash
   cp ../config/hosts.conf.template ../config/hosts.conf
   ```

## Usage
```bash
./net_check.sh [OPTIONS] [HOST...]
```

### Options
- `-h, --help`: Display help message
- `-c, --config`: Use configuration file for host list
- `-v, --verbose`: Show detailed output including traceroute
- `-p, --ports PORTS`: Comma-separated list of ports to check (default: 80,443)
- `-t, --timeout SEC`: Timeout in seconds (default: 5)
- `-r, --retries N`: Number of retries (default: 3)

### Examples
```bash
# Check specific hosts
./net_check.sh google.com 8.8.8.8

# Use configuration file
./net_check.sh --config

# Check specific ports with verbose output
./net_check.sh --verbose --ports 22,80,443 example.com
```

## Configuration File
The script can read hosts from a configuration file (../config/hosts.conf):
```bash
# List one host per line
google.com
8.8.8.8
example.com
```

## Output
The script provides:
1. Real-time console output with color coding
2. Log file in ../logs/net_check_YYYYMMDD.log
3. DNS resolution results
4. Ping test results with RTT
5. Port check results
6. Traceroute analysis (in verbose mode or when issues found)
7. Slack notifications for connectivity issues
8. Email notifications with detailed reports

## Exit Codes
- 0: Success (all hosts reachable)
- 1: Error (dependency missing, invalid arguments, or connectivity issues)

## Logging
Logs are stored in the ../logs directory with the format:
```
net_check_YYYYMMDD.log
```

Each log entry includes:
- Timestamp
- Host being checked
- Test results (DNS, ping, ports)
- Error messages (if any)
- Traceroute results (if enabled)

## Notifications
### Slack
- Sends alerts when connectivity issues are found
- Includes failed host details
- Shows specific test failures

### Email
- Sends detailed reports of connectivity issues
- Includes full test results
- Shows traceroute data when available

## Security Considerations
- Script requires network access
- Webhook URLs and email addresses should be properly secured
- Consider implications of port scanning
- Be mindful of rate limiting and firewall rules

## Troubleshooting
1. If notifications aren't working:
   - Verify environment variables are set
   - Check network connectivity
   - Verify curl is installed for Slack notifications
   - Ensure mail utility is configured for email notifications

2. If connectivity checks fail:
   - Verify network connectivity
   - Check firewall rules
   - Verify DNS resolution
   - Check for rate limiting

3. If dependencies are missing:
   - Install required packages
   - Verify PATH includes necessary commands
   - Check system permissions

## Maintenance
- Review and rotate log files periodically
- Update Slack webhook URL if changed
- Verify email configuration remains valid
- Keep host list up to date

## Best Practices
1. Use configuration file for consistent monitoring
2. Set appropriate timeouts for your network
3. Monitor critical hosts more frequently
4. Document expected port availability
5. Keep logs for historical analysis
6. Test notifications periodically

## Common Use Cases
1. Basic connectivity check:
   ```bash
   ./net_check.sh google.com cloudflare.com
   ```

2. Service monitoring:
   ```bash
   ./net_check.sh --ports 80,443,3306 db.example.com
   ```

3. Network troubleshooting:
   ```bash
   ./net_check.sh --verbose --retries 5 problematic-host.com
   ```

4. Regular monitoring:
   ```bash
   # Add to cron for periodic checks
   */5 * * * * /path/to/net_check.sh --config
   ```

## Integration Tips
1. Monitoring system integration:
   ```bash
   # Check exit code for automation
   if ! ./net_check.sh critical-host.com; then
       trigger_alert.sh "Network connectivity issue detected"
   fi
   ```

2. Load balancer health checks:
   ```bash
   # Check multiple backend servers
   ./net_check.sh --ports 8080 backend1 backend2 backend3
   ```

3. DNS monitoring:
   ```bash
   # Focus on DNS checks
   ./net_check.sh --verbose domain1.com domain2.com
