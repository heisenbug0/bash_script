# Cloud Services Deployment Scripts

Deploy your applications to Amazon Web Services (AWS).

## Available Services

### AWS EC2
Virtual servers in the cloud.
- **Flexible sizing** - Choose CPU, memory, storage
- **Multiple regions** - Deploy close to your users
- **Auto-scaling** - Handle traffic spikes
- **Load balancing** - Distribute traffic across servers

### AWS RDS
Managed database service.
- **PostgreSQL** - Fully managed PostgreSQL
- **Automatic backups** - Point-in-time recovery
- **High availability** - Multi-AZ deployments
- **Monitoring** - Performance insights included

### AWS Lambda
Serverless function execution.
- **No servers** - Just upload your code
- **Auto-scaling** - Handles any load automatically
- **Pay per use** - Only pay when code runs
- **Event-driven** - Trigger from APIs, databases, files

## Quick Deployments

### Node.js on EC2
```bash
cd aws/ec2/nodejs/
export APP_NAME="my-node-app"
export INSTANCE_TYPE="t3.micro"
export KEY_PAIR="my-keypair"
./deploy.sh
```

### PostgreSQL on RDS
```bash
cd aws/rds/postgresql/
export DB_NAME="myapp"
export DB_INSTANCE_CLASS="db.t3.micro"
./deploy.sh
```

### Lambda Function
```bash
cd aws/lambda/nodejs/
export FUNCTION_NAME="my-function"
export RUNTIME="nodejs18.x"
./deploy.sh
```

## What You Need

### AWS Account Setup
1. **AWS Account** - Sign up at aws.amazon.com
2. **AWS CLI** - Install and configure credentials
3. **Key Pair** - Create EC2 key pair for server access
4. **IAM Permissions** - Proper permissions for services

### Application Requirements
- Your application code
- Requirements file (package.json, requirements.txt, etc.)
- Environment variables (if needed)

## What Gets Created

### EC2 Deployments
- **EC2 Instance** with your chosen specifications
- **Security Group** with proper firewall rules
- **Elastic IP** (optional) for static IP address
- **Application setup** with web server and process management
- **SSL certificate** if domain provided
- **CloudWatch monitoring** for logs and metrics

### RDS Deployments
- **Database instance** with chosen engine and size
- **Security group** allowing access from your applications
- **Automated backups** with retention policy
- **Parameter group** optimized for performance
- **CloudWatch alarms** for monitoring

### Lambda Deployments
- **Function** with your code deployed
- **IAM role** with necessary permissions
- **API Gateway** (optional) for HTTP access
- **CloudWatch logs** for debugging
- **Environment variables** configured

## Configuration

### Common Settings
```bash
export AWS_REGION="us-east-1"          # AWS region
export AWS_PROFILE="default"           # AWS CLI profile
export ENVIRONMENT="production"        # Environment tag
```

### EC2 Settings
```bash
export INSTANCE_TYPE="t3.micro"        # Instance size
export KEY_PAIR="my-keypair"           # SSH key pair name
export DOMAIN="myapp.com"              # Custom domain
```

### RDS Settings
```bash
export DB_INSTANCE_CLASS="db.t3.micro" # Database size
export DB_ENGINE="postgres"            # Database engine
export MULTI_AZ="false"                # High availability
```

## Cost Management

### Free Tier Eligible
- **EC2**: t2.micro instances (750 hours/month)
- **RDS**: db.t2.micro (750 hours/month)
- **Lambda**: 1M requests + 400,000 GB-seconds/month

### Cost Optimization Tips
- Use **t3.micro** or **t3.small** for small applications
- Enable **auto-scaling** to handle traffic efficiently
- Set up **billing alerts** to monitor costs
- Use **Reserved Instances** for long-term deployments

## Management

### AWS Console
Access your resources at: https://console.aws.amazon.com

### Command Line
```bash
# List EC2 instances
aws ec2 describe-instances

# Check RDS databases
aws rds describe-db-instances

# View Lambda functions
aws lambda list-functions

# Monitor costs
aws ce get-cost-and-usage
```

## Security

All deployments include:
- **Security groups** with minimal required access
- **IAM roles** with least privilege permissions
- **Encryption** at rest and in transit
- **VPC** isolation where applicable
- **SSL certificates** for web applications

## Monitoring

### CloudWatch Integration
- **Logs** from all services
- **Metrics** for performance monitoring
- **Alarms** for automated alerts
- **Dashboards** for visualization

### Health Checks
- **Application health** endpoints
- **Database connectivity** monitoring
- **SSL certificate** expiration alerts
- **Disk space** and memory monitoring

Each service folder has detailed setup instructions and AWS-specific configuration options.