# Flask Deployment Scripts

Comprehensive deployment scripts for Flask applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
flask/
├── standalone/          # Flask apps without external dependencies
├── with-postgresql/     # Flask + PostgreSQL combinations
├── with-mysql/         # Flask + MySQL combinations
├── with-sqlite/        # Flask + SQLite combinations
├── with-redis/         # Flask + Redis combinations
├── full-stack/         # Complete stacks (DB + Cache + Monitoring)
├── api-only/           # Flask REST API deployments
├── microservices/      # Flask microservices
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- Simple Flask websites
- API servers
- Microservices
- Prototype applications
- Development environments

### Database Integrations
- **PostgreSQL**: Production-ready relational database
- **MySQL**: Traditional relational database
- **SQLite**: Lightweight embedded database
- **MongoDB**: Document-based NoSQL (via Flask-PyMongo)

### Caching Solutions
- **Redis**: In-memory data structure store
- **Memcached**: Distributed memory caching
- **Flask-Caching**: Built-in caching support

### API Frameworks
- **Flask-RESTful**: RESTful API development
- **Flask-RESTX**: API development with Swagger
- **Flask-GraphQL**: GraphQL API support
- **Flask-SocketIO**: WebSocket support

## 🚀 Quick Start Examples

### Deploy Flask App to VPS
```bash
cd standalone/vps/ubuntu/
export APP_NAME="my-flask-app"
export PYTHON_VERSION="3.11"
export DOMAIN="app.example.com"
sudo ./deploy.sh
```

### Deploy Flask + PostgreSQL to AWS
```bash
cd with-postgresql/aws-ec2/
export APP_NAME="my-webapp"
export DB_NAME="myapp"
sudo ./deploy.sh
```

### Deploy Flask API to Render
```bash
cd api-only/render/
export PROJECT_NAME="my-api"
export DATABASE_TYPE="postgresql"
./deploy.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-flask-app"
export PYTHON_VERSION="3.11"
export FLASK_VERSION="2.3"
export FLASK_ENV="production"
export FLASK_DEBUG="False"
export SECRET_KEY="your-secret-key"

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
export JWT_SECRET_KEY="your-jwt-secret"
export CORS_ORIGINS="https://example.com"

# Performance Configuration
export WORKERS="4"
export WORKER_CLASS="gevent"
export WORKER_CONNECTIONS="1000"
export MAX_REQUESTS="1000"
export MAX_REQUESTS_JITTER="100"
```

## 📝 Application Examples

### Simple Flask Application
```python
# app.py
from flask import Flask, jsonify, request
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello, World!',
        'status': 'success'
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify({'users': []})

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    return jsonify({'message': 'User created', 'data': data}), 201

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)
```

### Flask with Database Integration
```python
# app.py
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import os
from datetime import datetime

app = Flask(__name__)

# Database configuration
database_url = os.environ.get('DATABASE_URL')
if database_url and database_url.startswith('postgres://'):
    database_url = database_url.replace('postgres://', 'postgresql://', 1)

app.config['SQLALCHEMY_DATABASE_URI'] = database_url or 'sqlite:///app.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')

db = SQLAlchemy(app)
migrate = Migrate(app, db)

# Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'created_at': self.created_at.isoformat()
        }

# Routes
@app.route('/health')
def health():
    try:
        # Test database connection
        db.session.execute('SELECT 1')
        db_status = 'healthy'
    except Exception:
        db_status = 'unhealthy'
    
    return jsonify({
        'status': 'healthy',
        'database': db_status,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/users', methods=['GET'])
def get_users():
    users = User.query.all()
    return jsonify([user.to_dict() for user in users])

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    
    if not data or 'name' not in data or 'email' not in data:
        return jsonify({'error': 'Name and email are required'}), 400
    
    user = User(name=data['name'], email=data['email'])
    
    try:
        db.session.add(user)
        db.session.commit()
        return jsonify(user.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'User creation failed'}), 500

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict())

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)
```

## 📝 Build Scripts

### Standard Build Script
```bash
#!/usr/bin/env bash
# build.sh for Flask deployment
set -o errexit

echo "🚀 Starting Flask deployment build..."

# Create virtual environment
echo "🐍 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Set Flask environment
export FLASK_APP=app.py
export FLASK_ENV=production

# Run database migrations
if [ -d "migrations" ]; then
    echo "🗄️ Running database migrations..."
    flask db upgrade
fi

# Collect static files (if using Flask-Assets)
if python -c "import flask_assets" 2>/dev/null; then
    echo "📁 Building static assets..."
    flask assets build
fi

echo "✅ Build completed successfully!"
```

### Gunicorn Configuration
```python
# gunicorn.conf.py
import os

bind = f"0.0.0.0:{os.environ.get('PORT', '5000')}"
workers = int(os.environ.get('WORKERS', '4'))
worker_class = os.environ.get('WORKER_CLASS', 'gevent')
worker_connections = int(os.environ.get('WORKER_CONNECTIONS', '1000'))
max_requests = int(os.environ.get('MAX_REQUESTS', '1000'))
max_requests_jitter = int(os.environ.get('MAX_REQUESTS_JITTER', '100'))
timeout = 30
keepalive = 2
preload_app = True

# Logging
accesslog = '-'
errorlog = '-'
loglevel = 'info'
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'
```

## 📦 Requirements Files

### requirements.txt
```txt
Flask==2.3.3
gunicorn==21.2.0
python-dotenv==1.0.0

# Database
Flask-SQLAlchemy==3.0.5
Flask-Migrate==4.0.5
psycopg2-binary==2.9.7  # for PostgreSQL
PyMySQL==1.1.0          # for MySQL

# Caching
Flask-Caching==2.1.0
redis==5.0.0

# API Development
Flask-RESTful==0.3.10
Flask-RESTX==1.1.0
Flask-CORS==4.0.0

# Authentication
Flask-JWT-Extended==4.5.2
Flask-Login==0.6.3

# Forms and Validation
Flask-WTF==1.1.1
WTForms==3.0.1
marshmallow==3.20.1

# Utilities
requests==2.31.0
celery==5.3.1           # for background tasks
```

### requirements-dev.txt
```txt
-r requirements.txt

# Testing
pytest==7.4.2
pytest-flask==1.2.0
pytest-cov==4.1.0
factory-boy==3.3.0

# Code Quality
black==23.7.0
flake8==6.0.0
isort==5.12.0
mypy==1.5.1

# Development
Flask-DebugToolbar==0.13.1
python-dotenv==1.0.0
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

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", "--config", "gunicorn.conf.py", "app:app"]
```

## 📝 Features

### Security
- ✅ Environment variable management
- ✅ Database security configuration
- ✅ SSL/TLS certificate setup
- ✅ CORS configuration
- ✅ CSRF protection
- ✅ JWT authentication

### Performance
- ✅ Gunicorn WSGI server
- ✅ Redis caching setup
- ✅ Database connection pooling
- ✅ Static file optimization
- ✅ CDN configuration

### Monitoring
- ✅ Flask logging configuration
- ✅ Error tracking setup
- ✅ Performance monitoring
- ✅ Health check endpoints
- ✅ Database monitoring

### Development Tools
- ✅ Flask-DebugToolbar setup
- ✅ Testing configuration
- ✅ Code quality tools
- ✅ Migration management
- ✅ Hot reloading

## 🛠️ Prerequisites

### System Requirements
- Python 3.8+ (3.11+ recommended)
- pip package manager
- Virtual environment support
- Database system (if required)
- Redis server (if caching enabled)

## 📚 Usage Examples

### Example 1: Simple API
```bash
# Deploy Flask API to Ubuntu VPS
cd api-only/vps/ubuntu/
export APP_NAME="user-api"
export PORT="5000"
export DOMAIN="api.mysite.com"
sudo ./deploy.sh
```

### Example 2: Full-Stack Application
```bash
# Deploy Flask app with PostgreSQL
cd with-postgresql/vps/ubuntu/
export APP_NAME="my-webapp"
export DB_NAME="webapp"
sudo ./deploy.sh
```

### Example 3: Microservice
```bash
# Deploy Flask microservice to Kubernetes
cd microservices/kubernetes/
export SERVICE_NAME="user-service"
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
python -c "from app import db; db.create_all()"

# Check environment variables
env | grep DB_
```

**Performance Issues**
```bash
# Profile Flask application
pip install flask-profiler
# Add to your app configuration

# Monitor with htop
htop

# Check Gunicorn workers
ps aux | grep gunicorn
```

## 🔗 Related Documentation

- [Database Scripts](../../../databases/README.md)
- [Caching Scripts](../../../caching/README.md)
- [Cloud Services](../../../cloud-services/README.md)
- [Hosting Platforms](../../../hosting/README.md)