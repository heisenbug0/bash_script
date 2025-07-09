# Ruby on Rails Deployment Scripts

Comprehensive deployment scripts for Ruby on Rails applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
rails/
├── standalone/          # Rails apps without external dependencies
├── with-postgresql/     # Rails + PostgreSQL combinations
├── with-mysql/         # Rails + MySQL combinations
├── with-sqlite/        # Rails + SQLite combinations
├── with-redis/         # Rails + Redis combinations
├── full-stack/         # Complete stacks (DB + Cache + Background Jobs)
├── api-only/           # Rails API deployments
├── microservices/      # Rails microservices
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- Full-stack web applications
- Content management systems
- E-commerce platforms
- Blog applications
- Admin dashboards

### Database Integrations
- **PostgreSQL**: Production-ready relational database
- **MySQL**: Traditional relational database
- **SQLite**: Lightweight embedded database
- **MongoDB**: Document-based NoSQL (via Mongoid)

### Caching Solutions
- **Redis**: In-memory data structure store
- **Memcached**: Distributed memory caching
- **Rails.cache**: Built-in caching support

### Background Processing
- **Sidekiq**: Redis-based background jobs
- **Resque**: Redis-backed job queue
- **Delayed Job**: Database-backed jobs
- **Good Job**: PostgreSQL-based jobs

## 🚀 Quick Start Examples

### Deploy Rails App to VPS
```bash
cd standalone/vps/ubuntu/
export APP_NAME="my-rails-app"
export RUBY_VERSION="3.2"
export DOMAIN="app.example.com"
sudo ./deploy.sh
```

### Deploy Rails + PostgreSQL to AWS
```bash
cd with-postgresql/aws-ec2/
export APP_NAME="my-webapp"
export DB_NAME="myapp"
sudo ./deploy.sh
```

### Deploy Rails API to Render
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
export APP_NAME="my-rails-app"
export RUBY_VERSION="3.2"
export RAILS_VERSION="7.1"
export RAILS_ENV="production"
export RACK_ENV="production"
export SECRET_KEY_BASE="your-secret-key"

# Database Configuration
export DATABASE_URL="postgresql://user:pass@localhost/db"
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
export DB_USER="appuser"
export DB_PASSWORD="securepassword"

# Redis Configuration (if applicable)
export REDIS_URL="redis://localhost:6379/0"
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""

# Background Jobs
export SIDEKIQ_REDIS_URL="redis://localhost:6379/1"
export SIDEKIQ_CONCURRENCY="5"

# Security Configuration
export RAILS_MASTER_KEY="your-master-key"
export DEVISE_SECRET_KEY="your-devise-secret"

# Performance Configuration
export WEB_CONCURRENCY="2"
export MAX_THREADS="5"
export RAILS_MAX_THREADS="5"
export RAILS_MIN_THREADS="5"
```

## 📝 Application Examples

### Simple Rails Application
```ruby
# Gemfile
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.0'

gem 'rails', '~> 7.1.0'
gem 'pg', '~> 1.1'
gem 'puma', '~> 6.0'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 5.0'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder', '~> 2.7'
gem 'bootsnap', '>= 1.4.4', require: false
gem 'redis', '~> 5.0'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

group :development do
  gem 'web-console', '>= 4.1.0'
  gem 'listen', '~> 3.3'
  gem 'spring'
end

group :production do
  gem 'sidekiq'
  gem 'sidekiq-web'
end
```

### Rails API Application
```ruby
# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    @users = User.all
    render json: @users
  end

  def show
    render json: @user
  end

  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
```

### User Model
```ruby
# app/models/user.rb
class User < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def to_json_api
    {
      id: id,
      name: name,
      email: email,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601
    }
  end
end
```

## 📝 Build Scripts

### Standard Build Script
```bash
#!/usr/bin/env bash
# build.sh for Rails deployment
set -o errexit

echo "🚀 Starting Rails deployment build..."

# Install Ruby dependencies
echo "💎 Installing Ruby gems..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

# Set Rails environment
export RAILS_ENV=production
export RACK_ENV=production

# Precompile assets
echo "🎨 Precompiling assets..."
bundle exec rails assets:precompile

# Run database migrations
echo "🗄️ Running database migrations..."
bundle exec rails db:migrate

# Seed database if needed
if [ "$RAILS_ENV" != "production" ]; then
    echo "🌱 Seeding database..."
    bundle exec rails db:seed
fi

echo "✅ Build completed successfully!"
```

### Puma Configuration
```ruby
# config/puma.rb
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

port ENV.fetch("PORT") { 3000 }

environment ENV.fetch("RAILS_ENV") { "development" }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

workers ENV.fetch("WEB_CONCURRENCY") { 2 }

preload_app!

before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

plugin :tmp_restart
```

## 📝 Configuration Files

### Database Configuration
```yaml
# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: myapp_development

test:
  <<: *default
  database: myapp_test

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
```

### Redis Configuration
```ruby
# config/initializers/redis.rb
if Rails.env.production?
  $redis = Redis.new(url: ENV['REDIS_URL'])
else
  $redis = Redis.new(host: 'localhost', port: 6379, db: 0)
end
```

### Sidekiq Configuration
```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['SIDEKIQ_REDIS_URL'] || ENV['REDIS_URL'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['SIDEKIQ_REDIS_URL'] || ENV['REDIS_URL'] }
end
```

## 📦 Docker Configuration

### Dockerfile
```dockerfile
FROM ruby:3.2-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN npm install -g yarn

# Create non-root user
RUN useradd --create-home --shell /bin/bash app

WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy package.json and install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY --chown=app:app . .

# Precompile assets
RUN RAILS_ENV=production bundle exec rails assets:precompile

USER app

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### Docker Compose
```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp_production
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    volumes:
      - ./log:/app/log
      - ./tmp:/app/tmp

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp_production
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  sidekiq:
    build: .
    command: bundle exec sidekiq
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp_production
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    volumes:
      - ./log:/app/log

volumes:
  postgres_data:
  redis_data:
```

## 📝 Features

### Security
- ✅ Rails security features
- ✅ CSRF protection
- ✅ SQL injection prevention
- ✅ XSS protection
- ✅ Secure headers

### Performance
- ✅ Asset pipeline optimization
- ✅ Database query optimization
- ✅ Caching strategies
- ✅ Background job processing
- ✅ CDN integration

### Development
- ✅ Hot reloading
- ✅ Testing framework integration
- ✅ Code quality tools
- ✅ Database migrations
- ✅ Seed data management

### Monitoring
- ✅ Rails logging
- ✅ Performance monitoring
- ✅ Error tracking
- ✅ Health check endpoints
- ✅ Background job monitoring

## 🛠️ Prerequisites

### System Requirements
- Ruby 3.0+ (3.2+ recommended)
- Bundler gem manager
- Node.js and Yarn (for assets)
- Database system (PostgreSQL, MySQL, etc.)
- Redis server (if using background jobs)

## 📚 Usage Examples

### Example 1: E-commerce Platform
```bash
# Deploy Rails e-commerce to VPS
cd full-stack/vps/ubuntu/
export APP_NAME="ecommerce-platform"
export DB_NAME="ecommerce"
export SIDEKIQ_ENABLED="true"
sudo ./deploy.sh
```

### Example 2: API Backend
```bash
# Deploy Rails API with PostgreSQL
cd api-only/with-postgresql/
export APP_NAME="api-backend"
export DB_NAME="api"
sudo ./deploy.sh
```

### Example 3: SaaS Application
```bash
# Deploy Rails SaaS to AWS
cd full-stack/aws-ec2/
export APP_NAME="saas-app"
export BACKGROUND_JOBS="sidekiq"
sudo ./deploy.sh
```

## 🔍 Troubleshooting

### Common Issues

**Bundle Install Issues**
```bash
# Clear bundle cache
bundle clean --force

# Update bundler
gem update bundler

# Install with verbose output
bundle install --verbose
```

**Asset Compilation Issues**
```bash
# Clear assets
bundle exec rails assets:clobber

# Precompile assets
RAILS_ENV=production bundle exec rails assets:precompile

# Check asset paths
bundle exec rails assets:environment
```

**Database Issues**
```bash
# Check database connection
bundle exec rails db:version

# Reset database
bundle exec rails db:drop db:create db:migrate

# Check migrations
bundle exec rails db:migrate:status
```

### Performance Optimization

**Database Optimization**
```ruby
# Add database indexes
class AddIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :email
    add_index :users, [:active, :created_at]
  end
end
```

**Caching Configuration**
```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
config.action_controller.perform_caching = true
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000'
}
```

## 🔗 Related Documentation

- [Database Scripts](../../../databases/README.md)
- [Caching Scripts](../../../caching/README.md)
- [Cloud Services](../../../cloud-services/README.md)
- [Hosting Platforms](../../../hosting/README.md)