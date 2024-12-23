#!/usr/bin/env bash
#
# linux_server_security_check.sh
#
# SYNOPSIS
#   Security misconfiguration checker for general Linux servers (Ubuntu, Debian, RHEL, CentOS).
#
# DESCRIPTION
#   - Checks if firewall (ufw or firewalld) is running and has basic rules.
#   - Verifies SSH settings (root login disabled, password auth disabled if desired).
#   - Ensures critical security packages are installed (fail2ban, etc.).
#   - Logs findings to /var/log/linux_server_security_check.log
#

LOGFILE="/var/log/linux_server_security_check.log"

echo "===== Starting Linux Server Security Check at $(date) =====" | tee -a "$LOGFILE"

# 1. Check firewall status
if command -v ufw >/dev/null 2>&1; then
  fwStatus=$(ufw status | grep -i 'Status:')
  echo "UFW firewall status: $fwStatus" | tee -a "$LOGFILE"
elif command -v firewall-cmd >/dev/null 2>&1; then
  fwState=$(firewall-cmd --state 2>/dev/null)
  if [ "$fwState" == "running" ]; then
    echo "firewalld is running." | tee -a "$LOGFILE"
  else
    echo "WARNING: firewalld not running or not installed." | tee -a "$LOGFILE"
  fi
else
  echo "WARNING: No recognized firewall (ufw/firewalld) found." | tee -a "$LOGFILE"
fi

# 2. Check SSH settings
SSH_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSH_CONFIG" ]; then
  rootLogin=$(grep -E '^PermitRootLogin\s+' "$SSH_CONFIG" | awk '{print $2}')
  if [ "$rootLogin" != "no" ]; then
    echo "WARNING: PermitRootLogin is not set to 'no' in $SSH_CONFIG" | tee -a "$LOGFILE"
  else
    echo "Root login disabled - OK" | tee -a "$LOGFILE"
  fi

  passAuth=$(grep -E '^PasswordAuthentication\s+' "$SSH_CONFIG" | awk '{print $2}')
  if [ "$passAuth" != "no" ]; then
    echo "WARNING: PasswordAuthentication is not set to 'no' in $SSH_CONFIG" | tee -a "$LOGFILE"
  else
    echo "PasswordAuthentication disabled - OK" | tee -a "$LOGFILE"
  fi
else
  echo "ERROR: $SSH_CONFIG not found. Cannot verify SSH settings." | tee -a "$LOGFILE"
fi

# 3. Check if fail2ban or intrusion detection installed
if command -v fail2ban-client >/dev/null 2>&1; then
  echo "fail2ban is installed." | tee -a "$LOGFILE"
else
  echo "WARNING: fail2ban is not installed. Consider installing it for brute-force protection." | tee -a "$LOGFILE"
fi

# (Optional) 4. Check automatic updates or relevant security updates
if command -v apt-get >/dev/null 2>&1; then
  aptSecUpdates=$(apt-get upgrade --just-print | grep "^Inst" | grep -i security)
  if [ -n "$aptSecUpdates" ]; then
    echo "WARNING: There are pending security updates:" | tee -a "$LOGFILE"
    echo "$aptSecUpdates" | tee -a "$LOGFILE"
  else
    echo "No pending security updates from apt-get." | tee -a "$LOGFILE"
  fi
elif command -v yum >/dev/null 2>&1; then
  yum check-update --security 2>/dev/null
  if [ $? -eq 100 ]; then
    echo "WARNING: There are pending security updates via yum." | tee -a "$LOGFILE"
  else
    echo "No pending security updates found via yum." | tee -a "$LOGFILE"
  fi
fi

echo "===== Linux Server Security Check Completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
