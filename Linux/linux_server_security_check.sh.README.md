# linux_server_security_check.sh

### Purpose
Performs comprehensive security auditing of Linux servers, checking for common misconfigurations and security issues. The script is compatible with major Linux distributions including Ubuntu, Debian, RHEL, and CentOS.

### Features
- Firewall status verification (UFW/firewalld)
- SSH configuration security audit
- Security package presence verification
- Pending security updates check
- Cross-distribution compatibility
- Detailed logging of all findings

### Requirements
- Root or sudo access
- Access to system configuration files
- Package manager (apt or yum)
- SSH server configuration access

### Usage
```bash
sudo ./linux_server_security_check.sh
```

### Security Checks Performed

1. **Firewall Configuration**
   - Detects and verifies UFW or firewalld
   - Checks firewall operational status
   - Reports if no firewall is found

2. **SSH Security**
   - Validates root login restrictions
   - Checks password authentication settings
   - Verifies SSH configuration file presence

3. **Intrusion Prevention**
   - Checks for fail2ban installation
   - Reports if additional protection is needed

4. **System Updates**
   - Identifies pending security updates
   - Supports both apt and yum package managers
   - Reports available security patches

### Output Format
The script provides both real-time console output and logged results:
```
===== Starting Linux Server Security Check at [timestamp] =====
UFW firewall status: active
Root login disabled - OK
PasswordAuthentication disabled - OK
fail2ban is installed.
No pending security updates from apt-get.
===== Linux Server Security Check Completed at [timestamp] =====
```

### Error Handling
- Validates existence of configuration files
- Handles missing utilities gracefully
- Reports warnings for security issues
- Provides clear status messages

### Log File
The script maintains a detailed log at `/var/log/linux_server_security_check.log` containing:
- Timestamp of security checks
- All findings and warnings
- System security status
- Recommended actions

### Customization
To customize the script:
1. Add additional security checks
2. Modify warning thresholds
3. Adjust logging verbosity
4. Add custom security policies

### Best Practices
- Run the script regularly (e.g., via cron)
- Review logs for security trends
- Address warnings promptly
- Keep the script updated with new security checks
