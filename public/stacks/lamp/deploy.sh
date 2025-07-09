#!/bin/bash

# Deploy LAMP stack (Linux, Apache, MySQL, PHP)
# Classic web development stack

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/common.sh"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/validation.sh"

# Configuration
APP_NAME="${APP_NAME:-lamp-app}"
PHP_VERSION="${PHP_VERSION:-8.1}"
MYSQL_VERSION="${MYSQL_VERSION:-8.0}"
DB_NAME="${DB_NAME:-${APP_NAME//-/_}}"
DB_USER="${DB_USER:-${APP_NAME//-/_}_user}"
DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-16)}"
DOMAIN="${DOMAIN:-}"

main() {
    log_step "Starting LAMP stack deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    # Detect OS and update
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    update_system
    
    # Install Apache
    log_step "Installing Apache web server"
    install_package apache2
    systemctl start apache2
    systemctl enable apache2
    
    # Install MySQL
    log_step "Installing MySQL $MYSQL_VERSION"
    export DEBIAN_FRONTEND=noninteractive
    install_package mysql-server
    systemctl start mysql
    systemctl enable mysql
    
    # Secure MySQL installation
    mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    # Create application database
    mysql -u root -p"$DB_PASSWORD" << EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Install PHP
    log_step "Installing PHP $PHP_VERSION"
    install_package "php$PHP_VERSION" "php$PHP_VERSION-mysql" "php$PHP_VERSION-curl" "php$PHP_VERSION-json" "php$PHP_VERSION-mbstring" "php$PHP_VERSION-xml" libapache2-mod-php
    
    # Enable PHP module
    a2enmod php$PHP_VERSION
    
    # Deploy application files
    log_step "Deploying application"
    
    # Remove default Apache page
    rm -f /var/www/html/index.html
    
    # Copy application files or create a sample
    if [ -f "index.php" ]; then
        cp -r . /var/www/html/
    else
        # Create a sample PHP application
        cat > /var/www/html/index.php << EOF
<?php
\$servername = "localhost";
\$username = "$DB_USER";
\$password = "$DB_PASSWORD";
\$dbname = "$DB_NAME";

try {
    \$pdo = new PDO("mysql:host=\$servername;dbname=\$dbname", \$username, \$password);
    \$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    \$db_status = "Connected successfully";
} catch(PDOException \$e) {
    \$db_status = "Connection failed: " . \$e->getMessage();
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>$APP_NAME - LAMP Stack</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 20px; border-radius: 5px; margin: 20px 0; }
        .success { background-color: #d4edda; color: #155724; }
        .info { background-color: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <h1>$APP_NAME</h1>
    <div class="status info">
        <h3>LAMP Stack Information</h3>
        <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
        <p><strong>Server:</strong> <?php echo \$_SERVER['SERVER_SOFTWARE']; ?></p>
        <p><strong>Database:</strong> <?php echo \$db_status; ?></p>
    </div>
    
    <div class="status success">
        <h3>Deployment Successful!</h3>
        <p>Your LAMP stack is running correctly.</p>
        <p>Database: $DB_NAME</p>
        <p>User: $DB_USER</p>
    </div>
</body>
</html>
EOF
    fi
    
    # Set proper permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    # Configure Apache virtual host if domain provided
    if [ -n "$DOMAIN" ]; then
        log_step "Configuring virtual host for $DOMAIN"
        
        cat > "/etc/apache2/sites-available/$APP_NAME.conf" << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${APP_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${APP_NAME}_access.log combined
</VirtualHost>
EOF
        
        a2ensite "$APP_NAME"
        a2dissite 000-default
        
        # Enable mod_rewrite for pretty URLs
        a2enmod rewrite
        
        systemctl restart apache2
        
        # Setup SSL
        log_step "Setting up SSL certificate"
        install_package certbot python3-certbot-apache
        certbot --apache -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    else
        systemctl restart apache2
    fi
    
    log_success "LAMP stack deployed successfully!"
    echo
    echo "Application: $APP_NAME"
    echo "Web server: Apache"
    echo "Database: MySQL"
    echo "PHP Version: $PHP_VERSION"
    echo
    echo "Database Details:"
    echo "  Name: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  Password: $DB_PASSWORD"
    echo "  Root Password: $DB_PASSWORD"
    echo
    if [ -n "$DOMAIN" ]; then
        echo "URL: https://$DOMAIN"
    else
        echo "URL: http://$(curl -s ifconfig.me)"
    fi
    echo
    echo "Files: /var/www/html"
    echo "Logs: /var/log/apache2/"
    echo "MySQL: mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME"
}

main "$@"