# Utility Scripts

Helper functions and common utilities used by deployment scripts.

## Available Utilities

### common.sh
Basic system functions that work across different Linux distributions.
- **OS detection** - Automatically detect Ubuntu, Debian, CentOS
- **Package management** - Install packages regardless of OS
- **Service management** - Start, stop, enable services
- **User management** - Create users and set permissions
- **Network utilities** - Check ports, get IP addresses

### logging.sh
Clean, readable output for deployment scripts.
- **Colored output** - Green for success, red for errors
- **Progress indicators** - Show what's happening
- **Log levels** - Info, warning, error, debug
- **File logging** - Optional log file output

### validation.sh
Input validation and system checks.
- **Pre-deployment checks** - Verify system requirements
- **Input validation** - Check domains, emails, ports
- **Project validation** - Verify Node.js, Python projects
- **Database connectivity** - Test database connections

### security.sh
Basic server hardening and security setup.
- **Firewall setup** - Configure UFW with sensible defaults
- **SSH hardening** - Secure SSH configuration
- **User creation** - Create non-root deployment users
- **Auto-updates** - Enable automatic security updates
- **Fail2ban** - Protect against brute force attacks

## Usage

### In Your Scripts
```bash
#!/bin/bash
# Load utilities
source "$(dirname "$0")/../../utils/common.sh"
source "$(dirname "$0")/../../utils/logging.sh"
source "$(dirname "$0")/../../utils/validation.sh"

# Use the functions
detect_os
log_info "Detected: $OS_NAME $OS_VERSION"

if ! pre_deployment_check; then
    log_error "System requirements not met"
    exit 1
fi

install_package nginx
log_success "Nginx installed successfully"
```

### Standalone Usage
```bash
# Run security hardening
./utils/security.sh

# Check system requirements
./utils/validation.sh

# Test logging functions
./utils/logging.sh
```

## Function Reference

### Common Functions
- `detect_os()` - Set OS_NAME, OS_VERSION, PKG_MANAGER
- `install_package()` - Install package on any supported OS
- `service_running()` - Check if systemd service is active
- `port_free()` - Check if network port is available
- `has_command()` - Check if command exists
- `generate_password()` - Create secure random passwords

### Logging Functions
- `log_info()` - Green checkmark with message
- `log_warn()` - Yellow warning with message
- `log_error()` - Red X with error message
- `log_step()` - Blue arrow showing current step
- `log_success()` - Green celebration for completion

### Validation Functions
- `check_root()` - Verify running as root/sudo
- `valid_domain()` - Check domain name format
- `valid_email()` - Check email address format
- `has_internet()` - Test internet connectivity
- `pre_deployment_check()` - Complete system validation

### Security Functions
- `setup_firewall()` - Configure UFW firewall
- `secure_ssh()` - Harden SSH configuration
- `create_deploy_user()` - Create non-root user
- `setup_fail2ban()` - Install and configure fail2ban
- `secure_server()` - Complete security hardening

## Examples

### Basic Deployment Script
```bash
#!/bin/bash
set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/common.sh"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/validation.sh"

main() {
    log_step "Starting deployment"
    
    # Check system
    if ! pre_deployment_check; then
        log_error "System check failed"
        exit 1
    fi
    
    # Detect OS
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    
    # Install packages
    log_step "Installing packages"
    install_package nginx
    install_package postgresql
    
    # Start services
    systemctl start nginx
    systemctl start postgresql
    
    log_success "Deployment complete!"
}

main "$@"
```

### Security Hardening
```bash
#!/bin/bash
# Secure a fresh server

source utils/security.sh

# Complete security setup
secure_server 22 deploy ~/.ssh/id_rsa.pub

# This sets up:
# - Firewall with basic rules
# - Non-root deploy user
# - SSH key authentication
# - Fail2ban protection
# - Automatic security updates
# - System hardening
```

## Best Practices

### Error Handling
```bash
set -e  # Exit on any error

# Check prerequisites first
if ! pre_deployment_check; then
    log_error "Prerequisites not met"
    exit 1
fi
```

### Logging
```bash
# Use appropriate log levels
log_step "Installing Node.js"    # For major steps
log_info "Node.js 18 installed"  # For confirmations
log_warn "No domain provided"    # For warnings
log_error "Installation failed"  # For errors
```

### Validation
```bash
# Validate inputs before using them
if [ -n "$DOMAIN" ] && ! valid_domain "$DOMAIN"; then
    log_error "Invalid domain: $DOMAIN"
    exit 1
fi
```

These utilities make deployment scripts more reliable, readable, and maintainable across different systems.