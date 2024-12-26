#!/bin/bash

# Script: fix_permissions.sh
# Description: Fix file ownership and permissions recursively

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_DIR="../../logs"
readonly LOG_FILE="${LOG_DIR}/fix_permissions_$(date +%Y%m%d).log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Environment variables for notifications
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}

# Default values
DEFAULT_PERMS="750"
DEFAULT_OWNER="$(whoami)"
DEFAULT_GROUP="$(id -gn)"

# Function to display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] TARGET_DIR

Fix file ownership and permissions recursively for a specified directory.

Options:
    -h, --help          Display this help message
    -d, --dry-run       Show what would be changed without making changes
    -o, --owner USER    Set owner (default: current user)
    -g, --group GROUP   Set group (default: current user's primary group)
    -p, --perms MODE    Set permissions (default: 750)
    
Examples:
    $SCRIPT_NAME /var/www/app
    $SCRIPT_NAME --owner www-data --group www-data /var/www/app
    $SCRIPT_NAME --dry-run --perms 755 /var/www/app
    
Environment variables:
    SLACK_WEBHOOK_URL    Webhook URL for Slack notifications
    EMAIL_RECIPIENT      Email address for notifications
EOF
    exit 1
}

# Function to log messages
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} $1"
    else
        echo -e "$1"
    fi
}

# Function to send Slack notification
send_slack_notification() {
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        local message="$1"
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$SLACK_WEBHOOK_URL" || true
    fi
}

# Function to send email notification
send_email_notification() {
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        local subject="$1"
        local body="$2"
        echo "$body" | mail -s "$subject" "$EMAIL_RECIPIENT" || true
    fi
}

# Function to check if user/group exists
check_user_group() {
    local owner="$1"
    local group="$2"
    
    if ! id "$owner" &>/dev/null; then
        log "${RED}Error: User $owner does not exist${NC}"
        return 1
    fi
    
    if ! getent group "$group" &>/dev/null; then
        log "${RED}Error: Group $group does not exist${NC}"
        return 1
    fi
    
    return 0
}

# Function to validate permissions
validate_permissions() {
    local perms="$1"
    if ! [[ "$perms" =~ ^[0-7]{3,4}$ ]]; then
        log "${RED}Error: Invalid permissions format. Use octal notation (e.g., 750)${NC}"
        return 1
    fi
    return 0
}

# Function to fix permissions for a single file/directory
fix_permissions() {
    local path="$1"
    local changes=false
    local current_owner=$(stat -c '%U' "$path")
    local current_group=$(stat -c '%G' "$path")
    local current_perms=$(stat -c '%a' "$path")
    
    # Check ownership
    if [[ "$current_owner" != "$OWNER" || "$current_group" != "$GROUP" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log "Would change ownership of $path from $current_owner:$current_group to $OWNER:$GROUP"
        else
            chown "$OWNER:$GROUP" "$path"
            log "Changed ownership of $path from $current_owner:$current_group to $OWNER:$GROUP"
        fi
        changes=true
    fi
    
    # Check permissions
    if [[ "$current_perms" != "$PERMS" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log "Would change permissions of $path from $current_perms to $PERMS"
        else
            chmod "$PERMS" "$path"
            log "Changed permissions of $path from $current_perms to $PERMS"
        fi
        changes=true
    fi
    
    return $([ "$changes" == "true" ] && echo 0 || echo 1)
}

# Initialize variables
DRY_RUN=false
OWNER="$DEFAULT_OWNER"
GROUP="$DEFAULT_GROUP"
PERMS="$DEFAULT_PERMS"
TARGET_DIR=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -o|--owner)
            OWNER="$2"
            shift 2
            ;;
        -g|--group)
            GROUP="$2"
            shift 2
            ;;
        -p|--perms)
            PERMS="$2"
            shift 2
            ;;
        *)
            if [[ -z "$TARGET_DIR" ]]; then
                TARGET_DIR="$1"
            else
                log "${RED}Error: Multiple target directories provided${NC}"
                usage
            fi
            shift
            ;;
    esac
done

# Check if target directory is provided
if [[ -z "$TARGET_DIR" ]]; then
    log "${RED}Error: Target directory is required${NC}"
    usage
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Validate inputs
if ! check_user_group "$OWNER" "$GROUP"; then
    exit 1
fi

if ! validate_permissions "$PERMS"; then
    exit 1
fi

# Check if target directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    log "${RED}Error: Directory $TARGET_DIR does not exist${NC}"
    exit 1
fi

# Main logic
log "Starting permission fix for directory: $TARGET_DIR"
log "Configuration: owner=$OWNER, group=$GROUP, permissions=$PERMS"

# Initialize counters
total_files=0
changed_files=0

# Process all files recursively
while IFS= read -r -d '' file; do
    ((total_files++))
    if fix_permissions "$file"; then
        ((changed_files++))
    fi
done < <(find "$TARGET_DIR" -print0)

# Generate summary
summary="Processed $total_files files/directories. Changed permissions for $changed_files items."
log "${GREEN}$summary${NC}"

# Send notifications if changes were made
if [[ $changed_files -gt 0 && "${DRY_RUN:-false}" != "true" ]]; then
    notification_message="Permission changes applied to $TARGET_DIR: $summary"
    send_slack_notification "$notification_message"
    send_email_notification \
        "Permission Changes Report" \
        "Target Directory: $TARGET_DIR\n$summary\nTimestamp: $(date)"
fi

exit 0
