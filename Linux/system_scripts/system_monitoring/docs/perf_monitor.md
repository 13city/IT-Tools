# Performance Monitor Script Documentation

## Overview
The performance monitoring script (`perf_monitor.sh`) provides comprehensive system performance monitoring and reporting capabilities. It tracks CPU usage, memory utilization, system load, disk I/O, and network throughput, with configurable thresholds and notification options.

## Features
- Real-time monitoring of system performance metrics
- Configurable collection intervals and count
- Customizable thresholds for CPU, memory, and system load
- Notification support via Slack and email
- Detailed logging with timestamp
- Network throughput monitoring
- Disk I/O statistics

## Prerequisites
- sysstat package (provides mpstat, iostat)
- bc (basic calculator)
- curl (for Slack notifications)
- mail command (for email notifications)

## Usage
```bash
./perf_monitor.sh [OPTIONS]
```

### Options
- `-h, --help`: Display help message
- `-i, --interval SEC`: Collection interval in seconds (default: 5)
- `-c, --count N`: Number of collections (default: 1)
- `--cpu-threshold PCT`: CPU usage threshold percentage (default: 80)
- `--mem-threshold PCT`: Memory usage threshold percentage (default: 80)
- `--load-threshold N`: Load average threshold (default: 5)

### Examples
```bash
# Basic usage with default settings
./perf_monitor.sh

# Monitor every 10 seconds for 6 collections
./perf_monitor.sh --interval 10 --count 6

# Custom thresholds
./perf_monitor.sh --cpu-threshold 90 --mem-threshold 85 --load-threshold 8
```

## Configuration
The script can be configured using environment variables:

- `SLACK_WEBHOOK_URL`: Webhook URL for Slack notifications
- `EMAIL_RECIPIENT`: Email address for notifications

## Output Metrics
The script provides the following metrics:

1. CPU Usage
   - Percentage of CPU utilization
   - Calculated from mpstat data

2. Memory Usage
   - Percentage of memory utilization
   - Based on free memory command output

3. System Load
   - 1-minute load average
   - From /proc/loadavg

4. Disk I/O
   - Disk utilization percentage
   - Average wait time
   - Collected using iostat

5. Network Throughput
   - Receive (RX) rate
   - Transmit (TX) rate
   - Calculated from /proc/net/dev

## Notifications
Alerts are triggered when metrics exceed defined thresholds:
- CPU usage above threshold
- Memory usage above threshold
- System load above threshold

Notifications can be sent via:
- Slack (requires webhook URL)
- Email (requires valid email recipient)

## Logging
- Logs are stored in `../logs/perf_monitor_YYYYMMDD.log`
- Each entry includes timestamp and collected metrics
- Performance alerts are also logged

## Error Handling
- Strict error checking with set -euo pipefail
- Dependency verification before execution
- Input validation for all command-line arguments
- Graceful handling of missing notification configurations

## Exit Codes
- 0: Successful execution
- 1: Error (invalid arguments, missing dependencies, etc.)

## Limitations
- Network statistics default to eth0 interface
- Email notifications require a configured mail transport agent
- Some metrics may require root privileges for full accuracy

## Troubleshooting
1. Missing dependencies
   - Install sysstat package for mpstat and iostat
   - Ensure mail command is available for email notifications

2. Permission issues
   - Some metrics may require elevated privileges
   - Ensure log directory is writable

3. Notification failures
   - Verify Slack webhook URL is valid
   - Check email configuration is correct
   - Ensure network connectivity

## Security Considerations
- Script runs with user privileges
- Webhook URLs and email addresses should be properly secured
- Log files may contain sensitive system information
