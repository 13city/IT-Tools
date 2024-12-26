#!/usr/bin/env bash
# 
# .SYNOPSIS
#   Automates Linux server provisioning and configuration.
#
# .DESCRIPTION
#   This script:
#   - Configures LVM storage on a new disk
#   - Creates and configures standard user accounts
#   - Implements SSH security hardening
#   - Installs essential system packages
#   - Provides detailed logging of all operations
#
# .NOTES
#   Author: 13city
#   Compatible with: Ubuntu 18.04+, RHEL/CentOS 7+, Debian 10+
#   Requirements: Root/sudo access, available secondary disk
#
# .PARAMETER LOGFILE
#   Path where provisioning logs will be written
#   Default: /var/log/auto_provision.log
#
# .PARAMETER DISK
#   Target disk for LVM configuration
#   Default: /dev/sdb
#
# .PARAMETER VGNAME
#   Name for the volume group
#   Default: vg_data
#
# .PARAMETER LVNAME
#   Name for the logical volume
#   Default: lv_data
#
# .PARAMETER MOUNTPOINT
#   Mount point for the new volume
#   Default: /data
#
# .PARAMETER USERNAME
#   Username for the new system account
#   Default: devops
#
# .EXAMPLE
#   sudo ./auto_provision.sh
#   Provisions server with default settings
#

LOGFILE="/var/log/auto_provision.log"
DISK="/dev/sdb"            # Example for a secondary disk
VGNAME="vg_data"
LVNAME="lv_data"
MOUNTPOINT="/data"
USERNAME="devops"
SSHD_CONFIG="/etc/ssh/sshd_config"

echo "=== Starting auto_provision.sh at $(date) ===" | tee -a "$LOGFILE"

# 1. Check if $DISK exists
if [ ! -b "$DISK" ]; then
  echo "ERROR: Disk $DISK not found. Exiting." | tee -a "$LOGFILE"
  exit 1
fi

# 2. Partition and LVM setup (assuming entire /dev/sdb used)
echo "Partitioning and setting up LVM on $DISK..." | tee -a "$LOGFILE"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart primary 0% 100%
pvcreate "${DISK}1"
vgcreate "$VGNAME" "${DISK}1"
lvcreate -n "$LVNAME" -l 100%FREE "$VGNAME"
mkfs.ext4 "/dev/$VGNAME/$LVNAME"
mkdir -p "$MOUNTPOINT"
echo "/dev/$VGNAME/$LVNAME  $MOUNTPOINT  ext4  defaults  0  2" >> /etc/fstab
mount -a

# 3. Create standard user
echo "Creating user $USERNAME..." | tee -a "$LOGFILE"
id "$USERNAME" &>/dev/null
if [ $? -ne 0 ]; then
   useradd -m -s /bin/bash "$USERNAME"
   passwd -d "$USERNAME"  # remove password, might set up SSH key
else
   echo "User $USERNAME already exists. Skipping creation." | tee -a "$LOGFILE"
fi

# 4. SSH Hardening
echo "Hardening SSH..." | tee -a "$LOGFILE"
sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' "$SSHD_CONFIG"
systemctl restart sshd

# 5. Install base packages
echo "Installing base packages (git, curl, htop)..." | tee -a "$LOGFILE"
if command -v apt-get >/dev/null; then
   apt-get update -y
   apt-get install -y git curl htop
elif command -v yum >/dev/null; then
   yum install -y git curl htop
fi

echo "=== auto_provision.sh completed successfully at $(date) ===" | tee -a "$LOGFILE"
exit 0
