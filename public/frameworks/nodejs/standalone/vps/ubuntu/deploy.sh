#!/bin/bash

# Node.js Standalone Application Deployment Script for Ubuntu VPS
# Deploys Node.js applications without external database dependencies

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../../../utils/common.sh"

# Configuration with defaults
APP_NAME="${APP_NAME:-nodejs-app}"
NODE_VERSION="${NODE_VERSION:-18}"
PORT="${PORT:-3000}"
DOMAIN="${DOMAIN:-}"
SSL_EMAIL="${SSL_EMAIL:-admin@${DOMAIN}}"
NODE_ENV="${NODE_ENV:-production}"
PM2_INSTANCES="${PM2_INSTANCES:-max}"
PM2_MAX_MEMORY="${PM2_MAX_MEMORY:-500M}"
ENABLE_MONITORING="${ENABLE_MONITORING:-true}"
LOG_LEVEL="${LOG_LEVEL:-info}"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Validate prerequisites
validate_prerequisites() {
    log_step "Validating prerequisites..."
    
    # Check if running as root
    if ! check_root; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        log_error "package.json not found. Please run this script from your Node.js project root."
        exit 1
    fi
    
    # Validate domain if provided
    if [ -n "$DOMAIN" ] && ! validate_domain "$DOMAIN"; then
        log_error "Invalid domain format: $DOMAIN"
        exit 1
    fi
    
    log_info "Prerequisites validation passed"
}

# Update system packages
update_system() {
    log_step "Updating system packages..."
    
    detect_os
    update_system
    
    # Install essential packages
    install_package "curl"
    install_package "wget"
    install_package "git"
    install_package "build-essential"
    install_package "nginx"
    install_package "ufw"
    install_package "certbot"
    install_package "python3-certbot-nginx"
    
    log_info "System packages updated successfully"
}

# Install Node.js via NVM
install_nodejs() {
    log_step "Installing Node.js $NODE_VERSION..."
    
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Install Node.js
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    
    log_info "Node.js installed: $node_version"
    log_info "npm installed: $npm_version"
}

# Create deployment user
create_deploy_user() {
    log_step "Creating deployment user..."
    
    if ! user_exists "deploy"; then
        create_user "deploy" "/home/deploy" "/bin/bash"
        usermod -aG sudo deploy
        
        # Copy NVM to deploy user
        cp -r "$HOME/.nvm" /home/deploy/
        chown -R deploy:deploy /home/deploy/.nvm
        
        # Add NVM to deploy user's bashrc
        cat >> /home/deploy/.bashrc << 'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
        
        log_info "Deploy user created successfully"
    else
        log_info "Deploy user already exists"
    fi
}

# Setup application directory
setup_app_directory() {
    log_step "Setting up application directory..."
    
    APP_DIR="/home/deploy/$APP_NAME"
    
    # Create application directory
    create_directory "$APP_DIR" "deploy" "deploy" "755"
    
    # Copy application files
    cp -r . "$APP_DIR/"
    chown -R deploy:deploy "$APP_DIR"
    
    # Create logs directory
    create_directory "/var/log/$APP_NAME" "deploy" "deploy" "755"
    
    log_info "Application directory setup completed"
}

# Install application dependencies
install_dependencies() {
    log_step "Installing application dependencies..."
    
    cd "$APP_DIR"
    
    # Switch to deploy user for npm operations
    sudo -u deploy bash -c "
        source /home/deploy/.bashrc
        cd $APP_DIR
        
        if [ -f 'package-lock.json' ]; then
            npm ci --production
        elif [ -f 'yarn.lock' ]; then
            npm install -g yarn
            yarn install --production --frozen-lockfile
        elif [ -f 'pnpm-lock.yaml' ]; then
            npm install -g pnpm
            pnpm install --production --frozen-lockfile
        else
            npm install --production
        fi
    "
    
    log_info "Dependencies installed successfully"
}

# Install and configure PM2
setup_pm2() {
    log_step "Setting up PM2 process manager..."
    
    # Install PM2 globally
    sudo -u deploy bash -c "
        source /home/deploy/.bashrc
        npm install -g pm2
    "
    
    # Create PM2 ecosystem file
    cat > "$APP_DIR/ecosystem.config.js" << EOF
module.exports = {
  apps: [{
    name: '$APP_NAME',
    script: './app.js',
    instances: '$PM2_INSTANCES',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development',
      PORT: $PORT
    },
    env_production: {
      NODE_ENV: '$NODE_ENV',
      PORT: $PORT
    },
    max_memory_restart: '$PM2_MAX_MEMORY',
    error_file: '/var/log/$APP_NAME/error.log',
    out_file: '/var/log/$APP_NAME/out.log',
    log_file: '/var/log/$APP_NAME/combined.log',
    time: true,
    watch: false,
    ignore_watch: ['node_modules', 'logs'],
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
EOF
    
    chown deploy:deploy "$APP_DIR/ecosystem.config.js"
    
    # Start application with PM2
    sudo -u deploy bash -c "
        source /home/deploy/.bashrc
        cd $APP_DIR
        pm2 start ecosystem.config.js --env production
        pm2 save
        pm2 startup
    "
    
    # Setup PM2 startup script
    env $(sudo -u deploy bash -c "source /home/deploy/.bashrc && pm2 startup systemd -u deploy --hp /home/deploy" | tail -1)
    
    log_info "PM2 setup completed"
}

# Configure Nginx reverse proxy
configure_nginx() {
    log_step "Configuring Nginx reverse proxy..."
    
    # Remove default Nginx configuration
    rm -f /etc/nginx/sites-enabled/default
    
    # Create Nginx configuration for the application
    cat > "/etc/nginx/sites-available/$APP_NAME" << EOF
server {
    listen 80;
    server_name ${DOMAIN:-localhost};
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;
    
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:$PORT/health;
        access_log off;
    }
    
    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:$PORT;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Enable the site
    ln -sf "/etc/nginx/sites-available/$APP_NAME" "/etc/nginx/sites-enabled/"
    
    # Test Nginx configuration
    nginx -t
    
    # Restart Nginx
    systemctl restart nginx
    systemctl enable nginx
    
    log_info "Nginx configuration completed"
}

# Setup SSL certificate
setup_ssl() {
    if [ -n "$DOMAIN" ]; then
        log_step "Setting up SSL certificate..."
        
        # Obtain SSL certificate
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect
        
        # Setup automatic renewal
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        
        log_info "SSL certificate setup completed"
    else
        log_warn "No domain specified, skipping SSL setup"
    fi
}

# Configure firewall
configure_firewall() {
    log_step "Configuring firewall..."
    
    # Reset UFW to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80
    ufw allow 443
    
    # Enable firewall
    ufw --force enable
    
    log_info "Firewall configured successfully"
}

# Setup monitoring
setup_monitoring() {
    if [ "$ENABLE_MONITORING" = "true" ]; then
        log_step "Setting up monitoring..."
        
        # Create monitoring script
        cat > "/usr/local/bin/monitor-$APP_NAME.sh" << 'EOF'
#!/bin/bash

APP_NAME="$1"
LOG_FILE="/var/log/$APP_NAME/monitor.log"

# Check if PM2 process is running
if ! sudo -u deploy pm2 list | grep -q "$APP_NAME"; then
    echo "$(date): $APP_NAME is not running, attempting to restart..." >> "$LOG_FILE"
    sudo -u deploy bash -c "source /home/deploy/.bashrc && cd /home/deploy/$APP_NAME && pm2 restart $APP_NAME"
fi

# Check application health
if command -v curl &> /dev/null; then
    if ! curl -f http://localhost:3000/health &> /dev/null; then
        echo "$(date): Health check failed for $APP_NAME" >> "$LOG_FILE"
    fi
fi
EOF
        
        chmod +x "/usr/local/bin/monitor-$APP_NAME.sh"
        
        # Add monitoring cron job
        (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-$APP_NAME.sh $APP_NAME") | crontab -
        
        log_info "Monitoring setup completed"
    fi
}

# Setup log rotation
setup_log_rotation() {
    log_step "Setting up log rotation..."
    
    cat > "/etc/logrotate.d/$APP_NAME" << EOF
/var/log/$APP_NAME/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 deploy deploy
    postrotate
        sudo -u deploy bash -c "source /home/deploy/.bashrc && pm2 reloadLogs"
    endscript
}
EOF
    
    log_info "Log rotation setup completed"
}

# Display deployment information
display_info() {
    log_info "Deployment completed successfully!"
    echo
    echo "Application Information:"
    echo "======================="
    echo "App Name: $APP_NAME"
    echo "Node.js Version: $(node --version)"
    echo "Application Directory: $APP_DIR"
    echo "Port: $PORT"
    if [ -n "$DOMAIN" ]; then
        echo "Domain: https://$DOMAIN"
    else
        echo "Local Access: http://$(get_public_ip):80"
    fi
    echo
    echo "Management Commands:"
    echo "==================="
    echo "Check status: sudo -u deploy pm2 status"
    echo "View logs: sudo -u deploy pm2 logs $APP_NAME"
    echo "Restart app: sudo -u deploy pm2 restart $APP_NAME"
    echo "Stop app: sudo -u deploy pm2 stop $APP_NAME"
    echo
    echo "Log Files:"
    echo "=========="
    echo "Application logs: /var/log/$APP_NAME/"
    echo "Nginx logs: /var/log/nginx/"
    echo
    if [ -n "$DOMAIN" ]; then
        echo "SSL Certificate:"
        echo "==============="
        echo "Certificate location: /etc/letsencrypt/live/$DOMAIN/"
        echo "Renewal: Automatic (via cron)"
    fi
}

# Main execution
main() {
    log_info "Starting Node.js standalone application deployment..."
    
    validate_prerequisites
    update_system
    install_nodejs
    create_deploy_user
    setup_app_directory
    install_dependencies
    setup_pm2
    configure_nginx
    setup_ssl
    configure_firewall
    setup_monitoring
    setup_log_rotation
    display_info
    
    log_info "Deployment completed successfully!"
}

# Cleanup function for failed deployments
cleanup() {
    log_warn "Cleaning up failed deployment..."
    
    # Stop PM2 processes
    sudo -u deploy bash -c "source /home/deploy/.bashrc && pm2 delete $APP_NAME" 2>/dev/null || true
    
    # Remove application directory
    rm -rf "$APP_DIR" 2>/dev/null || true
    
    # Remove Nginx configuration
    rm -f "/etc/nginx/sites-available/$APP_NAME" 2>/dev/null || true
    rm -f "/etc/nginx/sites-enabled/$APP_NAME" 2>/dev/null || true
    
    # Remove log directory
    rm -rf "/var/log/$APP_NAME" 2>/dev/null || true
    
    log_info "Cleanup completed"
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"

# Disable trap on successful completion
trap - EXIT