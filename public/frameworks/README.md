# Framework Deployment Scripts

Deploy popular web frameworks quickly and easily.

## Available Frameworks

### Node.js
Deploy Node.js applications with or without databases.
- **Standalone apps** - Just Node.js, no database
- **With PostgreSQL** - Full-stack Node.js + database
- **Express APIs** - RESTful API servers
- **Real-time apps** - WebSocket and Socket.io support

### Python
Deploy Python web applications.
- **Django** - Full-featured web framework with admin
- **Database integration** - PostgreSQL setup included
- **Static files** - Automatic handling and serving
- **Production ready** - Gunicorn + Nginx setup

### React
Deploy React applications as static sites.
- **Create React App** - Standard React builds
- **Vite projects** - Modern build tool support
- **Static hosting** - Nginx with proper routing
- **API integration** - Connect to backend APIs

## Quick Examples

### Node.js API
```bash
cd nodejs/
export APP_NAME="my-api"
export PORT="3000"
sudo ./deploy.sh
```

### Django Website
```bash
cd python/django/
export APP_NAME="my-site"
export DOMAIN="mysite.com"
sudo ./deploy.sh
```

### React App
```bash
cd react/
export APP_NAME="my-react-app"
sudo ./deploy.sh
```

## What You Get

Every deployment includes:
- Web server (Nginx)
- SSL certificate (if domain provided)
- Process management (PM2 or systemd)
- Basic security (firewall rules)
- Automatic restarts
- Log management

## Requirements

- Linux server (Ubuntu/Debian/CentOS)
- Root access
- Your application code
- Internet connection

Each framework folder has detailed instructions and examples.