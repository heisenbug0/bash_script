#!/bin/bash

# MERN Stack Deployment Script for Ubuntu VPS
# Deploys MongoDB, Express.js, React, and Node.js applications

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../../utils/common.sh"

# Configuration with defaults
STACK_NAME="${STACK_NAME:-mern-app}"
NODE_VERSION="${NODE_VERSION:-18}"
MONGODB_VERSION="${MONGODB_VERSION:-6.0}"
API_PORT="${API_PORT:-5000}"
CLIENT_PORT="${CLIENT_PORT:-3000}"
DOMAIN="${DOMAIN:-}"
SSL_EMAIL="${SSL_EMAIL:-admin@${DOMAIN}}"
NODE_ENV="${NODE_ENV:-production}"

# Directory structure
BACKEND_DIR="${BACKEND_DIR:-backend}"
FRONTEND_DIR="${FRONTEND_DIR:-frontend}"
BUILD_DIR="${BUILD_DIR:-build}"

# Database configuration
MONGO_DB="${MONGO_DB:-${STACK_NAME//-/_}}"
MONGO_USER="${MONGO_USER:-${STACK_NAME//-/_}_user}"
MONGO_PASSWORD="${MONGO_PASSWORD:-$(generate_password 32)}"
MONGO_AUTH_DB="${MONGO_AUTH_DB:-admin}"

# PM2 configuration
PM2_INSTANCES="${PM2_INSTANCES:-max}"
PM2_MAX_MEMORY="${PM2_MAX_MEMORY:-500M}"

# Monitoring and backup
ENABLE_MONITORING="${ENABLE_MONITORING:-true}"
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"
BACKUP_SCHEDULE="${BACKUP_SCHEDULE:-0 2 * * *}"
BACKUP_RETENTION="${BACKUP_RETENTION:-7}"

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
    
    # Check for backend package.json
    if [ ! -f "$BACKEND_DIR/package.json" ]; then
        log_error "$BACKEND_DIR/package.json not found. Please ensure your backend is in the $BACKEND_DIR directory."
        exit 1
    fi
    
    # Check for frontend package.json
    if [ ! -f "$FRONTEND_DIR/package.json" ]; then
        log_error "$FRONTEND_DIR/package.json not found. Please ensure your frontend is in the $FRONTEND_DIR directory."
        exit 1
    fi
    
    # Check for MongoDB dependencies in backend
    if ! grep -q -E '"(mongoose|mongodb)"' "$BACKEND_DIR/package.json"; then
        log_warn "No MongoDB dependencies found in backend package.json. Make sure your backend uses mongoose or mongodb driver."
    fi
    
    # Check for React in frontend
    if ! grep -q '"react"' "$FRONTEND_DIR/package.json"; then
        log_warn "React not found in frontend package.json. Make sure your frontend is a React application."
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
    install_package "gnupg"
    
    log_info "System packages updated successfully"
}

# Install MongoDB
install_mongodb() {
    log_step "Installing MongoDB $MONGODB_VERSION..."
    
    # Import MongoDB public GPG key
    curl -fsSL https://pgp.mongodb.com/server-$MONGODB_VERSION.asc | gpg -o /usr/share/keyrings/mongodb-server-$MONGODB_VERSION.gpg --dearmor
    
    # Add MongoDB repository
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-$MONGODB_VERSION.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/$MONGODB_VERSION multiverse" | tee /etc/apt/sources.list.d/mongodb-org-$MONGODB_VERSION.list
    
    # Update package list and install MongoDB
    apt update
    install_package "mongodb-org"
    
    # Start and enable MongoDB
    systemctl start mongod
    systemctl enable mongod
    
    # Wait for MongoDB to start
    sleep 5
    
    log_info "MongoDB $MONGODB_VERSION installed successfully"
}

# Configure MongoDB
configure_mongodb() {
    log_step "Configuring MongoDB..."
    
    # Backup original configuration
    backup_file "/etc/mongod.conf"
    
    # Configure MongoDB
    cat > /etc/mongod.conf << EOF
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where to store data
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# Where to write logging data
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1

# Process management
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

# Security
security:
  authorization: enabled

# Operation profiling
operationProfiling:
  slowOpThresholdMs: 100
  mode: slowOp

# Replication (for future scaling)
#replication:
#  replSetName: "rs0"
EOF
    
    # Restart MongoDB to apply configuration
    systemctl restart mongod
    
    log_info "MongoDB configuration completed"
}

# Setup MongoDB database and user
setup_mongodb() {
    log_step "Setting up MongoDB database and user..."
    
    # Create admin user first (if not exists)
    mongosh --eval "
        use admin;
        if (db.getUser('admin') == null) {
            db.createUser({
                user: 'admin',
                pwd: '$MONGO_PASSWORD',
                roles: ['userAdminAnyDatabase', 'dbAdminAnyDatabase', 'readWriteAnyDatabase']
            });
        }
    " || log_warn "Admin user might already exist"
    
    # Create application database and user
    mongosh -u admin -p "$MONGO_PASSWORD" --authenticationDatabase admin --eval "
        use $MONGO_DB;
        if (db.getUser('$MONGO_USER') == null) {
            db.createUser({
                user: '$MONGO_USER',
                pwd: '$MONGO_PASSWORD',
                roles: ['readWrite']
            });
        }
    "
    
    # Test database connection
    if mongosh -u "$MONGO_USER" -p "$MONGO_PASSWORD" --authenticationDatabase "$MONGO_DB" --eval "db.runCommand('ping')" > /dev/null 2>&1; then
        log_info "Database connection test successful"
    else
        log_error "Database connection test failed"
        exit 1
    fi
    
    log_info "MongoDB database '$MONGO_DB' and user '$MONGO_USER' created successfully"
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

# Setup application directories
setup_app_directories() {
    log_step "Setting up application directories..."
    
    APP_DIR="/home/deploy/$STACK_NAME"
    BACKEND_APP_DIR="$APP_DIR/backend"
    FRONTEND_APP_DIR="$APP_DIR/frontend"
    
    # Create application directories
    create_directory "$APP_DIR" "deploy" "deploy" "755"
    create_directory "$BACKEND_APP_DIR" "deploy" "deploy" "755"
    create_directory "$FRONTEND_APP_DIR" "deploy" "deploy" "755"
    
    # Copy application files
    cp -r "$BACKEND_DIR"/* "$BACKEND_APP_DIR/"
    cp -r "$FRONTEND_DIR"/* "$FRONTEND_APP_DIR/"
    chown -R deploy:deploy "$APP_DIR"
    
    # Create logs directory
    create_directory "/var/log/$STACK_NAME" "deploy" "deploy" "755"
    
    log_info "Application directories setup completed"
}

# Create environment configuration
create_env_config() {
    log_step "Creating environment configuration..."
    
    # Create backend .env file
    cat > "$BACKEND_APP_DIR/.env" << EOF
# Application Configuration
NODE_ENV=$NODE_ENV
PORT=$API_PORT

# Database Configuration
MONGODB_URI=mongodb://$MONGO_USER:$MONGO_PASSWORD@localhost:27017/$MONGO_DB?authSource=$MONGO_DB
DB_NAME=$MONGO_DB

# Frontend Configuration
CLIENT_URL=http://localhost:$CLIENT_PORT
FRONTEND_BUILD_PATH=../frontend/$BUILD_DIR

# Security
JWT_SECRET=$(generate_password 64)
SESSION_SECRET=$(generate_password 64)
BCRYPT_ROUNDS=12

# CORS Configuration
CORS_ORIGIN=http://localhost:$CLIENT_PORT
EOF
    
    # Create frontend .env file
    cat > "$FRONTEND_APP_DIR/.env" << EOF
# API Configuration
REACT_APP_API_URL=http://localhost:$API_PORT
REACT_APP_API_BASE_URL=http://localhost:$API_PORT/api

# Build Configuration
GENERATE_SOURCEMAP=false
EOF
    
    # Set proper permissions
    chown deploy:deploy "$BACKEND_APP_DIR/.env" "$FRONTEND_APP_DIR/.env"
    chmod 600 "$BACKEND_APP_DIR/.env" "$FRONTEND_APP_DIR/.env"
    
    log_info "Environment configuration created"
}

# Install dependencies and build frontend
install_dependencies_and_build() {
    log_step "Installing dependencies and building applications..."
    
    # Install backend dependencies
    sudo -u deploy bash -c "
        source /home/deploy/.bashrc
        cd $BACKEND_APP_DIR
        
        if [ -f 'package-lock.json' ]; then
            npm ci --production
        elif [ -f 'yarn.lock' ]; then
            npm install -g yarn
            yarn install --production --frozen-lockfile
        else
            npm install --production
        fi
    "
    
    # Install frontend dependencies and build
    sudo -u deploy bash -c "
        source /home/deploy/.bashrc
        cd $FRONTEND_APP_DIR
        
        if [ -f 'package-lock.json' ]; then
            npm ci
        elif [ -f 'yarn.lock' ]; then
            npm install -g yarn
            yarn install --frozen-lockfile
        else
            npm install
        fi
        
        # Build the React application
        npm run build
    "
    
    log_info "Dependencies installed and frontend built successfully"
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
  apps: [
    {
      name: '$STACK_NAME-backend',
      script: './backend/server.js',
      cwd: '$APP_DIR',
      instances: '$PM2_INSTANCES',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'development',
        PORT: $API_PORT
      },
      env_production: {
        NODE_ENV: '$NODE_ENV',
        PORT: $API_PORT
      },
      max_memory_restart: '$PM2_MAX_MEMORY',
      error_file: '/var/log/$STACK_NAME/backend-error.log',
      out_file: '/var/log/$STACK_NAME/backend-out.log',
      log_file: '/var/log/$STACK_NAME/backend-combined.log',
      time: true,
      watch: false,
      ignore_watch: ['node_modules', 'logs', 'frontend'],
      max_restarts: 10,
      min_uptime: '10s',
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000
    }
  ]
};
EOF
    
    chown deploy:deploy "$APP_DIR/ecosystem.config.js"
    
    # Start backend with PM2
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

# Configure Nginx
configure_nginx() {
    log_step "Configuring Nginx..."
    
    # Remove default Nginx configuration
    rm -f /etc/nginx/sites-enabled/default
    
    # Create Nginx configuration for the MERN stack
    cat > "/etc/nginx/sites-available/$STACK_NAME" << EOF
server {
    listen 80;
    server_name ${DOMAIN:-localhost};
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
    
    # API routes - proxy to backend
    location /api/ {
        proxy_pass http://localhost:$API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Extended timeouts for API calls
        proxy_connect_timeout 120s;
        proxy_send_timeout 120s;
        proxy_read_timeout 120s;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:$API_PORT/health;
        access_log off;
    }
    
    # Serve React application
    location / {
        root $FRONTEND_APP_DIR/$BUILD_DIR;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Don't cache index.html
        location = /index.html {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
    
    # Handle React Router (SPA)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root $FRONTEND_APP_DIR/$BUILD_DIR;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Enable the site
    ln -sf "/etc/nginx/sites-available/$STACK_NAME" "/etc/nginx/sites-enabled/"
    
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
        
        # Update frontend .env for production URL
        sed -i "s|http://localhost:$API_PORT|https://$DOMAIN|g" "$FRONTEND_APP_DIR/.env"
        
        # Update backend .env for production URL
        sed -i "s|http://localhost:$CLIENT_PORT|https://$DOMAIN|g" "$BACKEND_APP_DIR/.env"
        
        # Rebuild frontend with updated API URL
        sudo -u deploy bash -c "
            source /home/deploy/.bashrc
            cd $FRONTEND_APP_DIR
            npm run build
        "
        
        # Obtain SSL certificate
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect
        
        # Setup automatic renewal
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        
        # Restart PM2 to pick up new environment variables
        sudo -u deploy bash -c "
            source /home/deploy/.bashrc
            pm2 restart all
        "
        
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
    
    # Allow MongoDB (only from localhost)
    ufw allow from 127.0.0.1 to any port 27017
    
    # Enable firewall
    ufw --force enable
    
    log_info "Firewall configured successfully"
}

# Setup database backup
setup_backup() {
    if [ "$BACKUP_ENABLED" = "true" ]; then
        log_step "Setting up database backup..."
        
        # Create backup directory
        create_directory "/var/backups/$STACK_NAME" "deploy" "deploy" "755"
        
        # Create backup script
        cat > "/usr/local/bin/backup-$STACK_NAME.sh" << EOF
#!/bin/bash

BACKUP_DIR="/var/backups/$STACK_NAME"
DATE=\$(date +%Y%m%d_%H%M%S)
DB_NAME="$MONGO_DB"
MONGO_USER="$MONGO_USER"
MONGO_PASSWORD="$MONGO_PASSWORD"

# Create MongoDB backup
mongodump --host localhost --port 27017 --db "\$DB_NAME" --username "\$MONGO_USER" --password "\$MONGO_PASSWORD" --authenticationDatabase "\$DB_NAME" --out "\$BACKUP_DIR/\${DB_NAME}_\${DATE}"

# Compress backup
tar -czf "\$BACKUP_DIR/\${DB_NAME}_\${DATE}.tar.gz" -C "\$BACKUP_DIR" "\${DB_NAME}_\${DATE}"
rm -rf "\$BACKUP_DIR/\${DB_NAME}_\${DATE}"

# Keep only last $BACKUP_RETENTION days of backups
find "\$BACKUP_DIR" -name "\${DB_NAME}_*.tar.gz" -mtime +$BACKUP_RETENTION -delete

echo "Backup completed: \$BACKUP_DIR/\${DB_NAME}_\${DATE}.tar.gz"
EOF
        
        chmod +x "/usr/local/bin/backup-$STACK_NAME.sh"
        
        # Add backup cron job
        (crontab -l 2>/dev/null; echo "$BACKUP_SCHEDULE /usr/local/bin/backup-$STACK_NAME.sh") | crontab -
        
        log_info "Database backup setup completed"
    fi
}

# Setup monitoring
setup_monitoring() {
    if [ "$ENABLE_MONITORING" = "true" ]; then
        log_step "Setting up monitoring..."
        
        # Create monitoring script
        cat > "/usr/local/bin/monitor-$STACK_NAME.sh" << EOF
#!/bin/bash

STACK_NAME="$STACK_NAME"
LOG_FILE="/var/log/\$STACK_NAME/monitor.log"
DB_NAME="$MONGO_DB"
MONGO_USER="$MONGO_USER"
MONGO_PASSWORD="$MONGO_PASSWORD"

# Check if PM2 processes are running
if ! sudo -u deploy pm2 list | grep -q "\$STACK_NAME-backend"; then
    echo "\$(date): \$STACK_NAME backend is not running, attempting to restart..." >> "\$LOG_FILE"
    sudo -u deploy bash -c "source /home/deploy/.bashrc && cd /home/deploy/\$STACK_NAME && pm2 restart \$STACK_NAME-backend"
fi

# Check backend health
if command -v curl &> /dev/null; then
    if ! curl -f http://localhost:$API_PORT/health &> /dev/null; then
        echo "\$(date): Backend health check failed for \$STACK_NAME" >> "\$LOG_FILE"
    fi
fi

# Check MongoDB connectivity
if ! mongosh -u "\$MONGO_USER" -p "\$MONGO_PASSWORD" --authenticationDatabase "\$DB_NAME" --eval "db.runCommand('ping')" > /dev/null 2>&1; then
    echo "\$(date): MongoDB connection failed for \$STACK_NAME" >> "\$LOG_FILE"
fi

# Check Nginx status
if ! systemctl is-active --quiet nginx; then
    echo "\$(date): Nginx is not running for \$STACK_NAME" >> "\$LOG_FILE"
    systemctl restart nginx
fi

# Check disk space
DISK_USAGE=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')
if [ "\$DISK_USAGE" -gt 80 ]; then
    echo "\$(date): Disk usage is \$DISK_USAGE% for \$STACK_NAME" >> "\$LOG_FILE"
fi
EOF
        
        chmod +x "/usr/local/bin/monitor-$STACK_NAME.sh"
        
        # Add monitoring cron job
        (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-$STACK_NAME.sh") | crontab -
        
        log_info "Monitoring setup completed"
    fi
}

# Setup log rotation
setup_log_rotation() {
    log_step "Setting up log rotation..."
    
    cat > "/etc/logrotate.d/$STACK_NAME" << EOF
/var/log/$STACK_NAME/*.log {
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
    
    # MongoDB log rotation
    cat > "/etc/logrotate.d/mongodb-$STACK_NAME" << EOF
/var/log/mongodb/mongod.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 mongodb mongodb
    postrotate
        systemctl reload mongod
    endscript
}
EOF
    
    log_info "Log rotation setup completed"
}

# Display deployment information
display_info() {
    log_info "MERN Stack deployment completed successfully!"
    echo
    echo "Stack Information:"
    echo "=================="
    echo "Stack Name: $STACK_NAME"
    echo "Node.js Version: $(node --version)"
    echo "MongoDB Version: $MONGODB_VERSION"
    echo "Backend Port: $API_PORT"
    echo "Frontend Build: $FRONTEND_APP_DIR/$BUILD_DIR"
    if [ -n "$DOMAIN" ]; then
        echo "Domain: https://$DOMAIN"
    else
        echo "Local Access: http://$(get_public_ip):80"
    fi
    echo
    echo "Database Information:"
    echo "===================="
    echo "Database Name: $MONGO_DB"
    echo "Database User: $MONGO_USER"
    echo "Database Password: $MONGO_PASSWORD"
    echo "Connection URI: mongodb://$MONGO_USER:$MONGO_PASSWORD@localhost:27017/$MONGO_DB?authSource=$MONGO_DB"
    echo
    echo "Application Directories:"
    echo "======================="
    echo "Backend: $BACKEND_APP_DIR"
    echo "Frontend: $FRONTEND_APP_DIR"
    echo "Frontend Build: $FRONTEND_APP_DIR/$BUILD_DIR"
    echo
    echo "Management Commands:"
    echo "==================="
    echo "Check backend status: sudo -u deploy pm2 status"
    echo "View backend logs: sudo -u deploy pm2 logs $STACK_NAME-backend"
    echo "Restart backend: sudo -u deploy pm2 restart $STACK_NAME-backend"
    echo "Stop backend: sudo -u deploy pm2 stop $STACK_NAME-backend"
    echo
    echo "Database Commands:"
    echo "=================="
    echo "Connect to MongoDB: mongosh -u $MONGO_USER -p $MONGO_PASSWORD --authenticationDatabase $MONGO_DB"
    echo "Create backup: /usr/local/bin/backup-$STACK_NAME.sh"
    echo "Check MongoDB status: sudo systemctl status mongod"
    echo
    echo "Frontend Commands:"
    echo "=================="
    echo "Rebuild frontend: cd $FRONTEND_APP_DIR && npm run build"
    echo "Update API URL: Edit $FRONTEND_APP_DIR/.env and rebuild"
    echo
    echo "Log Files:"
    echo "=========="
    echo "Backend logs: /var/log/$STACK_NAME/"
    echo "MongoDB logs: /var/log/mongodb/"
    echo "Nginx logs: /var/log/nginx/"
    echo
    if [ "$BACKUP_ENABLED" = "true" ]; then
        echo "Backup Information:"
        echo "=================="
        echo "Backup directory: /var/backups/$STACK_NAME/"
        echo "Backup schedule: $BACKUP_SCHEDULE"
        echo "Backup retention: $BACKUP_RETENTION days"
    fi
    echo
    if [ -n "$DOMAIN" ]; then
        echo "SSL Certificate:"
        echo "==============="
        echo "Certificate location: /etc/letsencrypt/live/$DOMAIN/"
        echo "Renewal: Automatic (via cron)"
    fi
    echo
    echo "IMPORTANT: Please save the database password securely!"
}

# Main execution
main() {
    log_info "Starting MERN Stack deployment..."
    
    validate_prerequisites
    update_system
    install_mongodb
    configure_mongodb
    setup_mongodb
    install_nodejs
    create_deploy_user
    setup_app_directories
    create_env_config
    install_dependencies_and_build
    setup_pm2
    configure_nginx
    setup_ssl
    configure_firewall
    setup_backup
    setup_monitoring
    setup_log_rotation
    display_info
    
    log_info "MERN Stack deployment completed successfully!"
}

# Cleanup function for failed deployments
cleanup() {
    log_warn "Cleaning up failed deployment..."
    
    # Stop PM2 processes
    sudo -u deploy bash -c "source /home/deploy/.bashrc && pm2 delete all" 2>/dev/null || true
    
    # Remove application directory
    rm -rf "$APP_DIR" 2>/dev/null || true
    
    # Remove Nginx configuration
    rm -f "/etc/nginx/sites-available/$STACK_NAME" 2>/dev/null || true
    rm -f "/etc/nginx/sites-enabled/$STACK_NAME" 2>/dev/null || true
    
    # Remove MongoDB database and user
    mongosh -u admin -p "$MONGO_PASSWORD" --authenticationDatabase admin --eval "
        use $MONGO_DB;
        db.dropUser('$MONGO_USER');
        db.dropDatabase();
    " 2>/dev/null || true
    
    # Remove log directory
    rm -rf "/var/log/$STACK_NAME" 2>/dev/null || true
    
    # Remove backup directory
    rm -rf "/var/backups/$STACK_NAME" 2>/dev/null || true
    
    log_info "Cleanup completed"
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"

# Disable trap on successful completion
trap - EXIT