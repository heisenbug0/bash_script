#!/bin/bash

# Deploy Django app with PostgreSQL
# Production-ready setup with Gunicorn and Nginx

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
PORT="${PORT:-8000}"

main() {
    log_step "Starting Django + PostgreSQL deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    if ! valid_python_project; then
        log_error "Not a valid Python project (missing requirements.txt or manage.py)"
        exit 1
    fi
    
    if [ ! -f "manage.py" ]; then
        log_error "This doesn't look like a Django project (no manage.py found)"
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
ALTER USER $DB_USER CREATEDB;
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
    
    # Create Django settings for production
    log_step "Creating production settings"
    cat > .env << EOF
DEBUG=False
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
ALLOWED_HOSTS=localhost,127.0.0.1${DOMAIN:+,$DOMAIN}
EOF
    
    # Run Django setup
    log_step "Setting up Django"
    python manage.py collectstatic --noinput
    python manage.py migrate
    
    # Create superuser if credentials provided
    if [ -n "${DJANGO_SUPERUSER_USERNAME:-}" ]; then
        python manage.py shell << EOF
from django.contrib.auth.models import User
import os
username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@example.com')
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', 'admin123')
if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username, email, password)
    print(f'Superuser {username} created')
EOF
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
ExecStart=$(pwd)/venv/bin/gunicorn --workers 3 --bind unix:$(pwd)/$APP_NAME.sock ${APP_NAME}.wsgi:application
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
    
    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        root $(pwd);
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location / {
        include proxy_params;
        proxy_pass http://unix:$(pwd)/$APP_NAME.sock;
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
    
    log_success "Django app deployed successfully!"
    echo
    echo "App: $APP_NAME"
    echo "Database: $DB_NAME"
    echo "User: $DB_USER"
    echo "Password: $DB_PASSWORD"
    if [ -n "$DOMAIN" ]; then
        echo "URL: https://$DOMAIN"
        echo "Admin: https://$DOMAIN/admin/"
    else
        echo "URL: http://$(curl -s ifconfig.me)"
        echo "Admin: http://$(curl -s ifconfig.me)/admin/"
    fi
    echo
    echo "Manage with: systemctl status|restart|logs $APP_NAME"
}

main "$@"