#!/bin/bash

# Script: net_check.sh
# Description: Network connectivity checks and troubleshooting

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_DIR="../../logs"
readonly LOG_FILE="${LOG_DIR}/net_check_$(date +%Y%m%d).log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color
readonly CONFIG_FILE="../../config/hosts.conf"

# Environment variables for notifications
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}

# Default values
DEFAULT_TIMEOUT=5
DEFAULT_RETRIES=3
DEFAULT_PORTS=(80 443)

# Function to display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [HOST...]

Network connectivity checks and troubleshooting.

Options:
    -h, --help          Display this help message
    -c, --config        Use configuration file for host list
    -v, --verbose       Show detailed output including traceroute
    -p, --ports PORTS   Comma-separated list of ports to check (default: 80,443)
    -t, --timeout SEC   Timeout in seconds (default: $DEFAULT_TIMEOUT)
    -r, --retries N     Number of retries (default: $DEFAULT_RETRIES)
    
Examples:
    $SCRIPT_NAME google.com 8.8.8.8
    $SCRIPT_NAME --config
    $SCRIPT_NAME --verbose --ports 22,80,443 example.com
    
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

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in ping traceroute nc dig; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        exit 1
    fi
}

# Function to load hosts from config file
load_hosts_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "${RED}Error: Config file $CONFIG_FILE not found${NC}"
        exit 1
    fi
    
    # Read hosts from config file, ignoring comments and empty lines
    mapfile -t HOSTS < <(grep -v '^#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$')
    
    if [[ ${#HOSTS[@]} -eq 0 ]]; then
        log "${RED}Error: No hosts found in config file${NC}"
        exit 1
    fi
}

# Function to check DNS resolution
check_dns() {
    local host="$1"
    local ip
    
    log "Checking DNS resolution for $host..."
    
    if ip=$(dig +short "$host" 2>/dev/null); then
        if [[ -n "$ip" ]]; then
            log "${GREEN}DNS resolution successful: $host -> $ip${NC}"
            return 0
        fi
    fi
    
    log "${RED}DNS resolution failed for $host${NC}"
    return 1
}

# Function to check ping connectivity
check_ping() {
    local host="$1"
    local timeout="$2"
    local retries="$3"
    local count=0
    
    log "Checking ping connectivity to $host..."
    
    while [[ $count -lt $retries ]]; do
        if ping -c 1 -W "$timeout" "$host" &>/dev/null; then
            local rtt
            rtt=$(ping -c 1 -W "$timeout" "$host" | grep -oP 'time=\K[0-9.]+')
            log "${GREEN}Ping successful to $host (RTT: ${rtt}ms)${NC}"
            return 0
        fi
        ((count++))
    done
    
    log "${RED}Ping failed to $host after $retries attempts${NC}"
    return 1
}

# Function to check port connectivity
check_port() {
    local host="$1"
    local port="$2"
    local timeout="$3"
    
    log "Checking port $port on $host..."
    
    if nc -zv -w "$timeout" "$host" "$port" 2>/dev/null; then
        log "${GREEN}Port $port is open on $host${NC}" Claude Dev
        return 0
    fi
    
    log "${RED}Port $port is closed on $host${NC}"
    return 1
}

# Function to perform traceroute
do_traceroute() {
    local host="$1"
    local result
    
    log "Running traceroute to $host..."
    result=$(traceroute -n "$host" 2>&1)
    log "Traceroute results:\n$result"
}

# Initialize variables
VERBOSE=false
USE_CONFIG=false
TIMEOUT=$DEFAULT_TIMEOUT
RETRIES=$DEFAULT_RETRIES
PORTS=("${DEFAULT_PORTS[@]}")
declare -a HOSTS

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Check dependencies
check_dependencies

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -c|--config)
            USE_CONFIG=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -p|--ports)
            IFS=',' read -ra PORTS <<< "$2"
            shift 2
            ;;
        -t|--timeout)
            if [[ ! $2 =~ ^[0-9]+$ ]]; then
                log "${RED}Error: Invalid timeout value: $2${NC}"
                exit 1
            fi
            TIMEOUT="$2"
            shift 2
            ;;
        -r|--retries)
            if [[ ! $2 =~ ^[0-9]+$ ]]; then
                log "${RED}Error: Invalid retries value: $2${NC}"
                exit 1
            fi
            RETRIES="$2"
            shift 2
            ;;
        *)
            HOSTS+=("$1")
            shift
            ;;
    esac
done

# Load hosts from config if specified
if [[ "$USE_CONFIG" == "true" ]]; then
    load_hosts_config
elif [[ ${#HOSTS[@]} -eq 0 ]]; then
    log "${RED}Error: No hosts specified. Use --help for usage information.${NC}"
    exit 1
fi

# Main logic
log "Starting network connectivity checks..."
failed_hosts=()
issues_found=false

for host in "${HOSTS[@]}"; do
    log "\nChecking host: $host"
    host_issues=()
    
    # Check DNS resolution
    if ! check_dns "$host"; then
        host_issues+=("DNS resolution failed")
        issues_found=true
    fi
    
    # Check ping connectivity
    if ! check_ping "$host" "$TIMEOUT" "$RETRIES"; then
        host_issues+=("Ping failed")
        issues_found=true
    fi
    
    # Check port connectivity
    for port in "${PORTS[@]}"; do
        if ! check_port "$host" "$port" "$TIMEOUT"; then
            host_issues+=("Port $port closed")
            issues_found=true
        fi
    done
    
    # Run traceroute if verbose mode is enabled or issues were found
    if [[ "$VERBOSE" == "true" || ${#host_issues[@]} -gt 0 ]]; then
        do_traceroute "$host"
    fi
    
    # If any issues were found with this host, add to failed hosts
    if [[ ${#host_issues[@]} -gt 0 ]]; then
        failed_hosts+=("$host: ${host_issues[*]}")
    fi
done

# Generate summary
summary="Network Check Summary:\n"
summary+="Total hosts checked: ${#HOSTS[@]}\n"
summary+="Hosts with issues: ${#failed_hosts[@]}"

log "\n$summary"

# Send notifications if issues were found
if [[ "$issues_found" == "true" ]]; then
    notification_message="Network Check Alert:\n$summary"
    
    if [[ ${#failed_hosts[@]} -gt 0 ]]; then
        notification_message+="\n\nFailed hosts:\n"
        for host in "${failed_hosts[@]}"; do
            notification_message+="- $host\n"
        done
    fi
    
    send_slack_notification "$notification_message"
    send_email_notification \
        "Network Check Alert" \
        "$notification_message\n\nTimestamp: $(date)"
    
    exit 1
fi

exit 0
