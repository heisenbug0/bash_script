# Render Deployment

Deploy applications to Render with automatic configuration detection.

## What You Get

- **Automatic detection** of Node.js, Python, or static sites
- **Database integration** for Django/Flask apps
- **Environment variables** configured automatically
- **SSL certificates** included
- **Global CDN** for static assets

## Quick Start

```bash
export PROJECT_NAME="my-app"
./deploy.sh
```

## Supported Project Types

### Node.js Applications
- Express APIs
- React apps (built as static sites)
- Any Node.js server

### Python Applications
- Django web apps (with PostgreSQL)
- Flask APIs
- Any Python web application

### Static Sites
- HTML/CSS/JS sites
- Built frontend applications
- Documentation sites

## What Happens

1. **Project detection** - Automatically identifies your project type
2. **Configuration** - Creates render.yaml based on project
3. **Deployment** - Uses Render CLI to deploy
4. **Database setup** - Adds PostgreSQL for Django/Flask (if needed)

## Environment Variables

```bash
export PROJECT_NAME="my-app"        # Your project name
export SERVICE_TYPE="web"          # Service type (web/static)
export DOMAIN="example.com"         # Custom domain (optional)
```

## Project Detection

The script automatically detects:

- **Node.js**: If `package.json` exists
- **React**: If `package.json` contains React
- **Django**: If `manage.py` exists
- **Python**: If `requirements.txt` exists
- **Static**: If none of the above

## Configuration Examples

### Node.js API
```yaml
services:
  - type: web
    name: my-api
    env: node
    buildCommand: npm install
    startCommand: npm start
```

### Django App
```yaml
services:
  - type: web
    name: my-django-app
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn myproject.wsgi:application

databases:
  - name: my-django-app-db
    databaseName: myproject
```

### Static Site
```yaml
services:
  - type: web
    name: my-site
    env: static
    buildCommand: npm run build
    staticPublishPath: ./build
```

## After Deployment

Your app will be available at:
- Render URL: `https://your-app.onrender.com`
- Custom domain: `https://yourdomain.com` (if configured)

### Managing Your App

```bash
# View services
render services list

# View logs
render logs your-app-name

# Redeploy
render deploy your-app-name
```

## Database Access

For Django/Flask apps with databases:
- Connection string provided automatically
- Access via Render dashboard
- Backup and restore available

## Custom Configuration

You can customize the generated `render.yaml`:

```yaml
services:
  - type: web
    name: my-app
    env: node
    buildCommand: npm install && npm run build
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: API_KEY
        value: your-secret-key
```

## Troubleshooting

**Build failed?**
- Check build logs in Render dashboard
- Verify build command is correct
- Check dependencies in package.json/requirements.txt

**App not starting?**
- Check start command
- Verify port configuration (Render provides PORT env var)
- Check application logs

**Database connection issues?**
- Verify DATABASE_URL environment variable
- Check database status in Render dashboard

Perfect for quick deployments without server management.