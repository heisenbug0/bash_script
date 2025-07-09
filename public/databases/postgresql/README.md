# PostgreSQL Database Setup

Install and configure PostgreSQL database with user and performance optimization.

## What You Get

- **PostgreSQL** latest stable version
- **Database and user** created automatically
- **Performance tuning** applied
- **Backup script** included
- **Security configuration**

## Quick Start

```bash
export DB_NAME="myapp"
export DB_USER="appuser"
sudo ./setup.sh
```

## What Happens

1. **Installation** - PostgreSQL server and client tools
2. **Configuration** - Performance optimization applied
3. **Database setup** - Database and user created
4. **Security** - Connection testing and validation
5. **Backup script** - Automated backup solution

## Environment Variables

```bash
export DB_NAME="myapp"              # Database name
export DB_USER="appuser"            # Database user
export DB_PASSWORD="auto-generated" # Password (auto-generated)
export POSTGRES_VERSION="15"        # PostgreSQL version
```

## After Setup

Your PostgreSQL database will be ready with:
- Database: Your specified name
- User: Your specified username
- Password: Auto-generated (shown after setup)
- Connection: `postgresql://user:pass@localhost:5432/dbname`

### Managing PostgreSQL

```bash
# Check status
systemctl status postgresql

# Connect to database
psql -h localhost -U your_user -d your_database

# View databases
psql -h localhost -U your_user -l

# Create backup
/usr/local/bin/postgres-backup.sh
```

## Connection Examples

### Node.js (with pg)
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: 'postgresql://user:password@localhost:5432/database'
});

// Test connection
pool.query('SELECT NOW()', (err, res) => {
  console.log(err ? err : res.rows[0]);
});
```

### Python (with psycopg2)
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="your_database",
    user="your_user",
    password="your_password"
)

cur = conn.cursor()
cur.execute("SELECT version();")
print(cur.fetchone())
```

### Django Settings
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'your_database',
        'USER': 'your_user',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

## Performance Tuning

The script applies these optimizations:
- **Shared buffers**: 256MB (memory for caching)
- **Effective cache size**: 1GB (OS cache estimate)
- **Maintenance work mem**: 64MB (for maintenance operations)
- **Checkpoint completion**: 0.9 (smoother checkpoints)
- **WAL buffers**: 16MB (write-ahead log buffer)
- **Random page cost**: 1.1 (SSD optimization)

## Backup and Recovery

### Automatic Backups
```bash
# Manual backup
/usr/local/bin/postgres-backup.sh

# Backup location
ls /var/backups/postgresql/

# Restore from backup
gunzip < backup.sql.gz | psql -h localhost -U user -d database
```

### Backup Schedule
The script creates a backup script that:
- Compresses backups with gzip
- Keeps 7 days of backups
- Names files with timestamps
- Can be scheduled with cron

## Security Features

- **Password authentication** required
- **User isolation** - app user can't access other databases
- **Connection testing** - validates setup works
- **Local connections only** by default

## Troubleshooting

**Connection refused?**
- Check if PostgreSQL is running: `systemctl status postgresql`
- Verify port 5432 is open: `netstat -tlnp | grep 5432`
- Check PostgreSQL logs: `journalctl -u postgresql -f`

**Authentication failed?**
- Verify username and password
- Check pg_hba.conf configuration
- Try connecting as postgres user first

**Performance issues?**
- Monitor with: `SELECT * FROM pg_stat_activity;`
- Check slow queries: `SELECT * FROM pg_stat_statements;`
- Adjust configuration based on your server specs

Perfect for production applications requiring reliable data storage.