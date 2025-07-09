# LAMP Stack Deployment

Deploy classic LAMP stack applications (Linux + Apache + MySQL + PHP).

## What You Get

- **Apache** web server
- **MySQL** database with user
- **PHP** with common extensions
- **phpMyAdmin** for database management
- **SSL certificate** (with domain)
- **Optimized configuration**

## Quick Start

```bash
export APP_NAME="my-website"
export DOMAIN="mysite.com"  # optional
sudo ./deploy.sh
```

## Requirements

Your PHP project should have:
- `index.php` or `index.html` file
- PHP files for your application
- Database connection code (optional)

## What Happens

1. **System setup** - Apache, MySQL, PHP installed
2. **Database setup** - MySQL secured with user created
3. **Web server** - Apache virtual host configured
4. **PHP optimization** - Performance settings applied
5. **File deployment** - Your files copied to web directory
6. **SSL setup** - Free certificate if domain provided
7. **phpMyAdmin** - Database management interface

## Environment Variables

```bash
export APP_NAME="my-website"        # Your app name
export PHP_VERSION="8.1"           # PHP version
export MYSQL_VERSION="8.0"         # MySQL version
export DB_NAME="myapp"              # Database name
export DOMAIN="example.com"         # Your domain (optional)
```

## After Deployment

Your LAMP site will be running at:
- Website: `https://yourdomain.com`
- phpMyAdmin: `https://yourdomain.com/phpmyadmin`

### Managing Your Stack

```bash
# Apache status
systemctl status apache2

# MySQL status
systemctl status mysql

# Apache logs
tail -f /var/log/apache2/my-website-access.log

# Restart services
systemctl restart apache2
systemctl restart mysql
```

## Database Connection

The script creates a `config.php` file with database credentials:

```php
<?php
define('DB_HOST', 'localhost');
define('DB_NAME', 'your_db_name');
define('DB_USER', 'your_db_user');
define('DB_PASS', 'your_db_password');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}
?>
```

Use it in your PHP files:

```php
<?php
require_once 'config.php';

// Your database queries here
$stmt = $pdo->query("SELECT * FROM users");
$users = $stmt->fetchAll();
?>
```

## File Structure

Your files are deployed to `/var/www/your-app-name/`:
- Web root: `/var/www/your-app-name/`
- Config file: `/var/www/your-app-name/config.php`
- phpMyAdmin: `/var/www/your-app-name/phpmyadmin/`

## PHP Configuration

The script optimizes PHP settings:
- Upload limit: 64MB
- Post limit: 64MB
- Timezone: UTC
- Error reporting: Off (production)

## Apache Configuration

Virtual host configured with:
- Document root set correctly
- .htaccess support enabled
- Error and access logging
- Security headers

## Database Management

Access phpMyAdmin at `/phpmyadmin` with:
- Username: Your database user
- Password: Generated password (shown after deployment)

## Updating Your Site

1. Update your PHP files
2. Copy to web directory: `cp -r . /var/www/your-app-name/`
3. Set permissions: `chown -R www-data:www-data /var/www/your-app-name/`

## Troubleshooting

**Site not loading?**
- Check Apache: `systemctl status apache2`
- Check logs: `tail -f /var/log/apache2/error.log`
- Test config: `apache2ctl configtest`

**Database connection errors?**
- Test MySQL: `mysql -u username -p database_name`
- Check MySQL: `systemctl status mysql`
- Verify credentials in config.php

**PHP errors?**
- Check PHP version: `php -v`
- Check error logs: `tail -f /var/log/apache2/error.log`
- Verify file permissions

Perfect for WordPress, custom PHP applications, and traditional websites.