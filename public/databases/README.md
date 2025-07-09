# Database Setup Scripts

Set up databases for your applications.

## Available Databases

### PostgreSQL
The most popular open-source relational database.
- **Production ready** - Reliable and performant
- **Full-text search** - Built-in search capabilities
- **JSON support** - Store and query JSON data
- **Extensions** - Rich ecosystem of add-ons

### Redis
In-memory data store for caching and sessions.
- **Blazing fast** - Sub-millisecond response times
- **Versatile** - Cache, sessions, queues, pub/sub
- **Persistent** - Optional data persistence
- **Clustering** - Scale horizontally

## Quick Setup

### PostgreSQL
```bash
cd postgresql/
export DB_NAME="myapp"
export DB_USER="appuser"
sudo ./setup.sh
```

### Redis
```bash
cd redis/
export REDIS_PASSWORD="securepassword"
sudo ./setup.sh
```

## What Gets Configured

### PostgreSQL
- Latest stable version installed
- Database and user created
- Performance tuning applied
- Backup scripts created
- Security hardening
- Connection pooling ready

### Redis
- Latest stable version installed
- Password authentication
- Memory optimization
- Persistence configured
- Security settings applied
- Monitoring ready

## Integration

These databases work seamlessly with our framework scripts:

```bash
# Node.js + PostgreSQL
cd ../frameworks/nodejs/with-postgresql/
export DB_NAME="myapp"
sudo ./deploy.sh

# Django automatically uses PostgreSQL
cd ../frameworks/python/django/
sudo ./deploy.sh
```

## Management

### PostgreSQL
```bash
# Connect to database
psql -h localhost -U appuser -d myapp

# Check status
sudo systemctl status postgresql

# View logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Redis
```bash
# Connect to Redis
redis-cli -a yourpassword

# Check status
sudo systemctl status redis

# Monitor performance
redis-cli --latency
```

## Backup & Recovery

Both databases include automatic backup scripts:
- **Daily backups** with retention policies
- **Easy restore** procedures
- **Monitoring** for backup success
- **Compression** to save space

Check each database folder for specific backup instructions.