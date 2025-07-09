# Laravel Deployment Scripts

Comprehensive deployment scripts for Laravel applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
laravel/
├── standalone/          # Laravel apps without external dependencies
├── with-mysql/         # Laravel + MySQL combinations
├── with-postgresql/    # Laravel + PostgreSQL combinations
├── with-redis/         # Laravel + Redis combinations
├── full-stack/         # Complete stacks (DB + Cache + Queue)
├── api-only/           # Laravel API deployments
├── queue/              # Laravel Queue worker deployments
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- Simple Laravel websites
- Portfolio sites
- Blog applications
- Prototype applications
- Development environments

### Database Integrations
- **MySQL**: Traditional Laravel database
- **PostgreSQL**: Advanced relational database
- **SQLite**: Lightweight embedded database
- **MongoDB**: Document-based NoSQL (via Laravel MongoDB)

### Caching Solutions
- **Redis**: In-memory data structure store
- **Memcached**: Distributed memory caching
- **File caching**: Laravel's built-in file caching

### Queue Systems
- **Redis Queue**: Redis-based job queue
- **Database Queue**: Database-backed queue
- **SQS**: Amazon Simple Queue Service
- **Horizon**: Laravel Horizon for Redis queues

## 🚀 Quick Start Examples

### Deploy Laravel App to VPS
```bash
cd standalone/vps/ubuntu/
export APP_NAME="my-laravel-app"
export PHP_VERSION="8.2"
export DOMAIN="app.example.com"
sudo ./deploy.sh
```

### Deploy Laravel + MySQL to AWS
```bash
cd with-mysql/aws-ec2/
export APP_NAME="my-webapp"
export DB_NAME="myapp"
sudo ./deploy.sh
```

### Deploy Laravel API to Render
```bash
cd api-only/render/
export PROJECT_NAME="my-api"
export DATABASE_TYPE="postgresql"
./deploy.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-laravel-app"
export PHP_VERSION="8.2"
export LARAVEL_VERSION="10"
export APP_ENV="production"
export APP_DEBUG="false"
export APP_KEY="base64:generated-key"

# Database Configuration
export DB_CONNECTION="mysql"
export DB_HOST="localhost"
export DB_PORT="3306"
export DB_DATABASE="myapp"
export DB_USERNAME="appuser"
export DB_PASSWORD="securepassword"

# Redis Configuration (if applicable)
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""

# Queue Configuration
export QUEUE_CONNECTION="redis"
export QUEUE_DRIVER="redis"

# Mail Configuration
export MAIL_MAILER="smtp"
export MAIL_HOST="smtp.gmail.com"
export MAIL_PORT="587"
export MAIL_USERNAME="your-email@gmail.com"
export MAIL_PASSWORD="your-password"

# Cache Configuration
export CACHE_DRIVER="redis"
export SESSION_DRIVER="redis"

# File Storage
export FILESYSTEM_DISK="local"
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION="us-east-1"
export AWS_BUCKET=""
```

## 📝 Build Scripts

### Composer Build Script
```bash
#!/usr/bin/env bash
# build.sh for Laravel deployment
set -o errexit

echo "🚀 Starting Laravel deployment build..."

# Install PHP dependencies
echo "📦 Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader

# Generate application key if not set
if [ -z "$APP_KEY" ]; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# Clear and cache configuration
echo "⚙️ Optimizing configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations
echo "🗄️ Running database migrations..."
php artisan migrate --force

# Seed database if needed
if [ "$APP_ENV" != "production" ]; then
    echo "🌱 Seeding database..."
    php artisan db:seed --force
fi

# Create storage link
echo "🔗 Creating storage link..."
php artisan storage:link

# Clear application cache
echo "🧹 Clearing application cache..."
php artisan cache:clear

# Optimize for production
echo "🚀 Optimizing for production..."
php artisan optimize

echo "✅ Build completed successfully!"
```

### Frontend Build Script
```bash
#!/usr/bin/env bash
# build-frontend.sh
set -o errexit

echo "🎨 Building frontend assets..."

# Install Node.js dependencies
if [ -f "package.json" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm ci --production=false
    
    # Build assets
    echo "🔨 Building assets..."
    npm run build
    
    # Clean up node_modules for production
    echo "🧹 Cleaning up development dependencies..."
    rm -rf node_modules
    npm ci --production=true
fi

echo "✅ Frontend build completed!"
```

## 📋 Platform Blueprints

### Render Blueprint
```yaml
# render.yaml
services:
  - type: web
    name: laravel-app
    env: php
    buildCommand: "./build.sh"
    startCommand: "php artisan serve --host=0.0.0.0 --port=$PORT"
    envVars:
      - key: APP_KEY
        generateValue: true
      - key: APP_ENV
        value: "production"
      - key: APP_DEBUG
        value: "false"
      - key: DATABASE_URL
        fromDatabase:
          name: laravel-db
          property: connectionString
      - key: REDIS_URL
        fromService:
          type: redis
          name: laravel-redis
          property: connectionString

  - type: worker
    name: laravel-worker
    env: php
    buildCommand: "./build.sh"
    startCommand: "php artisan queue:work --verbose --tries=3 --timeout=90"
    envVars:
      - key: APP_KEY
        sync: false
      - key: APP_ENV
        value: "production"
      - key: DATABASE_URL
        fromDatabase:
          name: laravel-db
          property: connectionString
      - key: REDIS_URL
        fromService:
          type: redis
          name: laravel-redis
          property: connectionString

  - type: redis
    name: laravel-redis
    ipAllowList: []

databases:
  - name: laravel-db
    databaseName: laravel_app
    user: laravel_user
```

### Railway Configuration
```toml
# railway.toml
[build]
builder = "NIXPACKS"
buildCommand = "./build.sh"

[deploy]
startCommand = "php artisan serve --host=0.0.0.0 --port=$PORT"
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10

[environments.production]
variables = { APP_ENV = "production", APP_DEBUG = "false" }
```

## 📝 Docker Configuration

### Laravel Dockerfile
```dockerfile
FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev \
    postgresql-dev \
    mysql-client \
    nodejs \
    npm

# Install PHP extensions
RUN docker-php-ext-install \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    xml

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create non-root user
RUN addgroup -g 1001 -S laravel && \
    adduser -S laravel -u 1001 -G laravel

WORKDIR /var/www/html

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --no-dev --no-scripts --no-autoloader

# Copy application code
COPY --chown=laravel:laravel . .

# Install frontend dependencies and build assets
RUN if [ -f "package.json" ]; then \
        npm ci && \
        npm run build && \
        rm -rf node_modules; \
    fi

# Generate optimized autoloader
RUN composer dump-autoload --optimize

# Set permissions
RUN chown -R laravel:laravel /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

USER laravel

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
```

### Docker Compose
```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: laravel-app
    restart: unless-stopped
    environment:
      - APP_ENV=production
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis
    networks:
      - laravel-network

  nginx:
    image: nginx:alpine
    container_name: laravel-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./storage/app/public:/var/www/html/storage/app/public
    depends_on:
      - app
    networks:
      - laravel-network

  mysql:
    image: mysql:8.0
    container_name: laravel-mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel
      MYSQL_PASSWORD: password
      MYSQL_ROOT_PASSWORD: rootpassword
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - laravel-network

  redis:
    image: redis:7-alpine
    container_name: laravel-redis
    restart: unless-stopped
    networks:
      - laravel-network

  queue:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: laravel-queue
    restart: unless-stopped
    command: php artisan queue:work --verbose --tries=3 --timeout=90
    environment:
      - APP_ENV=production
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis
    networks:
      - laravel-network

  scheduler:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: laravel-scheduler
    restart: unless-stopped
    command: php artisan schedule:work
    environment:
      - APP_ENV=production
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis
    networks:
      - laravel-network

volumes:
  mysql_data:

networks:
  laravel-network:
    driver: bridge
```

## 📝 Features

### Security
- ✅ Environment variable management
- ✅ Database security configuration
- ✅ SSL/TLS certificate setup
- ✅ CORS configuration
- ✅ CSRF protection
- ✅ XSS protection

### Performance
- ✅ OPcache configuration
- ✅ Redis caching setup
- ✅ Database connection pooling
- ✅ Asset optimization
- ✅ CDN configuration

### Monitoring
- ✅ Laravel logging configuration
- ✅ Error tracking setup
- ✅ Performance monitoring
- ✅ Health check endpoints
- ✅ Queue monitoring

### Development Tools
- ✅ Laravel Telescope setup
- ✅ Testing configuration
- ✅ Code quality tools
- ✅ Migration management
- ✅ Seeder setup

## 🛠️ Prerequisites

### System Requirements
- PHP 8.1+ (8.2+ recommended)
- Composer package manager
- Node.js and npm (for frontend assets)
- Database system (MySQL, PostgreSQL, etc.)
- Redis server (if caching enabled)

### Laravel Requirements
```json
{
    "require": {
        "php": "^8.1",
        "laravel/framework": "^10.0",
        "laravel/sanctum": "^3.2",
        "laravel/tinker": "^2.8"
    },
    "require-dev": {
        "fakerphp/faker": "^1.9.1",
        "laravel/pint": "^1.0",
        "laravel/sail": "^1.18",
        "mockery/mockery": "^1.4.4",
        "nunomaduro/collision": "^7.0",
        "phpunit/phpunit": "^10.1",
        "spatie/laravel-ignition": "^2.0"
    }
}
```

## 📚 Usage Examples

### Example 1: E-commerce Platform
```bash
# Deploy Laravel e-commerce to VPS
cd full-stack/vps/ubuntu/
export APP_NAME="ecommerce-platform"
export DB_CONNECTION="mysql"
export QUEUE_CONNECTION="redis"
sudo ./deploy.sh
```

### Example 2: API Backend
```bash
# Deploy Laravel API with PostgreSQL
cd api-only/with-postgresql/
export APP_NAME="api-backend"
export DB_CONNECTION="pgsql"
sudo ./deploy.sh
```

### Example 3: SaaS Application
```bash
# Deploy Laravel SaaS to AWS
cd full-stack/aws-ec2/
export APP_NAME="saas-app"
export QUEUE_CONNECTION="sqs"
sudo ./deploy.sh
```

## 🔍 Troubleshooting

### Common Issues

**Composer Issues**
```bash
# Clear Composer cache
composer clear-cache

# Update dependencies
composer update

# Install with verbose output
composer install -vvv
```

**Artisan Command Issues**
```bash
# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Regenerate autoloader
composer dump-autoload
```

**Permission Issues**
```bash
# Fix storage permissions
sudo chown -R www-data:www-data storage/
sudo chmod -R 775 storage/

# Fix bootstrap cache permissions
sudo chown -R www-data:www-data bootstrap/cache/
sudo chmod -R 775 bootstrap/cache/
```

### Performance Optimization

**OPcache Configuration**
```ini
; php.ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.revalidate_freq=0
opcache.validate_timestamps=0
```

**Laravel Optimization**
```bash
# Optimize for production
php artisan optimize

# Cache configuration
php artisan config:cache

# Cache routes
php artisan route:cache

# Cache views
php artisan view:cache
```

## 🔗 Related Documentation

- [Database Scripts](../../../databases/README.md)
- [Caching Scripts](../../../caching/README.md)
- [Cloud Services](../../../cloud-services/README.md)
- [Hosting Platforms](../../../hosting/README.md)