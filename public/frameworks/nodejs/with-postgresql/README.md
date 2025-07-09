# Node.js + PostgreSQL Deployment Scripts

Deploy Node.js applications with PostgreSQL database integration across various platforms.

## 📁 Available Deployments

```
with-postgresql/
├── vps/
│   ├── ubuntu/         # Ubuntu VPS with PostgreSQL
│   ├── debian/         # Debian VPS with PostgreSQL
│   ├── centos/         # CentOS VPS with PostgreSQL
│   └── generic/        # Generic Linux deployment
├── cloud/
│   ├── aws-ec2/        # AWS EC2 with RDS PostgreSQL
│   ├── aws-rds/        # AWS RDS managed PostgreSQL
│   ├── gcp-compute/    # GCP Compute with Cloud SQL
│   ├── gcp-cloudsql/   # GCP Cloud SQL managed
│   ├── azure-vm/       # Azure VM with PostgreSQL
│   └── digitalocean/   # DigitalOcean with managed DB
├── hosting/
│   ├── render/         # Render with PostgreSQL service
│   ├── railway/        # Railway with PostgreSQL
│   └── heroku/         # Heroku with PostgreSQL addon
└── containers/
    ├── docker-compose/ # Docker Compose setup
    └── kubernetes/     # Kubernetes deployment
```

## 🎯 Use Cases

### Web Applications
- E-commerce platforms
- Content management systems
- User management systems
- Blog platforms
- Social media applications

### API Services
- RESTful APIs with persistent data
- GraphQL APIs
- Authentication services
- Data processing APIs
- Analytics platforms

### Business Applications
- CRM systems
- Inventory management
- Financial applications
- Reporting systems
- Dashboard applications

## 🚀 Quick Start

### VPS Deployment
```bash
# Ubuntu VPS with local PostgreSQL
cd vps/ubuntu/
export APP_NAME="my-webapp"
export DB_NAME="myapp"
export DB_USER="appuser"
export DOMAIN="app.example.com"
sudo ./deploy.sh
```

### Cloud Deployment with Managed Database
```bash
# AWS EC2 with RDS PostgreSQL
cd cloud/aws-rds/
export DB_INSTANCE_CLASS="db.t3.micro"
export DB_NAME="myapp"
export MULTI_AZ="false"
./deploy.sh
```

### Hosting Platform
```bash
# Render with PostgreSQL service
cd hosting/render/
export SERVICE_NAME="my-webapp"
export DB_NAME="myapp_db"
./deploy.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-webapp"
export NODE_VERSION="18"
export PORT="3000"
export NODE_ENV="production"

# Database Configuration
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
export DB_USER="appuser"
export DB_PASSWORD="securepassword"
export DB_SSL="require"
export DB_POOL_SIZE="10"

# PostgreSQL Version
export POSTGRES_VERSION="15"

# SSL Configuration
export DOMAIN="example.com"
export SSL_EMAIL="admin@example.com"

# Backup Configuration
export BACKUP_ENABLED="true"
export BACKUP_SCHEDULE="0 2 * * *"
export BACKUP_RETENTION="7"
```

### Database Connection Examples

#### Using pg (node-postgres)
```javascript
// db.js
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'require' ? { rejectUnauthorized: false } : false,
  max: parseInt(process.env.DB_POOL_SIZE) || 10,
});

module.exports = pool;
```

#### Using Sequelize ORM
```javascript
// models/index.js
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: 'postgres',
    ssl: process.env.DB_SSL === 'require',
    pool: {
      max: parseInt(process.env.DB_POOL_SIZE) || 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

module.exports = sequelize;
```

#### Using Prisma
```javascript
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
}
```

## 📝 Features

### Database Management
- ✅ PostgreSQL installation and configuration
- ✅ Database and user creation
- ✅ Connection pooling setup
- ✅ SSL/TLS encryption
- ✅ Performance optimization
- ✅ Backup and restore scripts

### Application Features
- ✅ Database migration support
- ✅ Connection health checks
- ✅ Query logging and monitoring
- ✅ Transaction management
- ✅ Error handling and recovery

### Security
- ✅ Database user permissions
- ✅ Network security rules
- ✅ SSL certificate setup
- ✅ Password encryption
- ✅ SQL injection protection

### Monitoring & Maintenance
- ✅ Database performance monitoring
- ✅ Query performance analysis
- ✅ Automated backups
- ✅ Log rotation
- ✅ Health checks

## 🛠️ Prerequisites

### System Requirements
- Linux server with minimum 1GB RAM (2GB+ recommended)
- Root or sudo access
- Internet connection
- Sufficient disk space for database

### Application Requirements
- Node.js application with PostgreSQL dependency
- Database migration scripts (optional)
- Environment variable configuration
- Health check endpoints

### Required npm Packages
```json
{
  "dependencies": {
    "pg": "^8.8.0",
    // OR
    "sequelize": "^6.25.0",
    "pg-hstore": "^2.3.4",
    // OR
    "@prisma/client": "^4.6.0"
  },
  "devDependencies": {
    "prisma": "^4.6.0"
  }
}
```

## 📚 Migration Examples

### Raw SQL Migrations
```sql
-- migrations/001_create_users.sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

### Sequelize Migrations
```javascript
// migrations/20231201000000-create-user.js
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('Users', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      email: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true
      },
      name: {
        type: Sequelize.STRING
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('Users');
  }
};
```

### Prisma Migrations
```bash
# Generate migration
npx prisma migrate dev --name init

# Deploy to production
npx prisma migrate deploy
```

## 🔍 Troubleshooting

### Database Connection Issues
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection
psql -h localhost -U appuser -d myapp

# Check logs
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

### Performance Issues
```bash
# Check active connections
SELECT count(*) FROM pg_stat_activity;

# Check slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

# Check database size
SELECT pg_size_pretty(pg_database_size('myapp'));
```

### Backup and Restore
```bash
# Create backup
pg_dump -h localhost -U appuser myapp > backup.sql

# Restore backup
psql -h localhost -U appuser myapp < backup.sql

# Automated backup script location
/usr/local/bin/postgres-backup.sh myapp
```

## 🔗 Related Documentation

- [PostgreSQL Scripts](../../../databases/postgresql/README.md)
- [Cloud Services](../../../cloud-services/README.md)
- [Hosting Platforms](../../../hosting/README.md)