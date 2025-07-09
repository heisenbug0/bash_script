# Django Deployment Scripts

Comprehensive deployment scripts for Django applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
django/
├── standalone/          # Django apps without external dependencies
├── with-postgresql/     # Django + PostgreSQL combinations
├── with-mysql/         # Django + MySQL combinations
├── with-sqlite/        # Django + SQLite combinations
├── with-redis/         # Django + Redis combinations
├── full-stack/         # Complete stacks (DB + Cache + Monitoring)
├── api-only/           # Django REST API deployments
├── celery/             # Django + Celery task queue
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- Simple Django websites
- Portfolio sites
- Blog applications
- Prototype applications
- Development environments

### Database Integrations
- **PostgreSQL**: Production-ready relational database
- **MySQL**: Traditional relational database
- **SQLite**: Lightweight embedded database
- **MongoDB**: Document-based NoSQL (via MongoEngine)

### Caching Solutions
- **Redis**: In-memory data structure store
- **Memcached**: Distributed memory caching
- **Database caching**: Django's built-in caching

### Full-Stack Combinations
- **Django + PostgreSQL + Redis**: Complete web application stack
- **Django + Celery + Redis**: Background task processing
- **Django REST + React**: API backend with React frontend
- **Django + Channels**: WebSocket support for real-time features

## 🚀 Quick Start Examples

### Deploy Django App to Render
```bash
cd hosting/render/django/
export PROJECT_NAME="my-django-app"
export DATABASE_TYPE="postgresql"
export REDIS_ENABLED="true"
./deploy.sh
```

### Deploy Django + PostgreSQL to VPS
```bash
cd with-postgresql/vps/ubuntu/
export APP_NAME="my-webapp"
export DB_NAME="myapp"
export DOMAIN="app.example.com"
sudo ./deploy.sh
```

### Deploy Django API to AWS ECS
```bash
cd containers/aws-ecs/
export CLUSTER_NAME="django-api"
export SERVICE_NAME="api-service"
export IMAGE_URI="my-account.dkr.ecr.region.amazonaws.com/django-api:latest"
./deploy.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-django-app"
export PYTHON_VERSION="3.11"
export DJANGO_VERSION="4.2"
export DEBUG="False"
export SECRET_KEY="your-secret-key"

# Database Configuration
export DB_ENGINE="postgresql"
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
export DB_USER="appuser"
export DB_PASSWORD="securepassword"

# Redis Configuration (if applicable)
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""
export REDIS_DB="0"

# Celery Configuration (if applicable)
export CELERY_BROKER_URL="redis://localhost:6379/0"
export CELERY_RESULT_BACKEND="redis://localhost:6379/0"

# Static Files
export STATIC_URL="/static/"
export STATIC_ROOT="/var/www/static/"
export MEDIA_URL="/media/"
export MEDIA_ROOT="/var/www/media/"

# Email Configuration
export EMAIL_BACKEND="django.core.mail.backends.smtp.EmailBackend"
export EMAIL_HOST="smtp.gmail.com"
export EMAIL_PORT="587"
export EMAIL_USE_TLS="True"

# Security
export ALLOWED_HOSTS="example.com,www.example.com"
export CORS_ALLOWED_ORIGINS="https://example.com"
export CSRF_TRUSTED_ORIGINS="https://example.com"
```

### Django Settings Examples

#### Production Settings
```python
# settings/production.py
import os
from .base import *

DEBUG = False
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

# Redis Cache
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': f"redis://{os.environ.get('REDIS_HOST', 'localhost')}:{os.environ.get('REDIS_PORT', '6379')}/1",
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

# Celery Configuration
CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL')
CELERY_RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND')

# Static Files
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Security
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

## 📝 Build Scripts

### Render Build Script
```bash
#!/usr/bin/env bash
# build.sh for Render deployment
set -o errexit

echo "🚀 Starting Django deployment build..."

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Set Django settings module
export DJANGO_SETTINGS_MODULE=myproject.settings.production

# Database setup
echo "🗄️ Setting up database..."
python manage.py migrate

# Collect static files
echo "📁 Collecting static files..."
python manage.py collectstatic --no-input

# Create superuser if needed
echo "👤 Setting up admin user..."
python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('✅ Superuser created')
else:
    print('✅ Superuser already exists')
"

echo "✅ Build completed successfully!"
```

### Railway Build Script
```bash
#!/usr/bin/env bash
# railway-build.sh
set -e

echo "🚂 Starting Railway Django deployment..."

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --no-input

# Create superuser from environment variables
python manage.py shell -c "
import os
from django.contrib.auth.models import User
username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@example.com')
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', 'admin123')
if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username, email, password)
    print(f'✅ Superuser {username} created')
"

echo "✅ Railway build completed!"
```

## 📋 Platform Blueprints

### Render Blueprint
```yaml
# render.yaml
services:
  - type: web
    name: django-app
    env: python
    buildCommand: "./build.sh"
    startCommand: "gunicorn myproject.wsgi:application"
    envVars:
      - key: SECRET_KEY
        generateValue: true
      - key: DEBUG
        value: "False"
      - key: DJANGO_SETTINGS_MODULE
        value: "myproject.settings.production"
      - key: DATABASE_URL
        fromDatabase:
          name: django-db
          property: connectionString
      - key: REDIS_URL
        fromService:
          type: redis
          name: django-redis
          property: connectionString

  - type: redis
    name: django-redis
    ipAllowList: []

databases:
  - name: django-db
    databaseName: django_app
    user: django_user
```

### Railway Configuration
```toml
# railway.toml
[build]
builder = "NIXPACKS"
buildCommand = "./railway-build.sh"

[deploy]
startCommand = "gunicorn myproject.wsgi:application --bind 0.0.0.0:$PORT"
healthcheckPath = "/health/"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10

[environments.production]
variables = { DJANGO_SETTINGS_MODULE = "myproject.settings.production" }
```

## 📝 Features

### Security
- ✅ Environment variable management
- ✅ Database security configuration
- ✅ SSL/TLS certificate setup
- ✅ CORS configuration
- ✅ CSRF protection
- ✅ Security middleware setup

### Performance
- ✅ Database connection pooling
- ✅ Redis caching configuration
- ✅ Static file optimization
- ✅ Gunicorn/uWSGI setup
- ✅ CDN configuration

### Monitoring
- ✅ Django logging configuration
- ✅ Error tracking setup
- ✅ Performance monitoring
- ✅ Health check endpoints
- ✅ Database monitoring

### Development Tools
- ✅ Django Debug Toolbar setup
- ✅ Testing configuration
- ✅ Code quality tools
- ✅ Migration management
- ✅ Fixture loading

## 🛠️ Prerequisites

### System Requirements
- Python 3.8+ (3.11+ recommended)
- pip package manager
- Virtual environment support
- Database system (if required)
- Redis server (if caching enabled)

### Django Requirements
```txt
# requirements.txt
Django>=4.2,<5.0
gunicorn>=20.1.0
psycopg2-binary>=2.9.0  # for PostgreSQL
django-redis>=5.2.0     # for Redis caching
whitenoise>=6.4.0       # for static files
django-cors-headers>=4.0.0
celery>=5.2.0           # for background tasks
channels>=4.0.0         # for WebSocket support
djangorestframework>=3.14.0  # for API development
```

## 📚 Usage Examples

### Example 1: Simple Blog
```bash
# Deploy a Django blog to Render
cd hosting/render/django/
export PROJECT_NAME="my-blog"
export DATABASE_TYPE="postgresql"
./deploy.sh
```

### Example 2: E-commerce API
```bash
# Deploy Django REST API with Redis
cd api-only/with-redis/
export APP_NAME="ecommerce-api"
export REDIS_ENABLED="true"
sudo ./deploy.sh
```

### Example 3: Real-time Chat App
```bash
# Deploy Django Channels app
cd with-redis/channels/
export APP_NAME="chat-app"
export CHANNELS_ENABLED="true"
sudo ./deploy.sh
```

## 🔍 Troubleshooting

### Common Issues

**Static Files Not Loading**
```bash
# Check static files configuration
python manage.py collectstatic --dry-run
python manage.py findstatic admin/css/base.css
```

**Database Connection Issues**
```bash
# Test database connection
python manage.py dbshell
python manage.py migrate --check
```

**Redis Connection Issues**
```bash
# Test Redis connection
python manage.py shell -c "
from django.core.cache import cache
cache.set('test', 'value')
print(cache.get('test'))
"
```

### Performance Optimization

**Database Queries**
```bash
# Enable query logging
export DJANGO_LOG_LEVEL=DEBUG

# Use Django Debug Toolbar
pip install django-debug-toolbar
```

**Caching**
```bash
# Check cache performance
python manage.py shell -c "
from django.core.cache import cache
import time
start = time.time()
cache.get('test_key')
print(f'Cache access time: {time.time() - start}s')
"
```

## 🔗 Related Documentation

- [Database Scripts](../../../databases/README.md)
- [Caching Scripts](../../../caching/README.md)
- [Cloud Services](../../../cloud-services/README.md)
- [Hosting Platforms](../../../hosting/README.md)