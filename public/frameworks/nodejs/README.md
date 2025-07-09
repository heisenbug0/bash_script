# Node.js Deployment Scripts

Comprehensive deployment scripts for Node.js applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
nodejs/
├── standalone/          # Node.js apps without external dependencies
├── with-postgresql/     # Node.js + PostgreSQL combinations
├── with-mysql/         # Node.js + MySQL combinations
├── with-mongodb/       # Node.js + MongoDB combinations
├── with-redis/         # Node.js + Redis combinations
├── full-stack/         # Complete stacks (DB + Cache + Monitoring)
├── microservices/      # Microservices deployments
├── serverless/         # Serverless Node.js deployments
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- API servers without persistent data
- Utility services
- Webhook handlers
- Static file servers
- Development environments

### Database Integrations
- **PostgreSQL**: Relational data with ACID compliance
- **MySQL**: Traditional relational database
- **MongoDB**: Document-based NoSQL database
- **SQLite**: Lightweight embedded database

### Caching Solutions
- **Redis**: In-memory data structure store
- **Memcached**: Distributed memory caching
- **Application-level**: In-process caching

### Full-Stack Combinations
- **PERN**: PostgreSQL + Express + React + Node.js
- **MEAN**: MongoDB + Express + Angular + Node.js
- **MERN**: MongoDB + Express + React + Node.js
- **Custom**: Any combination of databases and caching

## 🚀 Quick Start Examples

### Deploy Standalone Node.js App to VPS
```bash
cd standalone/vps/
export APP_NAME="my-api"
export DOMAIN="api.example.com"
sudo ./deploy.sh
```

### Deploy Node.js + PostgreSQL to AWS EC2
```bash
cd with-postgresql/aws-ec2/
export DB_NAME="myapp"
export DB_USER="appuser"
sudo ./deploy.sh
```

### Deploy MERN Stack to DigitalOcean
```bash
cd full-stack/mern/digitalocean/
export MONGO_DB="myapp"
export REACT_BUILD_DIR="client/build"
sudo ./deploy.sh
```

## 📋 Platform Support

### VPS Providers
- **Generic VPS**: Ubuntu, Debian, CentOS, RHEL
- **DigitalOcean Droplets**: Optimized for DO
- **Linode**: Linode-specific optimizations
- **Vultr**: Vultr-specific configurations

### Cloud Platforms
- **AWS**: EC2, ECS, Lambda, Elastic Beanstalk
- **Google Cloud**: Compute Engine, Cloud Run, App Engine
- **Azure**: Virtual Machines, Container Instances, App Service
- **Oracle Cloud**: Compute instances

### Hosting Platforms
- **Render**: Web services and databases
- **Railway**: Full-stack deployments
- **Heroku**: Container-based deployments
- **Fly.io**: Global application deployment

## 🔧 Configuration Options

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-node-app"
export NODE_VERSION="18"
export PORT="3000"
export NODE_ENV="production"

# Database Configuration (if applicable)
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
export DB_USER="appuser"
export DB_PASSWORD="securepassword"

# Redis Configuration (if applicable)
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""

# SSL Configuration
export DOMAIN="example.com"
export SSL_EMAIL="admin@example.com"

# Monitoring
export ENABLE_MONITORING="true"
export LOG_LEVEL="info"
```

### Package Manager Support
- **npm**: Default package manager
- **yarn**: Yarn package manager
- **pnpm**: Fast, disk space efficient package manager

### Process Management
- **PM2**: Production process manager
- **systemd**: System service management
- **Docker**: Containerized deployments
- **Kubernetes**: Orchestrated deployments

## 📝 Features

### Security
- ✅ Firewall configuration
- ✅ SSL/TLS certificate setup
- ✅ User permission management
- ✅ Environment variable security
- ✅ Database security hardening

### Performance
- ✅ Node.js optimization
- ✅ Database connection pooling
- ✅ Caching strategies
- ✅ Load balancing setup
- ✅ CDN configuration

### Monitoring
- ✅ Application monitoring
- ✅ Database monitoring
- ✅ Log aggregation
- ✅ Performance metrics
- ✅ Error tracking

### Backup & Recovery
- ✅ Database backups
- ✅ Application backups
- ✅ Automated backup scheduling
- ✅ Disaster recovery procedures

## 🛠️ Prerequisites

### System Requirements
- Linux-based operating system (Ubuntu 18.04+, Debian 9+, CentOS 7+)
- Root or sudo access
- Internet connection
- Minimum 1GB RAM (2GB+ recommended)

### Software Dependencies
- Git (automatically installed)
- Node.js (automatically installed via NVM)
- Process manager (PM2, automatically installed)
- Database software (if required, automatically installed)

## 📚 Usage Examples

### Example 1: Simple Express API
```bash
# Deploy a standalone Express API to Ubuntu VPS
cd standalone/vps/ubuntu/
export APP_NAME="express-api"
export PORT="3000"
export DOMAIN="api.mysite.com"
sudo ./deploy.sh
```

### Example 2: E-commerce Backend
```bash
# Deploy Node.js + PostgreSQL + Redis for e-commerce
cd full-stack/ecommerce/
export APP_NAME="ecommerce-api"
export DB_NAME="ecommerce"
export REDIS_CACHE="true"
sudo ./deploy.sh
```

### Example 3: Microservices
```bash
# Deploy multiple Node.js services
cd microservices/docker-compose/
export SERVICES="auth,products,orders,notifications"
sudo ./deploy.sh
```

## 🔍 Troubleshooting

### Common Issues

**Port Already in Use**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :3000
# Kill the process if needed
sudo kill -9 <PID>
```

**Database Connection Issues**
```bash
# Check database status
sudo systemctl status postgresql
# Check connection
psql -h localhost -U appuser -d myapp
```

**SSL Certificate Issues**
```bash
# Check certificate status
sudo certbot certificates
# Renew certificate
sudo certbot renew
```

### Log Locations
- Application logs: `/var/log/myapp/`
- PM2 logs: `~/.pm2/logs/`
- Database logs: `/var/log/postgresql/` (PostgreSQL)
- Nginx logs: `/var/log/nginx/`

## 🔗 Related Documentation

- [Database Scripts](../../databases/README.md)
- [Caching Scripts](../../caching/README.md)
- [Cloud Services](../../cloud-services/README.md)
- [Hosting Platforms](../../hosting/README.md)