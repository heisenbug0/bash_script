# Django Deployment

Deploy Django applications with PostgreSQL database and production setup.

## What You Get

- **Django** web framework
- **PostgreSQL** database with user
- **Gunicorn** WSGI server
- **Nginx** reverse proxy
- **SSL certificate** (with domain)
- **Systemd service** for auto-restart
- **Static file serving**

## Quick Start

```bash
export APP_NAME="my-django-app"
export DOMAIN="mysite.com"  # optional
sudo ./deploy.sh
```

## Requirements

Your Django project needs:
- `requirements.txt` file
- `manage.py` file
- Working Django settings
- Database configuration ready

## What Happens

1. **System setup** - Python, PostgreSQL, Nginx installed
2. **Database created** - PostgreSQL database and user
3. **Virtual environment** - Python dependencies installed
4. **Django setup** - Migrations run, static files collected
5. **Service created** - Systemd service for Gunicorn
6. **Web server** - Nginx configured as reverse proxy
7. **SSL setup** - Free certificate if domain provided

## Environment Variables

```bash
export APP_NAME="my-django-app"     # Your app name
export PYTHON_VERSION="3.11"       # Python version
export DB_NAME="myapp"              # Database name
export DOMAIN="example.com"         # Your domain (optional)
```

## After Deployment

Your Django app will be running at:
- Your domain: `https://yourdomain.com`
- Admin interface: `https://yourdomain.com/admin/`

### Managing Your App
```bash
# Check status
systemctl status my-django-app

# View logs
journalctl -u my-django-app -f

# Restart
systemctl restart my-django-app

# Database access
psql -h localhost -U dbuser -d dbname
```

## Django Settings

The script creates a `.env` file with:
- `DEBUG=False`
- `SECRET_KEY` (auto-generated)
- `DATABASE_URL` (PostgreSQL connection)
- `ALLOWED_HOSTS` (your domain)

Make sure your Django settings can read from environment variables:

```python
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get('SECRET_KEY')
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

## Updating Your App

1. Update your code
2. Restart the service: `systemctl restart my-django-app`
3. For database changes: Run migrations manually

## Troubleshooting

**App won't start?**
- Check logs: `journalctl -u my-django-app -f`
- Verify requirements.txt has all dependencies
- Check Django settings for errors

**Database issues?**
- Test connection: `psql -h localhost -U dbuser -d dbname`
- Check PostgreSQL: `systemctl status postgresql`

**Static files not loading?**
- Run: `python manage.py collectstatic`
- Check Nginx config: `nginx -t`

Works with any Django project that follows standard structure.