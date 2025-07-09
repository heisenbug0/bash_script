# Railway Deployment Scripts

Deploy your applications to Railway with automated scripts for different frameworks and configurations.

## 📁 Available Scripts

```
railway/
├── nodejs/             # Node.js applications
├── python/             # Python applications (Django, Flask, FastAPI)
├── go/                 # Go applications
├── rust/               # Rust applications
├── php/                # PHP applications (Laravel, Symfony)
├── ruby/               # Ruby applications (Rails, Sinatra)
├── java/               # Java applications (Spring Boot)
├── dotnet/             # .NET applications
├── static/             # Static sites
└── databases/          # Database deployments
```

## 🚀 Quick Start

### Node.js Application
```bash
cd nodejs/
export PROJECT_NAME="my-node-app"
export DATABASE_TYPE="postgresql"
./deploy.sh
```

### Python Django Application
```bash
cd python/django/
export PROJECT_NAME="my-django-app"
export PYTHON_VERSION="3.11"
./deploy.sh
```

### Go Application
```bash
cd go/
export PROJECT_NAME="my-go-app"
export GO_VERSION="1.21"
./deploy.sh
```

## 📋 Prerequisites

- Railway account
- Git repository
- Railway CLI (automatically installed)
- Application source code

## 🔧 Configuration

### Environment Variables
```bash
# General Configuration
export PROJECT_NAME="my-app"
export RAILWAY_TOKEN="your-railway-token"
export ENVIRONMENT="production"

# Database Configuration
export DATABASE_TYPE="postgresql"  # postgresql, mysql, mongodb, redis
export DATABASE_NAME="myapp"

# Framework-specific
export NODE_VERSION="18"          # For Node.js apps
export PYTHON_VERSION="3.11"      # For Python apps
export GO_VERSION="1.21"          # For Go apps
export RUST_VERSION="1.75"        # For Rust apps
```

## 📝 Features

### Build Configuration
- ✅ Automatic buildpack detection
- ✅ Custom build commands
- ✅ Environment variable management
- ✅ Dependency caching
- ✅ Multi-stage builds

### Database Integration
- ✅ PostgreSQL databases
- ✅ MySQL databases
- ✅ MongoDB databases
- ✅ Redis instances
- ✅ Automatic connection strings

### Deployment Features
- ✅ Git-based deployments
- ✅ Automatic SSL certificates
- ✅ Custom domains
- ✅ Environment management
- ✅ Rollback capabilities

### Monitoring
- ✅ Application logs
- ✅ Metrics dashboard
- ✅ Health checks
- ✅ Performance monitoring
- ✅ Error tracking

## 🛠️ Supported Frameworks

### JavaScript/TypeScript
- **Node.js**: Express, Fastify, Koa
- **React**: Create React App, Next.js, Vite
- **Vue.js**: Vue CLI, Nuxt.js, Vite
- **Angular**: Angular CLI applications

### Python
- **Django**: Full-stack web framework
- **Flask**: Lightweight web framework
- **FastAPI**: Modern API framework
- **Streamlit**: Data science applications

### Other Languages
- **Go**: Gin, Echo, Fiber frameworks
- **Rust**: Actix, Warp, Rocket frameworks
- **PHP**: Laravel, Symfony, CodeIgniter
- **Ruby**: Ruby on Rails, Sinatra
- **Java**: Spring Boot, Quarkus
- **.NET**: ASP.NET Core applications

## 📚 Configuration Examples

### railway.toml
```toml
[build]
builder = "NIXPACKS"
buildCommand = "npm run build"

[deploy]
startCommand = "npm start"
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10

[environments.production]
variables = { NODE_ENV = "production" }

[environments.staging]
variables = { NODE_ENV = "staging" }
```

### Build Scripts
```bash
#!/usr/bin/env bash
# railway-build.sh
set -e

echo "🚂 Starting Railway build..."

# Install dependencies
npm ci

# Build application
npm run build

# Run tests
npm test

echo "✅ Railway build completed!"
```

### Environment Variables
```bash
# Set via Railway CLI
railway variables set NODE_ENV=production
railway variables set DATABASE_URL=$DATABASE_URL
railway variables set REDIS_URL=$REDIS_URL

# Set via railway.toml
[environments.production.variables]
NODE_ENV = "production"
LOG_LEVEL = "info"
```

## 📦 Database Configuration

### PostgreSQL
```bash
# Create PostgreSQL database
railway add postgresql

# Get connection string
railway variables get DATABASE_URL
```

### Redis
```bash
# Create Redis instance
railway add redis

# Get connection string
railway variables get REDIS_URL
```

### MongoDB
```bash
# Create MongoDB database
railway add mongodb

# Get connection string
railway variables get MONGO_URL
```

## 🔍 Troubleshooting

### Common Issues

**Build Failures**
```bash
# Check build logs
railway logs --deployment

# Debug build locally
railway run npm run build
```

**Environment Variables**
```bash
# List all variables
railway variables

# Set variable
railway variables set KEY=value

# Delete variable
railway variables delete KEY
```

**Database Connection**
```bash
# Test database connection
railway connect postgresql

# Check database status
railway status
```

### Performance Optimization

**Build Performance**
- Use dependency caching
- Optimize Docker layers
- Minimize build steps
- Use multi-stage builds

**Runtime Performance**
- Configure appropriate resources
- Enable Redis caching
- Optimize database queries
- Use CDN for static assets

## 🔗 Related Documentation

- [Framework Scripts](../../frameworks/README.md)
- [Database Scripts](../../databases/README.md)
- [Cloud Services](../../cloud-services/README.md)