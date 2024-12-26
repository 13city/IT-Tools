#!/usr/bin/env bash
# .SYNOPSIS
#   Checks cloud Linux VM security configurations often relevant in AWS, Azure, or GCP.
#
# .DESCRIPTION
#   This script:
#   - Looks for presence of cloud-init or relevant cloud agent
#   - Verifies SSH key-based login is preferred over password
#   - Checks for disk encryption or checks if ephemeral storage is handled properly
#   - Logs findings to specified log file
#
# .NOTES
#   Author: 13city
#   Compatible with: Ubuntu 18.04+, RHEL/CentOS 7+, Debian 10+
#
# .PARAMETER LOGFILE
#   Path where security check results will be written
#   Default: /var/log/cloud_linux_security_check.log
#
# .EXAMPLE
#   ./cloud_linux_security_check.sh
#   Performs security checks with default logging location
#

LOGFILE="/var/log/cloud_linux_security_check.log"

echo "===== Starting Cloud Linux VM Security Check at $(date) =====" | tee -a "$LOGFILE"

# 1. Check for cloud-init or other cloud agents
if command -v cloud-init >/dev/null 2>&1; then
  echo "cloud-init is installed." | tee -a "$LOGFILE"
else
  echo "WARNING: cloud-init not found. Ensure your cloud environment doesn't require it." | tee -a "$LOGFILE"
fi

# 2. SSH settings for key-based auth
SSH_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSH_CONFIG" ]; then
  passAuth=$(grep -E '^PasswordAuthentication\s+' "$SSH_CONFIG" | awk '{print $2}')
  if [ "$passAuth" == "yes" ]; then
    echo "WARNING: PasswordAuthentication is enabled. Consider key-based only for better security." | tee -a "$LOGFILE"
  else
    echo "SSH key-based auth enforced - good." | tee -a "$LOGFILE"
  fi
else
  echo "ERROR: $SSH_CONFIG not found, can't verify SSH settings." | tee -a "$LOGFILE"
fi

# 3. Check ephemeral storage or encryption (just a minimal placeholder)
if lsblk | grep -i ephemeral >/dev/null 2>&1; then
  echo "Ephemeral storage detected. Ensure sensitive data isn't stored here." | tee -a "$LOGFILE"
fi

# 4. Check any known agent for Azure or AWS (example)
if command -v waagent >/dev/null 2>&1; then
  echo "Azure Linux Agent (waagent) found. Check if it's running." | tee -a "$LOGFILE"
  systemctl is-active waagent >/dev/null || echo "WARNING: Azure Linux Agent not active." | tee -a "$LOGFILE"
fi
if [ -f "/usr/local/bin/cfn-init" ]; then
  echo "AWS cfn-init found - indicates CloudFormation usage." | tee -a "$LOGFILE"
fi

echo "===== Cloud Linux VM Security Check Completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
