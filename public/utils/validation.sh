#!/bin/bash

# Input validation utilities
# Keeps scripts safe by checking everything first

# Check if we're running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        return 1
    fi
    return 0
}

# Check if a command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a port is available
port_free() {
    local port=$1
    ! netstat -tuln 2>/dev/null | grep -q ":$port "
}

# Check if a service is running
service_running() {
    local service=$1
    systemctl is-active --quiet "$service" 2>/dev/null
}

# Validate email format
valid_email() {
    local email=$1
    echo "$email" | grep -qE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
}

# Validate domain format
valid_domain() {
    local domain=$1
    echo "$domain" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$'
}

# Validate IP address
valid_ip() {
    local ip=$1
    echo "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

# Check if directory exists and is writable
dir_writable() {
    local dir=$1
    [ -d "$dir" ] && [ -w "$dir" ]
}

# Check if file exists and is readable
file_readable() {
    local file=$1
    [ -f "$file" ] && [ -r "$file" ]
}

# Check minimum system requirements
check_system_requirements() {
    local min_ram_mb=${1:-512}
    local min_disk_gb=${2:-1}
    
    # Check RAM
    local ram_mb=$(free -m | awk 'NR==2{print $2}')
    if [ "$ram_mb" -lt "$min_ram_mb" ]; then
        return 1
    fi
    
    # Check disk space
    local disk_gb=$(df / | awk 'NR==2{print int($4/1024/1024)}')
    if [ "$disk_gb" -lt "$min_disk_gb" ]; then
        return 2
    fi
    
    return 0
}

# Check internet connectivity
has_internet() {
    curl -s --max-time 5 http://www.google.com > /dev/null 2>&1
}

# Validate package.json exists and has required fields
valid_nodejs_project() {
    local dir=${1:-.}
    
    if [ ! -f "$dir/package.json" ]; then
        return 1
    fi
    
    # Check if it has a name field
    if ! grep -q '"name"' "$dir/package.json"; then
        return 2
    fi
    
    return 0
}

# Validate Python project structure
valid_python_project() {
    local dir=${1:-.}
    
    # Look for common Python project indicators
    if [ -f "$dir/requirements.txt" ] || [ -f "$dir/setup.py" ] || [ -f "$dir/pyproject.toml" ]; then
        return 0
    fi
    
    return 1
}

# Check if database is accessible
database_accessible() {
    local db_type=$1
    local host=${2:-localhost}
    local port=$3
    local user=$4
    local password=$5
    local database=$6
    
    case "$db_type" in
        postgresql|postgres)
            PGPASSWORD="$password" psql -h "$host" -p "$port" -U "$user" -d "$database" -c "SELECT 1;" >/dev/null 2>&1
            ;;
        mysql)
            mysql -h "$host" -P "$port" -u "$user" -p"$password" "$database" -e "SELECT 1;" >/dev/null 2>&1
            ;;
        mongodb|mongo)
            mongosh --host "$host:$port" -u "$user" -p "$password" --authenticationDatabase "$database" --eval "db.runCommand('ping')" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Comprehensive pre-deployment checks
pre_deployment_check() {
    local errors=0
    
    echo "Running pre-deployment checks..."
    
    # Root check
    if ! check_root; then
        echo "❌ Must run as root or with sudo"
        errors=$((errors + 1))
    else
        echo "✅ Running with proper privileges"
    fi
    
    # Internet check
    if ! has_internet; then
        echo "❌ No internet connection"
        errors=$((errors + 1))
    else
        echo "✅ Internet connection available"
    fi
    
    # System requirements
    if ! check_system_requirements; then
        echo "❌ System doesn't meet minimum requirements"
        errors=$((errors + 1))
    else
        echo "✅ System requirements met"
    fi
    
    # Essential commands
    local required_commands="curl wget git"
    for cmd in $required_commands; do
        if ! has_command "$cmd"; then
            echo "❌ Missing required command: $cmd"
            errors=$((errors + 1))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        echo "✅ All pre-deployment checks passed"
        return 0
    else
        echo "❌ $errors check(s) failed"
        return 1
    fi
}

# Export functions
export -f check_root has_command port_free service_running valid_email valid_domain valid_ip
export -f dir_writable file_readable check_system_requirements has_internet
export -f valid_nodejs_project valid_python_project database_accessible pre_deployment_check