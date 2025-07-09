# Node.js Deployment Scripts

Deploy Node.js applications quickly and easily across different platforms and configurations.

## What's Available

### Basic Deployments
- **Standalone apps** - Just Node.js, no database needed
- **With PostgreSQL** - Node.js + PostgreSQL database
- **With MongoDB** - Node.js + MongoDB database  
- **With Redis** - Node.js + Redis caching

### Where You Can Deploy
- **VPS servers** (Ubuntu, Debian, CentOS)
- **Cloud platforms** (AWS, Google Cloud, Azure)
- **Hosting services** (Render, Railway, Heroku)

## Quick Start

### Simple Node.js App
```bash
# Just copy your app files here and run:
export APP_NAME="my-app"
export PORT="3000"
sudo ./deploy.sh
```

### Node.js + Database
```bash
# For apps that need a database:
cd with-postgresql/
export APP_NAME="my-app"
export DB_NAME="myapp_db"
sudo ./deploy.sh
```

### Custom Domain
```bash
# Add a domain and get free SSL:
export DOMAIN="myapp.com"
export APP_NAME="my-app"
sudo ./deploy.sh
```

## What You Need

Your Node.js project should have:
- `package.json` file
- A start script defined
- Main app file (usually `app.js` or `server.js`)

## What Gets Set Up

- Node.js (latest LTS version)
- PM2 process manager (keeps your app running)
- Nginx reverse proxy (handles web traffic)
- SSL certificate (if you provide a domain)
- Firewall rules (basic security)
- Automatic restarts (if your app crashes)

## Environment Variables

Set these before running the deployment:

```bash
export APP_NAME="my-awesome-app"    # Your app name
export NODE_VERSION="18"           # Node.js version (default: 18)
export PORT="3000"                 # Port your app runs on
export DOMAIN="example.com"        # Your domain (optional)
export DB_NAME="myapp"             # Database name (if using database)
```

## After Deployment

Your app will be running and accessible via:
- Your domain (if provided): `https://yourdomain.com`
- Server IP: `http://your-server-ip`

### Managing Your App
```bash
# Check if it's running
pm2 status

# View logs
pm2 logs your-app-name

# Restart app
pm2 restart your-app-name

# Stop app
pm2 stop your-app-name
```

### Updating Your App
1. Upload new files to the server
2. Run `pm2 restart your-app-name`

## Troubleshooting

**App won't start?**
- Check `pm2 logs your-app-name` for errors
- Make sure your `package.json` has a start script
- Verify your app listens on the correct port

**Can't access from browser?**
- Check if firewall allows HTTP/HTTPS traffic
- Verify domain DNS settings (if using custom domain)
- Check Nginx configuration: `sudo nginx -t`

**Database connection issues?**
- Verify database credentials in your app
- Check if database service is running
- Test database connection manually

## Examples

### Express.js API
```javascript
// app.js
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello World!' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### With Database
```javascript
// app.js with PostgreSQL
const express = require('express');
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/users', async (req, res) => {
  const result = await pool.query('SELECT * FROM users');
  res.json(result.rows);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

Need help? Check the specific deployment folder for detailed instructions.