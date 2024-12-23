# linux_desktop_security_check.sh

### Purpose
Performs security auditing specifically tailored for Linux desktop environments, focusing on GUI-related security settings and common desktop vulnerabilities. The script is primarily designed for Ubuntu and Debian-based desktop distributions.

### Features
- Auto-login detection and warning
- Screensaver/idle lock configuration check
- Desktop firewall verification
- Support for multiple display managers
- Detailed logging of security findings

### Requirements
- Root or sudo access
- Desktop environment (GNOME, etc.)
- Display manager (GDM3 or LightDM)
- Basic system utilities

### Usage
```bash
sudo ./linux_desktop_security_check.sh
```

### Security Checks Performed

1. **Display Manager Security**
   - Checks GDM3 auto-login settings
   - Verifies LightDM auto-login configuration
   - Reports potentially risky auto-login setups

2. **Screen Lock Security**
   - Validates screensaver lock settings
   - Checks idle timeout configuration
   - Verifies automatic screen lock functionality

3. **Desktop Firewall**
   - Verifies UFW installation and status
   - Checks firewall activation state
   - Reports if desktop firewall protection is missing

### Output Format
The script provides both real-time console output and logged results:
```
===== Starting Linux Desktop Security Check at [timestamp] =====
No auto-login found in GDM config.
GNOME Idle Delay: uint32 300
GNOME Lock Enabled: true
ufw is active.
===== Linux Desktop Security Check Completed at [timestamp] =====
```

### Error Handling
- Handles missing configuration files
- Adapts to different display managers
- Provides clear warnings for security issues
- Gracefully handles missing components

### Log File
The script maintains a detailed log at `/var/log/linux_desktop_security_check.log` containing:
- Timestamp of security checks
- Auto-login configuration status
- Screen lock settings
- Firewall status
- Security warnings and recommendations

### Customization
To customize the script:
1. Add checks for additional display managers
2. Modify security thresholds
3. Add checks for specific desktop environments
4. Include additional desktop security policies

### Best Practices
- Run regularly on desktop systems
- Review auto-login configurations
- Ensure screen lock is properly configured
- Maintain active desktop firewall
- Address security warnings promptly
