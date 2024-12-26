# File Permissions and Ownership Fix Script

## Overview
This script provides a robust solution for recursively fixing file ownership and permissions in a specified directory. It includes comprehensive logging, notifications, and a dry-run mode for safely previewing changes.

## Features
- Recursive permission and ownership fixes
- Dry-run mode for previewing changes
- Color-coded console output
- Detailed logging with timestamps
- Slack notifications for changes
- Email notifications with detailed reports
- Comprehensive error handling
- User and group validation

## Prerequisites
- `curl` for Slack notifications
- Local mail utility (`mail` command) for email notifications
- Proper permissions to modify target directories
- `stat` command for file information

## Installation
1. Ensure the script is executable:
   ```bash
   chmod +x fix_permissions.sh
   ```

2. Set up environment variables for notifications:
   ```bash
   export SLACK_WEBHOOK_URL="your-webhook-url"
   export EMAIL_RECIPIENT="admin@example.com"
   ```

## Usage
```bash
./fix_permissions.sh [OPTIONS] TARGET_DIR
```

### Options
- `-h, --help`: Display help message
- `-d, --dry-run`: Show what would be changed without making changes
- `-o, --owner USER`: Set owner (default: current user)
- `-g, --group GROUP`: Set group (default: current user's primary group)
- `-p, --perms MODE`: Set permissions in octal notation (default: 750)

### Examples
```bash
# Basic usage with default settings
./fix_permissions.sh /var/www/app

# Change owner and group
./fix_permissions.sh --owner www-data --group www-data /var/www/app

# Preview changes with different permissions
./fix_permissions.sh --dry-run --perms 755 /var/www/app
```

## Output
The script provides:
1. Real-time console output with color coding
2. Log file in ../logs/fix_permissions_YYYYMMDD.log
3. Slack notifications for changes
4. Email notifications with detailed reports

## Exit Codes
- 0: Success
- 1: Error (invalid arguments, missing directory, permission denied, etc.)

## Logging
Logs are stored in the ../logs directory with the format:
```
fix_permissions_YYYYMMDD.log
```

Each log entry includes:
- Timestamp
- Action performed
- File path
- Old and new permissions/ownership
- Error messages (if any)

## Notifications
### Slack
- Sends alerts when changes are made
- Includes summary of changes
- Shows target directory and timestamp

### Email
- Sends detailed reports of changes
- Includes full path information
- Lists number of files processed and changed

## Security Considerations
- Script requires appropriate permissions to modify target files
- Webhook URLs and email addresses should be properly secured
- Consider implications of permission changes on system security
- Use dry-run mode first to preview changes

## Troubleshooting
1. If notifications aren't working:
   - Verify environment variables are set
   - Check network connectivity
   - Verify curl is installed for Slack notifications
   - Ensure mail utility is configured for email notifications

2. If permission errors occur:
   - Verify script is run with appropriate privileges
   - Check target directory permissions
   - Verify user has permission to change ownership

3. If validation fails:
   - Verify user/group exists on the system
   - Check permission format (must be octal)
   - Ensure target directory exists and is accessible

## Maintenance
- Review and rotate log files periodically
- Update Slack webhook URL if changed
- Verify email configuration remains valid
- Test dry-run mode before making large-scale changes

## Best Practices
1. Always use --dry-run first to preview changes
2. Back up important directories before making changes
3. Test on a small subset of files first
4. Use appropriate permissions based on security requirements
5. Document any custom permission schemes used
