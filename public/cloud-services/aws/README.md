# AWS Deployment Scripts

Comprehensive scripts for deploying applications to various Amazon Web Services.

## 📁 Directory Structure

```
aws/
├── ec2/                # Elastic Compute Cloud
│   ├── nodejs/         # Node.js applications
│   ├── python/         # Python applications
│   ├── php/            # PHP applications
│   ├── java/           # Java applications
│   └── static/         # Static websites
├── ecs/                # Elastic Container Service
│   ├── fargate/        # Serverless containers
│   └── ec2-launch/     # EC2-backed containers
├── lambda/             # Serverless functions
│   ├── nodejs/         # Node.js functions
│   ├── python/         # Python functions
│   ├── java/           # Java functions
│   └── go/             # Go functions
├── elastic-beanstalk/  # Platform-as-a-Service
│   ├── nodejs/         # Node.js applications
│   ├── python/         # Python applications
│   ├── php/            # PHP applications
│   └── java/           # Java applications
├── lightsail/          # Simplified cloud platform
├── amplify/            # Full-stack development platform
├── s3/                 # Static website hosting
├── cloudfront/         # CDN deployments
├── rds/                # Managed databases
│   ├── postgresql/     # PostgreSQL databases
│   ├── mysql/          # MySQL databases
│   └── aurora/         # Aurora databases
├── elasticache/        # Managed caching
│   ├── redis/          # Redis clusters
│   └── memcached/      # Memcached clusters
└── infrastructure/     # Infrastructure as Code
    ├── terraform/      # Terraform templates
    ├── cloudformation/ # CloudFormation templates
    └── cdk/            # AWS CDK
```

## 🎯 Service Categories

### Compute Services
- **EC2**: Virtual servers for any application
- **ECS**: Container orchestration service
- **Lambda**: Serverless function execution
- **Elastic Beanstalk**: Easy application deployment
- **Lightsail**: Simplified virtual private servers

### Storage Services
- **S3**: Object storage and static website hosting
- **EFS**: Elastic file system
- **EBS**: Block storage for EC2

### Database Services
- **RDS**: Managed relational databases
- **DynamoDB**: NoSQL database service
- **ElastiCache**: In-memory caching
- **Aurora**: High-performance relational database

### Networking & Content Delivery
- **CloudFront**: Global content delivery network
- **Route 53**: DNS web service
- **VPC**: Virtual private cloud
- **Load Balancers**: Application and network load balancing

## 🚀 Quick Start Examples

### Deploy Node.js App to EC2
```bash
cd ec2/nodejs/
export APP_NAME="my-node-app"
export INSTANCE_TYPE="t3.micro"
export KEY_PAIR="my-keypair"
./deploy.sh
```

### Deploy Container to ECS Fargate
```bash
cd ecs/fargate/
export CLUSTER_NAME="my-cluster"
export SERVICE_NAME="my-service"
export IMAGE_URI="my-account.dkr.ecr.region.amazonaws.com/my-app:latest"
./deploy.sh
```

### Deploy Serverless Function
```bash
cd lambda/nodejs/
export FUNCTION_NAME="my-function"
export RUNTIME="nodejs18.x"
./deploy.sh
```

### Deploy Static Site to S3 + CloudFront
```bash
cd s3/static-website/
export BUCKET_NAME="my-website-bucket"
export DOMAIN="example.com"
./deploy.sh
```

## 📋 Prerequisites

### AWS CLI Setup
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
```

### Required Permissions
Each service requires specific IAM permissions. The scripts will check for required permissions and provide guidance.

### Environment Variables
```bash
# AWS Configuration
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"

# Application Configuration
export APP_NAME="my-application"
export ENVIRONMENT="production"

# Networking
export VPC_ID="vpc-12345678"
export SUBNET_IDS="subnet-12345678,subnet-87654321"
export SECURITY_GROUP_ID="sg-12345678"
```

## 📝 Service-Specific Features

### EC2 Deployments
- ✅ Instance provisioning and configuration
- ✅ Security group setup
- ✅ Key pair management
- ✅ Elastic IP assignment
- ✅ Load balancer configuration
- ✅ Auto Scaling setup
- ✅ CloudWatch monitoring

### ECS Deployments
- ✅ Cluster creation and management
- ✅ Task definition creation
- ✅ Service deployment
- ✅ Load balancer integration
- ✅ Auto scaling configuration
- ✅ Blue/green deployments

### Lambda Deployments
- ✅ Function creation and updates
- ✅ Environment variable management
- ✅ IAM role configuration
- ✅ API Gateway integration
- ✅ CloudWatch logs setup
- ✅ Deployment packages

### RDS Deployments
- ✅ Database instance creation
- ✅ Security group configuration
- ✅ Backup configuration
- ✅ Multi-AZ setup
- ✅ Read replica creation
- ✅ Parameter group optimization

## 🔧 Configuration Examples

### EC2 Instance Configuration
```bash
# Instance specifications
export INSTANCE_TYPE="t3.micro"
export AMI_ID="ami-0abcdef1234567890"
export KEY_PAIR="my-keypair"
export SECURITY_GROUP="web-server-sg"

# Storage configuration
export ROOT_VOLUME_SIZE="20"
export ROOT_VOLUME_TYPE="gp3"

# Networking
export SUBNET_ID="subnet-12345678"
export ASSIGN_PUBLIC_IP="true"
```

### RDS Configuration
```bash
# Database specifications
export DB_INSTANCE_CLASS="db.t3.micro"
export DB_ENGINE="postgres"
export DB_ENGINE_VERSION="15.3"
export ALLOCATED_STORAGE="20"

# Database settings
export DB_NAME="myapp"
export DB_USERNAME="appuser"
export DB_PASSWORD="securepassword"

# Backup and maintenance
export BACKUP_RETENTION_PERIOD="7"
export BACKUP_WINDOW="03:00-04:00"
export MAINTENANCE_WINDOW="sun:04:00-sun:05:00"
```

### Lambda Configuration
```bash
# Function settings
export FUNCTION_NAME="my-function"
export RUNTIME="nodejs18.x"
export HANDLER="index.handler"
export MEMORY_SIZE="128"
export TIMEOUT="30"

# Environment variables
export LAMBDA_ENV_VARS="NODE_ENV=production,API_KEY=secret"

# Triggers
export API_GATEWAY_INTEGRATION="true"
export S3_TRIGGER_BUCKET="my-trigger-bucket"
```

## 🛠️ Infrastructure as Code

### Terraform Example
```hcl
# main.tf
provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair

  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = var.subnet_id

  tags = {
    Name = var.app_name
    Environment = var.environment
  }
}
```

### CloudFormation Example
```yaml
# template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Web application infrastructure'

Parameters:
  InstanceType:
    Type: String
    Default: t3.micro
  KeyPair:
    Type: AWS::EC2::KeyPair::KeyName

Resources:
  WebServer:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0abcdef1234567890
      InstanceType: !Ref InstanceType
      KeyName: !Ref KeyPair
      SecurityGroupIds:
        - !Ref WebSecurityGroup
```

## 🔍 Monitoring and Logging

### CloudWatch Integration
- Application metrics
- Custom dashboards
- Log aggregation
- Alerting and notifications
- Performance monitoring

### X-Ray Tracing
- Distributed tracing
- Performance analysis
- Error tracking
- Service maps

## 💰 Cost Optimization

### Best Practices
- Right-sizing instances
- Reserved instances for predictable workloads
- Spot instances for fault-tolerant workloads
- Auto Scaling for variable workloads
- S3 storage classes optimization

### Cost Monitoring
- AWS Cost Explorer integration
- Budget alerts
- Resource tagging for cost allocation
- Unused resource identification

## 🔒 Security Best Practices

### IAM Configuration
- Least privilege access
- Role-based permissions
- Multi-factor authentication
- Access key rotation

### Network Security
- VPC configuration
- Security group rules
- Network ACLs
- Private subnets for databases

### Data Protection
- Encryption at rest
- Encryption in transit
- SSL/TLS certificates
- Secrets management

## 🔗 Related Documentation

- [Database Scripts](../../databases/README.md)
- [Caching Scripts](../../caching/README.md)
- [Framework Scripts](../../frameworks/README.md)