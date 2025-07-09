# Docker Deployment Scripts

Comprehensive Docker deployment scripts for containerizing and deploying applications across various platforms.

## 📁 Directory Structure

```
docker/
├── frameworks/         # Framework-specific Dockerfiles
│   ├── nodejs/        # Node.js applications
│   ├── python/        # Python applications
│   ├── go/            # Go applications
│   ├── rust/          # Rust applications
│   ├── java/          # Java applications
│   └── php/           # PHP applications
├── stacks/            # Full-stack Docker Compose setups
│   ├── mern/          # MongoDB, Express, React, Node.js
│   ├── lamp/          # Linux, Apache, MySQL, PHP
│   ├── django-react/  # Django backend, React frontend
│   └── microservices/ # Microservices architectures
├── databases/         # Database containers
│   ├── postgresql/    # PostgreSQL containers
│   ├── mysql/         # MySQL containers
│   ├── mongodb/       # MongoDB containers
│   └── redis/         # Redis containers
├── platforms/         # Platform-specific deployments
│   ├── aws-ecs/       # AWS Elastic Container Service
│   ├── gcp-run/       # Google Cloud Run
│   ├── azure-aci/     # Azure Container Instances
│   ├── kubernetes/    # Kubernetes deployments
│   └── docker-swarm/  # Docker Swarm deployments
└── tools/             # Docker utilities and tools
    ├── multi-stage/   # Multi-stage build examples
    ├── security/      # Security scanning and hardening
    ├── optimization/  # Image optimization tools
    └── monitoring/    # Container monitoring
```

## 🎯 Container Strategies

### Single Container Applications
Perfect for:
- Microservices
- API servers
- Simple web applications
- Utility services
- Development environments

### Multi-Container Applications
- **Docker Compose**: Local development and simple deployments
- **Kubernetes**: Production orchestration
- **Docker Swarm**: Simple container orchestration
- **Cloud Services**: Managed container platforms

### Container Optimization
- **Multi-stage builds**: Reduce image size
- **Layer caching**: Faster builds
- **Security scanning**: Vulnerability detection
- **Health checks**: Container monitoring
- **Resource limits**: Performance optimization

## 🚀 Quick Start Examples

### Containerize Node.js Application
```bash
cd frameworks/nodejs/
export APP_NAME="my-node-app"
export NODE_VERSION="18"
./dockerize.sh
```

### Deploy MERN Stack with Docker Compose
```bash
cd stacks/mern/
export STACK_NAME="my-mern-app"
export MONGO_DB="myapp"
docker-compose up -d
```

### Deploy to AWS ECS
```bash
cd platforms/aws-ecs/
export CLUSTER_NAME="my-cluster"
export SERVICE_NAME="my-service"
export IMAGE_URI="my-account.dkr.ecr.region.amazonaws.com/my-app:latest"
./deploy.sh
```

### Deploy to Kubernetes
```bash
cd platforms/kubernetes/
export APP_NAME="my-app"
export NAMESPACE="production"
kubectl apply -f manifests/
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-app"
export APP_VERSION="1.0.0"
export ENVIRONMENT="production"

# Container Configuration
export BASE_IMAGE="node:18-alpine"
export CONTAINER_PORT="3000"
export HEALTH_CHECK_PATH="/health"

# Build Configuration
export DOCKERFILE_PATH="./Dockerfile"
export BUILD_CONTEXT="."
export BUILD_ARGS="NODE_ENV=production"

# Registry Configuration
export REGISTRY_URL="my-registry.com"
export IMAGE_NAME="my-app"
export IMAGE_TAG="latest"

# Deployment Configuration
export REPLICAS="3"
export CPU_LIMIT="500m"
export MEMORY_LIMIT="512Mi"
export CPU_REQUEST="250m"
export MEMORY_REQUEST="256Mi"
```

## 📝 Dockerfile Examples

### Node.js Multi-Stage Dockerfile
```dockerfile
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Production stage
FROM node:18-alpine AS production

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

WORKDIR /app

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs . .

# Security and optimization
RUN apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

USER nextjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
```

### Python Django Dockerfile
```dockerfile
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash app

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code
COPY --chown=app:app . .

# Collect static files
RUN python manage.py collectstatic --noinput

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]
```

### Go Application Dockerfile
```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Production stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copy binary from builder stage
COPY --from=builder /app/main .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./main"]
```

## 📚 Docker Compose Examples

### MERN Stack
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:6.0
    container_name: mern-mongodb
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password
      MONGO_INITDB_DATABASE: mernapp
    volumes:
      - mongodb_data:/data/db
    networks:
      - mern-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: mern-backend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      MONGODB_URI: mongodb://admin:password@mongodb:27017/mernapp?authSource=admin
      JWT_SECRET: your-jwt-secret
    depends_on:
      - mongodb
    networks:
      - mern-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: mern-frontend
    restart: unless-stopped
    environment:
      REACT_APP_API_URL: http://backend:5000
    depends_on:
      - backend
    networks:
      - mern-network

  nginx:
    image: nginx:alpine
    container_name: mern-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - frontend
      - backend
    networks:
      - mern-network

volumes:
  mongodb_data:

networks:
  mern-network:
    driver: bridge
```

### Django + PostgreSQL + Redis
```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    container_name: django-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: djangodb
      POSTGRES_USER: djangouser
      POSTGRES_PASSWORD: djangopass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - django-network

  redis:
    image: redis:7-alpine
    container_name: django-redis
    restart: unless-stopped
    networks:
      - django-network

  web:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: django-web
    restart: unless-stopped
    environment:
      DEBUG: "False"
      DATABASE_URL: postgresql://djangouser:djangopass@db:5432/djangodb
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - django-network

  celery:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: django-celery
    restart: unless-stopped
    command: celery -A myproject worker --loglevel=info
    environment:
      DEBUG: "False"
      DATABASE_URL: postgresql://djangouser:djangopass@db:5432/djangodb
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - django-network

  nginx:
    image: nginx:alpine
    container_name: django-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    depends_on:
      - web
    networks:
      - django-network

volumes:
  postgres_data:
  static_volume:
  media_volume:

networks:
  django-network:
    driver: bridge
```

## 🔧 Container Optimization

### Multi-Stage Builds
- Separate build and runtime environments
- Reduce final image size
- Improve security by excluding build tools
- Cache build dependencies

### Security Best Practices
- Use non-root users
- Scan for vulnerabilities
- Use minimal base images
- Keep images updated
- Implement health checks

### Performance Optimization
- Layer caching strategies
- Minimize image layers
- Use .dockerignore files
- Optimize dependency installation
- Configure resource limits

## 🛠️ Platform Deployments

### AWS ECS
- Task definitions
- Service configuration
- Load balancer integration
- Auto scaling setup
- CloudWatch monitoring

### Google Cloud Run
- Serverless container deployment
- Automatic scaling
- Traffic management
- Custom domains
- IAM integration

### Azure Container Instances
- Quick container deployment
- Virtual network integration
- Persistent storage
- Container groups
- Monitoring and logging

### Kubernetes
- Deployment manifests
- Service definitions
- ConfigMaps and Secrets
- Ingress controllers
- Horizontal Pod Autoscaling

## 📊 Monitoring and Logging

### Container Monitoring
- Resource usage tracking
- Performance metrics
- Health check monitoring
- Log aggregation
- Alert configuration

### Tools Integration
- Prometheus metrics
- Grafana dashboards
- ELK stack logging
- Jaeger tracing
- New Relic monitoring

## 🔍 Troubleshooting

### Common Issues

**Build Failures**
```bash
# Check build logs
docker build --no-cache -t my-app .

# Debug build process
docker run -it --rm my-app /bin/sh
```

**Container Startup Issues**
```bash
# Check container logs
docker logs container-name

# Debug running container
docker exec -it container-name /bin/sh
```

**Network Connectivity**
```bash
# Test network connectivity
docker network ls
docker network inspect network-name

# Test service communication
docker exec -it container-name ping other-service
```

### Performance Issues

**Resource Usage**
```bash
# Monitor resource usage
docker stats

# Check container resource limits
docker inspect container-name | grep -A 10 Resources
```

**Image Size Optimization**
```bash
# Analyze image layers
docker history my-app:latest

# Use dive tool for detailed analysis
dive my-app:latest
```

## 🔗 Related Documentation

- [Framework Scripts](../../frameworks/README.md)
- [Cloud Services](../../cloud-services/README.md)
- [Kubernetes Scripts](../kubernetes/README.md)
- [Database Scripts](../../databases/README.md)