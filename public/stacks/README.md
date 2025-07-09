# Full-Stack Deployment Scripts

Complete deployment solutions for popular technology stacks and combinations.

## 📁 Directory Structure

```
stacks/
├── mean/               # MongoDB, Express, Angular, Node.js
├── mern/               # MongoDB, Express, React, Node.js
├── mevn/               # MongoDB, Express, Vue.js, Node.js
├── lamp/               # Linux, Apache, MySQL, PHP
├── lemp/               # Linux, Nginx, MySQL, PHP
├── pern/               # PostgreSQL, Express, React, Node.js
├── django-react/       # Django backend, React frontend
├── rails-react/        # Ruby on Rails backend, React frontend
├── laravel-vue/        # Laravel backend, Vue.js frontend
├── spring-angular/     # Spring Boot backend, Angular frontend
├── dotnet-react/       # .NET Core backend, React frontend
├── jamstack/           # JAMstack deployments
├── microservices/      # Microservices architectures
└── serverless/         # Serverless full-stack applications
```

## 🎯 Stack Categories

### JavaScript Full-Stack
- **MEAN**: MongoDB + Express + Angular + Node.js
- **MERN**: MongoDB + Express + React + Node.js
- **MEVN**: MongoDB + Express + Vue.js + Node.js
- **PERN**: PostgreSQL + Express + React + Node.js

### Traditional Web Stacks
- **LAMP**: Linux + Apache + MySQL + PHP
- **LEMP**: Linux + Nginx + MySQL + PHP

### Modern Full-Stack
- **Django + React**: Python backend with React frontend
- **Rails + React**: Ruby backend with React frontend
- **Laravel + Vue**: PHP backend with Vue.js frontend
- **Spring + Angular**: Java backend with Angular frontend

### Cloud-Native Stacks
- **JAMstack**: JavaScript + APIs + Markup
- **Serverless**: Function-based architectures
- **Microservices**: Distributed service architectures

## 🚀 Quick Start Examples

### Deploy MERN Stack
```bash
cd mern/
export STACK_NAME="my-mern-app"
export MONGO_DB="myapp"
export DOMAIN="myapp.com"
sudo ./deploy.sh
```

### Deploy LAMP Stack
```bash
cd lamp/
export APP_NAME="my-website"
export MYSQL_DB="website_db"
export DOMAIN="website.com"
sudo ./deploy.sh
```

### Deploy Django + React
```bash
cd django-react/
export PROJECT_NAME="my-project"
export DB_ENGINE="postgresql"
export FRONTEND_BUILD_DIR="frontend/build"
sudo ./deploy.sh
```

### Deploy JAMstack
```bash
cd jamstack/
export SITE_NAME="my-jamstack-site"
export API_PROVIDER="netlify-functions"
export CMS="strapi"
./deploy.sh
```

## 📋 Platform Support

### VPS Deployments
- **Ubuntu**: 18.04, 20.04, 22.04
- **Debian**: 9, 10, 11
- **CentOS**: 7, 8
- **RHEL**: 7, 8, 9

### Cloud Platforms
- **AWS**: EC2, ECS, Lambda, Amplify
- **Google Cloud**: Compute Engine, Cloud Run, App Engine
- **Azure**: Virtual Machines, Container Instances, App Service
- **DigitalOcean**: Droplets, App Platform

### Hosting Platforms
- **Vercel**: JAMstack and serverless
- **Netlify**: Static sites and serverless functions
- **Render**: Full-stack applications
- **Railway**: Database-backed applications

## 🔧 Configuration Examples

### MERN Stack Configuration
```bash
# Application Configuration
export STACK_NAME="my-mern-app"
export NODE_VERSION="18"
export REACT_BUILD_DIR="client/build"

# Database Configuration
export MONGO_DB="myapp"
export MONGO_USER="appuser"
export MONGO_PASSWORD="securepassword"

# Server Configuration
export API_PORT="5000"
export CLIENT_PORT="3000"
export DOMAIN="myapp.com"

# SSL Configuration
export SSL_EMAIL="admin@myapp.com"
export FORCE_HTTPS="true"
```

### LAMP Stack Configuration
```bash
# Application Configuration
export APP_NAME="my-website"
export PHP_VERSION="8.1"
export DOCUMENT_ROOT="/var/www/html"

# Database Configuration
export MYSQL_VERSION="8.0"
export MYSQL_DB="website_db"
export MYSQL_USER="webuser"
export MYSQL_PASSWORD="securepassword"

# Web Server Configuration
export APACHE_VERSION="2.4"
export DOMAIN="website.com"
export SSL_EMAIL="admin@website.com"
```

### Django + React Configuration
```bash
# Backend Configuration
export DJANGO_PROJECT="myproject"
export PYTHON_VERSION="3.11"
export DJANGO_SETTINGS="production"

# Frontend Configuration
export REACT_APP_DIR="frontend"
export REACT_BUILD_DIR="frontend/build"
export NODE_VERSION="18"

# Database Configuration
export DB_ENGINE="postgresql"
export DB_NAME="myproject"
export DB_USER="projectuser"
export DB_PASSWORD="securepassword"
```

## 📝 Stack-Specific Features

### MERN/MEAN/MEVN Stacks
- ✅ MongoDB setup and configuration
- ✅ Express.js API server
- ✅ Frontend framework setup (React/Angular/Vue)
- ✅ Node.js environment configuration
- ✅ JWT authentication setup
- ✅ API proxy configuration
- ✅ Build process automation

### LAMP/LEMP Stacks
- ✅ Web server configuration (Apache/Nginx)
- ✅ PHP installation and optimization
- ✅ MySQL database setup
- ✅ Virtual host configuration
- ✅ SSL certificate setup
- ✅ PHP-FPM optimization
- ✅ Caching configuration

### Modern Full-Stack
- ✅ Backend API setup
- ✅ Frontend build and deployment
- ✅ Database integration
- ✅ Authentication systems
- ✅ API documentation
- ✅ Testing setup
- ✅ CI/CD pipeline configuration

### JAMstack
- ✅ Static site generation
- ✅ Serverless function deployment
- ✅ CDN configuration
- ✅ CMS integration
- ✅ Form handling
- ✅ Authentication providers
- ✅ Performance optimization

## 🛠️ Development Workflow

### Local Development
```bash
# Start development environment
./dev-setup.sh

# Run all services
./dev-start.sh

# Stop all services
./dev-stop.sh
```

### Staging Deployment
```bash
# Deploy to staging
export ENVIRONMENT="staging"
./deploy.sh
```

### Production Deployment
```bash
# Deploy to production
export ENVIRONMENT="production"
./deploy.sh
```

## 📚 Architecture Examples

### MERN Stack Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Client  │───▶│  Express API    │───▶│   MongoDB       │
│   (Frontend)    │    │  (Backend)      │    │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Microservices Architecture
```
┌─────────────────┐    ┌─────────────────┐
│   Frontend      │───▶│  API Gateway    │
│   (React/Vue)   │    │  (Nginx/Kong)   │
└─────────────────┘    └─────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
        ┌───────▼──────┐ ┌──────▼──────┐ ┌─────▼──────┐
        │ Auth Service │ │ User Service│ │ Data Service│
        │ (Node.js)    │ │ (Python)    │ │ (Go)        │
        └──────────────┘ └─────────────┘ └────────────┘
```

### JAMstack Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Static Site   │───▶│      CDN        │───▶│  Serverless     │
│   (Generated)   │    │   (CloudFront)  │    │  Functions      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                               ┌───────▼──────┐
                                               │   Database   │
                                               │  (DynamoDB)  │
                                               └──────────────┘
```

## 🔍 Monitoring and Maintenance

### Health Checks
- Application health endpoints
- Database connectivity checks
- Service dependency monitoring
- Performance metrics collection

### Logging
- Centralized log aggregation
- Error tracking and alerting
- Performance monitoring
- Security audit logs

### Backup Strategies
- Database backups
- Application code backups
- Configuration backups
- Disaster recovery procedures

## 🔒 Security Considerations

### Authentication & Authorization
- JWT token management
- OAuth integration
- Role-based access control
- Session management

### Data Protection
- Database encryption
- API security
- Input validation
- XSS/CSRF protection

### Infrastructure Security
- Firewall configuration
- SSL/TLS certificates
- Network segmentation
- Security updates

## 🔗 Related Documentation

- [Framework Scripts](../frameworks/README.md)
- [Database Scripts](../databases/README.md)
- [Cloud Services](../cloud-services/README.md)
- [Hosting Platforms](../hosting/README.md)