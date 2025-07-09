# Google Cloud Platform (GCP) Deployment Scripts

Comprehensive scripts for deploying applications to various Google Cloud Platform services.

## 📁 Directory Structure

```
gcp/
├── compute-engine/     # Virtual machine deployments
│   ├── nodejs/        # Node.js applications
│   ├── python/        # Python applications
│   ├── go/            # Go applications
│   └── java/          # Java applications
├── cloud-run/         # Serverless container deployments
│   ├── nodejs/        # Node.js containers
│   ├── python/        # Python containers
│   ├── go/            # Go containers
│   └── java/          # Java containers
├── app-engine/        # Platform-as-a-Service deployments
│   ├── standard/      # Standard environment
│   └── flexible/      # Flexible environment
├── kubernetes-engine/ # Managed Kubernetes deployments
│   ├── clusters/      # GKE cluster setup
│   ├── workloads/     # Application deployments
│   └── monitoring/    # Monitoring setup
├── cloud-functions/   # Serverless function deployments
│   ├── nodejs/        # Node.js functions
│   ├── python/        # Python functions
│   ├── go/            # Go functions
│   └── java/          # Java functions
├── cloud-sql/         # Managed database deployments
│   ├── postgresql/    # PostgreSQL instances
│   ├── mysql/         # MySQL instances
│   └── sqlserver/     # SQL Server instances
├── memorystore/       # Managed Redis deployments
├── storage/           # Cloud Storage deployments
└── infrastructure/    # Infrastructure as Code
    ├── terraform/     # Terraform templates
    └── deployment-manager/ # Deployment Manager templates
```

## 🎯 Service Categories

### Compute Services
- **Compute Engine**: Virtual machines for any application
- **Cloud Run**: Serverless containers
- **App Engine**: Platform-as-a-Service
- **Kubernetes Engine**: Managed Kubernetes
- **Cloud Functions**: Serverless functions

### Database Services
- **Cloud SQL**: Managed relational databases
- **Firestore**: NoSQL document database
- **Bigtable**: NoSQL wide-column database
- **Memorystore**: Managed Redis and Memcached

### Storage Services
- **Cloud Storage**: Object storage
- **Persistent Disk**: Block storage
- **Filestore**: Managed file storage

### Networking Services
- **Cloud Load Balancing**: Global load balancing
- **Cloud CDN**: Content delivery network
- **VPC**: Virtual private cloud
- **Cloud DNS**: Domain name system

## 🚀 Quick Start Examples

### Deploy Node.js App to Compute Engine
```bash
cd compute-engine/nodejs/
export PROJECT_ID="my-gcp-project"
export INSTANCE_NAME="nodejs-app"
export ZONE="us-central1-a"
./deploy.sh
```

### Deploy Container to Cloud Run
```bash
cd cloud-run/nodejs/
export PROJECT_ID="my-gcp-project"
export SERVICE_NAME="my-service"
export REGION="us-central1"
./deploy.sh
```

### Deploy to App Engine
```bash
cd app-engine/standard/nodejs/
export PROJECT_ID="my-gcp-project"
export SERVICE_NAME="default"
./deploy.sh
```

### Deploy Function to Cloud Functions
```bash
cd cloud-functions/nodejs/
export PROJECT_ID="my-gcp-project"
export FUNCTION_NAME="my-function"
export REGION="us-central1"
./deploy.sh
```

## 📋 Prerequisites

### GCP CLI Setup
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialize gcloud
gcloud init

# Authenticate
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### Required Permissions
Each service requires specific IAM permissions. The scripts will check for required permissions and provide guidance.

### Environment Variables
```bash
# GCP Configuration
export PROJECT_ID="my-gcp-project"
export REGION="us-central1"
export ZONE="us-central1-a"

# Application Configuration
export APP_NAME="my-application"
export SERVICE_NAME="my-service"
export ENVIRONMENT="production"

# Networking
export VPC_NAME="default"
export SUBNET_NAME="default"
export FIREWALL_RULES="allow-http,allow-https"
```

## 📝 Service-Specific Features

### Compute Engine Deployments
- ✅ Instance provisioning and configuration
- ✅ Custom machine types
- ✅ Startup scripts
- ✅ Load balancer setup
- ✅ Auto scaling configuration
- ✅ Monitoring setup

### Cloud Run Deployments
- ✅ Container deployment
- ✅ Automatic scaling
- ✅ Traffic management
- ✅ Custom domains
- ✅ Environment variables
- ✅ Secret management

### App Engine Deployments
- ✅ Application deployment
- ✅ Version management
- ✅ Traffic splitting
- ✅ Automatic scaling
- ✅ Cron jobs
- ✅ Task queues

### Kubernetes Engine Deployments
- ✅ Cluster creation and management
- ✅ Workload deployment
- ✅ Service mesh integration
- ✅ Auto scaling
- ✅ Monitoring and logging

### Cloud Functions Deployments
- ✅ Function deployment
- ✅ Trigger configuration
- ✅ Environment variables
- ✅ Secret management
- ✅ Monitoring setup

### Cloud SQL Deployments
- ✅ Database instance creation
- ✅ High availability setup
- ✅ Backup configuration
- ✅ Read replicas
- ✅ Security configuration

## 🔧 Configuration Examples

### Compute Engine Configuration
```bash
# Instance specifications
export MACHINE_TYPE="e2-medium"
export BOOT_DISK_SIZE="20GB"
export BOOT_DISK_TYPE="pd-standard"
export IMAGE_FAMILY="ubuntu-2004-lts"
export IMAGE_PROJECT="ubuntu-os-cloud"

# Network configuration
export NETWORK_TIER="STANDARD"
export SUBNET="default"
export EXTERNAL_IP="ephemeral"

# Metadata
export STARTUP_SCRIPT="startup-script.sh"
export SERVICE_ACCOUNT="default"
```

### Cloud Run Configuration
```bash
# Service specifications
export CPU="1"
export MEMORY="512Mi"
export MAX_INSTANCES="100"
export MIN_INSTANCES="0"
export CONCURRENCY="80"

# Container configuration
export IMAGE_URL="gcr.io/PROJECT_ID/SERVICE_NAME"
export PORT="8080"
export TIMEOUT="300"

# Traffic configuration
export ALLOW_UNAUTHENTICATED="true"
export INGRESS="all"
```

### App Engine Configuration
```yaml
# app.yaml
runtime: nodejs18

env_variables:
  NODE_ENV: production
  DATABASE_URL: postgresql://user:pass@host/db

automatic_scaling:
  min_instances: 1
  max_instances: 10
  target_cpu_utilization: 0.6

resources:
  cpu: 1
  memory_gb: 0.5
  disk_size_gb: 10

handlers:
- url: /.*
  script: auto
  secure: always
```

### Cloud Functions Configuration
```bash
# Function specifications
export RUNTIME="nodejs18"
export ENTRY_POINT="helloWorld"
export MEMORY="256MB"
export TIMEOUT="60s"
export MAX_INSTANCES="100"

# Trigger configuration
export TRIGGER_TYPE="http"
export TRIGGER_RESOURCE=""
export TRIGGER_EVENT=""

# Environment variables
export ENV_VARS="NODE_ENV=production,API_KEY=secret"
```

## 🛠️ Infrastructure as Code

### Terraform Example
```hcl
# main.tf
provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "web_server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = file("startup-script.sh")

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["web-server", "http-server", "https-server"]
}

resource "google_compute_firewall" "web_firewall" {
  name    = "allow-web-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}
```

### Deployment Manager Example
```yaml
# deployment.yaml
resources:
- name: web-server
  type: compute.v1.instance
  properties:
    zone: us-central1-a
    machineType: zones/us-central1-a/machineTypes/e2-medium
    disks:
    - deviceName: boot
      type: PERSISTENT
      boot: true
      autoDelete: true
      initializeParams:
        sourceImage: projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts
        diskSizeGb: 20
    networkInterfaces:
    - network: global/networks/default
      accessConfigs:
      - name: External NAT
        type: ONE_TO_ONE_NAT
    metadata:
      items:
      - key: startup-script
        value: |
          #!/bin/bash
          apt-get update
          apt-get install -y nginx
          systemctl start nginx
          systemctl enable nginx
    tags:
      items:
      - web-server
      - http-server

- name: web-firewall
  type: compute.v1.firewall
  properties:
    allowed:
    - IPProtocol: TCP
      ports:
      - "80"
      - "443"
    sourceRanges:
    - "0.0.0.0/0"
    targetTags:
    - web-server
```

## 🔍 Monitoring and Logging

### Cloud Monitoring Integration
- Application metrics
- Custom dashboards
- Alerting policies
- SLI/SLO monitoring
- Performance monitoring

### Cloud Logging
- Centralized logging
- Log-based metrics
- Log exports
- Error reporting
- Audit logs

### Cloud Trace
- Distributed tracing
- Performance analysis
- Latency insights
- Request flow visualization

## 💰 Cost Optimization

### Best Practices
- Right-sizing resources
- Committed use discounts
- Preemptible instances
- Auto scaling configuration
- Resource scheduling

### Cost Monitoring
- Budget alerts
- Cost breakdown
- Resource utilization
- Billing exports
- Cost optimization recommendations

## 🔒 Security Best Practices

### IAM Configuration
- Principle of least privilege
- Service accounts
- Role-based access control
- Identity federation

### Network Security
- VPC configuration
- Firewall rules
- Private Google Access
- Cloud NAT
- Load balancer security

### Data Protection
- Encryption at rest
- Encryption in transit
- Secret management
- Key management
- Data loss prevention

## 🔗 Related Documentation

- [Database Scripts](../../databases/README.md)
- [Caching Scripts](../../caching/README.md)
- [Framework Scripts](../../frameworks/README.md)