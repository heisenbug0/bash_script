#!/bin/bash

# Deploy Flask app with PostgreSQL
# Lightweight Python web framework deployment

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../utils/common.sh"
source "$SCRIPT_DIR/../../../utils/logging.sh"
source "$SCRIPT_DIR/../../../utils/validation.sh"

# Configuration
APP_NAME="${APP_NAME:-my-flask-app}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
DB_NAME="${DB_NAME:-${APP_NAME//-/_}}"
DB_USER="${DB_USER:-${APP_NAME//-/_}_user}"
DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-16)}"
DOMAIN="${DOMAIN:-}"
PORT="${PORT:-5000}"
FLASK_APP="${FLASK_APP:-app.py}"

main() {
    log_step "Starting Flask + PostgreSQL deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    if ! valid_python_project; then
        log_error "Not a valid Python project (missing requirements.txt)"
        exit 1
    fi
    
    if [ ! -f "$FLASK_APP" ] && [ ! -f "app.py" ] && [ ! -f "main.py" ]; then
        log_error "No Flask app file found (looking for app.py, main.py, or $FLASK_APP)"
        exit 1
    fi
    
    # Detect OS and update
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    update_system
    
    # Install Python and PostgreSQL
    log_step "Installing Python $PYTHON_VERSION and PostgreSQL"
    install_package python3 python3-pip python3-venv python3-dev
    install_package postgresql postgresql-contrib libpq-dev
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
    
    # Create virtual environment
    log_step "Setting up Python virtual environment"
    python3 -m venv venv
    source venv/bin/activate
    
    # Install dependencies
    log_step "Installing Python dependencies"
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install gunicorn psycopg2-binary
    
    # Create environment file
    log_step "Creating environment configuration"
    cat > .env << EOF
FLASK_ENV=production
SECRET_KEY=$(python -c 'import secrets; print(secrets.token_hex(32))')
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
EOF
    
    # Run Flask setup (if there's a setup script)
    if [ -f "setup.py" ] || grep -q "flask db" requirements.txt; then
        log_step "Running Flask database setup"
        export FLASK_APP="$FLASK_APP"
        flask db upgrade 2>/dev/null || log_info "No Flask-Migrate found, skipping migrations"
    fi
    
    # Create systemd service
    log_step "Creating systemd service"
    cat > "/etc/systemd/system/$APP_NAME.service" << EOF
[Unit]
Description=Gunicorn instance to serve $APP_NAME
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
EnvironmentFile=$(pwd)/.env
ExecStart=$(pwd)/venv/bin/gunicorn --workers 3 --bind unix:$(pwd)/$APP_NAME.sock ${FLASK_APP%.*}:app
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    
    # Set permissions
    chown -R www-data:www-data .
    
    # Start service
    systemctl daemon-reload
    systemctl start "$APP_NAME"
    systemctl enable "$APP_NAME"
    
    # Setup Nginx
    log_step "Setting up Nginx"
    install_package nginx
    
    cat > "/etc/nginx/sites-available/$APP_NAME" << EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};
    
    location / {
        include proxy_params;
        proxy_pass http://unix:$(pwd)/$APP_NAME.sock;
    }
    
    # Static files (if any)
    location /static/ {
        root $(pwd);
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    ln -sf "/etc/nginx/sites-available/$APP_NAME" "/etc/nginx/sites-enabled/"
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
    
    log_success "Flask app deployed successfully!"
    echo
    echo "App: $APP_NAME"
    echo "Database: $DB_NAME"
    echo "User: $DB_USER"
    echo "Password: $DB_PASSWORD"
    if [ -n "$DOMAIN" ]; then
        echo "URL: https://$DOMAIN"
    else
        echo "URL: http://$(curl -s ifconfig.me)"
    fi
    echo
    echo "Manage with: systemctl status|restart|logs $APP_NAME"
}

main "$@"