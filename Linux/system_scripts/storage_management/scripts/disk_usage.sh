#!/bin/bash

# Script: disk_usage.sh
# Description: Monitor disk usage and identify large directories

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_DIR="../../logs"
readonly LOG_FILE="${LOG_DIR}/disk_usage_$(date +%Y%m%d).log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Environment variables for notifications
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}

# Default values
DEFAULT_ALERT_THRESHOLD=10
DEFAULT_TOP_N=5
DEFAULT_TARGET_DIR="/var"

# Function to display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [TARGET_DIR]

Monitor disk usage and identify large directories.

Options:
    -h, --help                  Display this help message
    -t, --alert-threshold PCT   Set alert threshold percentage (default: $DEFAULT_ALERT_THRESHOLD)
    -n, --top-n N              Show top N largest directories (default: $DEFAULT_TOP_N)
    
Examples:
    $SCRIPT_NAME /var
    $SCRIPT_NAME --alert-threshold 15 --top-n 10 /opt
    
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
    echo -e "$1"
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

# Function to format size
format_size() {
    local size="$1"
    local units=("B" "K" "M" "G" "T")
    local unit=0
    
    while [[ $size -gt 1024 && $unit -lt ${#units[@]} ]]; do
        size=$((size / 1024))
        ((unit++))
    done
    
    echo "$size${units[$unit]}"
}

# Function to check disk space
check_disk_space() {
    local partition="$1"
    local threshold="$2"
    local usage
    local available
    local total
    local percent
    
    # Get disk usage information
    read -r total used available percent _ < <(df -k "$partition" | tail -n 1 | awk '{print $2, $3, $4, $5}')
    percent=${percent%\%}
    
    # Format sizes for display
    total=$(format_size "$total")
    used=$(format_size "$used")
    available=$(format_size "$available")
    
    # Generate status message
    local status_msg="Disk Usage for $partition:\n"
    status_msg+="Total: $total\n"
    status_msg+="Used: $used ($percent%)\n"
    status_msg+="Available: $available"
    
    log "$status_msg"
    
    # Check if usage exceeds threshold
    if [[ $percent -gt $threshold ]]; then
        return 1
    fi
    
    return 0
}

# Function to find large directories
find_large_dirs() {
    local target_dir="$1"
    local top_n="$2"
    local result
    
    log "Scanning directory: $target_dir"
    log "Finding top $top_n largest directories..."
    
    # Use du to find directory sizes, sort by size
    result=$(du -h --max-depth=1 "$target_dir" 2>/dev/null | \
             sort -rh | \
             head -n "$top_n" | \
             awk '{printf "%-10s %s\n", $1, $2}')
    
    echo -e "\nLargest Directories in $target_dir:"
    echo -e "${BLUE}Size      Directory${NC}"
    echo -e "$result"
}

# Initialize variables
ALERT_THRESHOLD=$DEFAULT_ALERT_THRESHOLD
TOP_N=$DEFAULT_TOP_N
TARGET_DIR=$DEFAULT_TARGET_DIR

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -t|--alert-threshold)
            if [[ ! $2 =~ ^[0-9]+$ ]] || [[ $2 -gt 100 ]]; then
                log "${RED}Error: Invalid threshold percentage: $2${NC}"
                exit 1
            fi
            ALERT_THRESHOLD="$2"
            shift 2
            ;;
        -n|--top-n)
            if [[ ! $2 =~ ^[0-9]+$ ]]; then
                log "${RED}Error: Invalid number: $2${NC}"
                exit 1
            fi
            TOP_N="$2"
            shift 2
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Validate target directory
if [[ ! -d "$TARGET_DIR" ]]; then
    log "${RED}Error: Directory $TARGET_DIR does not exist${NC}"
    exit 1
fi

# Get partition of target directory
PARTITION=$(df "$TARGET_DIR" | tail -n 1 | awk '{print $1}')

# Main logic
log "Starting disk usage check with alert threshold: $ALERT_THRESHOLD%"

# Check disk space
if ! check_disk_space "$PARTITION" "$ALERT_THRESHOLD"; then
    alert_msg="ALERT: Disk usage exceeds threshold on $PARTITION"
    log "${RED}$alert_msg${NC}"
    
    # Find large directories
    dir_info=$(find_large_dirs "$TARGET_DIR" "$TOP_N")
    
    # Send notifications
    notification_message="$alert_msg\n\n$dir_info"
    send_slack_notification "$notification_message"
    send_email_notification \
        "Disk Usage Alert" \
        "$notification_message\n\nTimestamp: $(date)"
    
    exit 1
else
    log "${GREEN}Disk usage is within acceptable limits${NC}"
    
    # Still show large directories for information
    find_large_dirs "$TARGET_DIR" "$TOP_N"
fi

exit 0
