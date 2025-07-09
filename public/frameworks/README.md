# Framework Deployment Scripts

Deploy popular web frameworks quickly and easily.

## What's Available

### Node.js
Deploy Node.js applications with PostgreSQL database.
- **With PostgreSQL** - Complete Node.js + database setup
- **Production ready** - PM2, Nginx, SSL included

### Python  
Deploy Django applications (coming soon).
- **Django setup** - In development
- **Database included** - PostgreSQL integration

### React
Deploy React applications as static sites.
- **Static hosting** - Built and served by Nginx
- **SSL included** - Free certificates with domain

## Quick Examples

### Node.js + PostgreSQL
```bash
cd nodejs/with-postgresql/
export APP_NAME="my-api"
export DB_NAME="myapp"
export DOMAIN="myapi.com"
sudo ./deploy.sh
```

### React Static Site
```bash
cd react/
export APP_NAME="my-react-app"
export DOMAIN="myapp.com"
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

Each framework folder has detailed instructions.