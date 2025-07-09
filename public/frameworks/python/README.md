# Python Web Framework Deployments

Deploy Django, Flask, and FastAPI applications with ease.

## Available Frameworks

### Django
Full-featured web framework with admin interface, ORM, and everything included.
- Complete project setup
- Database migrations
- Static file serving
- Admin interface ready

### Flask  
Lightweight and flexible web framework.
- Minimal setup
- Easy to customize
- Perfect for APIs and small apps

### FastAPI
Modern, fast API framework with automatic documentation.
- Built-in API docs
- Type hints support
- High performance
- Great for microservices

## Quick Start

### Django Project
```bash
cd django/
export APP_NAME="my-django-site"
export DOMAIN="mysite.com"
sudo ./deploy.sh
```

### Flask API
```bash
cd flask/
export APP_NAME="my-api"
export PORT="5000"
sudo ./deploy.sh
```

### FastAPI Service
```bash
cd fastapi/
export APP_NAME="my-service"
export PORT="8000"
sudo ./deploy.sh
```

## What You Need

Your Python project should have:
- `requirements.txt` file with dependencies
- Main application file
- Basic project structure

### Django Projects
- `manage.py` file
- Django app structure
- Settings configured

### Flask Projects
- Main Flask app file
- Routes defined
- WSGI callable

### FastAPI Projects
- Main FastAPI app
- API routes defined
- Uvicorn or similar ASGI server

## What Gets Installed

- Python (latest version)
- Virtual environment for your app
- Web server (Gunicorn/Uvicorn)
- Nginx reverse proxy
- PostgreSQL database (if needed)
- SSL certificate (with domain)
- Process management (systemd)

## Configuration

```bash
export APP_NAME="my-python-app"
export PYTHON_VERSION="3.11"        # Python version
export DOMAIN="example.com"         # Your domain
export DB_NAME="myapp"              # Database name
export DB_USER="appuser"            # Database user
```

## After Deployment

### Django
- Admin available at `/admin/`
- Static files served automatically
- Database migrations run
- Superuser created (check deployment output for credentials)

### Flask/FastAPI
- API endpoints available
- JSON responses
- Automatic error handling

### Managing Your App
```bash
# Check status
sudo systemctl status your-app-name

# View logs
sudo journalctl -u your-app-name -f

# Restart
sudo systemctl restart your-app-name
```

## Database Access

If your app uses PostgreSQL:
```bash
# Connect to database
psql -h localhost -U your-db-user -d your-db-name

# Check connection from Python
python3 -c "import psycopg2; print('PostgreSQL connection works!')"
```

## Updating Your App

1. Upload new code to server
2. Activate virtual environment: `source venv/bin/activate`
3. Install new dependencies: `pip install -r requirements.txt`
4. Run migrations (Django): `python manage.py migrate`
5. Restart service: `sudo systemctl restart your-app-name`

## Common Issues

**Import errors?**
- Check virtual environment is activated
- Verify all dependencies in requirements.txt
- Check Python path settings

**Database connection failed?**
- Verify database credentials
- Check if PostgreSQL is running
- Test connection manually

**Static files not loading?**
- Run `python manage.py collectstatic` (Django)
- Check Nginx configuration
- Verify file permissions

## Examples

### Simple Django View
```python
# views.py
from django.http import JsonResponse

def api_hello(request):
    return JsonResponse({'message': 'Hello from Django!'})
```

### Flask API
```python
# app.py
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/api/hello')
def hello():
    return jsonify({'message': 'Hello from Flask!'})

if __name__ == '__main__':
    app.run()
```

### FastAPI Service
```python
# main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/api/hello")
def hello():
    return {"message": "Hello from FastAPI!"}
```

Each framework folder has detailed setup instructions and examples.