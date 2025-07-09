# Hosting Platform Deployments

Deploy your apps to popular hosting services with one command.

## Available Platforms

### Netlify
Perfect for static sites and JAMstack apps.
- Automatic builds from Git
- Free SSL certificates
- Global CDN
- Serverless functions
- Form handling

### Vercel  
Great for Next.js, React, and frontend apps.
- Zero-config deployments
- Preview deployments
- Edge functions
- Built-in analytics
- Custom domains

### Render
Full-stack hosting with databases.
- Web services
- PostgreSQL databases
- Redis instances
- Background workers
- Auto-deploy from Git

## Quick Deployments

### Static Site to Netlify
```bash
cd netlify/
export SITE_NAME="my-site"
./deploy.sh
```

### React App to Vercel
```bash
cd vercel/
export PROJECT_NAME="my-react-app"
./deploy.sh
```

### Full-Stack to Render
```bash
cd render/
export PROJECT_NAME="my-app"
export DATABASE_TYPE="postgresql"
./deploy.sh
```

## What You Need

### For Static Sites
- HTML, CSS, JS files
- Or a build process (npm run build)

### For React/Vue/Angular
- package.json with build script
- Modern Node.js project structure

### For Full-Stack Apps
- Backend code (Node.js, Python, etc.)
- Database requirements
- Environment variables

## Platform Features

### Netlify
- **Best for**: Static sites, JAMstack, blogs
- **Supports**: React, Vue, Gatsby, Hugo, Jekyll
- **Free tier**: 100GB bandwidth, 300 build minutes
- **Extras**: Forms, identity, analytics

### Vercel
- **Best for**: Next.js, React, frontend apps
- **Supports**: All frontend frameworks
- **Free tier**: 100GB bandwidth, unlimited projects
- **Extras**: Edge functions, image optimization

### Render
- **Best for**: Full-stack apps, APIs, databases
- **Supports**: Node.js, Python, Ruby, Go, Docker
- **Free tier**: 750 hours, PostgreSQL database
- **Extras**: Background jobs, cron jobs

## Configuration

Most platforms auto-detect your project type, but you can customize:

```bash
# Build settings
export BUILD_COMMAND="npm run build"
export BUILD_DIR="dist"
export NODE_VERSION="18"

# Custom domain
export DOMAIN="myapp.com"

# Environment variables
export API_URL="https://api.myapp.com"
export DATABASE_URL="postgresql://..."
```

## Deployment Process

1. **Prepare your code** - Make sure it builds locally
2. **Choose platform** - Based on your app type
3. **Run deployment script** - Handles everything automatically
4. **Configure domain** - If you have a custom domain
5. **Set environment variables** - For API keys, database URLs, etc.

## After Deployment

### Netlify
- Site available at: `https://site-name.netlify.app`
- Manage at: `https://app.netlify.com`
- Auto-deploys on Git push

### Vercel  
- App available at: `https://project-name.vercel.app`
- Manage at: `https://vercel.com/dashboard`
- Preview deployments for branches

### Render
- Service available at: `https://service-name.onrender.com`
- Manage at: `https://dashboard.render.com`
- Logs and metrics included

## Custom Domains

All platforms support custom domains:

1. **Add domain** in platform dashboard
2. **Update DNS** to point to platform
3. **SSL certificate** automatically provisioned
4. **HTTPS redirect** enabled by default

## Environment Variables

Set these in the platform dashboard:

```bash
# API endpoints
API_URL=https://api.example.com

# Database connections  
DATABASE_URL=postgresql://user:pass@host/db

# Third-party services
STRIPE_SECRET_KEY=sk_...
SENDGRID_API_KEY=SG...
```

## Troubleshooting

**Build failed?**
- Check build logs in platform dashboard
- Verify build command and output directory
- Test build locally first

**Site not loading?**
- Check if build produced files in correct directory
- Verify routing configuration for SPAs
- Check browser console for errors

**API not working?**
- Verify environment variables are set
- Check API endpoint URLs
- Review function/service logs

## Platform Comparison

| Feature | Netlify | Vercel | Render |
|---------|---------|--------|--------|
| Static Sites | ✅ Excellent | ✅ Excellent | ✅ Good |
| Frontend Apps | ✅ Great | ✅ Excellent | ✅ Good |
| Backend APIs | ⚠️ Functions only | ⚠️ Functions only | ✅ Full support |
| Databases | ❌ No | ❌ No | ✅ PostgreSQL |
| Free Tier | ✅ Generous | ✅ Generous | ✅ Limited |
| Custom Domains | ✅ Yes | ✅ Yes | ✅ Yes |

Choose based on your project needs:
- **Static/JAMstack**: Netlify or Vercel
- **Frontend apps**: Vercel (especially Next.js)
- **Full-stack apps**: Render
- **Simple sites**: Any platform works

Each platform folder has specific deployment guides and examples.