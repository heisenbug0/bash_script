#!/bin/bash

# Deploy MEAN stack (MongoDB, Express, Angular, Node.js)
# Complete full-stack deployment

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/common.sh"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/validation.sh"

# Configuration
STACK_NAME="${STACK_NAME:-mean-app}"
NODE_VERSION="${NODE_VERSION:-18}"
MONGODB_VERSION="${MONGODB_VERSION:-6.0}"
API_PORT="${API_PORT:-5000}"
CLIENT_PORT="${CLIENT_PORT:-4200}"
DOMAIN="${DOMAIN:-}"

# Directories
BACKEND_DIR="${BACKEND_DIR:-backend}"
FRONTEND_DIR="${FRONTEND_DIR:-frontend}"

main() {
    log_step "Starting MEAN stack deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    # Check project structure
    if [ ! -d "$BACKEND_DIR" ] || [ ! -d "$FRONTEND_DIR" ]; then
        log_error "Expected $BACKEND_DIR and $FRONTEND_DIR directories"
        exit 1
    fi
    
    # Detect OS and update
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    update_system
    
    # Install Node.js
    log_step "Installing Node.js $NODE_VERSION"
    if ! has_command node; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        install_package nodejs
    fi
    
    # Install MongoDB
    log_step "Installing MongoDB $MONGODB_VERSION"
    curl -fsSL https://pgp.mongodb.com/server-${MONGODB_VERSION}.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/${MONGODB_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
    
    apt update
    install_package mongodb-org
    systemctl start mongod
    systemctl enable mongod
    
    # Install Angular CLI
    log_step "Installing Angular CLI"
    npm install -g @angular/cli pm2
    
    # Setup backend
    log_step "Setting up backend"
    cd "$BACKEND_DIR"
    npm install --production
    
    # Start backend with PM2
    pm2 start npm --name "${STACK_NAME}-backend" -- start
    cd ..
    
    # Build frontend
    log_step "Building Angular frontend"
    cd "$FRONTEND_DIR"
    npm install
    ng build --configuration=production
    cd ..
    
    # Install and configure Nginx
    log_step "Setting up Nginx"
    install_package nginx
    
    # Copy Angular build to web directory
    rm -rf "/var/www/$STACK_NAME"
    mkdir -p "/var/www/$STACK_NAME"
    cp -r "$FRONTEND_DIR/dist"/* "/var/www/$STACK_NAME/"
    chown -R www-data:www-data "/var/www/$STACK_NAME"
    
    # Configure Nginx
    cat > "/etc/nginx/sites-available/$STACK_NAME" << EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};
    root /var/www/$STACK_NAME;
    index index.html;
    
    # Serve Angular app
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://localhost:$API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    ln -sf "/etc/nginx/sites-available/$STACK_NAME" "/etc/nginx/sites-enabled/"
    rm -f /etc/nginx/sites-enabled/default
    systemctl restart nginx
    systemctl enable nginx
    
    # Setup PM2 startup
    pm2 startup
    pm2 save
    
    # Setup SSL if domain provided
    if [ -n "$DOMAIN" ]; then
        log_step "Setting up SSL certificate"
        install_package certbot python3-certbot-nginx
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    fi
    
    log_success "MEAN stack deployed successfully!"
    echo
    echo "Stack: $STACK_NAME"
    echo "Backend: Running on port $API_PORT"
    echo "Frontend: Served by Nginx"
    echo "Database: MongoDB running locally"
    if [ -n "$DOMAIN" ]; then
        echo "URL: https://$DOMAIN"
    else
        echo "URL: http://$(curl -s ifconfig.me)"
    fi
    echo
    echo "Manage backend: pm2 status | logs | restart ${STACK_NAME}-backend"
    echo "MongoDB: systemctl status mongod"
}

main "$@"