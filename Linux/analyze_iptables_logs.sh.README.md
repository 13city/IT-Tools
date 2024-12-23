# analyze_iptables_logs.sh

### Purpose
Analyzes iptables firewall logs to identify potential security threats by parsing log entries for blocked traffic. The script identifies and reports the top offending source IP addresses and most frequently targeted ports.

### Features
- Parses system logs for iptables/netfilter entries
- Identifies top 5 blocked source IP addresses
- Shows top 5 targeted destination ports
- Maintains a separate log file for analysis results
- Handles both Debian/Ubuntu and RHEL-based system log locations

### Requirements
- Root or sudo access
- Access to system logs (`/var/log/syslog` or `/var/log/messages`)
- `grep`, `sed`, `sort`, and `uniq` utilities (typically pre-installed)

### Usage
```bash
sudo ./analyze_iptables_logs.sh
```

### Output
The script generates two types of output:
1. Console output showing real-time analysis
2. Log file (`/var/log/iptables_analysis.log`) containing historical analysis data

Example output:
```
=== Starting iptables log analysis at Wed Jan 10 10:00:00 EST 2024 ===
Top 5 Source IP addresses blocked:
     50 192.168.1.100
     35 10.0.0.15
     22 172.16.0.50
     18 192.168.1.200
     10 10.0.0.25

Top 5 Destination Ports targeted:
    100 22    # SSH attempts
     75 80    # HTTP
     45 443   # HTTPS
     30 3389  # RDP attempts
     25 25    # SMTP
=== iptables log analysis completed at Wed Jan 10 10:00:05 EST 2024 ===
```

### Error Handling
- Checks for existence of system log file
- Verifies presence of iptables-related log entries
- Creates temporary files securely
- Cleans up temporary files on exit

### Log File
The script maintains a log file at `/var/log/iptables_analysis.log` which contains:
- Timestamp of analysis runs
- Top offending IP addresses
- Most frequently targeted ports
- Error messages (if any)

### Customization
You can modify the following variables at the top of the script:
- `LOGFILE`: Location of the analysis output log
- `SYSLOG_PATH`: Location of the system log to analyze
