#!/bin/bash

# Deploy MEAN Stack (MongoDB + Express + Angular + Node.js)
# Complete JavaScript stack deployment

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

# Directory structure
BACKEND_DIR="${BACKEND_DIR:-backend}"
FRONTEND_DIR="${FRONTEND_DIR:-frontend}"
BUILD_DIR="${BUILD_DIR:-dist}"

# Database configuration
MONGO_DB="${MONGO_DB:-${STACK_NAME//-/_}}"
MONGO_USER="${MONGO_USER:-${STACK_NAME//-/_}_user}"
MONGO_PASSWORD="${MONGO_PASSWORD:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-16)}"

main() {
    log_step "Starting MEAN Stack deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    if [ ! -f "$BACKEND_DIR/package.json" ]; then
        log_error "$BACKEND_DIR/package.json not found"
        exit 1
    fi
    
    if [ ! -f "$FRONTEND_DIR/package.json" ]; then
        log_error "$FRONTEND_DIR/package.json not found"
        exit 1
    fi
    
    # Check for Angular
    if ! grep -q '"@angular/core"' "$FRONTEND_DIR/package.json"; then
        log_error "Frontend doesn't appear to be an Angular project"
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
    
    # Setup MongoDB database and user
    log_step "Setting up MongoDB database"
    mongosh << EOF
use admin
db.createUser({
  user: "admin",
  pwd: "$MONGO_PASSWORD",
  roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]
})

use $MONGO_DB
db.createUser({
  user: "$MONGO_USER",
  pwd: "$MONGO_PASSWORD",
  roles: ["readWrite"]
})
EOF
    
    # Install backend dependencies
    log_step "Installing backend dependencies"
    cd "$BACKEND_DIR"
    npm install --production
    cd ..
    
    # Install frontend dependencies and build
    log_step "Building Angular frontend"
    cd "$FRONTEND_DIR"
    npm install
    npm run build --prod
    cd ..
    
    # Create environment files
    log_step "Creating environment configuration"
    cat > "$BACKEND_DIR/.env" << EOF
NODE_ENV=production
PORT=$API_PORT
MONGODB_URI=mongodb://$MONGO_USER:$MONGO_PASSWORD@localhost:27017/$MONGO_DB?authSource=$MONGO_DB
JWT_SECRET=$(openssl rand -base64 64 | tr -d '=+/' | cut -c1-32)
CORS_ORIGIN=http://localhost:$CLIENT_PORT
EOF
    
    # Install PM2
    log_step "Installing PM2"
    npm install -g pm2
    
    # Create PM2 ecosystem file
    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: '$STACK_NAME-backend',
      script: './$BACKEND_DIR/server.js',
      instances: 'max',
      exec_mode: 'cluster',
      env_production: {
        NODE_ENV: 'production',
        PORT: $API_PORT
      },
      error_file: '/var/log/$STACK_NAME/backend-error.log',
      out_file: '/var/log/$STACK_NAME/backend-out.log',
      log_file: '/var/log/$STACK_NAME/backend-combined.log'
    }
  ]
}
EOF
    
    # Create log directory
    mkdir -p "/var/log/$STACK_NAME"
    
    # Start backend
    pm2 start ecosystem.config.js --env production
    pm2 startup
    pm2 save
    
    # Setup Nginx
    log_step "Setting up Nginx"
    install_package nginx
    
    # Deploy Angular build
    rm -rf "/var/www/$STACK_NAME"
    mkdir -p "/var/www/$STACK_NAME"
    cp -r "$FRONTEND_DIR/$BUILD_DIR"/* "/var/www/$STACK_NAME/"
    chown -R www-data:www-data "/var/www/$STACK_NAME"
    
    cat > "/etc/nginx/sites-available/$STACK_NAME" << EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};
    root /var/www/$STACK_NAME;
    index index.html;
    
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
    }
    
    # Angular app - handle routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    ln -sf "/etc/nginx/sites-available/$STACK_NAME" "/etc/nginx/sites-enabled/"
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t
    systemctl restart nginx
    systemctl enable nginx
    
    # Setup SSL if domain provided
    if [ -n "$DOMAIN" ]; then
        log_step "Setting up SSL certificate"
        install_package certbot python3-certbot-nginx
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    fi
    
    log_success "MEAN Stack deployed successfully!"
    echo
    echo "Stack: $STACK_NAME"
    echo "Database: $MONGO_DB"
    echo "User: $MONGO_USER"
    echo "Password: $MONGO_PASSWORD"
    if [ -n "$DOMAIN" ]; then
        echo "URL: https://$DOMAIN"
    else
        echo "URL: http://$(curl -s ifconfig.me)"
    fi
    echo
    echo "Backend: pm2 status | logs $STACK_NAME-backend"
    echo "Database: mongosh -u $MONGO_USER -p $MONGO_PASSWORD --authenticationDatabase $MONGO_DB"
}

main "$@"