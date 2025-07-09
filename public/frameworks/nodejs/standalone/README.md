# Standalone Node.js Deployment Scripts

Deploy Node.js applications that don't require external databases or caching systems.

## 📁 Available Deployments

```
standalone/
├── vps/
│   ├── ubuntu/         # Ubuntu VPS deployment
│   ├── debian/         # Debian VPS deployment
│   ├── centos/         # CentOS VPS deployment
│   └── generic/        # Generic Linux deployment
├── cloud/
│   ├── aws-ec2/        # AWS EC2 deployment
│   ├── gcp-compute/    # Google Cloud Compute
│   ├── azure-vm/       # Azure Virtual Machine
│   └── digitalocean/   # DigitalOcean Droplet
├── hosting/
│   ├── render/         # Render web service
│   ├── railway/        # Railway deployment
│   ├── heroku/         # Heroku deployment
│   └── fly-io/         # Fly.io deployment
└── containers/
    ├── docker/         # Docker deployment
    └── kubernetes/     # Kubernetes deployment
```

## 🎯 Use Cases

### API Servers
- REST APIs
- GraphQL servers
- Webhook handlers
- Microservices
- Authentication services

### Utility Services
- File processing services
- Image manipulation APIs
- Email services
- Notification services
- Proxy servers

### Static File Servers
- Asset servers
- Documentation sites
- File download services
- Media streaming

## 🚀 Quick Start

### VPS Deployment
```bash
# Ubuntu VPS
cd vps/ubuntu/
export APP_NAME="my-api"
export DOMAIN="api.example.com"
sudo ./deploy.sh

# Generic Linux
cd vps/generic/
export NODE_VERSION="18"
export PORT="3000"
sudo ./deploy.sh
```

### Cloud Deployment
```bash
# AWS EC2
cd cloud/aws-ec2/
export INSTANCE_TYPE="t3.micro"
export KEY_PAIR="my-keypair"
./deploy.sh

# Google Cloud
cd cloud/gcp-compute/
export MACHINE_TYPE="e2-micro"
export ZONE="us-central1-a"
./deploy.sh
```

### Hosting Platform
```bash
# Render
cd hosting/render/
export SERVICE_NAME="my-node-service"
./deploy.sh

# Railway
cd hosting/railway/
export PROJECT_NAME="my-api"
./deploy.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Application
export APP_NAME="my-node-app"
export NODE_VERSION="18"
export PORT="3000"
export NODE_ENV="production"

# Domain & SSL
export DOMAIN="example.com"
export SSL_EMAIL="admin@example.com"

# Process Management
export PM2_INSTANCES="max"
export PM2_MAX_MEMORY="500M"

# Monitoring
export ENABLE_MONITORING="true"
export LOG_LEVEL="info"
```

### Supported Frameworks
- **Express.js**: Fast, unopinionated web framework
- **Fastify**: Fast and low overhead web framework
- **Koa.js**: Next generation web framework
- **Hapi.js**: Rich framework for building applications
- **NestJS**: Progressive Node.js framework
- **Custom**: Any Node.js application

## 📝 Features

### Automatic Setup
- ✅ Node.js installation via NVM
- ✅ PM2 process manager setup
- ✅ Nginx reverse proxy configuration
- ✅ SSL certificate with Let's Encrypt
- ✅ Firewall configuration
- ✅ Log rotation setup

### Security
- ✅ Non-root user creation
- ✅ SSH key authentication
- ✅ Firewall rules
- ✅ SSL/TLS encryption
- ✅ Security headers

### Performance
- ✅ Nginx caching
- ✅ Gzip compression
- ✅ Static file serving
- ✅ Process clustering
- ✅ Memory management

### Monitoring
- ✅ PM2 monitoring
- ✅ Log aggregation
- ✅ Health checks
- ✅ Performance metrics
- ✅ Error tracking

## 🛠️ Prerequisites

### System Requirements
- Linux server (Ubuntu 18.04+, Debian 9+, CentOS 7+)
- Minimum 512MB RAM (1GB+ recommended)
- Root or sudo access
- Internet connection

### Application Requirements
- `package.json` file
- Start script defined
- Port configuration via environment variable
- Health check endpoint (recommended)

## 📚 Examples

### Express.js API
```javascript
// app.js
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/users', (req, res) => {
  res.json({ users: [] });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Fastify API
```javascript
// server.js
const fastify = require('fastify')({ logger: true });
const PORT = process.env.PORT || 3000;

fastify.get('/health', async (request, reply) => {
  return { status: 'healthy', timestamp: new Date().toISOString() };
});

fastify.get('/api/data', async (request, reply) => {
  return { data: 'Hello World' };
});

const start = async () => {
  try {
    await fastify.listen(PORT, '0.0.0.0');
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};
start();
```

## 🔍 Troubleshooting

### Common Issues

**Application Won't Start**
```bash
# Check PM2 status
pm2 status
pm2 logs

# Check application logs
tail -f /var/log/myapp/error.log
```

**Port Issues**
```bash
# Check if port is in use
sudo netstat -tulpn | grep :3000
sudo lsof -i :3000
```

**SSL Certificate Issues**
```bash
# Check certificate status
sudo certbot certificates
sudo nginx -t
sudo systemctl reload nginx
```

### Performance Optimization

**Memory Usage**
```bash
# Monitor memory usage
pm2 monit
htop

# Adjust PM2 memory limit
pm2 start app.js --max-memory-restart 500M
```

**CPU Usage**
```bash
# Check CPU usage
top
pm2 monit

# Adjust PM2 instances
pm2 scale app 4
```