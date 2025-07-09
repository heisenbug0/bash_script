#!/bin/bash

# Deploy LAMP Stack (Linux + Apache + MySQL + PHP)
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
DOCUMENT_ROOT="${DOCUMENT_ROOT:-/var/www/$APP_NAME}"

main() {
    log_step "Starting LAMP Stack deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    # Check for PHP files
    if [ ! -f "index.php" ] && [ ! -f "index.html" ]; then
        log_error "No index.php or index.html found in current directory"
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
    
    # Create application database and user
    log_step "Setting up database"
    mysql -u root -p"$DB_PASSWORD" << EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Install PHP
    log_step "Installing PHP $PHP_VERSION"
    install_package php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-zip
    
    # Configure PHP
    sed -i 's/;date.timezone =/date.timezone = UTC/' /etc/php/*/apache2/php.ini
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/*/apache2/php.ini
    sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php/*/apache2/php.ini
    
    # Deploy application files
    log_step "Deploying application files"
    mkdir -p "$DOCUMENT_ROOT"
    cp -r . "$DOCUMENT_ROOT/"
    chown -R www-data:www-data "$DOCUMENT_ROOT"
    chmod -R 755 "$DOCUMENT_ROOT"
    
    # Create database configuration file
    cat > "$DOCUMENT_ROOT/config.php" << EOF
<?php
define('DB_HOST', 'localhost');
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASS', '$DB_PASSWORD');

try {
    \$pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    \$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException \$e) {
    die("Connection failed: " . \$e->getMessage());
}
?>
EOF
    
    # Configure Apache virtual host
    log_step "Configuring Apache virtual host"
    cat > "/etc/apache2/sites-available/$APP_NAME.conf" << EOF
<VirtualHost *:80>
    ServerName ${DOMAIN:-localhost}
    DocumentRoot $DOCUMENT_ROOT
    
    <Directory $DOCUMENT_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/$APP_NAME-error.log
    CustomLog \${APACHE_LOG_DIR}/$APP_NAME-access.log combined
</VirtualHost>
EOF
    
    # Enable site and modules
    a2ensite "$APP_NAME"
    a2dissite 000-default
    a2enmod rewrite
    
    # Test and restart Apache
    apache2ctl configtest
    systemctl restart apache2
    
    # Setup SSL if domain provided
    if [ -n "$DOMAIN" ]; then
        log_step "Setting up SSL certificate"
        install_package certbot python3-certbot-apache
        certbot --apache -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    fi
    
    # Install phpMyAdmin (optional)
    log_step "Installing phpMyAdmin"
    install_package phpmyadmin
    
    # Create symbolic link for phpMyAdmin
    ln -sf /usr/share/phpmyadmin "$DOCUMENT_ROOT/phpmyadmin"
    
    log_success "LAMP Stack deployed successfully!"
    echo
    echo "Stack: $APP_NAME"
    echo "Document Root: $DOCUMENT_ROOT"
    echo "Database: $DB_NAME"
    echo "DB User: $DB_USER"
    echo "DB Password: $DB_PASSWORD"
    echo "MySQL Root Password: $DB_PASSWORD"
    if [ -n "$DOMAIN" ]; then
        echo "URL: https://$DOMAIN"
        echo "phpMyAdmin: https://$DOMAIN/phpmyadmin"
    else
        echo "URL: http://$(curl -s ifconfig.me)"
        echo "phpMyAdmin: http://$(curl -s ifconfig.me)/phpmyadmin"
    fi
    echo
    echo "Apache: systemctl status|restart apache2"
    echo "MySQL: systemctl status|restart mysql"
    echo "Logs: /var/log/apache2/$APP_NAME-*.log"
}

main "$@"