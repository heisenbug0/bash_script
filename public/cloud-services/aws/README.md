# AWS Deployment Scripts

Deploy applications to Amazon Web Services (AWS) with production-ready configurations.

## Available Services

### EC2 Instances
Virtual servers for running applications.
- **Node.js** - Express applications with PM2
- **Python** - Django/Flask with Gunicorn

### Lambda Functions
Serverless functions for event-driven applications.
- **Node.js** - API endpoints and event handlers
- **Python** - Coming soon

### RDS Databases
Managed relational databases.
- **PostgreSQL** - Coming soon
- **MySQL** - Coming soon

## Quick Start

### Deploy to EC2
```bash
cd ec2/nodejs/
export INSTANCE_TYPE="t3.micro"
export KEY_PAIR="my-key-pair"
./deploy.sh
```

### Deploy to Lambda
```bash
cd lambda/
export FUNCTION_NAME="my-function"
export RUNTIME="nodejs18.x"
./deploy.sh
```

## What You Get

### EC2 Deployments
- **Instance provisioning** - Correct size and AMI
- **Security groups** - Firewall rules for your app
- **User data** - Automatic setup on boot
- **Elastic IP** - Static IP address
- **Load balancer** - For high availability (optional)

### Lambda Deployments
- **Function packaging** - Code and dependencies
- **IAM role** - Proper permissions
- **API Gateway** - HTTP endpoints (optional)
- **Environment variables** - Configuration
- **Monitoring** - CloudWatch integration

## Requirements

- AWS CLI installed and configured
- AWS credentials with appropriate permissions
- SSH key pair for EC2 deployments
- Application code ready for deployment

## Environment Variables

### EC2 Configuration
```bash
export INSTANCE_TYPE="t3.micro"    # EC2 instance size
export KEY_PAIR="my-key-pair"      # SSH key pair name
export SECURITY_GROUP="web-server" # Security group name
export REGION="us-east-1"          # AWS region
```

### Lambda Configuration
```bash
export FUNCTION_NAME="my-function"  # Lambda function name
export RUNTIME="nodejs18.x"        # Runtime environment
export HANDLER="index.handler"      # Function handler
export MEMORY_SIZE="128"           # Memory allocation (MB)
export TIMEOUT="30"                # Function timeout (seconds)
```

## After Deployment

### EC2 Instance
- SSH access: `ssh -i ~/.ssh/key-name.pem ec2-user@ip-address`
- Web access: `http://ip-address` or your domain
- Logs: `/var/log/cloud-init-output.log` for setup logs

### Lambda Function
- Test in AWS Console
- Invoke with AWS CLI: `aws lambda invoke --function-name my-function output.json`
- API URL provided if API Gateway enabled

## Security Best Practices

All deployments include:
- **Least privilege** IAM roles
- **Security groups** with minimal access
- **Private subnets** for databases (EC2)
- **Environment variables** for secrets
- **CloudWatch** for monitoring and logs

## Coming Soon

- **S3 deployments** - Static website hosting
- **ECS deployments** - Docker container orchestration
- **CloudFront** - CDN for static assets
- **RDS** - Managed database deployments

Each service folder has detailed instructions and examples.