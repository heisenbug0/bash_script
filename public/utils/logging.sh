#!/bin/bash

# Simple logging utilities for deployment scripts
# Makes output cleaner and more readable

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log levels
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_FILE="${LOG_FILE:-}"

# Internal function to write to log file
_write_to_file() {
    if [ -n "$LOG_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
    fi
}

# Info messages (green)
log_info() {
    echo -e "${GREEN}✓${NC} $1"
    _write_to_file "INFO: $1"
}

# Warning messages (yellow)
log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    _write_to_file "WARN: $1"
}

# Error messages (red)
log_error() {
    echo -e "${RED}✗${NC} $1" >&2
    _write_to_file "ERROR: $1"
}

# Step indicators (blue)
log_step() {
    echo -e "${BLUE}→${NC} $1"
    _write_to_file "STEP: $1"
}

# Success messages (green, bold)
log_success() {
    echo -e "${GREEN}🎉 $1${NC}"
    _write_to_file "SUCCESS: $1"
}

# Debug messages (only shown if DEBUG=true)
log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${PURPLE}DEBUG:${NC} $1"
        _write_to_file "DEBUG: $1"
    fi
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%% %s${NC}" "$percent" "$message"
    
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# Simple spinner for long operations
spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${CYAN}${spin:$i:1}${NC} %s" "$message"
        sleep 0.1
    done
    printf "\r"
}

# Export functions
export -f log_info log_warn log_error log_step log_success log_debug show_progress spinner