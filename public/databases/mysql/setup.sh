#!/bin/bash

# MySQL Database Setup
# Installs and configures MySQL with user and database

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/common.sh"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/validation.sh"

# Configuration
DB_NAME="${DB_NAME:-myapp}"
DB_USER="${DB_USER:-appuser}"
DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-16)}"
ROOT_PASSWORD="${ROOT_PASSWORD:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-16)}"
MYSQL_VERSION="${MYSQL_VERSION:-8.0}"

main() {
    log_step "Starting MySQL setup"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    # Detect OS and update
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    update_system
    
    # Install MySQL
    log_step "Installing MySQL $MYSQL_VERSION"
    export DEBIAN_FRONTEND=noninteractive
    install_package mysql-server
    
    # Start and enable MySQL
    systemctl start mysql
    systemctl enable mysql
    
    # Wait for MySQL to start
    sleep 3
    
    # Secure MySQL installation
    log_step "Securing MySQL installation"
    mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    # Create database and user
    log_step "Creating database and user"
    mysql -u root -p"$ROOT_PASSWORD" << EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Test connection
    if mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
        log_info "Database connection test successful"
    else
        log_error "Database connection test failed"
        exit 1
    fi
    
    # Configure MySQL for better performance
    log_step "Optimizing MySQL configuration"
    cat >> /etc/mysql/mysql.conf.d/mysqld.cnf << EOF

# Performance tuning
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
query_cache_type = 1
query_cache_size = 32M
max_connections = 100
EOF
    
    systemctl restart mysql
    
    # Create backup script
    log_step "Creating backup script"
    cat > /usr/local/bin/mysql-backup.sh << EOF
#!/bin/bash
BACKUP_DIR="/var/backups/mysql"
DATE=\$(date +%Y%m%d_%H%M%S)
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASSWORD="$DB_PASSWORD"

mkdir -p "\$BACKUP_DIR"

mysqldump -u "\$DB_USER" -p"\$DB_PASSWORD" "\$DB_NAME" | gzip > "\$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz"

# Keep only last 7 days of backups
find "\$BACKUP_DIR" -name "\${DB_NAME}_*.sql.gz" -mtime +7 -delete

echo "Backup completed: \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz"
EOF
    
    chmod +x /usr/local/bin/mysql-backup.sh
    mkdir -p /var/backups/mysql
    
    log_success "MySQL setup complete!"
    echo
    echo "Database: $DB_NAME"
    echo "User: $DB_USER"
    echo "Password: $DB_PASSWORD"
    echo "Root Password: $ROOT_PASSWORD"
    echo "Connection: mysql://$DB_USER:$DB_PASSWORD@localhost:3306/$DB_NAME"
    echo
    echo "Connect: mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME"
    echo "Backup: /usr/local/bin/mysql-backup.sh"
    echo "Status: systemctl status mysql"
}

main "$@"