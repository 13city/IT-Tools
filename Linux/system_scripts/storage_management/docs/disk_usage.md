# Disk Usage Monitoring Script

## Overview
This script provides comprehensive disk usage monitoring and large directory identification with notifications. It helps identify storage issues by monitoring disk space usage and finding the largest directories in a specified path.

## Features
- Monitor disk space usage with configurable thresholds
- Identify and list largest directories
- Color-coded console output
- Detailed logging with timestamps
- Slack notifications for threshold breaches
- Email notifications with detailed reports
- Comprehensive error handling
- Human-readable size formatting

## Prerequisites
- `df` and `du` commands
- `curl` for Slack notifications
- Local mail utility (`mail` command) for email notifications
- Proper permissions to read target directories

## Installation
1. Ensure the script is executable:
   ```bash
   chmod +x disk_usage.sh
   ```

2. Set up environment variables for notifications:
   ```bash
   export SLACK_WEBHOOK_URL="your-webhook-url"
   export EMAIL_RECIPIENT="admin@example.com"
   ```

## Usage
```bash
./disk_usage.sh [OPTIONS] [TARGET_DIR]
```

### Options
- `-h, --help`: Display help message
- `-t, --alert-threshold PCT`: Set alert threshold percentage (default: 10)
- `-n, --top-n N`: Show top N largest directories (default: 5)

### Examples
```bash
# Check /var directory with default settings
./disk_usage.sh /var

# Custom threshold and number of directories
./disk_usage.sh --alert-threshold 15 --top-n 10 /opt

# Check default directory (/var)
./disk_usage.sh
```

## Output
The script provides:
1. Real-time console output with color coding
2. Log file in ../logs/disk_usage_YYYYMMDD.log
3. Disk usage statistics
4. List of largest directories
5. Slack notifications for threshold breaches
6. Email notifications with detailed reports

## Exit Codes
- 0: Success (usage below threshold)
- 1: Error or usage above threshold

## Logging
Logs are stored in the ../logs directory with the format:
```
disk_usage_YYYYMMDD.log
```

Each log entry includes:
- Timestamp
- Disk usage statistics
- Directory scan results
- Error messages (if any)

## Notifications
### Slack
- Sends alerts when disk usage exceeds threshold
- Includes partition and usage details
- Lists largest directories

### Email
- Sends detailed reports of disk usage
- Includes full directory size analysis
- Shows timestamp and threshold details

## Security Considerations
- Script requires read access to target directories
- Webhook URLs and email addresses should be properly secured
- Consider implications of directory scanning on system load
- Ensure log directory permissions are restricted

## Troubleshooting
1. If notifications aren't working:
   - Verify environment variables are set
   - Check network connectivity
   - Verify curl is installed for Slack notifications
   - Ensure mail utility is configured for email notifications

2. If directory scanning fails:
   - Check directory permissions
   - Verify disk is mounted and accessible
   - Check for system resource constraints
   - Ensure target directory exists

3. If size formatting issues occur:
   - Verify df and du commands are available
   - Check system locale settings
   - Ensure proper text encoding

## Maintenance
- Review and rotate log files periodically
- Update Slack webhook URL if changed
- Verify email configuration remains valid
- Adjust thresholds based on system requirements

## Best Practices
1. Set appropriate thresholds for your system
2. Run regularly through cron jobs
3. Monitor trends over time
4. Keep documentation of normal usage patterns
5. Test notifications periodically
6. Consider filesystem-specific thresholds

## Common Use Cases
1. System monitoring:
   ```bash
   ./disk_usage.sh --alert-threshold 90 /
   ```

2. Application storage monitoring:
   ```bash
   ./disk_usage.sh --top-n 10 /var/www
   ```

3. User home directory analysis:
   ```bash
   ./disk_usage.sh --alert-threshold 80 /home
   ```

4. Temporary file monitoring:
   ```bash
   ./disk_usage.sh --alert-threshold 70 /tmp
   ```

## Integration Tips
1. Cron job setup:
   ```bash
   # Check every hour
   0 * * * * /path/to/disk_usage.sh /var
   ```

2. System monitoring integration:
   ```bash
   # Add to monitoring scripts
   if ! ./disk_usage.sh --alert-threshold 85 /; then
       # Take action on threshold breach
       cleanup_space.sh
   fi
   ```

3. Multiple directory monitoring:
   ```bash
   # Create a wrapper script
   for dir in /var /opt /home; do
       ./disk_usage.sh "$dir"
   done
