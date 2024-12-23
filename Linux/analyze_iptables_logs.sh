#!/usr/bin/env bash
#
# analyze_iptables_logs.sh
#
# SYNOPSIS
#   Parses iptables log entries for blocked traffic, identifying top offending IPs and ports.
#

LOGFILE="/var/log/iptables_analysis.log"
SYSLOG_PATH="/var/log/syslog"   # or /var/log/messages on RHEL-based

echo "=== Starting iptables log analysis at $(date) ===" | tee -a "$LOGFILE"

if [ ! -f "$SYSLOG_PATH" ]; then
  echo "ERROR: Syslog not found at $SYSLOG_PATH. Exiting." | tee -a "$LOGFILE"
  exit 1
fi

# Filter lines with iptables or netfilter messages
TMPFILE=$(mktemp)
grep -E 'iptables|IN=|OUT=' "$SYSLOG_PATH" > "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
  echo "No iptables-related logs found." | tee -a "$LOGFILE"
  rm -f "$TMPFILE"
  exit 0
fi

# Extract IP addresses and ports from lines referencing "DPT=" or "SRC="
echo "Top 5 Source IP addresses blocked:" | tee -a "$LOGFILE"
cat "$TMPFILE" | grep "SRC=" | sed 's/.*SRC=\([^ ]*\).*/\1/' | sort | uniq -c | sort -rn | head -5 | tee -a "$LOGFILE"

echo "" | tee -a "$LOGFILE"
echo "Top 5 Destination Ports targeted:" | tee -a "$LOGFILE"
cat "$TMPFILE" | grep "DPT=" | sed 's/.*DPT=\([^ ]*\).*/\1/' | sort | uniq -c | sort -rn | head -5 | tee -a "$LOGFILE"

rm -f "$TMPFILE"
echo "=== iptables log analysis completed at $(date) ===" | tee -a "$LOGFILE"
exit 0
