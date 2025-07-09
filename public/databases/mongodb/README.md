# MongoDB Deployment Scripts

Scripts for deploying MongoDB database in various environments and configurations.

## 📁 Available Scripts

### Installation Scripts
- `setup.sh` - Basic MongoDB installation
- `docker-setup.sh` - Docker-based deployment
- `replica-set-setup.sh` - Replica set configuration
- `sharded-cluster-setup.sh` - Sharded cluster setup

### Cloud Deployments
- `aws-documentdb-setup.sh` - AWS DocumentDB
- `mongodb-atlas-setup.sh` - MongoDB Atlas
- `gcp-mongodb-setup.sh` - Google Cloud MongoDB

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

# Replica set
./replica-set-setup.sh
```

### Cloud Deployment
```bash
# MongoDB Atlas
./mongodb-atlas-setup.sh

# AWS DocumentDB
./aws-documentdb-setup.sh
```

## 📋 Prerequisites

- Root or sudo access (for local installation)
- Docker (for containerized deployment)
- Cloud CLI tools (for cloud deployment)

## 🔧 Configuration

Set environment variables before running:

```bash
export MONGO_INITDB_DATABASE="myapp"
export MONGO_INITDB_ROOT_USERNAME="admin"
export MONGO_INITDB_ROOT_PASSWORD="securepassword"
export MONGO_PORT="27017"
export MONGODB_VERSION="6.0"
```

## 📝 Features

- ✅ Multiple MongoDB versions support
- ✅ Automatic security configuration
- ✅ Performance tuning
- ✅ Backup and recovery setup
- ✅ Monitoring and alerting
- ✅ SSL/TLS encryption
- ✅ User and role management
- ✅ Replica set configuration
- ✅ Sharding support