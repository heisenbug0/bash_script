# Deployment Scripts Collection

Ready-to-use deployment scripts for web applications, databases, and hosting platforms. Get your projects online quickly without the hassle.

## What's Inside

### 🚀 Frameworks
Deploy popular web frameworks with one command:
- **Node.js** (Express, APIs, full-stack apps)
- **Python** (Django, Flask, FastAPI)
- **React** (Create React App, Vite, static builds)
- **And more coming soon...**

### 🏠 Hosting Platforms  
Deploy to popular hosting services:
- **Netlify** (static sites, JAMstack)
- **Vercel** (Next.js, React, frontend apps)
- **Render** (full-stack apps with databases)

### ☁️ Cloud Services
Deploy to major cloud providers:
- **AWS** (EC2, Lambda, RDS)
- **Google Cloud** (Compute Engine, Cloud Run)
- **Azure** (Virtual Machines, App Service)

### 🗄️ Databases
Set up databases quickly:
- **PostgreSQL** (most popular choice)
- **MySQL** (classic web database)
- **MongoDB** (NoSQL document database)
- **Redis** (caching and sessions)

### 📚 Full Stacks
Complete application stacks:
- **MERN** (MongoDB + Express + React + Node.js)
- **MEAN** (MongoDB + Express + Angular + Node.js)
- **LAMP** (Linux + Apache + MySQL + PHP)
- **JAMstack** (JavaScript + APIs + Markup)

## Quick Start

1. **Pick your deployment type**:
   ```bash
   # Node.js app with database
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

That's it! Your app will be live with SSL, monitoring, and automatic restarts.

## What Makes This Different

- **Actually works** - Scripts are tested on real servers
- **Human-friendly** - Clear instructions, no technical jargon
- **Complete setup** - Includes SSL, security, monitoring
- **One command** - No complex configuration files
- **Production ready** - Not just development setups

## Examples

### AWS Lambda Function
```bash
cd cloud-services/aws/lambda/
export FUNCTION_NAME="my-api"
export API_GATEWAY="true"
./deploy.sh
```
Gets you: Serverless function with API endpoint, IAM role, and CloudWatch logs

### Simple Node.js API
```bash
cd frameworks/nodejs/
export APP_NAME="my-api"
export PORT="3000"
sudo ./deploy.sh
```
Gets you: Node.js + PM2 + Nginx + SSL + Firewall

### Django Website  
```bash
cd frameworks/python/django/
export APP_NAME="my-site"
export DOMAIN="mysite.com"
sudo ./deploy.sh
```
Gets you: Django + PostgreSQL + Gunicorn + Nginx + SSL

### React App
```bash
cd frameworks/react/
export APP_NAME="my-react-app"
export DOMAIN="myapp.com"
sudo ./deploy.sh
```
Gets you: Built React app + Nginx + SSL + Caching

## Requirements

Most scripts work on:
- **Ubuntu** 18.04+ (recommended)
- **Debian** 9+
- **CentOS** 7+

You need:
- Root access (or sudo)
- Internet connection
- Your application code

## What Gets Set Up

Every deployment includes:
- ✅ **Web server** (Nginx or Apache)
- ✅ **SSL certificate** (free, auto-renewing)
- ✅ **Firewall** (basic security rules)
- ✅ **Process management** (keeps your app running)
- ✅ **Monitoring** (basic health checks)
- ✅ **Backups** (for databases)

## Environment Variables

Most scripts use these common settings:

```bash
export APP_NAME="my-app"           # Your app name
export DOMAIN="example.com"        # Your domain (optional)
export PORT="3000"                 # App port
export DB_NAME="myapp"             # Database name
export NODE_VERSION="18"           # Node.js version
export PYTHON_VERSION="3.11"      # Python version
```

## After Deployment

Your app will be accessible at:
- `https://yourdomain.com` (if you set DOMAIN)
- `http://your-server-ip` (always works)

### Managing Your App
```bash
# Check if running
pm2 status              # Node.js apps
systemctl status myapp  # Python apps

# View logs  
pm2 logs myapp          # Node.js apps
journalctl -u myapp -f  # Python apps

# Restart
pm2 restart myapp       # Node.js apps
systemctl restart myapp # Python apps
```

## Getting Help

1. **Check the README** in the specific folder you're using
2. **Look at the examples** - most common setups are covered
3. **Check logs** if something goes wrong
4. **Start simple** - try basic deployment first, add features later

## Contributing

Found a bug? Want to add a new framework? 

1. Fork the repository
2. Test your changes on a clean server
3. Update documentation
4. Submit a pull request

We especially need:
- More framework support (Ruby, Go, Rust, PHP)
- More hosting platform integrations
- Windows deployment scripts
- Better error handling

## License

MIT License - use these scripts however you want.

---

**Ready to deploy?** Pick a folder and follow the README inside. Most deployments take 5-10 minutes.

**Questions?** Each folder has detailed instructions and troubleshooting guides.