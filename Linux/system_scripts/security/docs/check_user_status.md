# User Account Status Check Script

## Overview
This script provides comprehensive user account status checking with notifications and detailed logging. It checks if user accounts are locked, expired, or valid, and can notify administrators through Slack and email when issues are detected.

## Features
- Checks user account existence and status
- Detects locked and expired accounts
- Color-coded console output
- Detailed logging with timestamps
- Slack notifications for issues
- Email notifications with detailed reports
- Silent mode for automated runs
- Comprehensive error handling

## Prerequisites
- `curl` for Slack notifications
- Local mail utility (`mail` command) for email notifications
- Proper permissions to read user account information

## Installation
1. Ensure the script is executable:
   ```bash
   chmod +x check_user_status.sh
   ```

2. Set up environment variables for notifications:
   ```bash
   export SLACK_WEBHOOK_URL="your-webhook-url"
   export EMAIL_RECIPIENT="admin@example.com"
   ```

## Usage
```bash
./check_user_status.sh [OPTIONS] USERNAME
```

### Options
- `-h, --help`: Display help message
- `-s, --silent`: Run in silent mode (no console output)

### Examples
```bash
# Check status for user 'alice'
./check_user_status.sh alice

# Silent check for user 'bob'
./check_user_status.sh -s bob
```

## Output
The script provides:
1. Console output (unless in silent mode)
2. Log file in ../logs/user_status_YYYYMMDD.log
3. Slack notifications for locked/expired accounts
4. Email notifications with detailed status

## Exit Codes
- 0: Success (account valid)
- 1: Error or account locked/expired

## Logging
Logs are stored in the ../logs directory with the format:
```
user_status_YYYYMMDD.log
```

Each log entry includes:
- Timestamp
- Action/status
- Error messages (if any)

## Notifications
### Slack
- Sends alerts when accounts are locked or expired
- Includes username and status

### Email
- Sends detailed reports for locked/expired accounts
- Includes username, status, and timestamp

## Security Considerations
- Script requires appropriate permissions to read user account information
- Webhook URLs and email addresses should be properly secured
- Consider running with restricted permissions

## Troubleshooting
1. If notifications aren't working:
   - Verify environment variables are set
   - Check network connectivity
   - Verify curl is installed for Slack notifications
   - Ensure mail utility is configured for email notifications

2. If permission errors occur:
   - Verify script is run with appropriate privileges
   - Check file permissions

## Maintenance
- Review and rotate log files periodically
- Update Slack webhook URL if changed
- Verify email configuration remains valid
