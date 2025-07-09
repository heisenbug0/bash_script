# Full-Stack Deployment Scripts

Deploy complete application stacks with all components configured together.

## Available Stacks

### MERN Stack
**MongoDB + Express + React + Node.js**
- Complete JavaScript stack
- MongoDB for data storage
- Express.js API backend
- React frontend
- Node.js runtime

### MEAN Stack  
**MongoDB + Express + Angular + Node.js**
- Full-featured JavaScript stack
- Angular frontend framework
- TypeScript support
- Enterprise-ready architecture

### LAMP Stack
**Linux + Apache + MySQL + PHP**
- Classic web development stack
- Apache web server
- MySQL database
- PHP server-side scripting
- Perfect for WordPress, traditional web apps

## Quick Deployments

### MERN Stack
```bash
cd mern/
export STACK_NAME="my-mern-app"
export DOMAIN="myapp.com"
sudo ./deploy.sh
```

### MEAN Stack
```bash
cd mean/
export STACK_NAME="my-mean-app"
export DOMAIN="myapp.com"
sudo ./deploy.sh
```

### LAMP Stack
```bash
cd lamp/
export APP_NAME="my-website"
export DOMAIN="mysite.com"
sudo ./deploy.sh
```

## What You Need

### MERN/MEAN Projects
Your project should have:
- `backend/` folder with Node.js API
- `frontend/` folder with React/Angular app
- `package.json` in both folders
- Database connection configured

### LAMP Projects
Your project should have:
- PHP files (or we'll create a sample)
- Database requirements (optional)
- Standard web structure

## What Gets Set Up

### MERN/MEAN Stacks
- **MongoDB** database with authentication
- **Node.js** backend with PM2 process management
- **Frontend** built and served by Nginx
- **API proxy** from frontend to backend
- **SSL certificate** for your domain
- **Firewall** and security rules

### LAMP Stack
- **Apache** web server
- **MySQL** database with secure setup
- **PHP** with common extensions
- **Virtual host** configuration
- **SSL certificate** for your domain
- **Database user** and permissions

## Project Structure

### MERN/MEAN Expected Structure
```
your-project/
├── backend/
│   ├── package.json
│   ├── server.js (or app.js)
│   └── ... (your API code)
└── frontend/
    ├── package.json
    ├── src/
    └── ... (your React/Angular code)
```

### LAMP Structure
```
your-project/
├── index.php
├── config/
├── includes/
└── ... (your PHP files)
```

## After Deployment

### MERN/MEAN
- **Frontend**: Accessible at your domain
- **API**: Available at `/api/` routes
- **Database**: MongoDB running locally
- **Logs**: PM2 logs for backend, Nginx logs for frontend

### LAMP
- **Website**: Accessible at your domain
- **Database**: MySQL with created user
- **Files**: Located in `/var/www/html/`
- **Logs**: Apache logs in `/var/log/apache2/`

## Management Commands

### MERN/MEAN
```bash
# Check backend status
pm2 status

# View backend logs
pm2 logs your-app-backend

# Restart backend
pm2 restart your-app-backend

# Check database
mongo
```

### LAMP
```bash
# Check Apache status
sudo systemctl status apache2

# Check MySQL status
sudo systemctl status mysql

# Connect to database
mysql -u your_user -p your_database

# View logs
sudo tail -f /var/log/apache2/error.log
```

## Updating Your Stack

### MERN/MEAN
1. Update backend code
2. Restart with `pm2 restart your-app-backend`
3. Update frontend code
4. Rebuild with `npm run build`
5. Copy new build to `/var/www/your-app/`

### LAMP
1. Update PHP files in `/var/www/html/`
2. No restart needed (PHP is interpreted)
3. Clear any caches if using frameworks

Each stack folder has detailed setup instructions and troubleshooting guides.