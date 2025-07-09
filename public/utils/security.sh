#!/bin/bash

# Security utilities for deployment scripts
# Basic hardening that every server should have

source "$(dirname "$0")/logging.sh"

# Setup basic firewall rules
setup_firewall() {
    local ssh_port=${1:-22}
    local http_port=${2:-80}
    local https_port=${3:-443}
    
    log_step "Setting up firewall..."
    
    # Install ufw if not present
    if ! command -v ufw >/dev/null 2>&1; then
        apt update && apt install -y ufw
    fi
    
    # Reset to defaults
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow essential ports
    ufw allow "$ssh_port/tcp"
    ufw allow "$http_port/tcp"
    ufw allow "$https_port/tcp"
    
    # Enable firewall
    ufw --force enable
    
    log_info "Firewall configured with basic rules"
}

# Create a non-root user for deployments
create_deploy_user() {
    local username=${1:-deploy}
    local ssh_key_path=$2
    
    log_step "Creating deployment user: $username"
    
    # Create user if doesn't exist
    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
        usermod -aG sudo "$username"
        log_info "Created user: $username"
    else
        log_info "User $username already exists"
    fi
    
    # Setup SSH key if provided
    if [ -n "$ssh_key_path" ] && [ -f "$ssh_key_path" ]; then
        local ssh_dir="/home/$username/.ssh"
        mkdir -p "$ssh_dir"
        cp "$ssh_key_path" "$ssh_dir/authorized_keys"
        chown -R "$username:$username" "$ssh_dir"
        chmod 700 "$ssh_dir"
        chmod 600 "$ssh_dir/authorized_keys"
        log_info "SSH key installed for $username"
    fi
}

# Secure SSH configuration
secure_ssh() {
    local ssh_port=${1:-22}
    local allow_root=${2:-no}
    
    log_step "Securing SSH configuration..."
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Apply security settings
    cat > /etc/ssh/sshd_config << EOF
# Basic SSH security configuration
Port $ssh_port
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
PermitRootLogin $allow_root
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security settings
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Connection settings
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10
EOF
    
    # Restart SSH service
    systemctl restart sshd
    log_info "SSH secured and restarted"
}

# Install and configure fail2ban
setup_fail2ban() {
    log_step "Installing fail2ban..."
    
    apt update && apt install -y fail2ban
    
    # Basic jail configuration
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF
    
    systemctl enable fail2ban
    systemctl start fail2ban
    log_info "Fail2ban configured and started"
}

# Set up automatic security updates
setup_auto_updates() {
    log_step "Setting up automatic security updates..."
    
    apt update && apt install -y unattended-upgrades
    
    # Configure automatic updates
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
    
    # Enable automatic updates
    cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
    
    log_info "Automatic security updates enabled"
}

# Basic system hardening
harden_system() {
    log_step "Applying basic system hardening..."
    
    # Disable unused network protocols
    cat > /etc/modprobe.d/blacklist-rare-network.conf << EOF
# Disable rare network protocols
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF
    
    # Set kernel parameters
    cat > /etc/sysctl.d/99-security.conf << EOF
# IP Spoofing protection
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log Martians
net.ipv4.conf.all.log_martians = 1

# Ignore ping requests
net.ipv4.icmp_echo_ignore_all = 1
EOF
    
    sysctl -p /etc/sysctl.d/99-security.conf
    log_info "System hardening applied"
}

# Generate strong passwords
generate_password() {
    local length=${1:-16}
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-"$length"
}

# Complete security setup
secure_server() {
    local ssh_port=${1:-22}
    local deploy_user=${2:-deploy}
    local ssh_key_path=$3
    
    log_step "Starting complete server security setup..."
    
    # Update system first
    apt update && apt upgrade -y
    
    # Run all security functions
    setup_firewall "$ssh_port"
    create_deploy_user "$deploy_user" "$ssh_key_path"
    secure_ssh "$ssh_port"
    setup_fail2ban
    setup_auto_updates
    harden_system
    
    log_success "Server security setup complete!"
    log_info "SSH port: $ssh_port"
    log_info "Deploy user: $deploy_user"
    log_warn "Make sure to test SSH access before closing this session!"
}

# Export functions
export -f setup_firewall create_deploy_user secure_ssh setup_fail2ban
export -f setup_auto_updates harden_system generate_password secure_server