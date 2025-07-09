# MEAN Stack Deployment

Deploy complete MEAN stack applications (MongoDB + Express + Angular + Node.js).

## What You Get

- **MongoDB** database with authentication
- **Express.js** API backend with PM2
- **Angular** frontend built and served
- **Node.js** runtime environment
- **Nginx** reverse proxy and static serving
- **SSL certificate** (with domain)

## Quick Start

```bash
export STACK_NAME="my-mean-app"
export DOMAIN="myapp.com"  # optional
sudo ./deploy.sh
```

## Project Structure

Your MEAN project should be organized like this:

```
your-project/
├── backend/
│   ├── package.json
│   ├── server.js (or app.js)
│   └── ... (your API code)
└── frontend/
    ├── package.json
    ├── angular.json
    ├── src/
    └── ... (your Angular code)
```

## What Happens

1. **System setup** - Node.js and MongoDB installed
2. **Database setup** - MongoDB with user authentication
3. **Backend deployment** - Express API with PM2 process management
4. **Frontend build** - Angular app built for production
5. **Web server** - Nginx serves frontend and proxies API calls
6. **SSL setup** - Free certificate if domain provided

## Environment Variables

```bash
export STACK_NAME="my-mean-app"     # Your app name
export NODE_VERSION="18"           # Node.js version
export MONGODB_VERSION="6.0"       # MongoDB version
export API_PORT="5000"             # Backend port
export DOMAIN="example.com"        # Your domain (optional)
```

## After Deployment

Your MEAN app will be running at:
- Frontend: `https://yourdomain.com`
- API: `https://yourdomain.com/api/`
- Database: MongoDB on localhost:27017

### Managing Your App

```bash
# Backend status
pm2 status

# Backend logs
pm2 logs my-mean-app-backend

# Restart backend
pm2 restart my-mean-app-backend

# Database access
mongosh -u dbuser -p password --authenticationDatabase myapp
```

## Backend Setup

Your Express server should be configured like this:

```javascript
// backend/server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

## Frontend Setup

Your Angular app should be configured to call the API:

```typescript
// frontend/src/app/services/api.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = '/api';  // Nginx will proxy this

  constructor(private http: HttpClient) { }

  getData() {
    return this.http.get(`${this.apiUrl}/data`);
  }
}
```

## Database Connection

The script creates these MongoDB credentials:
- Database: Your stack name
- User: Auto-generated
- Password: Auto-generated (shown after deployment)

## Updating Your Stack

### Backend Updates
1. Update your backend code
2. Restart: `pm2 restart my-mean-app-backend`

### Frontend Updates
1. Update your frontend code
2. Rebuild: `cd frontend && npm run build`
3. Copy build: `cp -r dist/* /var/www/my-mean-app/`

## Troubleshooting

**Backend won't start?**
- Check PM2 logs: `pm2 logs my-mean-app-backend`
- Verify MongoDB connection string
- Check package.json start script

**Frontend not loading?**
- Check Nginx config: `nginx -t`
- Verify build files: `ls /var/www/my-mean-app/`
- Check browser console for errors

**Database connection issues?**
- Test MongoDB: `mongosh -u user -p password --authenticationDatabase dbname`
- Check MongoDB status: `systemctl status mongod`

Perfect for full-stack JavaScript applications with real-time features.