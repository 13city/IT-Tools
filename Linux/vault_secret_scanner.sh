#!/usr/bin/env bash
# 
# .SYNOPSIS
#   Advanced HashiCorp Vault secret configuration scanner and analyzer.
#
# .DESCRIPTION
#   This script:
#   - Performs comprehensive scan of Vault secrets and configurations
#   - Validates environment setup and CLI availability
#   - Lists and analyzes secrets under specified mount points
#   - Checks secret age and rotation compliance
#   - Verifies metadata completeness and validity
#   - Identifies stale secrets requiring rotation
#   - Provides detailed logging of all findings
#
# .NOTES
#   Author: 13city
#   Compatible with: Ubuntu 18.04+, RHEL/CentOS 7+, Debian 10+
#   Requirements: 
#   - HashiCorp Vault CLI
#   - jq for JSON parsing
#   - Valid Vault authentication (token or other method)
#
# .PARAMETER MOUNT
#   Vault mount point to scan
#   Default: secret/
#
# .PARAMETER LOGFILE
#   Path where scan results will be written
#   Default: /var/log/vault_secret_scanner.log
#
# .EXAMPLE
#   ./vault_secret_scanner.sh
#   Scans default secret/ mount point
#
# .EXAMPLE
#   ./vault_secret_scanner.sh kv/
#   Scans specified mount point
#

LOGFILE="/var/log/vault_secret_scanner.log"
DEFAULT_MOUNT="secret/"

echo "===== Starting Vault Secret Scanner at $(date) =====" | tee -a "$LOGFILE"

# 1. Check required dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v vault >/dev/null 2>&1; then
        missing_deps+=("vault")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "ERROR: Missing required dependencies: ${missing_deps[*]}" | tee -a "$LOGFILE"
        echo "Please install missing dependencies and try again." | tee -a "$LOGFILE"
        exit 1
    fi
}

check_dependencies

# Validate environment and authentication
check_environment() {
    if [ -z "$VAULT_ADDR" ]; then
        echo "ERROR: VAULT_ADDR not set. Export VAULT_ADDR and possibly VAULT_TOKEN (or use vault login)." | tee -a "$LOGFILE"
        exit 1
    fi

    # Verify Vault connectivity and authentication
    if ! vault token lookup >/dev/null 2>&1; then
        echo "ERROR: Unable to authenticate with Vault. Check your token or authentication method." | tee -a "$LOGFILE"
        exit 1
    fi

    # Check if we have sufficient permissions
    if ! vault policy read default >/dev/null 2>&1; then
        echo "WARNING: Limited permissions detected. Some operations may fail." | tee -a "$LOGFILE"
    fi
}

check_environment

# Configuration
ROTATION_AGE_DAYS=30
MAX_VERSIONS=10
REPORT_FILE="/tmp/vault_scan_report_$(date +%Y%m%d_%H%M%S).html"

# 2. List and validate secrets under mount
MOUNT="${1:-$DEFAULT_MOUNT}"
echo "Scanning secrets in mount '$MOUNT'..." | tee -a "$LOGFILE"

# Determine KV version
kv_version=$(vault secrets list -format=json | jq -r ".[\"$MOUNT\"].options.version")
if [ "$kv_version" != "1" ] && [ "$kv_version" != "2" ]; then
    echo "ERROR: Unable to determine KV version for mount $MOUNT" | tee -a "$LOGFILE"
    exit 1
fi

# List secrets based on KV version
if [ "$kv_version" = "2" ]; then
    secret_list=$(vault kv list -format=json "$MOUNT" 2>/dev/null)
else
    secret_list=$(vault list -format=json "$MOUNT" 2>/dev/null)
fi

if [ $? -ne 0 ] || [ -z "$secret_list" ]; then
    echo "ERROR: Unable to list secrets at mount $MOUNT. Check permissions or path." | tee -a "$LOGFILE"
    exit 1
fi

# Initialize HTML report
cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Vault Secret Scan Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Vault Secret Scan Report - $(date)</h1>
    <table>
        <tr>
            <th>Secret Path</th>
            <th>Age (Days)</th>
            <th>Versions</th>
            <th>Last Modified</th>
            <th>Status</th>
        </tr>
EOF

# Process secrets
process_secret() {
    local secretName="$1"
    local secretPath="$MOUNT$secretName"
    local status=""
    
    # Get metadata based on KV version
    if [ "$kv_version" = "2" ]; then
        meta=$(vault kv metadata get -format=json "$secretPath" 2>/dev/null)
    else
        # For KV v1, we'll get the secret itself to check timestamps
        meta=$(vault read -format=json "$secretPath" 2>/dev/null)
    fi
    
    if [ $? -ne 0 ] || [ -z "$meta" ]; then
        echo "WARNING: Cannot retrieve metadata for $secretPath" | tee -a "$LOGFILE"
        return
    fi
    
    # Extract metadata based on KV version
    if [ "$kv_version" = "2" ]; then
        createdTime=$(echo "$meta" | jq -r '.data.created_time')
        currentVer=$(echo "$meta" | jq -r '.data.current_version')
        versions=$(echo "$meta" | jq -r '.data.versions | length')
        lastModified=$(echo "$meta" | jq -r '.data.updated_time')
    else
        createdTime=$(echo "$meta" | jq -r '.data.creation_time')
        currentVer="1"
        versions="1"
        lastModified=$(echo "$meta" | jq -r '.data.creation_time')
    fi
    
    # Validate metadata
    if [ "$createdTime" == "null" ]; then
        echo "WARNING: $secretPath missing creation time metadata" | tee -a "$LOGFILE"
        status="Missing metadata"
    fi
    
    # Check secret age
    if [ "$createdTime" != "null" ]; then
        createdEpoch=$(date -d "$createdTime" +%s)
        nowEpoch=$(date +%s)
        ageDays=$(( ($nowEpoch - $createdEpoch) / 86400 ))
        
        if [ "$ageDays" -gt "$ROTATION_AGE_DAYS" ]; then
            status="${status}Rotation needed (${ageDays} days old); "
        fi
    fi
    
    # Check version count
    if [ "$versions" -gt "$MAX_VERSIONS" ]; then
        status="${status}Too many versions (${versions}); "
    fi
    
    # Validate secret format (if possible)
    if [ "$kv_version" = "2" ]; then
        secret_data=$(vault kv get -format=json "$secretPath" 2>/dev/null)
        if [ $? -eq 0 ]; then
            # Check if secret is properly formatted JSON
            if ! echo "$secret_data" | jq -e '.data.data' >/dev/null 2>&1; then
                status="${status}Invalid format; "
            fi
        fi
    fi
    
    # Add to HTML report
    echo "<tr>
        <td>$secretPath</td>
        <td>$ageDays</td>
        <td>$versions</td>
        <td>$lastModified</td>
        <td class='${status:+warning}'>$status</td>
    </tr>" >> "$REPORT_FILE"
    
    # Log findings
    if [ -n "$status" ]; then
        echo "WARNING: $secretPath - $status" | tee -a "$LOGFILE"
    fi
}

# Process each secret
echo "$secret_list" | jq -r '.[]' | while read -r secretName; do
    process_secret "$secretName"
done

# Finalize HTML report
cat >> "$REPORT_FILE" << EOF
    </table>
    <p>Scan completed at $(date)</p>
</body>
</html>
EOF

echo "===== Vault Secret Scanner Completed at $(date) =====" | tee -a "$LOGFILE"
echo "Detailed report available at: $REPORT_FILE" | tee -a "$LOGFILE"

# Cleanup old reports (keep last 5)
find /tmp -name "vault_scan_report_*.html" -type f -mtime +5 -delete 2>/dev/null

exit 0
