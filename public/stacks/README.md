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

## Quick Deployment

### MERN Stack
```bash
cd mern/
export STACK_NAME="my-mern-app"
export DOMAIN="myapp.com"
sudo ./deploy.sh
```

## What You Need

### MERN Projects
Your project should have:
- `backend/` folder with Node.js API
- `frontend/` folder with React app
- `package.json` in both folders
- MongoDB connection configured

## What Gets Set Up

### MERN Stack
- **MongoDB** database with authentication
- **Node.js** backend with PM2 process management
- **React frontend** built and served by Nginx
- **API proxy** from frontend to backend
- **SSL certificate** for your domain
- **Firewall** and security rules

## Project Structure

### MERN Expected Structure
```
your-project/
├── backend/
│   ├── package.json
│   ├── server.js (or app.js)
│   └── ... (your API code)
└── frontend/
    ├── package.json
    ├── src/
    └── ... (your React code)
```

## After Deployment

### MERN
- **Frontend**: Accessible at your domain
- **API**: Available at `/api/` routes
- **Database**: MongoDB running locally
- **Logs**: PM2 logs for backend, Nginx logs for frontend

## Management Commands

### MERN
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

## Updating Your Stack

### MERN
1. Update backend code
2. Restart with `pm2 restart your-app-backend`
3. Update frontend code
4. Rebuild with `npm run build`
5. Copy new build to `/var/www/your-app/`

## Coming Soon

We're working on:
- **MEAN Stack** (MongoDB + Express + Angular + Node.js)
- **LAMP Stack** (Linux + Apache + MySQL + PHP)
- **JAMstack** (JavaScript + APIs + Markup)

The MERN stack folder has detailed setup instructions and troubleshooting guides.