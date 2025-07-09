# MySQL Database Setup

Install and configure MySQL database with user and performance optimization.

## What You Get

- **MySQL** latest stable version
- **Database and user** created automatically
- **Security hardening** applied
- **Performance tuning** included
- **Backup script** ready

## Quick Start

```bash
export DB_NAME="myapp"
export DB_USER="appuser"
sudo ./setup.sh
```

## What Happens

1. **Installation** - MySQL server and client tools
2. **Security** - Root password set, test databases removed
3. **Database setup** - Database and user created
4. **Performance tuning** - Configuration optimized
5. **Backup script** - Automated backup solution

## Environment Variables

```bash
export DB_NAME="myapp"              # Database name
export DB_USER="appuser"            # Database user
export DB_PASSWORD="auto-generated" # User password (auto-generated)
export ROOT_PASSWORD="auto-generated" # Root password (auto-generated)
export MYSQL_VERSION="8.0"         # MySQL version
```

## After Setup

Your MySQL database will be ready with:
- Database: Your specified name
- User: Your specified username
- Passwords: Auto-generated (shown after setup)
- Connection: `mysql://user:pass@localhost:3306/dbname`

### Managing MySQL

```bash
# Check status
systemctl status mysql

# Connect as root
mysql -u root -p

# Connect as app user
mysql -u your_user -p your_database

# Create backup
/usr/local/bin/mysql-backup.sh
```

## Connection Examples

### Node.js (with mysql2)
```javascript
const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'your_user',
  password: 'your_password',
  database: 'your_database'
});

connection.execute('SELECT NOW()', (err, results) => {
  console.log(results);
});
```

### Python (with PyMySQL)
```python
import pymysql

connection = pymysql.connect(
    host='localhost',
    user='your_user',
    password='your_password',
    database='your_database'
)

cursor = connection.cursor()
cursor.execute("SELECT VERSION()")
print(cursor.fetchone())
```

### PHP (with PDO)
```php
<?php
$dsn = "mysql:host=localhost;dbname=your_database";
$username = "your_user";
$password = "your_password";

try {
    $pdo = new PDO($dsn, $username, $password);
    $stmt = $pdo->query("SELECT VERSION()");
    echo $stmt->fetchColumn();
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}
?>
```

## Performance Tuning

The script applies these optimizations:
- **InnoDB buffer pool**: 256MB (main memory cache)
- **InnoDB log file size**: 64MB (transaction log size)
- **InnoDB flush method**: O_DIRECT (bypass OS cache)
- **Query cache**: 32MB (cache SELECT results)
- **Max connections**: 100 (concurrent connections)

## Security Features

Applied automatically:
- **Root password** set and secured
- **Anonymous users** removed
- **Test database** removed
- **Remote root access** disabled
- **User isolation** - app user limited to own database

## Backup and Recovery

### Automatic Backups
```bash
# Manual backup
/usr/local/bin/mysql-backup.sh

# Backup location
ls /var/backups/mysql/

# Restore from backup
gunzip < backup.sql.gz | mysql -u user -p database
```

### Backup Features
- **Compressed backups** with gzip
- **7-day retention** automatic cleanup
- **Timestamped files** for easy identification
- **Single database** backup (not full server)

## Database Management

### Common Operations
```sql
-- Show databases
SHOW DATABASES;

-- Use database
USE your_database;

-- Show tables
SHOW TABLES;

-- Create table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Show table structure
DESCRIBE users;
```

## Troubleshooting

**Can't connect?**
- Check MySQL status: `systemctl status mysql`
- Verify port 3306: `netstat -tlnp | grep 3306`
- Check error logs: `journalctl -u mysql -f`

**Access denied?**
- Verify username and password
- Check user privileges: `SHOW GRANTS FOR 'user'@'localhost';`
- Try connecting as root first

**Performance issues?**
- Check running queries: `SHOW PROCESSLIST;`
- Monitor slow queries: `SHOW VARIABLES LIKE 'slow_query_log';`
- Adjust buffer sizes based on available RAM

Perfect for web applications, content management systems, and traditional databases.