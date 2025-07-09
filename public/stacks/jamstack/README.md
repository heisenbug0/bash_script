# JAMstack Deployment Scripts

Deploy modern JAMstack (JavaScript, APIs, Markup) applications with various static site generators, headless CMS, and serverless functions.

## 📁 Directory Structure

```
jamstack/
├── generators/         # Static site generators
│   ├── gatsby/        # Gatsby sites
│   ├── nextjs/        # Next.js static export
│   ├── nuxtjs/        # Nuxt.js static generation
│   ├── hugo/          # Hugo sites
│   ├── jekyll/        # Jekyll sites
│   ├── eleventy/      # 11ty sites
│   └── gridsome/      # Gridsome sites
├── cms/               # Headless CMS integrations
│   ├── strapi/        # Strapi CMS
│   ├── contentful/    # Contentful CMS
│   ├── sanity/        # Sanity CMS
│   ├── ghost/         # Ghost CMS
│   ├── forestry/      # Forestry CMS
│   └── netlify-cms/   # Netlify CMS
├── functions/         # Serverless functions
│   ├── netlify/       # Netlify Functions
│   ├── vercel/        # Vercel Functions
│   ├── aws-lambda/    # AWS Lambda
│   └── cloudflare/    # Cloudflare Workers
├── hosting/           # Hosting platforms
│   ├── netlify/       # Netlify hosting
│   ├── vercel/        # Vercel hosting
│   ├── github-pages/  # GitHub Pages
│   ├── cloudflare/    # Cloudflare Pages
│   └── aws-s3/        # AWS S3 + CloudFront
└── full-stack/        # Complete JAMstack solutions
    ├── blog/          # Blog platforms
    ├── ecommerce/     # E-commerce sites
    ├── portfolio/     # Portfolio sites
    └── documentation/ # Documentation sites
```

## 🎯 JAMstack Architecture

### Core Principles
- **JavaScript**: Dynamic functionality on the client
- **APIs**: Server-side operations via reusable APIs
- **Markup**: Pre-built markup served from CDN

### Benefits
- **Performance**: Fast loading times with CDN
- **Security**: Reduced attack surface
- **Scalability**: Easy to scale with CDN
- **Developer Experience**: Modern development workflow
- **Cost Effective**: Lower hosting costs

## 🚀 Quick Start Examples

### Deploy Gatsby Site to Netlify
```bash
cd generators/gatsby/netlify/
export SITE_NAME="my-gatsby-site"
export CMS_TYPE="contentful"
./deploy.sh
```

### Deploy Next.js Static Site to Vercel
```bash
cd generators/nextjs/vercel/
export PROJECT_NAME="my-nextjs-site"
export API_PROVIDER="strapi"
./deploy.sh
```

### Deploy Hugo Site with Forestry CMS
```bash
cd generators/hugo/forestry/
export SITE_NAME="my-hugo-site"
export HOSTING_PROVIDER="netlify"
./deploy.sh
```

### Deploy E-commerce JAMstack
```bash
cd full-stack/ecommerce/
export SITE_NAME="my-store"
export CMS="strapi"
export PAYMENT_PROVIDER="stripe"
./deploy.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Site Configuration
export SITE_NAME="my-jamstack-site"
export SITE_URL="https://mysite.com"
export BUILD_COMMAND="npm run build"
export PUBLISH_DIR="public"

# CMS Configuration
export CMS_TYPE="strapi"          # strapi, contentful, sanity, etc.
export CMS_URL="https://cms.mysite.com"
export CMS_API_KEY="your-api-key"

# Hosting Configuration
export HOSTING_PROVIDER="netlify"  # netlify, vercel, github-pages
export DOMAIN="mysite.com"
export SSL_ENABLED="true"

# Functions Configuration
export FUNCTIONS_PROVIDER="netlify" # netlify, vercel, aws-lambda
export FUNCTIONS_DIR="functions"

# Build Configuration
export NODE_VERSION="18"
export PACKAGE_MANAGER="npm"      # npm, yarn, pnpm
export BUILD_CACHE="true"
```

## 📝 Static Site Generator Examples

### Gatsby Configuration
```javascript
// gatsby-config.js
module.exports = {
  siteMetadata: {
    title: process.env.SITE_NAME || 'My Gatsby Site',
    siteUrl: process.env.SITE_URL || 'https://localhost:8000',
  },
  plugins: [
    'gatsby-plugin-react-helmet',
    'gatsby-plugin-image',
    'gatsby-plugin-sharp',
    'gatsby-transformer-sharp',
    {
      resolve: 'gatsby-source-filesystem',
      options: {
        name: 'pages',
        path: './src/pages/',
      },
    },
    {
      resolve: 'gatsby-source-contentful',
      options: {
        spaceId: process.env.CONTENTFUL_SPACE_ID,
        accessToken: process.env.CONTENTFUL_ACCESS_TOKEN,
      },
    },
    {
      resolve: 'gatsby-plugin-manifest',
      options: {
        name: 'My Gatsby Site',
        short_name: 'Gatsby Site',
        start_url: '/',
        background_color: '#ffffff',
        theme_color: '#000000',
        display: 'minimal-ui',
        icon: 'src/images/icon.png',
      },
    },
  ],
};
```

### Next.js Configuration
```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
  env: {
    SITE_NAME: process.env.SITE_NAME,
    CMS_URL: process.env.CMS_URL,
    CMS_API_KEY: process.env.CMS_API_KEY,
  },
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.CMS_URL}/api/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;
```

### Hugo Configuration
```yaml
# config.yaml
baseURL: 'https://mysite.com'
languageCode: 'en-us'
title: 'My Hugo Site'
theme: 'my-theme'

params:
  cms_url: 'https://cms.mysite.com'
  api_key: 'your-api-key'

markup:
  goldmark:
    renderer:
      unsafe: true

build:
  publishDir: 'public'
  
menu:
  main:
    - name: 'Home'
      url: '/'
      weight: 1
    - name: 'About'
      url: '/about/'
      weight: 2
    - name: 'Blog'
      url: '/blog/'
      weight: 3
```

## 📝 Headless CMS Integration

### Strapi Integration
```javascript
// lib/strapi.js
const STRAPI_URL = process.env.CMS_URL || 'http://localhost:1337';
const STRAPI_TOKEN = process.env.CMS_API_KEY;

export async function fetchAPI(path, options = {}) {
  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${STRAPI_TOKEN}`,
    },
  };

  const mergedOptions = {
    ...defaultOptions,
    ...options,
  };

  const requestUrl = `${STRAPI_URL}/api${path}`;
  const response = await fetch(requestUrl, mergedOptions);

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  return await response.json();
}

export async function getArticles() {
  const articles = await fetchAPI('/articles?populate=*');
  return articles.data;
}

export async function getArticle(slug) {
  const articles = await fetchAPI(`/articles?filters[slug][$eq]=${slug}&populate=*`);
  return articles.data[0];
}
```

### Contentful Integration
```javascript
// lib/contentful.js
import { createClient } from 'contentful';

const client = createClient({
  space: process.env.CONTENTFUL_SPACE_ID,
  accessToken: process.env.CONTENTFUL_ACCESS_TOKEN,
});

export async function getEntries(contentType) {
  try {
    const entries = await client.getEntries({
      content_type: contentType,
      order: '-sys.createdAt',
    });
    return entries.items;
  } catch (error) {
    console.error('Error fetching entries:', error);
    return [];
  }
}

export async function getEntry(id) {
  try {
    const entry = await client.getEntry(id);
    return entry;
  } catch (error) {
    console.error('Error fetching entry:', error);
    return null;
  }
}
```

### Sanity Integration
```javascript
// lib/sanity.js
import { createClient } from '@sanity/client';

const client = createClient({
  projectId: process.env.SANITY_PROJECT_ID,
  dataset: process.env.SANITY_DATASET || 'production',
  token: process.env.SANITY_TOKEN,
  useCdn: process.env.NODE_ENV === 'production',
  apiVersion: '2023-01-01',
});

export async function getPosts() {
  const query = `
    *[_type == "post"] | order(publishedAt desc) {
      _id,
      title,
      slug,
      publishedAt,
      excerpt,
      mainImage {
        asset -> {
          _id,
          url
        }
      }
    }
  `;
  
  return await client.fetch(query);
}

export async function getPost(slug) {
  const query = `
    *[_type == "post" && slug.current == $slug][0] {
      _id,
      title,
      slug,
      publishedAt,
      body,
      mainImage {
        asset -> {
          _id,
          url
        }
      }
    }
  `;
  
  return await client.fetch(query, { slug });
}
```

## 📝 Serverless Functions

### Netlify Functions
```javascript
// netlify/functions/contact.js
exports.handler = async (event, context) => {
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  try {
    const { name, email, message } = JSON.parse(event.body);

    // Process contact form (send email, save to database, etc.)
    console.log('Contact form submission:', { name, email, message });

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ success: true, message: 'Message sent successfully' }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};
```

### Vercel Functions
```javascript
// api/contact.js
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { name, email, message } = req.body;

    // Process contact form
    console.log('Contact form submission:', { name, email, message });

    res.status(200).json({ success: true, message: 'Message sent successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
}
```

### AWS Lambda Function
```javascript
// functions/contact.js
exports.handler = async (event, context) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  try {
    const { name, email, message } = JSON.parse(event.body);

    // Process contact form
    console.log('Contact form submission:', { name, email, message });

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ success: true, message: 'Message sent successfully' }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};
```

## 📝 Build Configuration

### Package.json Scripts
```json
{
  "name": "my-jamstack-site",
  "version": "1.0.0",
  "scripts": {
    "dev": "gatsby develop",
    "build": "gatsby build",
    "serve": "gatsby serve",
    "clean": "gatsby clean",
    "test": "jest",
    "lint": "eslint src/",
    "format": "prettier --write src/"
  },
  "dependencies": {
    "gatsby": "^5.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "devDependencies": {
    "eslint": "^8.0.0",
    "prettier": "^3.0.0",
    "jest": "^29.0.0"
  }
}
```

### Netlify Configuration
```toml
# netlify.toml
[build]
  publish = "public"
  command = "npm run build"

[build.environment]
  NODE_VERSION = "18"
  NPM_VERSION = "9"

[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[context.production.environment]
  NODE_ENV = "production"
  CMS_URL = "https://cms.mysite.com"

[context.deploy-preview.environment]
  NODE_ENV = "staging"
  CMS_URL = "https://staging-cms.mysite.com"

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    X-Content-Type-Options = "nosniff"

[[headers]]
  for = "/static/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### Vercel Configuration
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "public"
      }
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "/api/$1"
    },
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "env": {
    "NODE_ENV": "production",
    "CMS_URL": "@cms-url",
    "CMS_API_KEY": "@cms-api-key"
  },
  "build": {
    "env": {
      "NODE_VERSION": "18"
    }
  }
}
```

## 📝 Features

### Performance
- ✅ Static site generation
- ✅ CDN distribution
- ✅ Image optimization
- ✅ Code splitting
- ✅ Lazy loading

### Developer Experience
- ✅ Hot reloading
- ✅ Modern build tools
- ✅ Git-based workflow
- ✅ Preview deployments
- ✅ Automated testing

### Content Management
- ✅ Headless CMS integration
- ✅ Content preview
- ✅ Version control
- ✅ Multi-language support
- ✅ Media management

### Scalability
- ✅ Serverless functions
- ✅ API integration
- ✅ Microservices architecture
- ✅ Edge computing
- ✅ Global distribution

## 🛠️ Prerequisites

### System Requirements
- Node.js 16+ (18+ recommended)
- Git version control
- Package manager (npm, yarn, or pnpm)
- Modern web browser

### Development Tools
- Code editor (VS Code recommended)
- Terminal/command line
- Git client
- Browser developer tools

## 📚 Usage Examples

### Example 1: Blog Platform
```bash
# Deploy Gatsby blog with Contentful
cd full-stack/blog/gatsby-contentful/
export SITE_NAME="my-blog"
export CMS_TYPE="contentful"
export HOSTING_PROVIDER="netlify"
./deploy.sh
```

### Example 2: E-commerce Site
```bash
# Deploy Next.js e-commerce with Strapi
cd full-stack/ecommerce/nextjs-strapi/
export SITE_NAME="my-store"
export PAYMENT_PROVIDER="stripe"
export HOSTING_PROVIDER="vercel"
./deploy.sh
```

### Example 3: Documentation Site
```bash
# Deploy Hugo documentation site
cd full-stack/documentation/hugo/
export SITE_NAME="my-docs"
export CMS_TYPE="forestry"
export HOSTING_PROVIDER="github-pages"
./deploy.sh
```

## 🔍 Troubleshooting

### Common Issues

**Build Failures**
```bash
# Clear cache
npm run clean
rm -rf node_modules package-lock.json
npm install

# Check build logs
npm run build -- --verbose
```

**CMS Connection Issues**
```bash
# Test API connection
curl -H "Authorization: Bearer $CMS_API_KEY" $CMS_URL/api/health

# Check environment variables
env | grep CMS_
```

**Function Deployment Issues**
```bash
# Test function locally
netlify dev
# or
vercel dev

# Check function logs
netlify functions:log function-name
```

### Performance Optimization

**Build Performance**
- Use build caching
- Optimize images
- Minimize dependencies
- Use incremental builds

**Runtime Performance**
- Implement lazy loading
- Optimize bundle size
- Use service workers
- Enable compression

## 🔗 Related Documentation

- [Static Site Generators](../generators/README.md)
- [Headless CMS](../cms/README.md)
- [Serverless Functions](../functions/README.md)
- [Hosting Platforms](../../hosting/README.md)