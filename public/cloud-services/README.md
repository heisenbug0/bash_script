# Cloud Services Deployment Scripts

Deploy applications to major cloud providers with production-ready configurations.

## Available Cloud Providers

### Amazon Web Services (AWS)
- **EC2** - Virtual servers for applications
- **Lambda** - Serverless functions
- **RDS** - Managed databases (coming soon)
- **S3** - Object storage (coming soon)

### Google Cloud Platform (GCP)
- Coming soon

### Microsoft Azure
- Coming soon

## Quick Start

### AWS Deployments
```bash
# EC2 Node.js deployment
cd aws/ec2/nodejs/
export INSTANCE_TYPE="t3.micro"
export KEY_PAIR="my-key-pair"
./deploy.sh

# Lambda function deployment
cd aws/lambda/
export FUNCTION_NAME="my-function"
export RUNTIME="nodejs18.x"
./deploy.sh
```

## What You Get

### AWS Deployments
- **Infrastructure as Code** - Automated provisioning
- **Security best practices** - Least privilege access
- **Monitoring** - CloudWatch integration
- **Scaling** - Auto-scaling configurations
- **Cost optimization** - Right-sized resources

## Requirements

- Cloud provider CLI tools installed
- Authentication configured
- Application code ready for deployment

## Environment Variables

Common settings across cloud providers:

```bash
# General
export APP_NAME="my-app"           # Application name
export REGION="us-east-1"          # Cloud region

# Authentication (if not using CLI defaults)
export AWS_PROFILE="default"       # AWS CLI profile
export AWS_ACCESS_KEY_ID="..."     # AWS access key
export AWS_SECRET_ACCESS_KEY="..." # AWS secret key
```

## After Deployment

Each script provides:
- **Access details** - URLs, IPs, connection strings
- **Credentials** - Generated passwords and keys
- **Management commands** - How to update, monitor, scale
- **Logs** - Where to find application logs

## Security Features

All cloud deployments include:
- **Secure defaults** - Minimal exposed ports
- **Encryption** - Data at rest and in transit
- **Identity management** - Proper IAM/IAP setup
- **Secrets handling** - Environment variables for secrets
- **Monitoring** - Logging and alerting

## Coming Soon

- **GCP deployments** - Compute Engine, Cloud Run, Cloud SQL
- **Azure deployments** - VMs, App Service, Azure SQL
- **Kubernetes** - EKS, GKE, AKS deployments
- **Serverless** - More function deployments
- **Databases** - Managed database services

Each cloud provider folder has detailed instructions and examples.