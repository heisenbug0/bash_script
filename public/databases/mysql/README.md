# MySQL Deployment Scripts

Scripts for deploying MySQL database in various environments and configurations.

## 📁 Available Scripts

### Installation Scripts
- `setup.sh` - Basic MySQL installation
- `docker-setup.sh` - Docker-based deployment
- `cluster-setup.sh` - High-availability cluster setup

### Cloud Deployments
- `aws-rds-setup.sh` - AWS RDS MySQL
- `gcp-cloudsql-setup.sh` - Google Cloud SQL
- `azure-mysql-setup.sh` - Azure Database for MySQL

### Management Scripts
- `backup.sh` - Database backup script
- `restore.sh` - Database restore script
- `monitoring.sh` - Monitoring setup
- `security.sh` - Security hardening

## 🚀 Quick Start

### Local Installation
```bash
# Ubuntu/Debian
sudo ./setup.sh

# With Docker
./docker-setup.sh

# High-availability cluster
./cluster-setup.sh
```

### Cloud Deployment
```bash
# AWS RDS
./aws-rds-setup.sh

# Google Cloud SQL
./gcp-cloudsql-setup.sh
```

## 📋 Prerequisites

- Root or sudo access (for local installation)
- Docker (for containerized deployment)
- Cloud CLI tools (for cloud deployment)

## 🔧 Configuration

Set environment variables before running:

```bash
export MYSQL_DATABASE="myapp"
export MYSQL_USER="appuser"
export MYSQL_PASSWORD="securepassword"
export MYSQL_PORT="3306"
export MYSQL_VERSION="8.0"
```

## 📝 Features

- ✅ Multiple MySQL versions support
- ✅ Automatic security configuration
- ✅ Performance tuning
- ✅ Backup and recovery setup
- ✅ Monitoring and alerting
- ✅ SSL/TLS encryption
- ✅ User and role management
- ✅ Replication setup