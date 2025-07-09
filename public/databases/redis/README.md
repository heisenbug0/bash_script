# Redis Deployment Scripts

Scripts for deploying Redis in various environments and configurations.

## 📁 Available Scripts

### Installation Scripts
- `setup.sh` - Basic Redis installation
- `docker-setup.sh` - Docker-based deployment
- `cluster-setup.sh` - Redis cluster configuration
- `sentinel-setup.sh` - Redis Sentinel for high availability

### Cloud Deployments
- `aws-elasticache-setup.sh` - AWS ElastiCache
- `gcp-memorystore-setup.sh` - Google Cloud Memorystore
- `azure-redis-setup.sh` - Azure Cache for Redis

### Management Scripts
- `backup.sh` - Redis backup script
- `restore.sh` - Redis restore script
- `monitoring.sh` - Monitoring setup
- `security.sh` - Security hardening

## 🚀 Quick Start

### Local Installation
```bash
# Ubuntu/Debian
sudo ./setup.sh

# With Docker
./docker-setup.sh

# Redis cluster
./cluster-setup.sh
```

### Cloud Deployment
```bash
# AWS ElastiCache
./aws-elasticache-setup.sh

# Google Cloud Memorystore
./gcp-memorystore-setup.sh
```

## 📋 Prerequisites

- Root or sudo access (for local installation)
- Docker (for containerized deployment)
- Cloud CLI tools (for cloud deployment)

## 🔧 Configuration

Set environment variables before running:

```bash
export REDIS_PASSWORD="securepassword"
export REDIS_PORT="6379"
export REDIS_VERSION="7.0"
export REDIS_MAXMEMORY="256mb"
export REDIS_MAXMEMORY_POLICY="allkeys-lru"
```

## 📝 Features

- ✅ Multiple Redis versions support
- ✅ Automatic security configuration
- ✅ Performance tuning
- ✅ Backup and recovery setup
- ✅ Monitoring and alerting
- ✅ SSL/TLS encryption
- ✅ Cluster configuration
- ✅ Sentinel setup
- ✅ Memory optimization