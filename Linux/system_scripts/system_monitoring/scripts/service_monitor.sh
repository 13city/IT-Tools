#!/bin/bash

# Script: service_monitor.sh
# Description: Monitor and auto-restart critical services

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_DIR="../../logs"
readonly LOG_FILE="${LOG_DIR}/service_monitor_$(date +%Y%m%d).log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color
readonly CONFIG_FILE="../../config/services.conf"

# Environment variables for notifications
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}

# Function to display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [SERVICE...]

Monitor and auto-restart system services. Services can be specified as arguments
or listed in $CONFIG_FILE.

Options:
    -h, --help      Display this help message
    -s, --silent    Run in silent mode (no console output)
    -c, --config    Use configuration file for service list
    
Examples:
    $SCRIPT_NAME httpd mysqld
    $SCRIPT_NAME --config
    $SCRIPT_NAME --silent nginx php-fpm
    
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

# Function to check if systemd is available
check_systemd() {
    if ! command -v systemctl &>/dev/null; then
        log "${RED}Error: systemctl not found. This script requires systemd.${NC}"
        exit 1
    fi
}

# Function to check service status
check_service() {
    local service="$1"
    local status
    local details
    
    # Get service status
    if ! status=$(systemctl is-active "$service" 2>/dev/null); then
        return 1
    fi
    
    # Get detailed status for logging
    details=$(systemctl status "$service" 2>&1 || true)
    log "Service $service status details:\n$details"
    
    return 0
}

# Function to restart service
restart_service() {
    local service="$1"
    local restart_output
    
    log "Attempting to restart $service..."
    
    if restart_output=$(systemctl restart "$service" 2>&1); then
        log "${GREEN}Successfully restarted $service${NC}"
        return 0
    else
        log "${RED}Failed to restart $service: $restart_output${NC}"
        return 1
    fi
}

# Function to load services from config file
load_services_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "${RED}Error: Config file $CONFIG_FILE not found${NC}"
        exit 1
    fi
    
    # Read services from config file, ignoring comments and empty lines
    mapfile -t SERVICES < <(grep -v '^#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$')
    
    if [[ ${#SERVICES[@]} -eq 0 ]]; then
        log "${RED}Error: No services found in config file${NC}"
        exit 1
    fi
}

# Function to validate service name
validate_service() {
    local service="$1"
    
    if ! systemctl list-unit-files "$service.service" &>/dev/null; then
        log "${RED}Error: Service $service not found${NC}"
        return 1
    fi
    return 0
}

# Initialize variables
SILENT_MODE=false
USE_CONFIG=false
declare -a SERVICES

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Check for systemd
check_systemd

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
        -c|--config)
            USE_CONFIG=true
            shift
            ;;
        *)
            SERVICES+=("$1")
            shift
            ;;
    esac
done

# Load services from config if specified
if [[ "$USE_CONFIG" == "true" ]]; then
    load_services_config
elif [[ ${#SERVICES[@]} -eq 0 ]]; then
    log "${RED}Error: No services specified. Use --help for usage information.${NC}"
    exit 1
fi

# Validate all services
for service in "${SERVICES[@]}"; do
    if ! validate_service "$service"; then
        exit 1
    fi
done

# Main monitoring logic
log "Starting service monitoring for: ${SERVICES[*]}"
failed_services=()
restarted_services=()

for service in "${SERVICES[@]}"; do
    if ! check_service "$service"; then
        log "${YELLOW}Service $service is not active, attempting restart...${NC}"
        
        if restart_service "$service"; then
            restarted_services+=("$service")
        else
            failed_services+=("$service")
        fi
    else
        log "${GREEN}Service $service is running${NC}"
    fi
done

# Generate summary
summary="Service Monitoring Summary:\n"
summary+="Total services checked: ${#SERVICES[@]}\n"
summary+="Services running: $((${#SERVICES[@]} - ${#failed_services[@]} - ${#restarted_services[@]}))\n"
summary+="Services restarted: ${#restarted_services[@]}\n"
summary+="Services failed: ${#failed_services[@]}"

log "$summary"

# Send notifications if there were any issues
if [[ ${#failed_services[@]} -gt 0 || ${#restarted_services[@]} -gt 0 ]]; then
    notification_message="Service Monitor Alert:\n$summary"
    
    if [[ ${#restarted_services[@]} -gt 0 ]]; then
        notification_message+="\n\nRestarted services: ${restarted_services[*]}"
    fi
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        notification_message+="\n\nFailed services: ${failed_services[*]}"
    fi
    
    send_slack_notification "$notification_message"
    send_email_notification \
        "Service Monitor Alert" \
        "$notification_message\n\nTimestamp: $(date)"
fi

# Exit with appropriate status code
if [[ ${#failed_services[@]} -gt 0 ]]; then
    exit 1
fi

exit 0
