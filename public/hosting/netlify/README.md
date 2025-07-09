# Netlify Deployment Scripts

Deploy your static sites and JAMstack applications to Netlify with automated scripts.

## 📁 Available Scripts

```
netlify/
├── static/             # Static HTML/CSS/JS sites
├── react/              # React applications
├── vue/                # Vue.js applications
├── angular/            # Angular applications
├── gatsby/             # Gatsby sites
├── hugo/               # Hugo static sites
├── jekyll/             # Jekyll sites
├── nextjs/             # Next.js static exports
├── nuxtjs/             # Nuxt.js static generation
└── functions/          # Netlify Functions
```

## 🚀 Quick Start

### React Application
```bash
cd react/
export SITE_NAME="my-react-app"
export BUILD_COMMAND="npm run build"
export PUBLISH_DIR="build"
./deploy.sh
```

### Vue.js Application
```bash
cd vue/
export SITE_NAME="my-vue-app"
export BUILD_COMMAND="npm run build"
export PUBLISH_DIR="dist"
./deploy.sh
```

### Static Site
```bash
cd static/
export SITE_NAME="my-static-site"
export PUBLISH_DIR="public"
./deploy.sh
```

## 📋 Prerequisites

- Netlify account
- Git repository
- Netlify CLI (automatically installed)
- Static site or JAMstack application

## 🔧 Configuration

### Environment Variables
```bash
# General Configuration
export SITE_NAME="my-site"
export NETLIFY_AUTH_TOKEN="your-netlify-token"
export DOMAIN="example.com"

# Build Configuration
export BUILD_COMMAND="npm run build"
export PUBLISH_DIR="dist"
export NODE_VERSION="18"

# Framework-specific
export REACT_APP_API_URL="https://api.example.com"
export VUE_APP_API_URL="https://api.example.com"
export GATSBY_API_URL="https://api.example.com"
```

## 📝 Features

### Build & Deploy
- ✅ Automatic builds from Git
- ✅ Custom build commands
- ✅ Environment variable management
- ✅ Build caching
- ✅ Deploy previews

### Hosting Features
- ✅ Global CDN
- ✅ Automatic SSL certificates
- ✅ Custom domains
- ✅ Redirects and rewrites
- ✅ Form handling

### Serverless Functions
- ✅ Netlify Functions
- ✅ Edge Functions
- ✅ Background Functions
- ✅ Scheduled Functions
- ✅ Event-triggered Functions

### Performance
- ✅ Asset optimization
- ✅ Image optimization
- ✅ Prerendering
- ✅ Edge caching
- ✅ Compression

## 🛠️ Supported Frameworks

### Static Site Generators
- **Gatsby**: React-based static site generator
- **Hugo**: Fast static site generator
- **Jekyll**: Ruby-based static site generator
- **Eleventy**: Simple static site generator
- **Gridsome**: Vue.js static site generator

### Frontend Frameworks
- **React**: Create React App, Vite React
- **Vue.js**: Vue CLI, Vite Vue, Nuxt.js
- **Angular**: Angular CLI applications
- **Svelte**: SvelteKit applications
- **Next.js**: Static export mode

### Build Tools
- **Vite**: Modern build tool
- **Webpack**: Module bundler
- **Parcel**: Zero-configuration build tool
- **Rollup**: Module bundler

## 📚 Configuration Examples

### netlify.toml
```toml
[build]
  publish = "dist"
  command = "npm run build"

[build.environment]
  NODE_VERSION = "18"
  NPM_VERSION = "9"

[[redirects]]
  from = "/api/*"
  to = "https://api.example.com/:splat"
  status = 200

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[context.production.environment]
  REACT_APP_ENV = "production"
  REACT_APP_API_URL = "https://api.example.com"

[context.deploy-preview.environment]
  REACT_APP_ENV = "staging"
  REACT_APP_API_URL = "https://staging-api.example.com"

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"

[[headers]]
  for = "/static/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### Build Scripts
```bash
#!/usr/bin/env bash
# netlify-build.sh
set -e

echo "🌐 Starting Netlify build..."

# Install dependencies
npm ci

# Build application
npm run build

# Optimize images (if using)
if command -v imagemin &> /dev/null; then
    imagemin dist/images/* --out-dir=dist/images/
fi

echo "✅ Netlify build completed!"
```

### Netlify Functions
```javascript
// netlify/functions/hello.js
exports.handler = async (event, context) => {
  const { name = "World" } = event.queryStringParameters || {};
  
  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify({
      message: `Hello, ${name}!`,
      timestamp: new Date().toISOString(),
    }),
  };
};
```

### Edge Functions
```javascript
// netlify/edge-functions/geolocation.js
export default async (request, context) => {
  const country = context.geo?.country?.name || "Unknown";
  const city = context.geo?.city || "Unknown";
  
  return new Response(
    JSON.stringify({
      country,
      city,
      timestamp: new Date().toISOString(),
    }),
    {
      headers: {
        "Content-Type": "application/json",
      },
    }
  );
};

export const config = {
  path: "/api/location",
};
```

## 📦 Form Handling

### HTML Form
```html
<!-- Contact form with Netlify handling -->
<form name="contact" method="POST" data-netlify="true">
  <input type="hidden" name="form-name" value="contact" />
  
  <label for="name">Name:</label>
  <input type="text" id="name" name="name" required />
  
  <label for="email">Email:</label>
  <input type="email" id="email" name="email" required />
  
  <label for="message">Message:</label>
  <textarea id="message" name="message" required></textarea>
  
  <button type="submit">Send Message</button>
</form>
```

### JavaScript Form Submission
```javascript
// Handle form submission with JavaScript
const handleSubmit = async (event) => {
  event.preventDefault();
  
  const formData = new FormData(event.target);
  
  try {
    const response = await fetch("/", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams(formData).toString(),
    });
    
    if (response.ok) {
      alert("Form submitted successfully!");
    } else {
      alert("Form submission failed.");
    }
  } catch (error) {
    alert("An error occurred.");
  }
};
```

## 🔍 Troubleshooting

### Common Issues

**Build Failures**
```bash
# Check build logs
netlify logs

# Test build locally
netlify build

# Debug with verbose output
netlify build --debug
```

**Environment Variables**
```bash
# List environment variables
netlify env:list

# Set environment variable
netlify env:set KEY value

# Import from .env file
netlify env:import .env
```

**Function Issues**
```bash
# Test functions locally
netlify dev

# Check function logs
netlify functions:log function-name

# Deploy functions only
netlify functions:build
```

### Performance Optimization

**Build Performance**
- Use build caching
- Optimize dependencies
- Minimize build steps
- Use incremental builds

**Site Performance**
- Optimize images
- Minimize JavaScript/CSS
- Use lazy loading
- Enable compression

**SEO Optimization**
- Add meta tags
- Generate sitemap
- Optimize for Core Web Vitals
- Use structured data

## 🔗 Related Documentation

- [Framework Scripts](../../frameworks/README.md)
- [Static Site Generators](../../static/README.md)
- [JAMstack Scripts](../../stacks/jamstack/README.md)