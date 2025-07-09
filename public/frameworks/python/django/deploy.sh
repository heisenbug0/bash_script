#!/bin/bash

# Deploy Django app with PostgreSQL
# Simple and straightforward

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../utils/common.sh"
source "$SCRIPT_DIR/../../../utils/logging.sh"
source "$SCRIPT_DIR/../../../utils/validation.sh"

# Configuration
APP_NAME="${APP_NAME:-my-django-app}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
DB_NAME="${DB_NAME:-${APP_NAME//-/_}}"
DB_USER="${DB_USER:-${APP_NAME//-/_}_user}"
DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-16)}"
DOMAIN="${DOMAIN:-}"

main() {
    log_step "Starting Django deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    if ! valid_python_project; then
        log_error "Not a valid Python project (missing requirements.txt)"
        exit 1
    fi
    
    # Detect OS and update
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    update_system
    
    # Install Python and PostgreSQL
    log_step "Installing Python $PYTHON_VERSION and PostgreSQL"
    install_package "python$PYTHON_VERSION" python3-pip python3-venv postgresql postgresql-contrib nginx
    
    # Start PostgreSQL
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
    log_step "Setting up Python environment"
    python3 -m venv venv
    source venv/bin/activate
    
    # Install dependencies
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install gunicorn psycopg2-binary
    
    # Django setup
    log_step "Configuring Django"
    
    # Create production settings if they don't exist
    if [ ! -f "*/settings/production.py" ]; then
        mkdir -p "$(find . -name settings.py -exec dirname {} \;)/settings" 2>/dev/null || true
        cat > "$(find . -name settings.py -exec dirname {} \;)/settings/production.py" << EOF
from .base import *
import os

DEBUG = False
ALLOWED_HOSTS = ['$DOMAIN', 'localhost']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '$DB_NAME',
        'USER': '$DB_USER',
        'PASSWORD': '$DB_PASSWORD',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

STATIC_ROOT = '/var/www/$APP_NAME/static/'
MEDIA_ROOT = '/var/www/$APP_NAME/media/'
EOF
    fi
    
    # Run migrations and collect static files
    export DJANGO_SETTINGS_MODULE="$(basename $(pwd)).settings.production"
    python manage.py migrate
    python manage.py collectstatic --noinput
    
    # Create directories for static files
    mkdir -p "/var/www/$APP_NAME"
    cp -r static "/var/www/$APP_NAME/" 2>/dev/null || true
    
    # Create systemd service
    log_step "Creating systemd service"
    cat > "/etc/systemd/system/$APP_NAME.service" << EOF
[Unit]
Description=$APP_NAME Django app
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$(pwd)
Environment=DJANGO_SETTINGS_MODULE=$APP_NAME.settings.production
ExecStart=$(pwd)/venv/bin/gunicorn --workers 3 --bind unix:$(pwd)/$APP_NAME.sock $APP_NAME.wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    # Fix permissions
    chown -R www-data:www-data .
    
    # Start service
    systemctl daemon-reload
    systemctl start "$APP_NAME"
    systemctl enable "$APP_NAME"
    
    # Setup Nginx
    log_step "Setting up Nginx"
    cat > "/etc/nginx/sites-available/$APP_NAME" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        root /var/www/$APP_NAME;
    }
    
    location / {
        include proxy_params;
        proxy_pass http://unix:$(pwd)/$APP_NAME.sock;
    }
}
EOF
    
    ln -sf "/etc/nginx/sites-available/$APP_NAME" "/etc/nginx/sites-enabled/"
    rm -f /etc/nginx/sites-enabled/default
    systemctl restart nginx
    systemctl enable nginx
    
    # Setup SSL if domain provided
    if [ -n "$DOMAIN" ]; then
        log_step "Setting up SSL certificate"
        install_package certbot python3-certbot-nginx
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    fi
    
    log_success "Django deployment complete!"
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