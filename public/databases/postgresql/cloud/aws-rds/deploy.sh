#!/bin/bash

# AWS RDS PostgreSQL Database Deployment Script
# Creates and configures PostgreSQL database on AWS RDS

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../../utils/common.sh"

# AWS Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"

# RDS Configuration
DB_INSTANCE_IDENTIFIER="${DB_INSTANCE_IDENTIFIER:-postgres-db}"
DB_INSTANCE_CLASS="${DB_INSTANCE_CLASS:-db.t3.micro}"
DB_ENGINE="${DB_ENGINE:-postgres}"
DB_ENGINE_VERSION="${DB_ENGINE_VERSION:-15.3}"
ALLOCATED_STORAGE="${ALLOCATED_STORAGE:-20}"
STORAGE_TYPE="${STORAGE_TYPE:-gp2}"
STORAGE_ENCRYPTED="${STORAGE_ENCRYPTED:-true}"

# Database Settings
DB_NAME="${DB_NAME:-myapp}"
DB_USERNAME="${DB_USERNAME:-appuser}"
DB_PASSWORD="${DB_PASSWORD:-$(generate_password 32)}"
DB_PORT="${DB_PORT:-5432}"

# Network Configuration
VPC_ID="${VPC_ID:-}"
SUBNET_GROUP_NAME="${SUBNET_GROUP_NAME:-${DB_INSTANCE_IDENTIFIER}-subnet-group}"
SECURITY_GROUP_NAME="${SECURITY_GROUP_NAME:-${DB_INSTANCE_IDENTIFIER}-sg}"
ALLOWED_CIDR="${ALLOWED_CIDR:-10.0.0.0/16}"

# Backup and Maintenance
BACKUP_RETENTION_PERIOD="${BACKUP_RETENTION_PERIOD:-7}"
BACKUP_WINDOW="${BACKUP_WINDOW:-03:00-04:00}"
MAINTENANCE_WINDOW="${MAINTENANCE_WINDOW:-sun:04:00-sun:05:00}"
MULTI_AZ="${MULTI_AZ:-false}"
PUBLICLY_ACCESSIBLE="${PUBLICLY_ACCESSIBLE:-false}"

# Monitoring
ENABLE_PERFORMANCE_INSIGHTS="${ENABLE_PERFORMANCE_INSIGHTS:-true}"
MONITORING_INTERVAL="${MONITORING_INTERVAL:-60}"
ENABLE_CLOUDWATCH_LOGS="${ENABLE_CLOUDWATCH_LOGS:-true}"

# Deletion Protection
DELETION_PROTECTION="${DELETION_PROTECTION:-true}"
SKIP_FINAL_SNAPSHOT="${SKIP_FINAL_SNAPSHOT:-false}"
FINAL_SNAPSHOT_IDENTIFIER="${FINAL_SNAPSHOT_IDENTIFIER:-${DB_INSTANCE_IDENTIFIER}-final-snapshot-$(date +%Y%m%d%H%M%S)}"

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
    
    # Check if jq is installed for JSON parsing
    if ! command_exists "jq"; then
        log_error "jq is not installed. Please install jq for JSON parsing."
        exit 1
    fi
    
    log_info "AWS prerequisites check passed"
}

# Get default VPC if not specified
get_default_vpc() {
    log_step "Getting VPC information..."
    
    if [ -z "$VPC_ID" ]; then
        VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")
        if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
            log_error "No default VPC found. Please specify VPC_ID."
            exit 1
        fi
        log_info "Using default VPC: $VPC_ID"
    else
        log_info "Using specified VPC: $VPC_ID"
    fi
    
    # Get VPC CIDR for security group
    VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query "Vpcs[0].CidrBlock" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")
    if [ -z "$ALLOWED_CIDR" ] || [ "$ALLOWED_CIDR" = "10.0.0.0/16" ]; then
        ALLOWED_CIDR="$VPC_CIDR"
    fi
    
    log_info "VPC CIDR: $VPC_CIDR"
}

# Create DB subnet group
create_db_subnet_group() {
    log_step "Creating DB subnet group..."
    
    # Check if subnet group already exists
    if aws rds describe-db-subnet-groups --db-subnet-group-name "$SUBNET_GROUP_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" > /dev/null 2>&1; then
        log_info "DB subnet group '$SUBNET_GROUP_NAME' already exists"
        return
    fi
    
    # Get subnets in the VPC
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")
    
    if [ -z "$SUBNET_IDS" ]; then
        log_error "No subnets found in VPC $VPC_ID"
        exit 1
    fi
    
    # Convert space-separated subnet IDs to array
    SUBNET_ARRAY=($SUBNET_IDS)
    
    # Need at least 2 subnets in different AZs for RDS
    if [ ${#SUBNET_ARRAY[@]} -lt 2 ]; then
        log_error "At least 2 subnets in different availability zones are required for RDS"
        exit 1
    fi
    
    # Create subnet group
    aws rds create-db-subnet-group \
        --db-subnet-group-name "$SUBNET_GROUP_NAME" \
        --db-subnet-group-description "Subnet group for $DB_INSTANCE_IDENTIFIER" \
        --subnet-ids ${SUBNET_ARRAY[@]} \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    log_info "DB subnet group '$SUBNET_GROUP_NAME' created successfully"
}

# Create security group
create_security_group() {
    log_step "Creating security group..."
    
    # Check if security group already exists
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null || echo "None")
    
    if [ "$SECURITY_GROUP_ID" != "None" ] && [ -n "$SECURITY_GROUP_ID" ]; then
        log_info "Using existing security group: $SECURITY_GROUP_ID"
        return
    fi
    
    # Create security group
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name "$SECURITY_GROUP_NAME" \
        --description "Security group for PostgreSQL RDS instance $DB_INSTANCE_IDENTIFIER" \
        --vpc-id "$VPC_ID" \
        --query "GroupId" \
        --output text \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE")
    
    # Add inbound rule for PostgreSQL
    aws ec2 authorize-security-group-ingress \
        --group-id "$SECURITY_GROUP_ID" \
        --protocol tcp \
        --port "$DB_PORT" \
        --cidr "$ALLOWED_CIDR" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    log_info "Security group created: $SECURITY_GROUP_ID"
}

# Create parameter group for optimization
create_parameter_group() {
    log_step "Creating DB parameter group..."
    
    PARAMETER_GROUP_NAME="${DB_INSTANCE_IDENTIFIER}-params"
    
    # Check if parameter group already exists
    if aws rds describe-db-parameter-groups --db-parameter-group-name "$PARAMETER_GROUP_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" > /dev/null 2>&1; then
        log_info "DB parameter group '$PARAMETER_GROUP_NAME' already exists"
        return
    fi
    
    # Create parameter group
    aws rds create-db-parameter-group \
        --db-parameter-group-name "$PARAMETER_GROUP_NAME" \
        --db-parameter-group-family "postgres15" \
        --description "Parameter group for $DB_INSTANCE_IDENTIFIER" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    # Modify parameters for better performance
    aws rds modify-db-parameter-group \
        --db-parameter-group-name "$PARAMETER_GROUP_NAME" \
        --parameters "ParameterName=shared_preload_libraries,ParameterValue=pg_stat_statements,ApplyMethod=pending-reboot" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    aws rds modify-db-parameter-group \
        --db-parameter-group-name "$PARAMETER_GROUP_NAME" \
        --parameters "ParameterName=log_statement,ParameterValue=all,ApplyMethod=immediate" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    aws rds modify-db-parameter-group \
        --db-parameter-group-name "$PARAMETER_GROUP_NAME" \
        --parameters "ParameterName=log_min_duration_statement,ParameterValue=1000,ApplyMethod=immediate" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    log_info "DB parameter group '$PARAMETER_GROUP_NAME' created and configured"
}

# Create option group (if needed)
create_option_group() {
    log_step "Creating DB option group..."
    
    OPTION_GROUP_NAME="${DB_INSTANCE_IDENTIFIER}-options"
    
    # Check if option group already exists
    if aws rds describe-option-groups --option-group-name "$OPTION_GROUP_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" > /dev/null 2>&1; then
        log_info "DB option group '$OPTION_GROUP_NAME' already exists"
        return
    fi
    
    # Create option group
    aws rds create-option-group \
        --option-group-name "$OPTION_GROUP_NAME" \
        --engine-name "$DB_ENGINE" \
        --major-engine-version "15" \
        --option-group-description "Option group for $DB_INSTANCE_IDENTIFIER" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    log_info "DB option group '$OPTION_GROUP_NAME' created"
}

# Create RDS instance
create_rds_instance() {
    log_step "Creating RDS PostgreSQL instance..."
    
    # Check if instance already exists
    if aws rds describe-db-instances --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" --region "$AWS_REGION" --profile "$AWS_PROFILE" > /dev/null 2>&1; then
        log_warn "RDS instance '$DB_INSTANCE_IDENTIFIER' already exists"
        return
    fi
    
    # Prepare create-db-instance command
    CREATE_PARAMS=(
        --db-instance-identifier "$DB_INSTANCE_IDENTIFIER"
        --db-instance-class "$DB_INSTANCE_CLASS"
        --engine "$DB_ENGINE"
        --engine-version "$DB_ENGINE_VERSION"
        --allocated-storage "$ALLOCATED_STORAGE"
        --storage-type "$STORAGE_TYPE"
        --db-name "$DB_NAME"
        --master-username "$DB_USERNAME"
        --master-user-password "$DB_PASSWORD"
        --port "$DB_PORT"
        --vpc-security-group-ids "$SECURITY_GROUP_ID"
        --db-subnet-group-name "$SUBNET_GROUP_NAME"
        --backup-retention-period "$BACKUP_RETENTION_PERIOD"
        --preferred-backup-window "$BACKUP_WINDOW"
        --preferred-maintenance-window "$MAINTENANCE_WINDOW"
        --region "$AWS_REGION"
        --profile "$AWS_PROFILE"
    )
    
    # Add optional parameters
    if [ "$STORAGE_ENCRYPTED" = "true" ]; then
        CREATE_PARAMS+=(--storage-encrypted)
    fi
    
    if [ "$MULTI_AZ" = "true" ]; then
        CREATE_PARAMS+=(--multi-az)
    fi
    
    if [ "$PUBLICLY_ACCESSIBLE" = "true" ]; then
        CREATE_PARAMS+=(--publicly-accessible)
    else
        CREATE_PARAMS+=(--no-publicly-accessible)
    fi
    
    if [ "$DELETION_PROTECTION" = "true" ]; then
        CREATE_PARAMS+=(--deletion-protection)
    fi
    
    if [ "$ENABLE_PERFORMANCE_INSIGHTS" = "true" ]; then
        CREATE_PARAMS+=(--enable-performance-insights)
    fi
    
    if [ "$MONITORING_INTERVAL" != "0" ]; then
        CREATE_PARAMS+=(--monitoring-interval "$MONITORING_INTERVAL")
    fi
    
    if [ "$ENABLE_CLOUDWATCH_LOGS" = "true" ]; then
        CREATE_PARAMS+=(--enable-cloudwatch-logs-exports postgresql)
    fi
    
    # Add parameter group
    CREATE_PARAMS+=(--db-parameter-group-name "$PARAMETER_GROUP_NAME")
    
    # Add option group
    CREATE_PARAMS+=(--option-group-name "$OPTION_GROUP_NAME")
    
    # Create the RDS instance
    aws rds create-db-instance "${CREATE_PARAMS[@]}"
    
    log_info "RDS instance creation initiated: $DB_INSTANCE_IDENTIFIER"
}

# Wait for RDS instance to be available
wait_for_instance() {
    log_step "Waiting for RDS instance to be available..."
    
    log_info "This may take 10-20 minutes..."
    
    # Wait for instance to be available
    aws rds wait db-instance-available \
        --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    log_info "RDS instance is now available"
}

# Get RDS instance details
get_instance_details() {
    log_step "Getting RDS instance details..."
    
    INSTANCE_DETAILS=$(aws rds describe-db-instances \
        --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
        --query "DBInstances[0]" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE")
    
    DB_ENDPOINT=$(echo "$INSTANCE_DETAILS" | jq -r '.Endpoint.Address')
    DB_PORT_ACTUAL=$(echo "$INSTANCE_DETAILS" | jq -r '.Endpoint.Port')
    DB_STATUS=$(echo "$INSTANCE_DETAILS" | jq -r '.DBInstanceStatus')
    
    log_info "Database endpoint: $DB_ENDPOINT"
    log_info "Database port: $DB_PORT_ACTUAL"
    log_info "Database status: $DB_STATUS"
}

# Create CloudWatch alarms
create_cloudwatch_alarms() {
    log_step "Creating CloudWatch alarms..."
    
    # CPU Utilization alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "${DB_INSTANCE_IDENTIFIER}-high-cpu" \
        --alarm-description "High CPU utilization for RDS instance" \
        --metric-name CPUUtilization \
        --namespace AWS/RDS \
        --statistic Average \
        --period 300 \
        --threshold 80 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 2 \
        --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE_IDENTIFIER" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    # Database connections alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "${DB_INSTANCE_IDENTIFIER}-high-connections" \
        --alarm-description "High database connections for RDS instance" \
        --metric-name DatabaseConnections \
        --namespace AWS/RDS \
        --statistic Average \
        --period 300 \
        --threshold 80 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 2 \
        --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE_IDENTIFIER" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    # Free storage space alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "${DB_INSTANCE_IDENTIFIER}-low-storage" \
        --alarm-description "Low free storage space for RDS instance" \
        --metric-name FreeStorageSpace \
        --namespace AWS/RDS \
        --statistic Average \
        --period 300 \
        --threshold 2000000000 \
        --comparison-operator LessThanThreshold \
        --evaluation-periods 1 \
        --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE_IDENTIFIER" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    log_info "CloudWatch alarms created"
}

# Test database connection
test_connection() {
    log_step "Testing database connection..."
    
    # Create a simple test script
    cat > /tmp/test_connection.py << EOF
#!/usr/bin/env python3
import psycopg2
import sys

try:
    conn = psycopg2.connect(
        host='$DB_ENDPOINT',
        port=$DB_PORT_ACTUAL,
        database='$DB_NAME',
        user='$DB_USERNAME',
        password='$DB_PASSWORD'
    )
    
    cursor = conn.cursor()
    cursor.execute('SELECT version();')
    version = cursor.fetchone()
    print(f"Successfully connected to PostgreSQL: {version[0]}")
    
    cursor.close()
    conn.close()
    sys.exit(0)
    
except Exception as e:
    print(f"Connection failed: {e}")
    sys.exit(1)
EOF
    
    # Test connection if Python and psycopg2 are available
    if command_exists "python3" && python3 -c "import psycopg2" 2>/dev/null; then
        if python3 /tmp/test_connection.py; then
            log_info "Database connection test successful"
        else
            log_warn "Database connection test failed. Please verify manually."
        fi
    else
        log_warn "Python3 or psycopg2 not available. Please test connection manually."
    fi
    
    # Cleanup
    rm -f /tmp/test_connection.py
}

# Create backup script
create_backup_script() {
    log_step "Creating backup management script..."
    
    cat > "/tmp/rds-backup-${DB_INSTANCE_IDENTIFIER}.sh" << EOF
#!/bin/bash

# RDS Backup Management Script for $DB_INSTANCE_IDENTIFIER

DB_INSTANCE_IDENTIFIER="$DB_INSTANCE_IDENTIFIER"
AWS_REGION="$AWS_REGION"
AWS_PROFILE="$AWS_PROFILE"

# Create manual snapshot
create_snapshot() {
    local snapshot_id="\${DB_INSTANCE_IDENTIFIER}-manual-\$(date +%Y%m%d%H%M%S)"
    
    echo "Creating manual snapshot: \$snapshot_id"
    aws rds create-db-snapshot \\
        --db-instance-identifier "\$DB_INSTANCE_IDENTIFIER" \\
        --db-snapshot-identifier "\$snapshot_id" \\
        --region "\$AWS_REGION" \\
        --profile "\$AWS_PROFILE"
    
    echo "Snapshot creation initiated: \$snapshot_id"
}

# List snapshots
list_snapshots() {
    echo "Listing snapshots for \$DB_INSTANCE_IDENTIFIER:"
    aws rds describe-db-snapshots \\
        --db-instance-identifier "\$DB_INSTANCE_IDENTIFIER" \\
        --query "DBSnapshots[*].[DBSnapshotIdentifier,Status,SnapshotCreateTime]" \\
        --output table \\
        --region "\$AWS_REGION" \\
        --profile "\$AWS_PROFILE"
}

# Delete old manual snapshots (keep last 5)
cleanup_snapshots() {
    echo "Cleaning up old manual snapshots..."
    
    # Get manual snapshots sorted by creation time
    SNAPSHOTS=\$(aws rds describe-db-snapshots \\
        --db-instance-identifier "\$DB_INSTANCE_IDENTIFIER" \\
        --snapshot-type manual \\
        --query "DBSnapshots[?contains(DBSnapshotIdentifier, 'manual')].DBSnapshotIdentifier" \\
        --output text \\
        --region "\$AWS_REGION" \\
        --profile "\$AWS_PROFILE" | tr '\t' '\n' | sort -r)
    
    # Keep only the 5 most recent snapshots
    echo "\$SNAPSHOTS" | tail -n +6 | while read snapshot; do
        if [ -n "\$snapshot" ]; then
            echo "Deleting old snapshot: \$snapshot"
            aws rds delete-db-snapshot \\
                --db-snapshot-identifier "\$snapshot" \\
                --region "\$AWS_REGION" \\
                --profile "\$AWS_PROFILE"
        fi
    done
}

# Main function
case "\${1:-help}" in
    create)
        create_snapshot
        ;;
    list)
        list_snapshots
        ;;
    cleanup)
        cleanup_snapshots
        ;;
    *)
        echo "Usage: \$0 {create|list|cleanup}"
        echo "  create  - Create a manual snapshot"
        echo "  list    - List all snapshots"
        echo "  cleanup - Delete old manual snapshots (keep last 5)"
        ;;
esac
EOF
    
    chmod +x "/tmp/rds-backup-${DB_INSTANCE_IDENTIFIER}.sh"
    
    log_info "Backup script created: /tmp/rds-backup-${DB_INSTANCE_IDENTIFIER}.sh"
}

# Display deployment information
display_info() {
    log_info "AWS RDS PostgreSQL deployment completed successfully!"
    echo
    echo "RDS Instance Information:"
    echo "========================"
    echo "Instance Identifier: $DB_INSTANCE_IDENTIFIER"
    echo "Instance Class: $DB_INSTANCE_CLASS"
    echo "Engine: $DB_ENGINE $DB_ENGINE_VERSION"
    echo "Allocated Storage: ${ALLOCATED_STORAGE}GB"
    echo "Multi-AZ: $MULTI_AZ"
    echo "Publicly Accessible: $PUBLICLY_ACCESSIBLE"
    echo
    echo "Database Connection:"
    echo "==================="
    echo "Endpoint: $DB_ENDPOINT"
    echo "Port: $DB_PORT_ACTUAL"
    echo "Database Name: $DB_NAME"
    echo "Username: $DB_USERNAME"
    echo "Password: $DB_PASSWORD"
    echo
    echo "Connection String:"
    echo "=================="
    echo "postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_ENDPOINT:$DB_PORT_ACTUAL/$DB_NAME"
    echo
    echo "Network Configuration:"
    echo "====================="
    echo "VPC ID: $VPC_ID"
    echo "Security Group: $SECURITY_GROUP_ID"
    echo "Subnet Group: $SUBNET_GROUP_NAME"
    echo
    echo "Backup Configuration:"
    echo "===================="
    echo "Backup Retention: $BACKUP_RETENTION_PERIOD days"
    echo "Backup Window: $BACKUP_WINDOW"
    echo "Maintenance Window: $MAINTENANCE_WINDOW"
    echo
    echo "Monitoring:"
    echo "==========="
    echo "Performance Insights: $ENABLE_PERFORMANCE_INSIGHTS"
    echo "CloudWatch Logs: $ENABLE_CLOUDWATCH_LOGS"
    echo "Monitoring Interval: ${MONITORING_INTERVAL}s"
    echo
    echo "AWS Console Links:"
    echo "=================="
    echo "RDS Console: https://console.aws.amazon.com/rds/home?region=$AWS_REGION#database:id=$DB_INSTANCE_IDENTIFIER"
    echo "CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION"
    echo "Performance Insights: https://console.aws.amazon.com/rds/home?region=$AWS_REGION#performance-insights-v20206:"
    echo
    echo "Management Commands:"
    echo "==================="
    echo "Connect via psql: psql -h $DB_ENDPOINT -p $DB_PORT_ACTUAL -U $DB_USERNAME -d $DB_NAME"
    echo "Create snapshot: /tmp/rds-backup-${DB_INSTANCE_IDENTIFIER}.sh create"
    echo "List snapshots: /tmp/rds-backup-${DB_INSTANCE_IDENTIFIER}.sh list"
    echo "View logs: aws rds describe-db-log-files --db-instance-identifier $DB_INSTANCE_IDENTIFIER --region $AWS_REGION"
    echo
    echo "Cost Optimization:"
    echo "=================="
    echo "- Consider using Reserved Instances for production workloads"
    echo "- Monitor CloudWatch metrics to right-size the instance"
    echo "- Use automated backups instead of manual snapshots when possible"
    echo "- Enable storage autoscaling if needed"
    echo
    echo "IMPORTANT: Please save the database password securely!"
    echo "Consider using AWS Secrets Manager for password management in production."
}

# Main execution
main() {
    log_info "Starting AWS RDS PostgreSQL deployment..."
    
    check_aws_prerequisites
    get_default_vpc
    create_db_subnet_group
    create_security_group
    create_parameter_group
    create_option_group
    create_rds_instance
    wait_for_instance
    get_instance_details
    create_cloudwatch_alarms
    test_connection
    create_backup_script
    display_info
    
    log_info "Deployment completed successfully!"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f /tmp/test_connection.py
}

# Set trap for cleanup
trap cleanup EXIT

# Run main function
main "$@"