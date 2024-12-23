# auto_provision.sh

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
