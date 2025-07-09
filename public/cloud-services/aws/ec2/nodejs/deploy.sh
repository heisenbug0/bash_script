#!/bin/bash

# AWS EC2 Node.js Application Deployment Script
# Provisions EC2 instance and deploys Node.js application

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../../utils/common.sh"

# AWS Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"

# EC2 Configuration
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
AMI_ID="${AMI_ID:-ami-0c02fb55956c7d316}"  # Ubuntu 22.04 LTS
KEY_PAIR="${KEY_PAIR:-}"
SECURITY_GROUP_NAME="${SECURITY_GROUP_NAME:-nodejs-app-sg}"
INSTANCE_NAME="${INSTANCE_NAME:-nodejs-app-instance}"

# Application Configuration
APP_NAME="${APP_NAME:-nodejs-app}"
NODE_VERSION="${NODE_VERSION:-18}"
PORT="${PORT:-3000}"
DOMAIN="${DOMAIN:-}"
SSL_EMAIL="${SSL_EMAIL:-admin@${DOMAIN}}"

# Storage Configuration
ROOT_VOLUME_SIZE="${ROOT_VOLUME_SIZE:-20}"
ROOT_VOLUME_TYPE="${ROOT_VOLUME_TYPE:-gp3}"

# Networking Configuration
VPC_ID="${VPC_ID:-}"
SUBNET_ID="${SUBNET_ID:-}"
ASSIGN_PUBLIC_IP="${ASSIGN_PUBLIC_IP:-true}"

# Monitoring Configuration
ENABLE_CLOUDWATCH="${ENABLE_CLOUDWATCH:-true}"
ENABLE_DETAILED_MONITORING="${ENABLE_DETAILED_MONITORING:-false}"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check AWS CLI and credentials
check_aws_prerequisites() {
    log_step "Checking AWS prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command_exists "aws"; then
        log_error "AWS CLI is not installed. Please install it first."
        echo "Installation: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" > /dev/null 2>&1; then
        log_error "AWS credentials not configured or invalid for profile: $AWS_PROFILE"
        echo "Run: aws configure --profile $AWS_PROFILE"
        exit 1
    fi
    
    # Check if key pair is specified
    if [ -z "$KEY_PAIR" ]; then
        log_error "KEY_PAIR environment variable is required"
        echo "Set: export KEY_PAIR=your-key-pair-name"
        exit 1
    fi
    
    # Verify key pair exists
    if ! aws ec2 describe-key-pairs --key-names "$KEY_PAIR" --region "$AWS_REGION" --profile "$AWS_PROFILE" > /dev/null 2>&1; then
        log_error "Key pair '$KEY_PAIR' not found in region $AWS_REGION"
        exit 1
    fi
    
    log_info "AWS prerequisites check passed"
}

# Get default VPC and subnet if not specified
get_default_vpc_subnet() {
    log_step "Getting default VPC and subnet..."
    
    if [ -z "$VPC_ID" ]; then
        VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")
        if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
            log_error "No default VPC found. Please specify VPC_ID."
            exit 1
        fi
        log_info "Using default VPC: $VPC_ID"
    fi
    
    if [ -z "$SUBNET_ID" ]; then
        SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=default-for-az,Values=true" --query "Subnets[0].SubnetId" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")
        if [ "$SUBNET_ID" = "None" ] || [ -z "$SUBNET_ID" ]; then
            log_error "No default subnet found. Please specify SUBNET_ID."
            exit 1
        fi
        log_info "Using default subnet: $SUBNET_ID"
    fi
}

# Create security group
create_security_group() {
    log_step "Creating security group..."
    
    # Check if security group already exists
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null || echo "None")
    
    if [ "$SECURITY_GROUP_ID" = "None" ] || [ -z "$SECURITY_GROUP_ID" ]; then
        # Create security group
        SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name "$SECURITY_GROUP_NAME" --description "Security group for Node.js application" --vpc-id "$VPC_ID" --query "GroupId" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")
        
        # Add inbound rules
        aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$AWS_REGION" --profile "$AWS_PROFILE"
        aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$AWS_REGION" --profile "$AWS_PROFILE"
        aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$AWS_REGION" --profile "$AWS_PROFILE"
        
        log_info "Security group created: $SECURITY_GROUP_ID"
    else
        log_info "Using existing security group: $SECURITY_GROUP_ID"
    fi
}

# Create IAM role for CloudWatch (if monitoring is enabled)
create_iam_role() {
    if [ "$ENABLE_CLOUDWATCH" = "true" ]; then
        log_step "Creating IAM role for CloudWatch..."
        
        ROLE_NAME="EC2-CloudWatch-Role-$APP_NAME"
        
        # Check if role exists
        if ! aws iam get-role --role-name "$ROLE_NAME" --profile "$AWS_PROFILE" > /dev/null 2>&1; then
            # Create trust policy
            cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
            
            # Create role
            aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file:///tmp/trust-policy.json --profile "$AWS_PROFILE"
            
            # Attach CloudWatch policy
            aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" --profile "$AWS_PROFILE"
            
            # Create instance profile
            aws iam create-instance-profile --instance-profile-name "$ROLE_NAME" --profile "$AWS_PROFILE"
            aws iam add-role-to-instance-profile --instance-profile-name "$ROLE_NAME" --role-name "$ROLE_NAME" --profile "$AWS_PROFILE"
            
            # Wait for role to be ready
            sleep 10
            
            log_info "IAM role created: $ROLE_NAME"
        else
            log_info "Using existing IAM role: $ROLE_NAME"
        fi
        
        IAM_INSTANCE_PROFILE="$ROLE_NAME"
    fi
}

# Create user data script
create_user_data() {
    log_step "Creating user data script..."
    
    cat > /tmp/user-data.sh << EOF
#!/bin/bash

# Update system
apt update && apt upgrade -y

# Install essential packages
apt install -y curl wget git build-essential nginx ufw certbot python3-certbot-nginx

# Install Node.js via NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="/root/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"

nvm install $NODE_VERSION
nvm use $NODE_VERSION
nvm alias default $NODE_VERSION

# Install PM2
npm install -g pm2

# Create deploy user
useradd -m -s /bin/bash deploy
usermod -aG sudo deploy

# Copy NVM to deploy user
cp -r /root/.nvm /home/deploy/
chown -R deploy:deploy /home/deploy/.nvm

# Add NVM to deploy user's bashrc
cat >> /home/deploy/.bashrc << 'EOFBASH'
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
EOFBASH

# Configure firewall
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

# Install CloudWatch agent if monitoring is enabled
if [ "$ENABLE_CLOUDWATCH" = "true" ]; then
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i amazon-cloudwatch-agent.deb
    
    # Create CloudWatch config
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOFCW'
{
  "metrics": {
    "namespace": "AWS/EC2/Custom",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "diskio": {
        "measurement": ["io_time"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/$APP_NAME/*.log",
            "log_group_name": "/aws/ec2/$APP_NAME",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOFCW
    
    # Start CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
fi

# Create application directory
mkdir -p /home/deploy/$APP_NAME
chown deploy:deploy /home/deploy/$APP_NAME

# Create logs directory
mkdir -p /var/log/$APP_NAME
chown deploy:deploy /var/log/$APP_NAME

# Signal that user data script is complete
/opt/aws/bin/cfn-signal -e \$? --stack \${AWS::StackName} --resource AutoScalingGroup --region \${AWS::Region} || true
EOF
    
    log_info "User data script created"
}

# Launch EC2 instance
launch_instance() {
    log_step "Launching EC2 instance..."
    
    # Prepare launch parameters
    LAUNCH_PARAMS="--image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_PAIR --security-group-ids $SECURITY_GROUP_ID --subnet-id $SUBNET_ID --user-data file:///tmp/user-data.sh"
    
    # Add block device mapping
    LAUNCH_PARAMS="$LAUNCH_PARAMS --block-device-mappings DeviceName=/dev/sda1,Ebs={VolumeSize=$ROOT_VOLUME_SIZE,VolumeType=$ROOT_VOLUME_TYPE,DeleteOnTermination=true}"
    
    # Add IAM instance profile if CloudWatch is enabled
    if [ "$ENABLE_CLOUDWATCH" = "true" ]; then
        LAUNCH_PARAMS="$LAUNCH_PARAMS --iam-instance-profile Name=$IAM_INSTANCE_PROFILE"
    fi
    
    # Add detailed monitoring if enabled
    if [ "$ENABLE_DETAILED_MONITORING" = "true" ]; then
        LAUNCH_PARAMS="$LAUNCH_PARAMS --monitoring Enabled=true"
    fi
    
    # Add public IP assignment
    if [ "$ASSIGN_PUBLIC_IP" = "true" ]; then
        LAUNCH_PARAMS="$LAUNCH_PARAMS --associate-public-ip-address"
    fi
    
    # Launch instance
    INSTANCE_ID=$(aws ec2 run-instances $LAUNCH_PARAMS --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Application,Value=$APP_NAME}]" --query "Instances[0].InstanceId" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")
    
    log_info "Instance launched: $INSTANCE_ID"
    
    # Wait for instance to be running
    log_info "Waiting for instance to be running..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" --profile "$AWS_PROFILE"
    
    # Get instance details
    INSTANCE_DETAILS=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0]" --region "$AWS_REGION" --profile "$AWS_PROFILE")
    PUBLIC_IP=$(echo "$INSTANCE_DETAILS" | jq -r '.PublicIpAddress // "N/A"')
    PRIVATE_IP=$(echo "$INSTANCE_DETAILS" | jq -r '.PrivateIpAddress')
    
    log_info "Instance is running"
    log_info "Public IP: $PUBLIC_IP"
    log_info "Private IP: $PRIVATE_IP"
}

# Wait for instance to be ready
wait_for_instance() {
    log_step "Waiting for instance to be ready for SSH..."
    
    # Wait for status checks to pass
    aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" --profile "$AWS_PROFILE"
    
    # Additional wait for SSH to be ready
    log_info "Waiting for SSH to be ready..."
    for i in {1..30}; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i ~/.ssh/"$KEY_PAIR".pem ubuntu@"$PUBLIC_IP" "echo 'SSH is ready'" 2>/dev/null; then
            log_info "SSH is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "SSH connection timeout"
            exit 1
        fi
        sleep 10
    done
}

# Deploy application to instance
deploy_application() {
    log_step "Deploying application to instance..."
    
    # Create deployment package
    tar -czf /tmp/app.tar.gz --exclude=node_modules --exclude=.git .
    
    # Copy application to instance
    scp -o StrictHostKeyChecking=no -i ~/.ssh/"$KEY_PAIR".pem /tmp/app.tar.gz ubuntu@"$PUBLIC_IP":/tmp/
    
    # Deploy application via SSH
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/"$KEY_PAIR".pem ubuntu@"$PUBLIC_IP" << EOF
# Extract application
sudo -u deploy tar -xzf /tmp/app.tar.gz -C /home/deploy/$APP_NAME/
sudo chown -R deploy:deploy /home/deploy/$APP_NAME/

# Install dependencies
sudo -u deploy bash -c "
    source /home/deploy/.bashrc
    cd /home/deploy/$APP_NAME
    npm install --production
"

# Create PM2 ecosystem file
sudo -u deploy tee /home/deploy/$APP_NAME/ecosystem.config.js > /dev/null << 'EOFECO'
module.exports = {
  apps: [{
    name: '$APP_NAME',
    script: './app.js',
    instances: 'max',
    exec_mode: 'cluster',
    env_production: {
      NODE_ENV: 'production',
      PORT: $PORT
    },
    max_memory_restart: '500M',
    error_file: '/var/log/$APP_NAME/error.log',
    out_file: '/var/log/$APP_NAME/out.log',
    log_file: '/var/log/$APP_NAME/combined.log',
    time: true
  }]
};
EOFECO

# Start application with PM2
sudo -u deploy bash -c "
    source /home/deploy/.bashrc
    cd /home/deploy/$APP_NAME
    pm2 start ecosystem.config.js --env production
    pm2 save
    pm2 startup
"

# Setup PM2 startup
sudo env PATH=\$PATH:/home/deploy/.nvm/versions/node/v$NODE_VERSION/bin /home/deploy/.nvm/versions/node/v$NODE_VERSION/lib/node_modules/pm2/bin/pm2 startup systemd -u deploy --hp /home/deploy

# Configure Nginx
sudo tee /etc/nginx/sites-available/$APP_NAME > /dev/null << 'EOFNGINX'
server {
    listen 80;
    server_name ${DOMAIN:-_};
    
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOFNGINX

# Enable site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Setup SSL if domain is provided
if [ -n "$DOMAIN" ]; then
    sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect
fi

# Cleanup
rm -f /tmp/app.tar.gz
EOF
    
    log_info "Application deployed successfully"
}

# Create CloudWatch log group
create_log_group() {
    if [ "$ENABLE_CLOUDWATCH" = "true" ]; then
        log_step "Creating CloudWatch log group..."
        
        LOG_GROUP_NAME="/aws/ec2/$APP_NAME"
        
        # Create log group if it doesn't exist
        if ! aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" --query "logGroups[?logGroupName=='$LOG_GROUP_NAME']" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE" | grep -q "$LOG_GROUP_NAME"; then
            aws logs create-log-group --log-group-name "$LOG_GROUP_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE"
            log_info "CloudWatch log group created: $LOG_GROUP_NAME"
        else
            log_info "CloudWatch log group already exists: $LOG_GROUP_NAME"
        fi
    fi
}

# Display deployment information
display_info() {
    log_info "AWS EC2 deployment completed successfully!"
    echo
    echo "Instance Information:"
    echo "===================="
    echo "Instance ID: $INSTANCE_ID"
    echo "Instance Type: $INSTANCE_TYPE"
    echo "Public IP: $PUBLIC_IP"
    echo "Private IP: $PRIVATE_IP"
    echo "Key Pair: $KEY_PAIR"
    echo "Security Group: $SECURITY_GROUP_ID"
    echo
    echo "Application Information:"
    echo "======================="
    echo "App Name: $APP_NAME"
    echo "Port: $PORT"
    if [ -n "$DOMAIN" ]; then
        echo "Domain: https://$DOMAIN"
    else
        echo "Access URL: http://$PUBLIC_IP"
    fi
    echo
    echo "SSH Access:"
    echo "==========="
    echo "ssh -i ~/.ssh/$KEY_PAIR.pem ubuntu@$PUBLIC_IP"
    echo
    echo "Management Commands (via SSH):"
    echo "=============================="
    echo "Check status: sudo -u deploy pm2 status"
    echo "View logs: sudo -u deploy pm2 logs $APP_NAME"
    echo "Restart app: sudo -u deploy pm2 restart $APP_NAME"
    echo
    if [ "$ENABLE_CLOUDWATCH" = "true" ]; then
        echo "CloudWatch Monitoring:"
        echo "====================="
        echo "Log Group: /aws/ec2/$APP_NAME"
        echo "Metrics Namespace: AWS/EC2/Custom"
        echo "View in AWS Console: https://console.aws.amazon.com/cloudwatch/"
    fi
    echo
    echo "AWS Resources Created:"
    echo "====================="
    echo "EC2 Instance: $INSTANCE_ID"
    echo "Security Group: $SECURITY_GROUP_ID"
    if [ "$ENABLE_CLOUDWATCH" = "true" ]; then
        echo "IAM Role: $IAM_INSTANCE_PROFILE"
        echo "CloudWatch Log Group: /aws/ec2/$APP_NAME"
    fi
}

# Cleanup function
cleanup() {
    log_warn "Cleaning up temporary files..."
    rm -f /tmp/user-data.sh /tmp/app.tar.gz /tmp/trust-policy.json
}

# Main execution
main() {
    log_info "Starting AWS EC2 Node.js deployment..."
    
    check_aws_prerequisites
    get_default_vpc_subnet
    create_security_group
    create_iam_role
    create_user_data
    launch_instance
    wait_for_instance
    create_log_group
    deploy_application
    display_info
    cleanup
    
    log_info "Deployment completed successfully!"
}

# Set trap for cleanup
trap cleanup EXIT

# Run main function
main "$@"