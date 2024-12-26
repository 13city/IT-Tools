#!/bin/bash

# Script: log_review.sh
# Description: Review logs for specific patterns with notifications

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_DIR="../../logs"
readonly RESULTS_DIR="../../logs/reviews"
readonly LOG_FILE="${LOG_DIR}/log_review_$(date +%Y%m%d).log"
readonly RESULTS_FILE="${RESULTS_DIR}/review_$(date +%Y%m%d_%H%M%S).log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Environment variables for notifications
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}

# Function to display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] LOG_FILE PATTERN [PATTERN...]

Review log files for specific patterns and generate reports.

Options:
    -h, --help              Display this help message
    -n, --last-n-lines N    Only check last N lines of the log
    -s, --since TIMESPEC    Only check entries since specified time
                           (e.g., '2 hours ago', 'yesterday', '2024-01-01')
    
Examples:
    $SCRIPT_NAME /var/log/syslog "error" "failed"
    $SCRIPT_NAME --last-n-lines 1000 /var/log/auth.log "authentication failure"
    $SCRIPT_NAME --since "2 hours ago" /var/log/messages "kernel"
    
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

# Function to check if file exists and is readable
check_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log "${RED}Error: File $file does not exist${NC}"
        return 1
    fi
    if [[ ! -r "$file" ]]; then
        log "${RED}Error: File $file is not readable${NC}"
        return 1
    fi
    return 0
}

# Function to format timestamp for display
format_timestamp() {
    local timestamp="$1"
    date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S'
}

# Function to parse timespec into seconds since epoch
parse_timespec() {
    local timespec="$1"
    date -d "$timespec" +%s || {
        log "${RED}Error: Invalid time specification: $timespec${NC}"
        exit 1
    }
}

# Function to search for patterns
search_patterns() {
    local log_file="$1"
    shift
    local patterns=("$@")
    local matches=0
    local command
    
    # Build grep command based on options
    if [[ -n "${LAST_N_LINES:-}" ]]; then
        command="tail -n $LAST_N_LINES \"$log_file\""
    elif [[ -n "${SINCE_TIME:-}" ]]; then
        local since_date
        since_date=$(format_timestamp "$SINCE_TIME")
        command="sed -n \"/^.*${since_date//\//\\/}.*/,\$p\" \"$log_file\""
    else
        command="cat \"$log_file\""
    fi
    
    # Add pattern matching
    for pattern in "${patterns[@]}"; do
        command+=" | grep --color=always -i \"$pattern\""
    done
    
    # Execute command and capture output
    log "Searching for patterns: ${patterns[*]}"
    log "In file: $log_file"
    
    {
        echo "=== Log Review Results ==="
        echo "Timestamp: $(date)"
        echo "Log File: $log_file"
        echo "Patterns: ${patterns[*]}"
        echo "==========================="
        echo
        
        # shellcheck disable=SC2086
        eval $command || true
        
    } | tee -a "$RESULTS_FILE"
    
    # Count matches
    matches=$(grep -c . "$RESULTS_FILE" || true)
    
    # Generate summary
    local summary="Found $matches matching entries"
    log "${BLUE}$summary${NC}"
    
    # Send notifications if matches found
    if [[ $matches -gt 0 ]]; then
        local notification_message="Log Review Alert:\n$summary\nLog: $log_file\nPatterns: ${patterns[*]}"
        send_slack_notification "$notification_message"
        send_email_notification \
            "Log Review Alert" \
            "$notification_message\n\nSee attached report for details.\n\nTimestamp: $(date)"
    fi
    
    return 0
}

# Initialize variables
LAST_N_LINES=""
SINCE_TIME=""
LOG_FILE_PATH=""
declare -a PATTERNS

# Create log directories if they don't exist
mkdir -p "$LOG_DIR" "$RESULTS_DIR"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -n|--last-n-lines)
            if [[ ! $2 =~ ^[0-9]+$ ]]; then
                log "${RED}Error: Invalid number of lines: $2${NC}"
                exit 1
            fi
            LAST_N_LINES="$2"
            shift 2
            ;;
        -s|--since)
            SINCE_TIME=$(parse_timespec "$2")
            shift 2
            ;;
        *)
            if [[ -z "$LOG_FILE_PATH" ]]; then
                LOG_FILE_PATH="$1"
            else
                PATTERNS+=("$1")
            fi
            shift
            ;;
    esac
done

# Validate inputs
if [[ -z "$LOG_FILE_PATH" ]]; then
    log "${RED}Error: Log file path is required${NC}"
    usage
fi

if [[ ${#PATTERNS[@]} -eq 0 ]]; then
    log "${RED}Error: At least one pattern is required${NC}"
    usage
fi

if ! check_file "$LOG_FILE_PATH"; then
    exit 1
fi

# Main logic
search_patterns "$LOG_FILE_PATH" "${PATTERNS[@]}"

exit 0
