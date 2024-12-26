# Log Review and Pattern Search Script

## Overview
This script provides comprehensive log file analysis with pattern matching capabilities, detailed reporting, and notifications. It can search for multiple patterns in log files, with options to limit the search scope by time or number of lines.

## Features
- Search for multiple patterns simultaneously
- Time-based log filtering
- Line-based log filtering
- Color-coded console output
- Detailed logging with timestamps
- Results archiving
- Slack notifications for matches
- Email notifications with detailed reports
- Comprehensive error handling

## Prerequisites
- `grep` with color support
- `curl` for Slack notifications
- Local mail utility (`mail` command) for email notifications
- Proper permissions to read log files

## Installation
1. Ensure the script is executable:
   ```bash
   chmod +x log_review.sh
   ```

2. Set up environment variables for notifications:
   ```bash
   export SLACK_WEBHOOK_URL="your-webhook-url"
   export EMAIL_RECIPIENT="admin@example.com"
   ```

## Usage
```bash
./log_review.sh [OPTIONS] LOG_FILE PATTERN [PATTERN...]
```

### Options
- `-h, --help`: Display help message
- `-n, --last-n-lines N`: Only check last N lines of the log
- `-s, --since TIMESPEC`: Only check entries since specified time
  - Examples: '2 hours ago', 'yesterday', '2024-01-01'

### Examples
```bash
# Search for multiple patterns
./log_review.sh /var/log/syslog "error" "failed"

# Check last 1000 lines for authentication failures
./log_review.sh --last-n-lines 1000 /var/log/auth.log "authentication failure"

# Check for kernel messages in the last 2 hours
./log_review.sh --since "2 hours ago" /var/log/messages "kernel"
```

## Output
The script provides:
1. Real-time console output with color coding
2. Log file in ../logs/log_review_YYYYMMDD.log
3. Results file in ../logs/reviews/review_YYYYMMDD_HHMMSS.log
4. Slack notifications for matches
5. Email notifications with detailed reports

## Exit Codes
- 0: Success (regardless of whether matches were found)
- 1: Error (invalid arguments, file not found/readable, etc.)

## Logging
### Script Logs
Stored in ../logs/log_review_YYYYMMDD.log with:
- Timestamp
- Search parameters
- Error messages (if any)

### Results
Stored in ../logs/reviews/review_YYYYMMDD_HHMMSS.log with:
- Search timestamp
- Log file path
- Patterns searched
- Matching entries with context

## Notifications
### Slack
- Sends alerts when patterns are matched
- Includes number of matches
- Shows log file and patterns

### Email
- Sends detailed reports of matches
- Includes full search parameters
- Lists number of matches found

## Security Considerations
- Script requires read access to log files
- Webhook URLs and email addresses should be properly secured
- Consider implications of pattern matching sensitive data
- Ensure results directory permissions are restricted

## Troubleshooting
1. If notifications aren't working:
   - Verify environment variables are set
   - Check network connectivity
   - Verify curl is installed for Slack notifications
   - Ensure mail utility is configured for email notifications

2. If pattern matching fails:
   - Check log file permissions
   - Verify pattern syntax
   - Check for special characters in patterns
   - Ensure log file is text-based

3. If time-based filtering fails:
   - Check date format in log files
   - Verify timespec format
   - Ensure system timezone is correct

## Maintenance
- Review and rotate script logs periodically
- Clean up old results files
- Update Slack webhook URL if changed
- Verify email configuration remains valid

## Best Practices
1. Use specific patterns to reduce false positives
2. Consider time-based filtering for large log files
3. Archive or clean up old result files
4. Document common patterns for your environment
5. Use quotes around patterns with spaces
6. Test patterns on small log samples first

## Common Use Cases
1. Security monitoring:
   ```bash
   ./log_review.sh /var/log/auth.log "Failed password" "Invalid user"
   ```

2. Error detection:
   ```bash
   ./log_review.sh /var/log/syslog "error" "critical" "failed"
   ```

3. Application monitoring:
   ```bash
   ./log_review.sh --since "1 hour ago" /var/log/application.log "exception" "error"
   ```

4. System health checks:
   ```bash
   ./log_review.sh /var/log/messages "oom killer" "out of memory" "disk full"
