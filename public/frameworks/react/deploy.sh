#!/bin/bash

# Deploy React app to Nginx
# Builds and serves static files

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/common.sh"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/validation.sh"

# Configuration
APP_NAME="${APP_NAME:-my-react-app}"
BUILD_DIR="${BUILD_DIR:-build}"
DOMAIN="${DOMAIN:-}"
API_URL="${API_URL:-}"

main() {
    log_step "Starting React app deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    if ! valid_nodejs_project; then
        log_error "Not a valid Node.js project (missing package.json)"
        exit 1
    fi
    
    if ! grep -q '"react"' package.json; then
        log_error "This doesn't look like a React project"
        exit 1
    fi
    
    # Detect OS and update
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    update_system
    
    # Install Node.js if needed
    if ! has_command node; then
        log_step "Installing Node.js"
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        install_package nodejs
    fi
    
    # Install Nginx
    log_step "Installing Nginx"
    install_package nginx
    
    # Build the React app
    log_step "Building React application"
    
    # Set API URL if provided
    if [ -n "$API_URL" ]; then
        echo "REACT_APP_API_URL=$API_URL" > .env.production
    fi
    
    npm install
    npm run build
    
    if [ ! -d "$BUILD_DIR" ]; then
        log_error "Build failed - no $BUILD_DIR directory found"
        exit 1
    fi
    
    # Deploy to web directory
    log_step "Deploying to web server"
    rm -rf "/var/www/$APP_NAME"
    mkdir -p "/var/www/$APP_NAME"
    cp -r "$BUILD_DIR"/* "/var/www/$APP_NAME/"
    chown -R www-data:www-data "/var/www/$APP_NAME"
    
    # Configure Nginx
    log_step "Configuring Nginx"
    cat > "/etc/nginx/sites-available/$APP_NAME" << EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};
    root /var/www/$APP_NAME;
    index index.html;
    
    # Handle React Router
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF
    
    ln -sf "/etc/nginx/sites-available/$APP_NAME" "/etc/nginx/sites-enabled/"
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and restart Nginx
    nginx -t
    systemctl restart nginx
    systemctl enable nginx
    
    # Setup SSL if domain provided
    if [ -n "$DOMAIN" ]; then
        log_step "Setting up SSL certificate"
        install_package certbot python3-certbot-nginx
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    fi
    
    log_success "React app deployed successfully!"
    echo
    echo "App: $APP_NAME"
    echo "Location: /var/www/$APP_NAME"
    if [ -n "$DOMAIN" ]; then
        echo "URL: https://$DOMAIN"
    else
        echo "URL: http://$(curl -s ifconfig.me)"
    fi
    if [ -n "$API_URL" ]; then
        echo "API: $API_URL"
    fi
    echo
    echo "To update: Run this script again or copy new build files to /var/www/$APP_NAME"
}

main "$@"