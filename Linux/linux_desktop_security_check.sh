#!/usr/bin/env bash
#
# linux_desktop_security_check.sh
#
# SYNOPSIS
#   Security checks for Linux desktop (e.g., Ubuntu, Debian).
#
# DESCRIPTION
#   - Checks if auto-login is enabled (potential security risk).
#   - Verifies if screensaver lock or idle lock is configured.
#   - Ensures at least a minimal firewall setup or NAT rules.
#   - Logs findings to /var/log/linux_desktop_security_check.log
#

LOGFILE="/var/log/linux_desktop_security_check.log"

echo "===== Starting Linux Desktop Security Check at $(date) =====" | tee -a "$LOGFILE"

# 1. Check GDM or LightDM auto-login
if [ -f "/etc/gdm3/custom.conf" ]; then
  autoLogin=$(grep -E 'AutomaticLogin\s*=' /etc/gdm3/custom.conf | awk -F'=' '{print $2}' | xargs)
  if [ -n "$autoLogin" ]; then
    echo "WARNING: Auto-login configured for user: $autoLogin in /etc/gdm3/custom.conf" | tee -a "$LOGFILE"
  else
    echo "No auto-login found in GDM config." | tee -a "$LOGFILE"
  fi
elif [ -f "/etc/lightdm/lightdm.conf" ]; then
  autoLogin=$(grep -E '^autologin-user=' /etc/lightdm/lightdm.conf | awk -F'=' '{print $2}' | xargs)
  if [ -n "$autoLogin" ]; then
    echo "WARNING: Auto-login configured for user: $autoLogin in /etc/lightdm/lightdm.conf" | tee -a "$LOGFILE"
  else
    echo "No auto-login found in LightDM config." | tee -a "$LOGFILE"
  fi
else
  echo "No GDM or LightDM config found. Possibly using another DM or console only." | tee -a "$LOGFILE"
fi

# 2. Check screensaver or idle lock settings (GNOME example)
dconfExists=$(command -v dconf)
if [ -n "$dconfExists" ]; then
  idleDelay=$(dconf read /org/gnome/desktop/session/idle-delay)
  lockEnabled=$(dconf read /org/gnome/desktop/screensaver/lock-enabled)
  echo "GNOME Idle Delay: $idleDelay" | tee -a "$LOGFILE"
  echo "GNOME Lock Enabled: $lockEnabled" | tee -a "$LOGFILE"
  # If needed, parse them further to see if they're secure enough (e.g., < 5 min).
else
  echo "dconf not found; skipping GNOME screensaver checks." | tee -a "$LOGFILE"
fi

# 3. Minimal firewall check
if command -v ufw >/dev/null 2>&1; then
  ufwStatus=$(ufw status | grep '^Status:' | awk '{print $2}')
  if [ "$ufwStatus" != "active" ]; then
    echo "WARNING: ufw not active on desktop system." | tee -a "$LOGFILE"
  else
    echo "ufw is active." | tee -a "$LOGFILE"
  fi
else
  echo "WARNING: ufw not installed on this desktop system." | tee -a "$LOGFILE"
fi

echo "===== Linux Desktop Security Check Completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
