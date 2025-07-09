#!/bin/bash

# Common utility functions for deployment scripts
# Source this file in your deployment scripts

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

# Detect operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        export OS_NAME="$NAME"
        export OS_VERSION="$VERSION_ID"
        export OS_ID="$ID"
    elif type lsb_release >/dev/null 2>&1; then
        export OS_NAME=$(lsb_release -si)
        export OS_VERSION=$(lsb_release -sr)
        export OS_ID=$(echo "$OS_NAME" | tr '[:upper:]' '[:lower:]')
    else
        echo "Cannot detect operating system"
        return 1
    fi
    
    # Set package manager
    case "$OS_ID" in
        ubuntu|debian)
            export PKG_MANAGER="apt"
            export PKG_UPDATE="apt update"
            export PKG_INSTALL="apt install -y"
            export PKG_REMOVE="apt remove -y"
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command -v dnf &> /dev/null; then
                export PKG_MANAGER="dnf"
                export PKG_UPDATE="dnf update -y"
                export PKG_INSTALL="dnf install -y"
                export PKG_REMOVE="dnf remove -y"
            else
                export PKG_MANAGER="yum"
                export PKG_UPDATE="yum update -y"
                export PKG_INSTALL="yum install -y"
                export PKG_REMOVE="yum remove -y"
            fi
            ;;
        amzn)
            export PKG_MANAGER="yum"
            export PKG_UPDATE="yum update -y"
            export PKG_INSTALL="yum install -y"
            export PKG_REMOVE="yum remove -y"
            ;;
        arch)
            export PKG_MANAGER="pacman"
            export PKG_UPDATE="pacman -Syu --noconfirm"
            export PKG_INSTALL="pacman -S --noconfirm"
            export PKG_REMOVE="pacman -R --noconfirm"
            ;;
        *)
            echo "Unsupported operating system: $OS_ID"
            return 1
            ;;
    esac
    
    return 0
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        return 1
    fi
    return 0
}

# Check if user exists
user_exists() {
    local username="$1"
    id "$username" &>/dev/null
}

# Create user if not exists
create_user() {
    local username="$1"
    local home_dir="${2:-/home/$username}"
    local shell="${3:-/bin/bash}"
    
    if ! user_exists "$username"; then
        useradd -m -d "$home_dir" -s "$shell" "$username"
        return $?
    fi
    return 0
}

# Install package using detected package manager
install_package() {
    local package="$1"
    
    if [ -z "$PKG_MANAGER" ]; then
        detect_os || return 1
    fi
    
    case "$PKG_MANAGER" in
        apt)
            apt update && apt install -y "$package"
            ;;
        dnf|yum)
            $PKG_MANAGER install -y "$package"
            ;;
        pacman)
            pacman -S --noconfirm "$package"
            ;;
        *)
            echo "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Update system packages
update_system() {
    if [ -z "$PKG_MANAGER" ]; then
        detect_os || return 1
    fi
    
    case "$PKG_MANAGER" in
        apt)
            apt update && apt upgrade -y
            ;;
        dnf|yum)
            $PKG_MANAGER update -y
            ;;
        pacman)
            pacman -Syu --noconfirm
            ;;
        *)
            echo "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Check if service exists
service_exists() {
    local service="$1"
    systemctl list-unit-files | grep -q "^$service"
}

# Start service
start_service() {
    local service="$1"
    
    if service_exists "$service"; then
        systemctl start "$service"
        return $?
    else
        echo "Service $service does not exist"
        return 1
    fi
}

# Stop service
stop_service() {
    local service="$1"
    
    if service_exists "$service"; then
        systemctl stop "$service"
        return $?
    else
        echo "Service $service does not exist"
        return 1
    fi
}

# Enable service
enable_service() {
    local service="$1"
    
    if service_exists "$service"; then
        systemctl enable "$service"
        return $?
    else
        echo "Service $service does not exist"
        return 1
    fi
}

# Check if port is available
port_available() {
    local port="$1"
    ! netstat -tuln | grep -q ":$port "
}

# Wait for service to be ready
wait_for_service() {
    local host="${1:-localhost}"
    local port="$2"
    local timeout="${3:-30}"
    local counter=0
    
    while [ $counter -lt $timeout ]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            return 0
        fi
        sleep 1
        counter=$((counter + 1))
    done
    
    return 1
}

# Generate random password
generate_password() {
    local length="${1:-16}"
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if command exists (alias for compatibility)
has_command() {
    command_exists "$1"
}

# Create directory with proper permissions
create_directory() {
    local dir="$1"
    local owner="${2:-root}"
    local group="${3:-root}"
    local permissions="${4:-755}"
    
    mkdir -p "$dir"
    chown "$owner:$group" "$dir"
    chmod "$permissions" "$dir"
}

# Backup file
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [ -f "$file" ]; then
        cp "$file" "$file$backup_suffix"
        return $?
    fi
    
    return 1
}

# Get public IP address
get_public_ip() {
    curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com
}

# Validate domain name
validate_domain() {
    local domain="$1"
    echo "$domain" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$'
}

# Export all functions
export -f detect_os check_root user_exists create_user install_package update_system
export -f service_exists start_service stop_service enable_service
export -f port_available wait_for_service generate_password command_exists has_command
export -f create_directory backup_file get_public_ip validate_domain