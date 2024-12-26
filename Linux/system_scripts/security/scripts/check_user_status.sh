#!/bin/bash

# Script: check_user_status.sh
# Description: Check user account status with comprehensive reporting and notifications

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_DIR="../../logs"
readonly LOG_FILE="${LOG_DIR}/user_status_$(date +%Y%m%d).log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Environment variables for notifications (should be set before running)
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}

# Function to display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] USERNAME

Check user account status and send notifications for locked/expired accounts.

Options:
    -h, --help      Display this help message
    -s, --silent    Run in silent mode (no console output)
    
Examples:
    $SCRIPT_NAME alice
    $SCRIPT_NAME --silent bob
    
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
    
    if [[ "${SILENT_MODE:-false}" != "true" ]]; then
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

# Function to check if account is locked
check_account_locked() {
    local username="$1"
    if passwd -S "$username" | grep -q "L"; then
        return 0
    fi
    return 1
}

# Function to check if account is expired
check_account_expired() {
    local username="$1"
    local expiry_date
    expiry_date=$(chage -l "$username" | grep "Account expires" | cut -d: -f2)
    
    if [[ "$expiry_date" != " never" ]]; then
        local today=$(date +%s)
        local expiry=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
        
        if [[ $expiry -lt $today ]]; then
            return 0
        fi
    fi
    return 1
}

# Initialize variables
SILENT_MODE=false
USERNAME=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -s|--silent)
            SILENT_MODE=true
            shift
            ;;
        *)
            if [[ -z "$USERNAME" ]]; then
                USERNAME="$1"
            else
                log "${RED}Error: Multiple usernames provided${NC}"
                usage
            fi
            shift
            ;;
    esac
done

# Check if username is provided
if [[ -z "$USERNAME" ]]; then
    log "${RED}Error: Username is required${NC}"
    usage
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Main logic
log "Starting user account status check for user: $USERNAME"

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    log "${RED}Error: User $USERNAME does not exist${NC}"
    exit 1
fi

# Initialize status variables
is_locked=false
is_expired=false
status_message=""

# Check account status
if check_account_locked "$USERNAME"; then
    is_locked=true
    status_message="${RED}LOCKED${NC}"
elif check_account_expired "$USERNAME"; then
    is_expired=true
    status_message="${YELLOW}EXPIRED${NC}"
else
    status_message="${GREEN}VALID${NC}"
fi

# Log status
log "Account Status for $USERNAME: $status_message"

# Send notifications if account is locked or expired
if [[ "$is_locked" == "true" || "$is_expired" == "true" ]]; then
    notification_message="Alert: User account '$USERNAME' is $([ "$is_locked" == "true" ] && echo "LOCKED" || echo "EXPIRED")"
    
    # Send Slack notification
    send_slack_notification "$notification_message"
    
    # Send email notification
    send_email_notification \
        "User Account Status Alert" \
        "User: $USERNAME\nStatus: $([ "$is_locked" == "true" ] && echo "LOCKED" || echo "EXPIRED")\nTimestamp: $(date)"
fi

# Display additional account information if not in silent mode
if [[ "$SILENT_MODE" != "true" ]]; then
    echo -e "\nDetailed Account Information:"
    chage -l "$USERNAME" 2>/dev/null || echo "Unable to retrieve detailed information"
fi

# Exit with appropriate status code
if [[ "$is_locked" == "true" || "$is_expired" == "true" ]]; then
    exit 1
fi

exit 0
