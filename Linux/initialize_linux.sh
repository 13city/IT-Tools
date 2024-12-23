#!/usr/bin/env bash
#
# initialize_linux.sh
#
# SYNOPSIS
#   Performs basic setup on a fresh Linux server.
#   - Updates system
#   - Installs common packages
#   - Creates a privileged user
#   - Configures firewall (ufw or firewalld if needed)
#
# NOTES
#   Compatible with: Ubuntu, Debian, CentOS, RHEL
#

LOGFILE="/var/log/initialize_linux.log"
ADMINUSER="admin"
ADMINPASS="Admin@123"
ENABLE_FIREWALL=true  # set to false if you do not wish to configure firewall

echo "===== Starting Linux initialization at $(date) =====" | tee -a "$LOGFILE"

# 1. Update & Install Common Packages
if command -v apt-get >/dev/null 2>&1; then
    echo "Updating system (apt)..." | tee -a "$LOGFILE"
    apt-get update -y && apt-get upgrade -y
    echo "Installing packages (curl, vim, git)..." | tee -a "$LOGFILE"
    apt-get install -y curl vim git
elif command -v yum >/dev/null 2>&1; then
    echo "Updating system (yum)..." | tee -a "$LOGFILE"
    yum update -y
    echo "Installing packages (curl, vim, git)..." | tee -a "$LOGFILE"
    yum install -y curl vim git
else
    echo "ERROR: Neither apt-get nor yum is found. Exiting." | tee -a "$LOGFILE"
    exit 1
fi

# 2. Create privileged user
if id "$ADMINUSER" &>/dev/null; then
    echo "User $ADMINUSER already exists. Skipping creation..." | tee -a "$LOGFILE"
else
    echo "Creating user $ADMINUSER..." | tee -a "$LOGFILE"
    useradd -m -s /bin/bash "$ADMINUSER"
    echo "$ADMINUSER:$ADMINPASS" | chpasswd
    usermod -aG sudo "$ADMINUSER" 2>/dev/null || usermod -aG wheel "$ADMINUSER" 2>/dev/null
    echo "User $ADMINUSER created and added to sudo/wheel group." | tee -a "$LOGFILE"
fi

# 3. Configure Firewall
if [ "$ENABLE_FIREWALL" = true ]; then
    if command -v ufw >/dev/null 2>&1; then
        echo "Configuring firewall (ufw)..." | tee -a "$LOGFILE"
        ufw allow OpenSSH
        ufw --force enable
        echo "ufw enabled and OpenSSH allowed." | tee -a "$LOGFILE"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "Configuring firewall (firewalld)..." | tee -a "$LOGFILE"
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --reload
        echo "firewalld reloaded and SSH allowed." | tee -a "$LOGFILE"
    else
        echo "No recognized firewall utility (ufw/firewalld). Skipping firewall setup..." | tee -a "$LOGFILE"
    fi
else
    echo "Firewall configuration is disabled (ENABLE_FIREWALL=false)." | tee -a "$LOGFILE"
fi

echo "===== Linux initialization completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
