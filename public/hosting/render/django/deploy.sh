#!/bin/bash

# Django Application Deployment Script for Render
# Supports Django applications with various database and caching configurations

set -euo pipefail

# Configuration with defaults
PROJECT_NAME="${PROJECT_NAME:-django-app}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
DJANGO_VERSION="${DJANGO_VERSION:-4.2}"
DATABASE_TYPE="${DATABASE_TYPE:-postgresql}"
REDIS_ENABLED="${REDIS_ENABLED:-false}"
CELERY_ENABLED="${CELERY_ENABLED:-false}"
CHANNELS_ENABLED="${CHANNELS_ENABLED:-false}"

# Render configuration
RENDER_API_KEY="${RENDER_API_KEY:-}"
SERVICE_TYPE="${SERVICE_TYPE:-web}"
REGION="${REGION:-oregon}"
PLAN="${PLAN:-starter}"

# Application configuration
DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE:-${PROJECT_NAME}.settings.production}"
START_COMMAND="${START_COMMAND:-gunicorn ${PROJECT_NAME}.wsgi:application}"
BUILD_COMMAND="${BUILD_COMMAND:-./build.sh}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed. Please install Python 3.8 or higher."
        exit 1
    fi
    
    # Check Python version
    PYTHON_CURRENT_VERSION=$(python3 --version | cut -d' ' -f2)
    PYTHON_MAJOR=$(echo "$PYTHON_CURRENT_VERSION" | cut -d'.' -f1)
    PYTHON_MINOR=$(echo "$PYTHON_CURRENT_VERSION" | cut -d'.' -f2)
    
    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
        log_error "Python 3.8 or higher is required. Current version: $PYTHON_CURRENT_VERSION"
        exit 1
    fi
    
    # Check if manage.py exists
    if [ ! -f "manage.py" ]; then
        log_error "manage.py not found. Please run this script from your Django project root."
        exit 1
    fi
    
    # Check if requirements.txt exists
    if [ ! -f "requirements.txt" ]; then
        log_error "requirements.txt not found. Please create a requirements.txt file."
        exit 1
    fi
    
    # Check for Django in requirements
    if ! grep -q -i "django" requirements.txt; then
        log_error "Django not found in requirements.txt. Please add Django to your requirements."
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Install Render CLI
install_render_cli() {
    log_step "Installing Render CLI..."
    
    if ! command -v render &> /dev/null; then
        # Install Render CLI
        if command -v npm &> /dev/null; then
            npm install -g @render/cli
        else
            log_warn "npm not found. Please install Render CLI manually: https://render.com/docs/cli"
            return 1
        fi
        log_info "Render CLI installed successfully"
    else
        log_info "Render CLI already installed"
    fi
}

# Authenticate with Render
authenticate_render() {
    log_step "Authenticating with Render..."
    
    if [ -n "$RENDER_API_KEY" ]; then
        render auth login --api-key "$RENDER_API_KEY"
        log_info "Authenticated using API key"
    else
        log_info "Please authenticate with Render:"
        render auth login
    fi
}

# Create build script
create_build_script() {
    log_step "Creating build script..."
    
    cat > build.sh << 'EOF'
#!/usr/bin/env bash
# Exit on error
set -o errexit

echo "🚀 Starting Django deployment build..."

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Set Django settings module
export DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE}

# Database setup
echo "🗄️ Setting up database..."
python manage.py migrate

# Collect static files
echo "📁 Collecting static files..."
python manage.py collectstatic --no-input

# Create superuser if environment variables are set
if [ -n "${DJANGO_SUPERUSER_USERNAME:-}" ] && [ -n "${DJANGO_SUPERUSER_EMAIL:-}" ] && [ -n "${DJANGO_SUPERUSER_PASSWORD:-}" ]; then
    echo "👤 Setting up admin user..."
    python manage.py shell -c "
from django.contrib.auth.models import User
import os
username = os.environ.get('DJANGO_SUPERUSER_USERNAME')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL')
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD')
if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username, email, password)
    print(f'✅ Superuser {username} created')
else:
    print(f'✅ Superuser {username} already exists')
"
fi

# Run any custom setup commands
if [ -f "setup.py" ]; then
    echo "🔧 Running custom setup..."
    python setup.py
fi

echo "✅ Build completed successfully!"
EOF
    
    chmod +x build.sh
    log_info "Build script created"
}

# Create Render blueprint
create_render_blueprint() {
    log_step "Creating Render blueprint..."
    
    # Determine start command based on configuration
    if [ "$CHANNELS_ENABLED" = "true" ]; then
        START_COMMAND="daphne ${PROJECT_NAME}.asgi:application -p \$PORT -b 0.0.0.0"
    else
        START_COMMAND="gunicorn ${PROJECT_NAME}.wsgi:application"
    fi
    
    cat > render.yaml << EOF
# Render Blueprint for $PROJECT_NAME
services:
  - type: web
    name: $PROJECT_NAME
    env: python
    buildCommand: "$BUILD_COMMAND"
    startCommand: "$START_COMMAND"
    plan: $PLAN
    region: $REGION
    envVars:
      - key: SECRET_KEY
        generateValue: true
      - key: DEBUG
        value: "False"
      - key: ALLOWED_HOSTS
        value: "$PROJECT_NAME.onrender.com,*.$PROJECT_NAME.onrender.com"
      - key: DJANGO_SETTINGS_MODULE
        value: "$DJANGO_SETTINGS_MODULE"
      - key: DJANGO_SUPERUSER_USERNAME
        value: "admin"
      - key: DJANGO_SUPERUSER_EMAIL
        value: "admin@$PROJECT_NAME.com"
      - key: DJANGO_SUPERUSER_PASSWORD
        generateValue: true
EOF

    # Add database configuration
    if [ "$DATABASE_TYPE" != "sqlite" ]; then
        cat >> render.yaml << EOF
      - key: DATABASE_URL
        fromDatabase:
          name: $PROJECT_NAME-db
          property: connectionString
EOF
    fi
    
    # Add Redis configuration
    if [ "$REDIS_ENABLED" = "true" ]; then
        cat >> render.yaml << EOF
      - key: REDIS_URL
        fromService:
          type: redis
          name: $PROJECT_NAME-redis
          property: connectionString
EOF
    fi
    
    # Add Celery configuration
    if [ "$CELERY_ENABLED" = "true" ]; then
        cat >> render.yaml << EOF
      - key: CELERY_BROKER_URL
        fromService:
          type: redis
          name: $PROJECT_NAME-redis
          property: connectionString
      - key: CELERY_RESULT_BACKEND
        fromService:
          type: redis
          name: $PROJECT_NAME-redis
          property: connectionString
EOF
    fi
    
    # Add Redis service if needed
    if [ "$REDIS_ENABLED" = "true" ] || [ "$CELERY_ENABLED" = "true" ]; then
        cat >> render.yaml << EOF

  - type: redis
    name: $PROJECT_NAME-redis
    ipAllowList: []
EOF
    fi
    
    # Add Celery worker if enabled
    if [ "$CELERY_ENABLED" = "true" ]; then
        cat >> render.yaml << EOF

  - type: worker
    name: $PROJECT_NAME-worker
    env: python
    buildCommand: "$BUILD_COMMAND"
    startCommand: "celery -A $PROJECT_NAME worker --loglevel=info"
    envVars:
      - key: SECRET_KEY
        sync: false
      - key: DEBUG
        value: "False"
      - key: DJANGO_SETTINGS_MODULE
        value: "$DJANGO_SETTINGS_MODULE"
      - key: DATABASE_URL
        fromDatabase:
          name: $PROJECT_NAME-db
          property: connectionString
      - key: CELERY_BROKER_URL
        fromService:
          type: redis
          name: $PROJECT_NAME-redis
          property: connectionString
      - key: CELERY_RESULT_BACKEND
        fromService:
          type: redis
          name: $PROJECT_NAME-redis
          property: connectionString
EOF
    fi
    
    # Add database configuration
    if [ "$DATABASE_TYPE" != "sqlite" ]; then
        cat >> render.yaml << EOF

databases:
  - name: $PROJECT_NAME-db
    databaseName: ${PROJECT_NAME//-/_}
    user: ${PROJECT_NAME//-/_}_user
EOF
    fi
    
    log_info "Render blueprint created"
}

# Create or update requirements.txt
update_requirements() {
    log_step "Updating requirements.txt..."
    
    # Create backup
    if [ -f "requirements.txt" ]; then
        cp requirements.txt requirements.txt.backup
    fi
    
    # Add essential packages if not present
    REQUIRED_PACKAGES=(
        "Django>=$DJANGO_VERSION"
        "gunicorn>=20.1.0"
        "whitenoise>=6.4.0"
    )
    
    # Add database-specific packages
    case "$DATABASE_TYPE" in
        postgresql)
            REQUIRED_PACKAGES+=("psycopg2-binary>=2.9.0")
            ;;
        mysql)
            REQUIRED_PACKAGES+=("mysqlclient>=2.1.0")
            ;;
    esac
    
    # Add Redis packages if enabled
    if [ "$REDIS_ENABLED" = "true" ]; then
        REQUIRED_PACKAGES+=("django-redis>=5.2.0")
    fi
    
    # Add Celery packages if enabled
    if [ "$CELERY_ENABLED" = "true" ]; then
        REQUIRED_PACKAGES+=("celery>=5.2.0")
    fi
    
    # Add Channels packages if enabled
    if [ "$CHANNELS_ENABLED" = "true" ]; then
        REQUIRED_PACKAGES+=("channels>=4.0.0" "daphne>=4.0.0")
    fi
    
    # Check and add missing packages
    for package in "${REQUIRED_PACKAGES[@]}"; do
        package_name=$(echo "$package" | cut -d'>' -f1 | cut -d'=' -f1)
        if ! grep -q "^$package_name" requirements.txt; then
            echo "$package" >> requirements.txt
            log_info "Added $package to requirements.txt"
        fi
    done
    
    log_info "Requirements updated"
}

# Create production settings
create_production_settings() {
    log_step "Creating production settings..."
    
    # Create settings directory if it doesn't exist
    SETTINGS_DIR="${PROJECT_NAME}/settings"
    mkdir -p "$SETTINGS_DIR"
    
    # Create __init__.py
    touch "$SETTINGS_DIR/__init__.py"
    
    # Create base settings if they don't exist
    if [ ! -f "$SETTINGS_DIR/base.py" ]; then
        # Move existing settings to base.py
        if [ -f "${PROJECT_NAME}/settings.py" ]; then
            mv "${PROJECT_NAME}/settings.py" "$SETTINGS_DIR/base.py"
        fi
    fi
    
    # Create production settings
    cat > "$SETTINGS_DIR/production.py" << EOF
import os
import dj_database_url
from .base import *

# Security
DEBUG = False
SECRET_KEY = os.environ.get('SECRET_KEY')
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# Database
if 'DATABASE_URL' in os.environ:
    DATABASES = {
        'default': dj_database_url.parse(os.environ.get('DATABASE_URL'))
    }
else:
    # Fallback to SQLite for development
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Security settings
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True

# CORS settings
CORS_ALLOWED_ORIGINS = os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',')
CSRF_TRUSTED_ORIGINS = os.environ.get('CSRF_TRUSTED_ORIGINS', '').split(',')
EOF

    # Add Redis cache configuration if enabled
    if [ "$REDIS_ENABLED" = "true" ]; then
        cat >> "$SETTINGS_DIR/production.py" << EOF

# Redis Cache
if 'REDIS_URL' in os.environ:
    CACHES = {
        'default': {
            'BACKEND': 'django_redis.cache.RedisCache',
            'LOCATION': os.environ.get('REDIS_URL'),
            'OPTIONS': {
                'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            }
        }
    }
EOF
    fi
    
    # Add Celery configuration if enabled
    if [ "$CELERY_ENABLED" = "true" ]; then
        cat >> "$SETTINGS_DIR/production.py" << EOF

# Celery Configuration
CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL')
CELERY_RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'UTC'
EOF
    fi
    
    # Add Channels configuration if enabled
    if [ "$CHANNELS_ENABLED" = "true" ]; then
        cat >> "$SETTINGS_DIR/production.py" << EOF

# Channels Configuration
ASGI_APPLICATION = '${PROJECT_NAME}.asgi.application'

if 'REDIS_URL' in os.environ:
    CHANNEL_LAYERS = {
        'default': {
            'BACKEND': 'channels_redis.core.RedisChannelLayer',
            'CONFIG': {
                'hosts': [os.environ.get('REDIS_URL')],
            },
        },
    }
EOF
    fi
    
    # Add dj-database-url to requirements if not present
    if ! grep -q "dj-database-url" requirements.txt; then
        echo "dj-database-url>=1.0.0" >> requirements.txt
    fi
    
    log_info "Production settings created"
}

# Deploy to Render
deploy_to_render() {
    log_step "Deploying to Render..."
    
    # Deploy using blueprint
    if render blueprint deploy render.yaml; then
        log_info "Deployment initiated successfully!"
        
        # Get service URL
        SERVICE_URL=$(render services list --format json | jq -r ".[] | select(.name==\"$PROJECT_NAME\") | .serviceDetails.url" 2>/dev/null || echo "")
        if [ -n "$SERVICE_URL" ]; then
            log_info "Service URL: $SERVICE_URL"
        fi
    else
        log_error "Deployment failed"
        exit 1
    fi
}

# Setup environment variables guide
create_env_guide() {
    log_step "Creating environment variables guide..."
    
    cat > ENV_SETUP.md << EOF
# Environment Variables Setup Guide

## Required Environment Variables

### Application Settings
- \`SECRET_KEY\`: Django secret key (auto-generated by Render)
- \`DEBUG\`: Set to "False" for production
- \`ALLOWED_HOSTS\`: Comma-separated list of allowed hosts
- \`DJANGO_SETTINGS_MODULE\`: Set to "${DJANGO_SETTINGS_MODULE}"

### Database Settings (if using external database)
- \`DATABASE_URL\`: Full database connection string
  - Format: \`postgresql://user:password@host:port/database\`
  - Auto-configured by Render for managed databases

### Admin User Settings
- \`DJANGO_SUPERUSER_USERNAME\`: Admin username (default: admin)
- \`DJANGO_SUPERUSER_EMAIL\`: Admin email
- \`DJANGO_SUPERUSER_PASSWORD\`: Admin password (auto-generated by Render)

EOF

    if [ "$REDIS_ENABLED" = "true" ]; then
        cat >> ENV_SETUP.md << EOF
### Redis Settings
- \`REDIS_URL\`: Redis connection string
  - Format: \`redis://host:port/db\`
  - Auto-configured by Render for managed Redis

EOF
    fi
    
    if [ "$CELERY_ENABLED" = "true" ]; then
        cat >> ENV_SETUP.md << EOF
### Celery Settings
- \`CELERY_BROKER_URL\`: Celery broker URL (usually same as REDIS_URL)
- \`CELERY_RESULT_BACKEND\`: Celery result backend URL

EOF
    fi
    
    cat >> ENV_SETUP.md << EOF
## Security Settings (Optional)
- \`CORS_ALLOWED_ORIGINS\`: Comma-separated list of allowed CORS origins
- \`CSRF_TRUSTED_ORIGINS\`: Comma-separated list of trusted CSRF origins

## Email Settings (Optional)
- \`EMAIL_BACKEND\`: Email backend class
- \`EMAIL_HOST\`: SMTP server host
- \`EMAIL_PORT\`: SMTP server port
- \`EMAIL_USE_TLS\`: Use TLS (True/False)
- \`EMAIL_HOST_USER\`: SMTP username
- \`EMAIL_HOST_PASSWORD\`: SMTP password

## How to Set Environment Variables in Render

1. Go to your service dashboard in Render
2. Click on "Environment" tab
3. Add the required environment variables
4. Click "Save Changes"
5. Your service will automatically redeploy

## Database Connection

If you're using Render's managed PostgreSQL:
1. The \`DATABASE_URL\` is automatically set
2. No additional configuration needed

If you're using an external database:
1. Set the \`DATABASE_URL\` manually
2. Ensure the database is accessible from Render's IP ranges

## Redis Connection

If you're using Render's managed Redis:
1. The \`REDIS_URL\` is automatically set
2. No additional configuration needed

If you're using an external Redis:
1. Set the \`REDIS_URL\` manually
2. Ensure Redis is accessible from Render's IP ranges
EOF
    
    log_info "Environment variables guide created: ENV_SETUP.md"
}

# Display deployment information
display_info() {
    log_info "Django application deployment to Render completed successfully!"
    echo
    echo "Project Information:"
    echo "==================="
    echo "Project Name: $PROJECT_NAME"
    echo "Python Version: $PYTHON_VERSION"
    echo "Django Version: $DJANGO_VERSION"
    echo "Database Type: $DATABASE_TYPE"
    echo "Redis Enabled: $REDIS_ENABLED"
    echo "Celery Enabled: $CELERY_ENABLED"
    echo "Channels Enabled: $CHANNELS_ENABLED"
    echo
    echo "Files Created:"
    echo "=============="
    echo "- build.sh (build script)"
    echo "- render.yaml (deployment blueprint)"
    echo "- ${PROJECT_NAME}/settings/production.py (production settings)"
    echo "- ENV_SETUP.md (environment variables guide)"
    echo
    echo "Render Commands:"
    echo "==============="
    echo "View services: render services list"
    echo "View logs: render logs $PROJECT_NAME"
    echo "Redeploy: render deploy $PROJECT_NAME"
    echo
    echo "Next Steps:"
    echo "==========="
    echo "1. Review and customize the generated files"
    echo "2. Set up environment variables in Render dashboard"
    echo "3. Configure your domain (if needed)"
    echo "4. Set up monitoring and alerts"
    echo "5. Configure backup strategies"
    echo
    echo "Important Files to Review:"
    echo "========================="
    echo "- render.yaml: Deployment configuration"
    echo "- build.sh: Build process customization"
    echo "- ENV_SETUP.md: Environment variables guide"
    echo "- ${PROJECT_NAME}/settings/production.py: Production settings"
    echo
    if [ -f "requirements.txt.backup" ]; then
        echo "Note: Original requirements.txt backed up as requirements.txt.backup"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Remove any temporary files created during deployment
    rm -f temp_*.txt 2>/dev/null || true
}

# Main execution
main() {
    log_info "Starting Django application deployment to Render..."
    
    check_prerequisites
    install_render_cli
    authenticate_render
    create_build_script
    update_requirements
    create_production_settings
    create_render_blueprint
    deploy_to_render
    create_env_guide
    display_info
    cleanup
    
    log_info "Deployment completed successfully!"
}

# Set trap for cleanup
trap cleanup EXIT

# Run main function
main "$@"