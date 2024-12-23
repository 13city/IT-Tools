#!/usr/bin/env bash
#
# vault_secret_scanner.sh
#
# SYNOPSIS
#   Advanced script to scan a HashiCorp Vault (or similar) for secret misconfigurations.
#
# DESCRIPTION
#   - Checks if vault CLI is installed and VAULT_ADDR is set.
#   - Retrieves a list of secret paths from a given mount.
#   - Verifies each secret for 'max_age' or 'rotation_interval' compliance if metadata is stored.
#   - Logs warnings if secrets are stale or missing mandatory metadata.
#

LOGFILE="/var/log/vault_secret_scanner.log"
DEFAULT_MOUNT="secret/"

echo "===== Starting Vault Secret Scanner at $(date) =====" | tee -a "$LOGFILE"

# 1. Check Vault CLI and environment
if ! command -v vault >/dev/null 2>&1; then
  echo "ERROR: vault CLI is not installed. Cannot proceed." | tee -a "$LOGFILE"
  exit 1
fi

if [ -z "$VAULT_ADDR" ]; then
  echo "ERROR: VAULT_ADDR not set. Export VAULT_ADDR and possibly VAULT_TOKEN (or use vault login)." | tee -a "$LOGFILE"
  exit 1
fi

# 2. List secrets under a mount
MOUNT="${1:-$DEFAULT_MOUNT}"
echo "Scanning secrets in mount '$MOUNT'..." | tee -a "$LOGFILE"

# If using KVv2, adapt the listing commands (vault kv list)
secret_list=$(vault kv list -format=json "$MOUNT" 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$secret_list" ]; then
  echo "ERROR: Unable to list secrets at mount $MOUNT. Check permissions or path." | tee -a "$LOGFILE"
  exit 1
fi

echo "$secret_list" | jq -r '.[]' | while read -r secretName; do
  secretPath="$MOUNT$secretName"
  # 3. Retrieve metadata or the secret itself
  # For KV v2, the path might be "vault kv metadata get" etc.
  meta=$(vault kv metadata get -format=json "$secretPath" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$meta" ]; then
    echo "WARNING: Cannot retrieve metadata for $secretPath" | tee -a "$LOGFILE"
    continue
  fi

  # 4. Analyze metadata (e.g., checking custom fields or version_age)
  createdTime=$(echo "$meta" | jq -r '.data.created_time')
  currentVer=$(echo "$meta" | jq -r '.data.current_version')
  if [ "$createdTime" == "null" ]; then
    echo "WARNING: $secretPath missing created_time in metadata." | tee -a "$LOGFILE"
  fi

  # 5. (Optional) Check if older than certain days => stale secret
  # e.g. 30 days
  if [ "$createdTime" != "null" ]; then
    createdEpoch=$(date -d "$createdTime" +%s)
    nowEpoch=$(date +%s)
    ageDays=$(( ($nowEpoch - $createdEpoch) / 86400 ))
    if [ "$ageDays" -gt 30 ]; then
      echo "WARNING: Secret $secretPath is $ageDays days old. Consider rotating." | tee -a "$LOGFILE"
    fi
  fi
done

echo "===== Vault Secret Scanner Completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
