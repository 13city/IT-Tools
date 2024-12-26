#!/usr/bin/env bash
# 
# .SYNOPSIS
#   Automates SSL/TLS certificate renewal for domains.
#
# .DESCRIPTION
#   This script:
#   - Supports both self-signed and Let's Encrypt certificates
#   - Generates new self-signed certificates with custom parameters
#   - Automates Let's Encrypt certificate renewal using certbot
#   - Creates necessary directory structure
#   - Provides detailed logging of all operations
#
# .NOTES
#   Author: 13city
#   Compatible with: Ubuntu 18.04+, RHEL/CentOS 7+, Debian 10+
#   Requirements: openssl, certbot (for Let's Encrypt mode)
#
# .PARAMETER MODE
#   Certificate type to generate: 'selfsigned' or 'letsencrypt'
#
# .PARAMETER DOMAIN
#   Domain name for the certificate (e.g., example.com)
#
# .EXAMPLE
#   ./ssl_renew.sh selfsigned myinternaldomain.local
#   ./ssl_renew.sh letsencrypt example.com
#

MODE="$1"        # "selfsigned" or "letsencrypt"
DOMAIN="$2"      # e.g., "myinternaldomain.local" or "domainname.com"
CERT_DIR="/etc/ssl/$DOMAIN"
LOGFILE="/var/log/ssl_renew.log"

echo "=== Starting SSL certificate renewal at $(date) ===" | tee -a "$LOGFILE"

if [ "$MODE" == "selfsigned" ]; then
  echo "Generating self-signed certificate for $DOMAIN..." | tee -a "$LOGFILE"
  mkdir -p "$CERT_DIR"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/$DOMAIN.key" \
    -out "$CERT_DIR/$DOMAIN.crt" \
    -subj "/CN=$DOMAIN/O=MyCompany/C=US" 2>>"$LOGFILE"

  echo "Self-signed certificate created at $CERT_DIR" | tee -a "$LOGFILE"

elif [ "$MODE" == "letsencrypt" ]; then
  echo "Requesting Let’s Encrypt certificate for $DOMAIN..." | tee -a "$LOGFILE"
  # Example usage of certbot in non-interactive mode
  certbot certonly --standalone -d "$DOMAIN" --agree-tos -m "admin@$DOMAIN" -n >>"$LOGFILE" 2>&1
  if [ $? -eq 0 ]; then
    echo "Let’s Encrypt certificate obtained successfully!" | tee -a "$LOGFILE"
  else
    echo "ERROR: Let’s Encrypt certificate request failed. Check logs." | tee -a "$LOGFILE"
    exit 1
  fi
else
  echo "Usage: $0 [selfsigned|letsencrypt] <domain>" | tee -a "$LOGFILE"
  exit 1
fi

echo "=== ssl_renew.sh completed at $(date) ===" | tee -a "$LOGFILE"
exit 0
