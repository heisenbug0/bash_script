# Flask Deployment

Deploy Flask applications with PostgreSQL database and production setup.

## What You Get

- **Flask** web framework
- **PostgreSQL** database with user
- **Gunicorn** WSGI server
- **Nginx** reverse proxy
- **SSL certificate** (with domain)
- **Systemd service** for auto-restart

## Quick Start

```bash
export APP_NAME="my-flask-app"
export DOMAIN="myapi.com"  # optional
sudo ./deploy.sh
```

## Requirements

Your Flask project needs:
- `requirements.txt` file
- Main app file (`app.py`, `main.py`, or custom)
- Flask app object named `app`

## What Happens

1. **System setup** - Python, PostgreSQL, Nginx installed
2. **Database created** - PostgreSQL database and user
3. **Virtual environment** - Python dependencies installed
4. **Service created** - Systemd service for Gunicorn
5. **Web server** - Nginx configured as reverse proxy
6. **SSL setup** - Free certificate if domain provided

## Environment Variables

```bash
export APP_NAME="my-flask-app"      # Your app name
export PYTHON_VERSION="3.11"       # Python version
export FLASK_APP="app.py"           # Main Flask file
export DB_NAME="myapp"              # Database name
export DOMAIN="example.com"         # Your domain (optional)
```

## After Deployment

Your Flask app will be running at:
- Your domain: `https://yourdomain.com`
- Server IP: `http://your-server-ip`

### Managing Your App
```bash
# Check status
systemctl status my-flask-app

# View logs
journalctl -u my-flask-app -f

# Restart
systemctl restart my-flask-app

# Database access
psql -h localhost -U dbuser -d dbname
```

## Flask App Structure

Your Flask app should look like this:

```python
# app.py
from flask import Flask
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY')
app.config['DATABASE_URL'] = os.environ.get('DATABASE_URL')

@app.route('/')
def hello():
    return 'Hello, World!'

@app.route('/health')
def health():
    return {'status': 'healthy'}

if __name__ == '__main__':
    app.run(debug=True)
```

## Environment File

The script creates a `.env` file with:
- `FLASK_ENV=production`
- `SECRET_KEY` (auto-generated)
- `DATABASE_URL` (PostgreSQL connection)

## Database Connection

Use the DATABASE_URL environment variable:

```python
import os
from sqlalchemy import create_engine

DATABASE_URL = os.environ.get('DATABASE_URL')
engine = create_engine(DATABASE_URL)
```

Or with Flask-SQLAlchemy:

```python
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
db = SQLAlchemy(app)
```

## Updating Your App

1. Update your code
2. Restart the service: `systemctl restart my-flask-app`

## Troubleshooting

**App won't start?**
- Check logs: `journalctl -u my-flask-app -f`
- Verify your Flask app object is named `app`
- Check requirements.txt has all dependencies

**Database issues?**
- Test connection: `psql -h localhost -U dbuser -d dbname`
- Check PostgreSQL: `systemctl status postgresql`

**Import errors?**
- Make sure all dependencies are in requirements.txt
- Check virtual environment: `source venv/bin/activate`

Perfect for APIs, microservices, and lightweight web applications.