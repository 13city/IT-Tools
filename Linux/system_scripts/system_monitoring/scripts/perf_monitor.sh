#!/bin/bash

# Script: perf_monitor.sh
# Description: System performance monitoring and reporting

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_DIR="../../logs"
readonly LOG_FILE="${LOG_DIR}/perf_monitor_$(date +%Y%m%d).log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Environment variables for notifications
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}

# Default values
DEFAULT_INTERVAL=5
DEFAULT_COUNT=1
DEFAULT_CPU_THRESHOLD=80
DEFAULT_MEM_THRESHOLD=80
DEFAULT_LOAD_THRESHOLD=5

# Function to display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Monitor system performance metrics.

Options:
    -h, --help              Display this help message
    -i, --interval SEC      Collection interval in seconds (default: $DEFAULT_INTERVAL)
    -c, --count N          Number of collections (default: $DEFAULT_COUNT)
    --cpu-threshold PCT    CPU usage threshold percentage (default: $DEFAULT_CPU_THRESHOLD)
    --mem-threshold PCT    Memory usage threshold percentage (default: $DEFAULT_MEM_THRESHOLD)
    --load-threshold N     Load average threshold (default: $DEFAULT_LOAD_THRESHOLD)
    
Examples:
    $SCRIPT_NAME
    $SCRIPT_NAME --interval 5 --count 3
    $SCRIPT_NAME --cpu-threshold 90 --mem-threshold 85
    
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
    
    for cmd in mpstat free iostat vmstat; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        log "Please install sysstat package"
        exit 1
    fi
}

# Function to get CPU usage
get_cpu_usage() {
    local cpu_idle
    cpu_idle=$(mpstat 1 1 | awk '/Average:/ {print $NF}')
    echo "$(awk -v idle="$cpu_idle" 'BEGIN {printf "%.1f", 100 - idle}')"
}

# Function to get memory usage
get_memory_usage() {
    local total used available percent
    read -r total used available < <(free -m | awk '/^Mem:/ {print $2, $3, $7}')
    percent=$(awk -v used="$used" -v total="$total" 'BEGIN {printf "%.1f", (used/total)*100}')
    echo "$percent"
}

# Function to get load average
get_load_average() {
    local load_1m
    read -r load_1m _ _ < /proc/loadavg
    echo "$load_1m"
}

# Function to get disk I/O stats
get_disk_io() {
    local result
    result=$(iostat -d -x 1 2 | awk 'END {printf "%.1f,%.1f", $NF, $(NF-1)}')
    echo "$result"
}

# Function to get network stats
get_network_stats() {
    local rx_bytes tx_bytes
    read -r rx_bytes tx_bytes < <(awk '/eth0:/ {print $2, $10}' /proc/net/dev 2>/dev/null || echo "0 0")
    echo "$rx_bytes,$tx_bytes"
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

# Function to collect and display metrics
collect_metrics() {
    local cpu_usage mem_usage load_avg disk_io network_old network_new
    local issues=()
    
    # Get initial network stats
    network_old=$(get_network_stats)
    
    # Collect metrics
    cpu_usage=$(get_cpu_usage)
    mem_usage=$(get_memory_usage)
    load_avg=$(get_load_average)
    disk_io=$(get_disk_io)
    sleep 1
    network_new=$(get_network_stats)
    
    # Calculate network throughput
    IFS=',' read -r old_rx old_tx <<< "$network_old"
    IFS=',' read -r new_rx new_tx <<< "$network_new"
    rx_rate=$((new_rx - old_rx))
    tx_rate=$((new_tx - old_tx))
    
    # Format output
    local output="System Performance Metrics:\n"
    output+="------------------------\n"
    output+="CPU Usage: ${cpu_usage}%\n"
    output+="Memory Usage: ${mem_usage}%\n"
    output+="Load Average: $load_avg\n"
    output+="Disk I/O (util,await): $disk_io\n"
    output+="Network (rx/tx): $(format_size "$rx_rate")/s / $(format_size "$tx_rate")/s\n"
    
    # Check thresholds
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        issues+=("CPU usage above threshold: ${cpu_usage}%")
    fi
    
    if (( $(echo "$mem_usage > $MEM_THRESHOLD" | bc -l) )); then
        issues+=("Memory usage above threshold: ${mem_usage}%")
    fi
    
    if (( $(echo "$load_avg > $LOAD_THRESHOLD" | bc -l) )); then
        issues+=("Load average above threshold: $load_avg")
    fi
    
    # Log output
    log "$output"
    
    # Send notifications if issues found
    if [[ ${#issues[@]} -gt 0 ]]; then
        local notification_message="Performance Alert:\n"
        for issue in "${issues[@]}"; do
            notification_message+="- $issue\n"
        done
        notification_message+="\n$output"
        
        send_slack_notification "$notification_message"
        send_email_notification \
            "System Performance Alert" \
            "$notification_message\n\nTimestamp: $(date)"
    fi
}

# Initialize variables
INTERVAL=$DEFAULT_INTERVAL
COUNT=$DEFAULT_COUNT
CPU_THRESHOLD=$DEFAULT_CPU_THRESHOLD
MEM_THRESHOLD=$DEFAULT_MEM_THRESHOLD
LOAD_THRESHOLD=$DEFAULT_LOAD_THRESHOLD

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
        -i|--interval)
            if [[ ! $2 =~ ^[0-9]+$ ]]; then
                log "${RED}Error: Invalid interval: $2${NC}"
                exit 1
            fi
            INTERVAL="$2"
            shift 2
            ;;
        -c|--count)
            if [[ ! $2 =~ ^[0-9]+$ ]]; then
                log "${RED}Error: Invalid count: $2${NC}"
                exit 1
            fi
            COUNT="$2"
            shift 2
            ;;
        --cpu-threshold)
            if [[ ! $2 =~ ^[0-9]+$ ]] || [[ $2 -gt 100 ]]; then
                log "${RED}Error: Invalid CPU threshold: $2${NC}"
                exit 1
            fi
            CPU_THRESHOLD="$2"
            shift 2
            ;;
        --mem-threshold)
            if [[ ! $2 =~ ^[0-9]+$ ]] || [[ $2 -gt 100 ]]; then
                log "${RED}Error: Invalid memory threshold: $2${NC}"
                exit 1
            fi
            MEM_THRESHOLD="$2"
            shift 2
            ;;
        --load-threshold)
            if [[ ! $2 =~ ^[0-9.]+$ ]]; then
                log "${RED}Error: Invalid load threshold: $2${NC}"
                exit 1
            fi
            LOAD_THRESHOLD="$2"
            shift 2
            ;;
        *)
            log "${RED}Error: Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Main logic
log "Starting performance monitoring..."
log "Collection interval: ${INTERVAL}s, Count: $COUNT"
log "Thresholds - CPU: ${CPU_THRESHOLD}%, Memory: ${MEM_THRESHOLD}%, Load: $LOAD_THRESHOLD"

iteration=0
while [[ $iteration -lt $COUNT ]]; do
    collect_metrics
    ((iteration++))
    
    if [[ $iteration -lt $COUNT ]]; then
        sleep "$INTERVAL"
    fi
done

exit 0
