# Linux Administration Scripts

This directory contains a collection of Linux administration and security scripts. Each script is documented below with its purpose, usage, and requirements.

## auto_provision.sh

### Purpose
Automates the initial provisioning of a Linux server by configuring storage, users, SSH security, and installing essential packages. The script is designed to work with both Debian/Ubuntu and RHEL-based distributions.

### Features
- Configures LVM on a secondary disk
- Creates and mounts a data partition
- Sets up standard user accounts
- Implements SSH security hardening
- Installs essential system packages
- Works across different Linux distributions
- Maintains detailed logs of all operations

### Requirements
- Root or sudo access
- Available secondary disk (default: /dev/sdb)
- Basic system utilities (parted, LVM tools)
- Package manager (apt or yum)

### Usage
```bash
sudo ./auto_provision.sh
```

### Configuration Variables
The script uses several configurable variables at the top:
```bash
LOGFILE="/var/log/auto_provision.log"
DISK="/dev/sdb"            # Target disk for LVM
VGNAME="vg_data"          # Volume group name
LVNAME="lv_data"          # Logical volume name
MOUNTPOINT="/data"        # Mount point for new volume
USERNAME="devops"         # Default user to create
SSHD_CONFIG="/etc/ssh/sshd_config"
```

### Operations Performed
1. **Disk Configuration**
   - Partitions the specified disk
   - Sets up LVM (Physical Volume, Volume Group, Logical Volume)
   - Creates ext4 filesystem
   - Configures automatic mounting via /etc/fstab

2. **User Management**
   - Creates specified user account
   - Configures shell access
   - Removes initial password (preparation for SSH key authentication)

3. **SSH Security**
   - Disables password authentication
   - Disables root login
   - Restarts SSH service to apply changes

4. **Package Installation**
   - Updates package repositories
   - Installs essential tools (git, curl, htop)
   - Handles different package managers (apt/yum)

### Error Handling
- Validates disk existence before operations
- Checks for existing user accounts
- Logs all operations and errors
- Provides clear error messages

### Log File
The script maintains a detailed log at `/var/log/auto_provision.log` containing:
- Timestamp of operations
- Success/failure of each step
- Error messages and warnings

### Customization
To customize the script for your environment:
1. Modify the variables at the top of the script
2. Adjust the package list in the installation section
3. Modify SSH hardening parameters as needed
4. Add or remove mount options in the fstab entry


## analyze_iptables_logs.sh

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

## ssl_renew.sh

### Purpose
Automates the process of SSL certificate renewal, supporting both self-signed certificates and Let's Encrypt certificates. This script simplifies SSL certificate management for internal and public-facing domains.

### Features
- Supports two certificate types:
  - Self-signed certificates for internal use
  - Let's Encrypt certificates for public domains
- Automated certificate generation/renewal
- Non-interactive mode for automation
- Detailed logging of all operations
- Configurable certificate parameters

### Requirements
- Root or sudo access
- For self-signed: OpenSSL
- For Let's Encrypt: Certbot installed
- Write access to /etc/ssl directory
- Public DNS (for Let's Encrypt mode)

### Usage
```bash
# For self-signed certificates
sudo ./ssl_renew.sh selfsigned mydomain.local

# For Let's Encrypt certificates
sudo ./ssl_renew.sh letsencrypt mydomain.com
```

### Configuration Variables
```bash
MODE="$1"        # Certificate type: "selfsigned" or "letsencrypt"
DOMAIN="$2"      # Domain name
CERT_DIR="/etc/ssl/$DOMAIN"
LOGFILE="/var/log/ssl_renew.log"
```

### Operations Performed
1. **Self-Signed Mode**
   - Creates certificate directory
   - Generates 2048-bit RSA key pair
   - Creates self-signed certificate valid for 365 days
   - Sets appropriate subject fields

2. **Let's Encrypt Mode**
   - Runs certbot in standalone mode
   - Automatically agrees to terms of service
   - Uses domain admin email
   - Handles certificate renewal

### Error Handling
- Validates input parameters
- Checks certificate generation success
- Logs all operations and errors
- Provides clear usage instructions

### Log File
The script maintains a log at `/var/log/ssl_renew.log` containing:
- Timestamp of operations
- Certificate generation details
- Success/failure status
- Error messages if any

### Certificate Locations
- Self-signed certificates: `/etc/ssl/<domain>/`
  - Private key: `<domain>.key`
  - Certificate: `<domain>.crt`
- Let's Encrypt certificates: Managed by certbot
  - Default location: `/etc/letsencrypt/live/<domain>/`

### Customization
To customize the script:
1. Modify the certificate validity period (default: 365 days)
2. Adjust the RSA key size (default: 2048 bits)
3. Change the certificate subject fields
4. Modify the certificate storage location

## linux_server_security_check.sh

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

## linux_desktop_security_check.sh

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
