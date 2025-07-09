# Deployment Scripts Collection

Ready-to-use deployment scripts for web applications. Get your projects online quickly without the hassle.

## What's Actually Here

### 🚀 Frameworks
- **Node.js + PostgreSQL** - Complete backend with database
- **React** - Static site deployment with Nginx
- **Python** - Coming soon (Django, Flask, FastAPI)

### 🏠 Hosting Platforms  
- **Netlify** - Static sites and JAMstack apps
- **Vercel** - React and frontend applications

### 📚 Full Stacks
- **MERN** - MongoDB + Express + React + Node.js

### 🛠️ Utilities
- **Common functions** - OS detection, package management
- **Logging** - Clean, readable output
- **Validation** - Input checking and system requirements
- **Security** - Basic server hardening

## Quick Start

1. **Pick what you want to deploy**:
   ```bash
   # Node.js API with database
   cd frameworks/nodejs/with-postgresql/
   
   # React app to Vercel
   cd hosting/vercel/
   
   # Full MERN stack
   cd stacks/mern/
   ```

2. **Set your preferences**:
   ```bash
   export APP_NAME="my-awesome-app"
   export DOMAIN="myapp.com"  # optional
   ```

3. **Deploy**:
   ```bash
   sudo ./deploy.sh
   ```

## What Actually Works

### Node.js + PostgreSQL ✅
```bash
cd frameworks/nodejs/with-postgresql/
export APP_NAME="my-api"
export DB_NAME="myapp"
sudo ./deploy.sh
```
**Gets you**: Node.js + PostgreSQL + PM2 + Nginx + SSL

### React Static Site ✅
```bash
cd frameworks/react/
export APP_NAME="my-react-app"
sudo ./deploy.sh
```
**Gets you**: Built React app + Nginx + SSL + Caching

### MERN Stack ✅
```bash
cd stacks/mern/
export STACK_NAME="my-mern-app"
sudo ./deploy.sh
```
**Gets you**: MongoDB + Express + React + Node.js + Nginx + SSL

### Netlify Deployment ✅
```bash
cd hosting/netlify/
export SITE_NAME="my-site"
./deploy.sh
```
**Gets you**: Static site on Netlify with SSL

### Vercel Deployment ✅
```bash
cd hosting/vercel/
export PROJECT_NAME="my-react-app"
./deploy.sh
```
**Gets you**: React app on Vercel with SSL

## What's Coming Soon

- **Django deployment** with PostgreSQL
- **Flask API** deployment
- **FastAPI** deployment
- **MEAN stack** (MongoDB + Express + Angular + Node.js)
- **LAMP stack** (Linux + Apache + MySQL + PHP)

## Requirements

Scripts work on:
- **Ubuntu** 18.04+ (recommended)
- **Debian** 9+
- **CentOS** 7+

You need:
- Root access (or sudo)
- Internet connection
- Your application code

## What Gets Set Up

Every deployment includes:
- ✅ **Web server** (Nginx)
- ✅ **SSL certificate** (free, auto-renewing)
- ✅ **Firewall** (basic security rules)
- ✅ **Process management** (keeps your app running)
- ✅ **Basic monitoring** (health checks)

## Environment Variables

Common settings across scripts:

```bash
export APP_NAME="my-app"           # Your app name
export DOMAIN="example.com"        # Your domain (optional)
export PORT="3000"                 # App port
export DB_NAME="myapp"             # Database name
export NODE_VERSION="18"           # Node.js version
```

## After Deployment

Your app will be accessible at:
- `https://yourdomain.com` (if you set DOMAIN)
- `http://your-server-ip` (always works)

### Managing Your App
```bash
# Node.js apps
pm2 status
pm2 logs myapp
pm2 restart myapp

# Database access
psql -h localhost -U dbuser -d dbname
```

## Getting Help

1. **Check the README** in the specific folder you're using
2. **Look at the examples** - common setups are covered
3. **Check logs** if something goes wrong
4. **Start simple** - try basic deployment first

## Contributing

We need help with:
- More framework support (Django, Flask, FastAPI)
- Better error handling
- More hosting platform integrations
- Testing on different OS versions

## License

MIT License - use these scripts however you want.

---

**Ready to deploy?** Pick a folder and follow the README inside. Most deployments take 5-10 minutes.