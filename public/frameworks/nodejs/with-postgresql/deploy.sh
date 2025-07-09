#!/bin/bash

# Deploy Node.js app with PostgreSQL
# Works on Ubuntu, Debian, and CentOS

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../utils/common.sh"
source "$SCRIPT_DIR/../../../utils/logging.sh"
source "$SCRIPT_DIR/../../../utils/validation.sh"

# Configuration
APP_NAME="${APP_NAME:-my-node-app}"
NODE_VERSION="${NODE_VERSION:-18}"
DB_NAME="${DB_NAME:-${APP_NAME//-/_}}"
DB_USER="${DB_USER:-${APP_NAME//-/_}_user}"
DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-16)}"
DOMAIN="${DOMAIN:-}"
PORT="${PORT:-3000}"

main() {
    log_step "Starting Node.js + PostgreSQL deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    if ! valid_nodejs_project; then
        log_error "Not a valid Node.js project (missing package.json)"
        exit 1
    fi
    
    # Detect OS and update system
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    
    log_step "Updating system packages"
    update_system
    
    # Install Node.js
    log_step "Installing Node.js $NODE_VERSION"
    if ! has_command node; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        install_package nodejs
    fi
    
    # Install PostgreSQL
    log_step "Installing PostgreSQL"
    install_package postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
    
    # Setup database
    log_step "Setting up database"
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\q
EOF
    
    # Install app dependencies
    log_step "Installing application dependencies"
    npm install --production
    
    # Create environment file
    log_step "Creating environment configuration"
    cat > .env << EOF
NODE_ENV=production
PORT=$PORT
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
EOF
    
    # Install PM2 for process management
    log_step "Installing PM2"
    npm install -g pm2
    
    # Start the application
    log_step "Starting application"
    pm2 start npm --name "$APP_NAME" -- start
    pm2 startup
    pm2 save
    
    # Setup Nginx if domain provided
    if [ -n "$DOMAIN" ]; then
        log_step "Setting up Nginx for $DOMAIN"
        install_package nginx
        
        cat > "/etc/nginx/sites-available/$APP_NAME" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
        
        ln -sf "/etc/nginx/sites-available/$APP_NAME" "/etc/nginx/sites-enabled/"
        rm -f /etc/nginx/sites-enabled/default
        systemctl restart nginx
        systemctl enable nginx
        
        # Setup SSL with Let's Encrypt
        install_package certbot python3-certbot-nginx
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    fi
    
    log_success "Deployment complete!"
    echo
    echo "App: $APP_NAME"
    echo "Database: $DB_NAME"
    echo "User: $DB_USER"
    echo "Password: $DB_PASSWORD"
    if [ -n "$DOMAIN" ]; then
        echo "URL: https://$DOMAIN"
    else
        echo "URL: http://$(curl -s ifconfig.me):$PORT"
    fi
    echo
    echo "Manage with: pm2 status | restart | logs $APP_NAME"
}

main "$@"