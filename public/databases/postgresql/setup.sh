#!/bin/bash

# PostgreSQL Database Setup
# Installs and configures PostgreSQL with user and database

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
POSTGRES_VERSION="${POSTGRES_VERSION:-15}"

main() {
    log_step "Starting PostgreSQL setup"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    # Detect OS and update
    detect_os
    log_info "Detected: $OS_NAME $OS_VERSION"
    update_system
    
    # Install PostgreSQL
    log_step "Installing PostgreSQL $POSTGRES_VERSION"
    case "$OS_ID" in
        ubuntu|debian)
            # Add PostgreSQL official repository
            curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
            echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/postgresql.list
            apt update
            install_package postgresql-$POSTGRES_VERSION postgresql-client-$POSTGRES_VERSION postgresql-contrib-$POSTGRES_VERSION
            ;;
        centos|rhel|fedora)
            install_package postgresql-server postgresql-contrib
            postgresql-setup initdb
            ;;
    esac
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Wait for PostgreSQL to start
    sleep 3
    
    # Create database and user
    log_step "Creating database and user"
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF
    
    # Test connection
    if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
        log_info "Database connection test successful"
    else
        log_error "Database connection test failed"
        exit 1
    fi
    
    # Configure PostgreSQL for better performance
    log_step "Optimizing PostgreSQL configuration"
    PG_CONFIG="/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
    if [ -f "$PG_CONFIG" ]; then
        cp "$PG_CONFIG" "$PG_CONFIG.backup"
        
        # Basic performance tuning
        sed -i "s/#shared_buffers = 128MB/shared_buffers = 256MB/" "$PG_CONFIG"
        sed -i "s/#effective_cache_size = 4GB/effective_cache_size = 1GB/" "$PG_CONFIG"
        sed -i "s/#maintenance_work_mem = 64MB/maintenance_work_mem = 64MB/" "$PG_CONFIG"
        sed -i "s/#checkpoint_completion_target = 0.5/checkpoint_completion_target = 0.9/" "$PG_CONFIG"
        sed -i "s/#wal_buffers = -1/wal_buffers = 16MB/" "$PG_CONFIG"
        sed -i "s/#random_page_cost = 4.0/random_page_cost = 1.1/" "$PG_CONFIG"
        
        systemctl restart postgresql
    fi
    
    # Create backup script
    log_step "Creating backup script"
    cat > /usr/local/bin/postgres-backup.sh << EOF
#!/bin/bash
BACKUP_DIR="/var/backups/postgresql"
DATE=\$(date +%Y%m%d_%H%M%S)
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"

mkdir -p "\$BACKUP_DIR"

PGPASSWORD="$DB_PASSWORD" pg_dump -h localhost -U "\$DB_USER" "\$DB_NAME" | gzip > "\$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz"

# Keep only last 7 days of backups
find "\$BACKUP_DIR" -name "\${DB_NAME}_*.sql.gz" -mtime +7 -delete

echo "Backup completed: \$BACKUP_DIR/\${DB_NAME}_\${DATE}.sql.gz"
EOF
    
    chmod +x /usr/local/bin/postgres-backup.sh
    mkdir -p /var/backups/postgresql
    
    log_success "PostgreSQL setup complete!"
    echo
    echo "Database: $DB_NAME"
    echo "User: $DB_USER"
    echo "Password: $DB_PASSWORD"
    echo "Connection: postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
    echo
    echo "Connect: psql -h localhost -U $DB_USER -d $DB_NAME"
    echo "Backup: /usr/local/bin/postgres-backup.sh"
    echo "Status: systemctl status postgresql"
}

main "$@"