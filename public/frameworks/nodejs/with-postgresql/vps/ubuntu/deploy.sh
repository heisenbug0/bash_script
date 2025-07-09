#!/bin/bash

# Node.js + PostgreSQL Application Deployment Script for Ubuntu VPS
# Deploys Node.js applications with PostgreSQL database integration

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../../../utils/common.sh"

# Configuration with defaults
APP_NAME="${APP_NAME:-nodejs-postgres-app}"
NODE_VERSION="${NODE_VERSION:-18}"
POSTGRES_VERSION="${POSTGRES_VERSION:-15}"
PORT="${PORT:-3000}"
DOMAIN="${DOMAIN:-}"
SSL_EMAIL="${SSL_EMAIL:-admin@${DOMAIN}}"
NODE_ENV="${NODE_ENV:-production}"

# Database configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-${APP_NAME//-/_}}"
DB_USER="${DB_USER:-${APP_NAME//-/_}_user}"
DB_PASSWORD="${DB_PASSWORD:-$(generate_password 32)}"
DB_SSL="${DB_SSL:-prefer}"
DB_POOL_SIZE="${DB_POOL_SIZE:-10}"

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
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        log_error "package.json not found. Please run this script from your Node.js project root."
        exit 1
    fi
    
    # Check for PostgreSQL dependencies in package.json
    if ! grep -q -E '"(pg|sequelize|prisma|typeorm)"' package.json; then
        log_warn "No PostgreSQL dependencies found in package.json. Make sure your app uses pg, Sequelize, Prisma, or TypeORM."
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

# Install PostgreSQL
install_postgresql() {
    log_step "Installing PostgreSQL $POSTGRES_VERSION..."
    
    # Add PostgreSQL official APT repository
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    
    apt update
    install_package "postgresql-$POSTGRES_VERSION"
    install_package "postgresql-client-$POSTGRES_VERSION"
    install_package "postgresql-contrib-$POSTGRES_VERSION"
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    log_info "PostgreSQL $POSTGRES_VERSION installed successfully"
}

# Configure PostgreSQL
configure_postgresql() {
    log_step "Configuring PostgreSQL..."
    
    PG_CONFIG_FILE="/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
    PG_HBA_FILE="/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"
    
    # Backup original configuration
    backup_file "$PG_CONFIG_FILE"
    backup_file "$PG_HBA_FILE"
    
    # Configure PostgreSQL settings
    cat >> "$PG_CONFIG_FILE" << EOF

# Custom configuration for Node.js application
listen_addresses = 'localhost'
port = $DB_PORT
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 10MB
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
EOF
    
    # Restart PostgreSQL to apply configuration
    systemctl restart postgresql
    
    log_info "PostgreSQL configuration completed"
}

# Setup database and user
setup_database() {
    log_step "Setting up database and user..."
    
    # Create database and user
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF
    
    # Test database connection
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        log_info "Database connection test successful"
    else
        log_error "Database connection test failed"
        exit 1
    fi
    
    log_info "Database '$DB_NAME' and user '$DB_USER' created successfully"
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

# Create environment configuration
create_env_config() {
    log_step "Creating environment configuration..."
    
    # Create .env file for the application
    cat > "$APP_DIR/.env" << EOF
# Application Configuration
NODE_ENV=$NODE_ENV
PORT=$PORT

# Database Configuration
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_SSL=$DB_SSL
DB_POOL_SIZE=$DB_POOL_SIZE

# Database URL (for Prisma, Sequelize, etc.)
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=$DB_SSL

# Application-specific variables (add your own)
JWT_SECRET=$(generate_password 64)
SESSION_SECRET=$(generate_password 64)
EOF
    
    chown deploy:deploy "$APP_DIR/.env"
    chmod 600 "$APP_DIR/.env"
    
    log_info "Environment configuration created"
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

# Run database migrations
run_migrations() {
    log_step "Running database migrations..."
    
    cd "$APP_DIR"
    
    # Check for different migration systems and run them
    sudo -u deploy bash -c "
        source /home/deploy/.bashrc
        cd $APP_DIR
        source .env
        
        # Prisma migrations
        if [ -f 'prisma/schema.prisma' ]; then
            echo 'Running Prisma migrations...'
            npx prisma migrate deploy
            npx prisma generate
        fi
        
        # Sequelize migrations
        if [ -f '.sequelizerc' ] || [ -d 'migrations' ]; then
            echo 'Running Sequelize migrations...'
            npx sequelize-cli db:migrate
        fi
        
        # TypeORM migrations
        if [ -f 'ormconfig.json' ] || [ -f 'ormconfig.js' ]; then
            echo 'Running TypeORM migrations...'
            npx typeorm migration:run
        fi
        
        # Custom migration script
        if npm run | grep -q 'migrate'; then
            echo 'Running custom migration script...'
            npm run migrate
        fi
    " || log_warn "No migrations found or migration failed"
    
    log_info "Database migrations completed"
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
    min_uptime: '10s',
    kill_timeout: 5000,
    wait_ready: true,
    listen_timeout: 10000
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
    
    # API endpoints with longer timeout
    location /api/ {
        proxy_pass http://localhost:$PORT;
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
    
    # Allow PostgreSQL (only from localhost)
    ufw allow from 127.0.0.1 to any port 5432
    
    # Enable firewall
    ufw --force enable
    
    log_info "Firewall configured successfully"
}

# Setup database backup
setup_backup() {
    if [ "$BACKUP_ENABLED" = "true" ]; then
        log_step "Setting up database backup..."
        
        # Create backup directory
        create_directory "/var/backups/$APP_NAME" "deploy" "deploy" "755"
        
        # Create backup script
        cat > "/usr/local/bin/backup-$APP_NAME.sh" << EOF
#!/bin/bash

BACKUP_DIR="/var/backups/$APP_NAME"
DATE=\$(date +%Y%m%d_%H%M%S)
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_HOST="$DB_HOST"
DB_PORT="$DB_PORT"

# Create backup
PGPASSWORD="$DB_PASSWORD" pg_dump -h "\$DB_HOST" -p "\$DB_PORT" -U "\$DB_USER" "\$DB_NAME" | gzip > "\$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz"

# Keep only last $BACKUP_RETENTION days of backups
find "\$BACKUP_DIR" -name "\${DB_NAME}_*.sql.gz" -mtime +$BACKUP_RETENTION -delete

echo "Backup completed: \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz"
EOF
        
        chmod +x "/usr/local/bin/backup-$APP_NAME.sh"
        
        # Add backup cron job
        (crontab -l 2>/dev/null; echo "$BACKUP_SCHEDULE /usr/local/bin/backup-$APP_NAME.sh") | crontab -
        
        log_info "Database backup setup completed"
    fi
}

# Setup monitoring
setup_monitoring() {
    if [ "$ENABLE_MONITORING" = "true" ]; then
        log_step "Setting up monitoring..."
        
        # Create monitoring script
        cat > "/usr/local/bin/monitor-$APP_NAME.sh" << EOF
#!/bin/bash

APP_NAME="$APP_NAME"
LOG_FILE="/var/log/\$APP_NAME/monitor.log"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_HOST="$DB_HOST"
DB_PORT="$DB_PORT"

# Check if PM2 process is running
if ! sudo -u deploy pm2 list | grep -q "\$APP_NAME"; then
    echo "\$(date): \$APP_NAME is not running, attempting to restart..." >> "\$LOG_FILE"
    sudo -u deploy bash -c "source /home/deploy/.bashrc && cd /home/deploy/\$APP_NAME && pm2 restart \$APP_NAME"
fi

# Check application health
if command -v curl &> /dev/null; then
    if ! curl -f http://localhost:$PORT/health &> /dev/null; then
        echo "\$(date): Health check failed for \$APP_NAME" >> "\$LOG_FILE"
    fi
fi

# Check database connectivity
if ! PGPASSWORD="$DB_PASSWORD" psql -h "\$DB_HOST" -p "\$DB_PORT" -U "\$DB_USER" -d "\$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "\$(date): Database connection failed for \$APP_NAME" >> "\$LOG_FILE"
fi

# Check disk space
DISK_USAGE=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')
if [ "\$DISK_USAGE" -gt 80 ]; then
    echo "\$(date): Disk usage is \$DISK_USAGE% for \$APP_NAME" >> "\$LOG_FILE"
fi
EOF
        
        chmod +x "/usr/local/bin/monitor-$APP_NAME.sh"
        
        # Add monitoring cron job
        (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-$APP_NAME.sh") | crontab -
        
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
    
    # PostgreSQL log rotation
    cat > "/etc/logrotate.d/postgresql-$APP_NAME" << EOF
/var/log/postgresql/postgresql-$POSTGRES_VERSION-main.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 postgres postgres
    postrotate
        systemctl reload postgresql
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
    echo "PostgreSQL Version: $POSTGRES_VERSION"
    echo "Application Directory: $APP_DIR"
    echo "Port: $PORT"
    if [ -n "$DOMAIN" ]; then
        echo "Domain: https://$DOMAIN"
    else
        echo "Local Access: http://$(get_public_ip):80"
    fi
    echo
    echo "Database Information:"
    echo "===================="
    echo "Database Host: $DB_HOST"
    echo "Database Port: $DB_PORT"
    echo "Database Name: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASSWORD"
    echo "Connection String: postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
    echo
    echo "Management Commands:"
    echo "==================="
    echo "Check app status: sudo -u deploy pm2 status"
    echo "View app logs: sudo -u deploy pm2 logs $APP_NAME"
    echo "Restart app: sudo -u deploy pm2 restart $APP_NAME"
    echo "Stop app: sudo -u deploy pm2 stop $APP_NAME"
    echo
    echo "Database Commands:"
    echo "=================="
    echo "Connect to DB: PGPASSWORD='$DB_PASSWORD' psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
    echo "Create backup: /usr/local/bin/backup-$APP_NAME.sh"
    echo "Check DB status: sudo systemctl status postgresql"
    echo
    echo "Log Files:"
    echo "=========="
    echo "Application logs: /var/log/$APP_NAME/"
    echo "PostgreSQL logs: /var/log/postgresql/"
    echo "Nginx logs: /var/log/nginx/"
    echo
    if [ "$BACKUP_ENABLED" = "true" ]; then
        echo "Backup Information:"
        echo "=================="
        echo "Backup directory: /var/backups/$APP_NAME/"
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
    log_info "Starting Node.js + PostgreSQL application deployment..."
    
    validate_prerequisites
    update_system
    install_postgresql
    configure_postgresql
    setup_database
    install_nodejs
    create_deploy_user
    setup_app_directory
    create_env_config
    install_dependencies
    run_migrations
    setup_pm2
    configure_nginx
    setup_ssl
    configure_firewall
    setup_backup
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
    
    # Remove database and user
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
    sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;" 2>/dev/null || true
    
    # Remove log directory
    rm -rf "/var/log/$APP_NAME" 2>/dev/null || true
    
    # Remove backup directory
    rm -rf "/var/backups/$APP_NAME" 2>/dev/null || true
    
    log_info "Cleanup completed"
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"

# Disable trap on successful completion
trap - EXIT