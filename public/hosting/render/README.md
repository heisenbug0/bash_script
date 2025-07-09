# Render Deployment Scripts

Deploy your applications to Render with automated scripts for different frameworks and configurations.

## 📁 Available Scripts

```
render/
├── django/             # Django applications
├── flask/              # Flask applications
├── fastapi/            # FastAPI applications
├── nodejs/             # Node.js applications
├── react/              # React applications
├── nextjs/             # Next.js applications
├── vue/                # Vue.js applications
├── static/             # Static sites
├── docker/             # Docker deployments
└── blueprints/         # Render blueprint templates
```

## 🚀 Quick Start

### Django Application
```bash
cd django/
export PROJECT_NAME="my-django-app"
export DATABASE_TYPE="postgresql"
export REDIS_ENABLED="true"
./deploy.sh
```

### Node.js Application
```bash
cd nodejs/
export APP_NAME="my-node-app"
export DATABASE_TYPE="postgresql"
./deploy.sh
```

### React Application
```bash
cd react/
export PROJECT_NAME="my-react-app"
./deploy.sh
```

## 📋 Prerequisites

- Render account
- Git repository
- Application source code
- Render CLI (automatically installed)

## 🔧 Configuration

### Environment Variables
```bash
# General Configuration
export PROJECT_NAME="my-app"
export RENDER_API_KEY="your-render-api-key"
export REGION="oregon"
export PLAN="starter"

# Database Configuration
export DATABASE_TYPE="postgresql"  # postgresql, mysql, sqlite
export REDIS_ENABLED="true"

# Framework-specific
export PYTHON_VERSION="3.11"      # For Python apps
export NODE_VERSION="18"          # For Node.js apps
export PHP_VERSION="8.1"          # For PHP apps
```

## 📝 Features

### Build Scripts
- ✅ Automatic build script generation
- ✅ Dependency installation
- ✅ Database migrations
- ✅ Static file collection
- ✅ Custom setup commands

### Render Blueprints
- ✅ Infrastructure as Code
- ✅ Multi-service deployments
- ✅ Database and Redis configuration
- ✅ Environment variable management
- ✅ Worker and cron job setup

### Security
- ✅ Environment variable encryption
- ✅ Secret key generation
- ✅ SSL certificate setup
- ✅ CORS configuration
- ✅ Security headers

### Monitoring
- ✅ Health check endpoints
- ✅ Log aggregation
- ✅ Performance monitoring
- ✅ Error tracking
- ✅ Uptime monitoring

## 🛠️ Supported Frameworks

### Python
- **Django**: Full-stack web framework
- **Flask**: Lightweight web framework
- **FastAPI**: Modern API framework
- **Streamlit**: Data science applications

### JavaScript/TypeScript
- **Node.js**: Server-side JavaScript
- **React**: Frontend library
- **Next.js**: Full-stack React framework
- **Vue.js**: Progressive framework
- **Express**: Web framework for Node.js

### Other Languages
- **Go**: Go web applications
- **Rust**: Rust web applications
- **Ruby**: Ruby on Rails applications
- **PHP**: Laravel and other PHP frameworks

## 📚 Blueprint Examples

### Django + PostgreSQL + Redis
```yaml
services:
  - type: web
    name: django-app
    env: python
    buildCommand: "./build.sh"
    startCommand: "gunicorn myproject.wsgi:application"
    envVars:
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

databases:
  - name: django-db
    databaseName: django_app
```

### Node.js + PostgreSQL
```yaml
services:
  - type: web
    name: nodejs-app
    env: node
    buildCommand: "npm install"
    startCommand: "npm start"
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: nodejs-db
          property: connectionString

databases:
  - name: nodejs-db
    databaseName: nodejs_app
```

### React Static Site
```yaml
services:
  - type: static_site
    name: react-app
    buildCommand: "npm run build"
    staticPublishPath: "./build"
    envVars:
      - key: REACT_APP_API_URL
        value: "https://api.example.com"
```

## 🔍 Troubleshooting

### Common Issues

**Build Failures**
```bash
# Check build logs
render logs my-app --type build

# Debug build script
chmod +x build.sh
./build.sh
```

**Environment Variables**
```bash
# List environment variables
render env list my-app

# Set environment variable
render env set my-app KEY=value
```

**Database Connection**
```bash
# Check database status
render services list --type database

# Test database connection
render shell my-app
```

### Performance Optimization

**Build Time**
- Use dependency caching
- Optimize Docker layers
- Minimize build steps

**Runtime Performance**
- Configure appropriate instance size
- Enable Redis caching
- Optimize database queries

## 🔗 Related Documentation

- [Framework Scripts](../../frameworks/README.md)
- [Database Scripts](../../databases/README.md)
- [Cloud Services](../../cloud-services/README.md)