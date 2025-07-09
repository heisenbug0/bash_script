# FastAPI Deployment Scripts

Comprehensive deployment scripts for FastAPI applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
fastapi/
├── standalone/          # FastAPI apps without external dependencies
├── with-postgresql/     # FastAPI + PostgreSQL combinations
├── with-mysql/         # FastAPI + MySQL combinations
├── with-mongodb/       # FastAPI + MongoDB combinations
├── with-redis/         # FastAPI + Redis combinations
├── full-stack/         # Complete stacks (DB + Cache + Monitoring)
├── api-only/           # FastAPI REST API deployments
├── microservices/      # FastAPI microservices
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- High-performance APIs
- Microservices
- Data processing services
- Real-time applications
- Machine learning APIs

### Database Integrations
- **PostgreSQL**: Production-ready relational database
- **MySQL**: Traditional relational database
- **MongoDB**: Document-based NoSQL database
- **SQLite**: Lightweight embedded database

### Caching Solutions
- **Redis**: In-memory data structure store
- **Memcached**: Distributed memory caching
- **In-memory**: Built-in Python caching

### Advanced Features
- **WebSocket**: Real-time communication
- **Background Tasks**: Async task processing
- **GraphQL**: GraphQL API support
- **Authentication**: OAuth2, JWT, API keys

## 🚀 Quick Start Examples

### Deploy FastAPI App to VPS
```bash
cd standalone/vps/ubuntu/
export APP_NAME="my-fastapi-app"
export PYTHON_VERSION="3.11"
export DOMAIN="api.example.com"
sudo ./deploy.sh
```

### Deploy FastAPI + PostgreSQL to AWS
```bash
cd with-postgresql/aws-ec2/
export APP_NAME="my-api"
export DB_NAME="myapp"
sudo ./deploy.sh
```

### Deploy FastAPI to Render
```bash
cd api-only/render/
export PROJECT_NAME="my-fastapi"
export DATABASE_TYPE="postgresql"
./deploy.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-fastapi-app"
export PYTHON_VERSION="3.11"
export FASTAPI_VERSION="0.104"
export ENVIRONMENT="production"
export DEBUG="False"

# Database Configuration
export DATABASE_URL="postgresql://user:pass@localhost/db"
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
export DB_USER="appuser"
export DB_PASSWORD="securepassword"

# Redis Configuration (if applicable)
export REDIS_URL="redis://localhost:6379/0"
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""

# Security Configuration
export SECRET_KEY="your-secret-key"
export JWT_SECRET_KEY="your-jwt-secret"
export CORS_ORIGINS="https://example.com"

# Performance Configuration
export WORKERS="4"
export WORKER_CLASS="uvicorn.workers.UvicornWorker"
export MAX_REQUESTS="1000"
export MAX_REQUESTS_JITTER="100"
```

## 📝 Application Examples

### Simple FastAPI Application
```python
# main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import os
from datetime import datetime

app = FastAPI(
    title="My FastAPI App",
    description="A simple FastAPI application",
    version="1.0.0"
)

class User(BaseModel):
    id: Optional[int] = None
    name: str
    email: str
    created_at: Optional[datetime] = None

class UserCreate(BaseModel):
    name: str
    email: str

# In-memory storage for demo
users_db = []
user_id_counter = 1

@app.get("/")
async def root():
    return {
        "message": "Hello, World!",
        "status": "success",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/users", response_model=List[User])
async def get_users():
    return users_db

@app.post("/api/users", response_model=User, status_code=201)
async def create_user(user: UserCreate):
    global user_id_counter
    
    new_user = User(
        id=user_id_counter,
        name=user.name,
        email=user.email,
        created_at=datetime.utcnow()
    )
    
    users_db.append(new_user)
    user_id_counter += 1
    
    return new_user

@app.get("/api/users/{user_id}", response_model=User)
async def get_user(user_id: int):
    for user in users_db:
        if user.id == user_id:
            return user
    raise HTTPException(status_code=404, detail="User not found")

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

### FastAPI with Database Integration
```python
# main.py
from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
from typing import List, Optional
import os
from datetime import datetime

# Database setup
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./app.db")
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database model
class UserDB(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models
class UserBase(BaseModel):
    name: str
    email: str

class UserCreate(UserBase):
    pass

class User(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# FastAPI app
app = FastAPI(
    title="FastAPI with Database",
    description="FastAPI application with database integration",
    version="1.0.0"
)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/health")
async def health(db: Session = Depends(get_db)):
    try:
        # Test database connection
        db.execute("SELECT 1")
        db_status = "healthy"
    except Exception:
        db_status = "unhealthy"
    
    return {
        "status": "healthy",
        "database": db_status,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/users", response_model=List[User])
async def get_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(UserDB).offset(skip).limit(limit).all()
    return users

@app.post("/api/users", response_model=User, status_code=201)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    db_user = db.query(UserDB).filter(UserDB.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_user = UserDB(**user.dict())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.get("/api/users/{user_id}", response_model=User)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.delete("/api/users/{user_id}")
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

## 📝 Build Scripts

### Standard Build Script
```bash
#!/usr/bin/env bash
# build.sh for FastAPI deployment
set -o errexit

echo "🚀 Starting FastAPI deployment build..."

# Create virtual environment
echo "🐍 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Run database migrations (if using Alembic)
if [ -d "alembic" ]; then
    echo "🗄️ Running database migrations..."
    alembic upgrade head
fi

echo "✅ Build completed successfully!"
```

### Uvicorn Configuration
```python
# uvicorn_config.py
import os

bind = f"0.0.0.0:{os.environ.get('PORT', '8000')}"
workers = int(os.environ.get('WORKERS', '4'))
worker_class = "uvicorn.workers.UvicornWorker"
max_requests = int(os.environ.get('MAX_REQUESTS', '1000'))
max_requests_jitter = int(os.environ.get('MAX_REQUESTS_JITTER', '100'))
timeout = 30
keepalive = 2
preload_app = True

# Logging
accesslog = '-'
errorlog = '-'
loglevel = 'info'
```

## 📦 Requirements Files

### requirements.txt
```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
gunicorn==21.2.0
python-multipart==0.0.6

# Database
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.7  # for PostgreSQL
PyMySQL==1.1.0          # for MySQL
motor==3.3.2            # for MongoDB (async)

# Caching
redis==5.0.1
aioredis==2.0.1

# Authentication & Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# Validation & Serialization
pydantic==2.5.0
pydantic-settings==2.0.3

# HTTP Client
httpx==0.25.2
aiohttp==3.9.1

# Background Tasks
celery==5.3.4
```

### requirements-dev.txt
```txt
-r requirements.txt

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
pytest-cov==4.1.0

# Code Quality
black==23.11.0
isort==5.12.0
flake8==6.1.0
mypy==1.7.1

# Development
uvicorn[standard]==0.24.0
```

## 📝 Docker Configuration

### Dockerfile
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

USER app

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 📝 Features

### Performance
- ✅ Async/await support
- ✅ High-performance ASGI server
- ✅ Automatic API documentation
- ✅ Request/response validation
- ✅ Dependency injection

### Security
- ✅ OAuth2 authentication
- ✅ JWT token support
- ✅ API key authentication
- ✅ CORS configuration
- ✅ Input validation

### Development
- ✅ Automatic OpenAPI/Swagger docs
- ✅ Interactive API documentation
- ✅ Type hints support
- ✅ Hot reloading
- ✅ Testing utilities

### Monitoring
- ✅ Built-in metrics
- ✅ Health check endpoints
- ✅ Structured logging
- ✅ Performance monitoring
- ✅ Error tracking

## 🛠️ Prerequisites

### System Requirements
- Python 3.8+ (3.11+ recommended)
- pip package manager
- Virtual environment support
- Database system (if required)
- Redis server (if caching enabled)

## 📚 Usage Examples

### Example 1: High-Performance API
```bash
# Deploy FastAPI to Ubuntu VPS
cd api-only/vps/ubuntu/
export APP_NAME="high-perf-api"
export PORT="8000"
export DOMAIN="api.mysite.com"
sudo ./deploy.sh
```

### Example 2: Microservice with Database
```bash
# Deploy FastAPI microservice with PostgreSQL
cd microservices/with-postgresql/
export SERVICE_NAME="user-service"
export DB_NAME="users"
sudo ./deploy.sh
```

### Example 3: ML API
```bash
# Deploy FastAPI ML API to Kubernetes
cd api-only/kubernetes/
export SERVICE_NAME="ml-api"
export NAMESPACE="production"
kubectl apply -f manifests/
```

## 🔍 Troubleshooting

### Common Issues

**Import Errors**
```bash
# Check Python path
python -c "import sys; print(sys.path)"

# Install missing packages
pip install -r requirements.txt

# Check virtual environment
which python
```

**Database Connection Issues**
```bash
# Test database connection
python -c "from sqlalchemy import create_engine; engine = create_engine('your-db-url'); engine.connect()"

# Check environment variables
env | grep DB_
```

**Performance Issues**
```bash
# Monitor with uvicorn
uvicorn main:app --workers 4 --log-level info

# Check async performance
python -c "import asyncio; print(asyncio.get_event_loop())"
```

## 🔗 Related Documentation

- [Database Scripts](../../../databases/README.md)
- [Caching Scripts](../../../caching/README.md)
- [Cloud Services](../../../cloud-services/README.md)
- [Hosting Platforms](../../../hosting/README.md)