# Node.js Deployment Scripts

Deploy Node.js applications with PostgreSQL database integration.

## What's Available

### Node.js + PostgreSQL
Complete deployment with database setup, user management, and production configuration.

**What you get:**
- Node.js (latest LTS)
- PostgreSQL database with user
- PM2 process management
- Nginx reverse proxy
- SSL certificate (with domain)
- Firewall configuration
- Automatic restarts

## Quick Start

```bash
cd with-postgresql/
export APP_NAME="my-app"
export DB_NAME="myapp_db"
export DOMAIN="myapp.com"  # optional
sudo ./deploy.sh
```

## What You Need

Your Node.js project should have:
- `package.json` file
- A start script defined
- Main app file (usually `app.js` or `server.js`)
- PostgreSQL connection code

## Environment Variables

```bash
export APP_NAME="my-awesome-app"    # Your app name
export NODE_VERSION="18"           # Node.js version (default: 18)
export PORT="3000"                 # Port your app runs on
export DOMAIN="example.com"        # Your domain (optional)
export DB_NAME="myapp"             # Database name
export DB_USER="appuser"           # Database user (auto-generated)
export DB_PASSWORD="..."           # Database password (auto-generated)
```

## After Deployment

Your app will be running at:
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

# Database access
psql -h localhost -U your-db-user -d your-db-name
```

## Example App Structure

```javascript
// app.js
const express = require('express');
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', async (req, res) => {
  const result = await pool.query('SELECT NOW()');
  res.json({ 
    message: 'Hello World!',
    database_time: result.rows[0].now
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

## Troubleshooting

**App won't start?**
- Check `pm2 logs your-app-name` for errors
- Make sure your `package.json` has a start script
- Verify your app listens on the correct port

**Database connection issues?**
- Check the DATABASE_URL environment variable
- Test connection: `psql $DATABASE_URL`
- Verify PostgreSQL is running: `systemctl status postgresql`

**Can't access from browser?**
- Check firewall: `ufw status`
- Verify Nginx: `systemctl status nginx`
- Check domain DNS settings (if using custom domain)

Need help? Check the deployment script for detailed setup steps.