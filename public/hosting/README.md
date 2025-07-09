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
Great for React and frontend apps.
- Zero-config deployments
- Preview deployments
- Edge functions
- Built-in analytics
- Custom domains

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

## What You Need

### For Static Sites
- HTML, CSS, JS files
- Or a build process (npm run build)

### For React/Vue/Angular
- package.json with build script
- Modern Node.js project structure

## Platform Features

### Netlify
- **Best for**: Static sites, JAMstack, blogs
- **Supports**: React, Vue, Gatsby, Hugo, Jekyll
- **Free tier**: 100GB bandwidth, 300 build minutes
- **Extras**: Forms, identity, analytics

### Vercel
- **Best for**: React, frontend apps
- **Supports**: All frontend frameworks
- **Free tier**: 100GB bandwidth, unlimited projects
- **Extras**: Edge functions, image optimization

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
```

## Deployment Process

1. **Prepare your code** - Make sure it builds locally
2. **Choose platform** - Based on your app type
3. **Run deployment script** - Handles everything automatically
4. **Configure domain** - If you have a custom domain
5. **Set environment variables** - For API keys, etc.

## After Deployment

### Netlify
- Site available at: `https://site-name.netlify.app`
- Manage at: `https://app.netlify.com`
- Auto-deploys on Git push

### Vercel  
- App available at: `https://project-name.vercel.app`
- Manage at: `https://vercel.com/dashboard`
- Preview deployments for branches

## Custom Domains

Both platforms support custom domains:

1. **Add domain** in platform dashboard
2. **Update DNS** to point to platform
3. **SSL certificate** automatically provisioned
4. **HTTPS redirect** enabled by default

## Troubleshooting

**Build failed?**
- Check build logs in platform dashboard
- Verify build command and output directory
- Test build locally first

**Site not loading?**
- Check if build produced files in correct directory
- Verify routing configuration for SPAs
- Check browser console for errors

## Platform Comparison

| Feature | Netlify | Vercel |
|---------|---------|--------|
| Static Sites | ✅ Excellent | ✅ Excellent |
| Frontend Apps | ✅ Great | ✅ Excellent |
| Free Tier | ✅ Generous | ✅ Generous |
| Custom Domains | ✅ Yes | ✅ Yes |

Choose based on your project needs:
- **Static/JAMstack**: Netlify
- **React/Next.js**: Vercel
- **Simple sites**: Either works great

Each platform folder has specific deployment guides and examples.