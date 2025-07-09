#!/bin/bash

# AWS Lambda Deployment Script
# Deploys a Node.js function to AWS Lambda

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../utils/common.sh"
source "$SCRIPT_DIR/../../../utils/logging.sh"
source "$SCRIPT_DIR/../../../utils/validation.sh"

# Configuration
FUNCTION_NAME="${FUNCTION_NAME:-my-lambda-function}"
RUNTIME="${RUNTIME:-nodejs18.x}"
HANDLER="${HANDLER:-index.handler}"
MEMORY_SIZE="${MEMORY_SIZE:-128}"
TIMEOUT="${TIMEOUT:-30}"
REGION="${REGION:-us-east-1}"
ROLE_NAME="${ROLE_NAME:-lambda-basic-execution}"

main() {
    log_step "Starting AWS Lambda deployment"
    
    # Pre-flight checks
    if ! pre_deployment_check; then
        log_error "Pre-deployment checks failed"
        exit 1
    fi
    
    # Check for AWS CLI
    if ! has_command aws; then
        log_error "AWS CLI is required but not installed"
        log_info "Install with: pip install awscli && aws configure"
        exit 1
    fi
    
    # Check for valid Node.js project
    if [ "$RUNTIME" == "nodejs"* ] && ! valid_nodejs_project; then
        log_error "Not a valid Node.js project (missing package.json)"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured or invalid"
        log_info "Run: aws configure"
        exit 1
    fi
    
    log_info "AWS credentials validated"
    
    # Create deployment package
    log_step "Creating deployment package"
    
    # Create a temporary directory for the package
    TEMP_DIR=$(mktemp -d)
    
    # Copy function code
    if [ -f "index.js" ]; then
        cp index.js "$TEMP_DIR/"
    elif [ -f "lambda.js" ]; then
        cp lambda.js "$TEMP_DIR/index.js"
    elif [ -f "handler.js" ]; then
        cp handler.js "$TEMP_DIR/index.js"
    else
        log_error "No Lambda function file found (index.js, lambda.js, or handler.js)"
        exit 1
    fi
    
    # Install production dependencies if package.json exists
    if [ -f "package.json" ]; then
        cp package.json "$TEMP_DIR/"
        if [ -f "package-lock.json" ]; then
            cp package-lock.json "$TEMP_DIR/"
        fi
        
        cd "$TEMP_DIR"
        npm install --production
        cd -
    fi
    
    # Create ZIP file
    cd "$TEMP_DIR"
    zip -r "../$FUNCTION_NAME.zip" .
    cd -
    
    log_info "Deployment package created: $FUNCTION_NAME.zip"
    
    # Create IAM role for Lambda if it doesn't exist
    log_step "Setting up IAM role"
    
    # Check if role exists
    if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
        log_info "Creating IAM role: $ROLE_NAME"
        
        # Create trust policy document
        cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
        
        # Create role
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file://trust-policy.json
        
        # Attach basic execution policy
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        
        # Wait for role to propagate
        log_info "Waiting for IAM role to propagate..."
        sleep 10
    else
        log_info "Using existing IAM role: $ROLE_NAME"
    fi
    
    # Get role ARN
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query "Role.Arn" --output text)
    
    # Check if function exists
    if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
        # Update existing function
        log_step "Updating existing Lambda function: $FUNCTION_NAME"
        
        aws lambda update-function-code \
            --function-name "$FUNCTION_NAME" \
            --zip-file "fileb://$FUNCTION_NAME.zip" \
            --region "$REGION"
        
        aws lambda update-function-configuration \
            --function-name "$FUNCTION_NAME" \
            --runtime "$RUNTIME" \
            --handler "$HANDLER" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY_SIZE" \
            --region "$REGION"
    else
        # Create new function
        log_step "Creating new Lambda function: $FUNCTION_NAME"
        
        aws lambda create-function \
            --function-name "$FUNCTION_NAME" \
            --runtime "$RUNTIME" \
            --handler "$HANDLER" \
            --role "$ROLE_ARN" \
            --zip-file "fileb://$FUNCTION_NAME.zip" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY_SIZE" \
            --region "$REGION"
    fi
    
    # Create API Gateway trigger (optional)
    if [ "${API_GATEWAY:-false}" == "true" ]; then
        log_step "Setting up API Gateway trigger"
        
        # Check if API exists
        API_ID=$(aws apigateway get-rest-apis --query "items[?name=='$FUNCTION_NAME-api'].id" --output text --region "$REGION")
        
        if [ -z "$API_ID" ] || [ "$API_ID" == "None" ]; then
            # Create new API
            log_info "Creating new API Gateway"
            
            API_ID=$(aws apigateway create-rest-api \
                --name "$FUNCTION_NAME-api" \
                --region "$REGION" \
                --query "id" --output text)
            
            # Get root resource ID
            RESOURCE_ID=$(aws apigateway get-resources \
                --rest-api-id "$API_ID" \
                --region "$REGION" \
                --query "items[0].id" --output text)
            
            # Create resource
            RESOURCE_ID=$(aws apigateway create-resource \
                --rest-api-id "$API_ID" \
                --parent-id "$RESOURCE_ID" \
                --path-part "{proxy+}" \
                --region "$REGION" \
                --query "id" --output text)
            
            # Create ANY method
            aws apigateway put-method \
                --rest-api-id "$API_ID" \
                --resource-id "$RESOURCE_ID" \
                --http-method "ANY" \
                --authorization-type "NONE" \
                --region "$REGION"
            
            # Create integration
            aws apigateway put-integration \
                --rest-api-id "$API_ID" \
                --resource-id "$RESOURCE_ID" \
                --http-method "ANY" \
                --type "AWS_PROXY" \
                --integration-http-method "POST" \
                --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$(aws sts get-caller-identity --query "Account" --output text):function:$FUNCTION_NAME/invocations" \
                --region "$REGION"
            
            # Deploy API
            aws apigateway create-deployment \
                --rest-api-id "$API_ID" \
                --stage-name "prod" \
                --region "$REGION"
            
            # Add permission for API Gateway to invoke Lambda
            aws lambda add-permission \
                --function-name "$FUNCTION_NAME" \
                --statement-id "apigateway-prod" \
                --action "lambda:InvokeFunction" \
                --principal "apigateway.amazonaws.com" \
                --source-arn "arn:aws:execute-api:$REGION:$(aws sts get-caller-identity --query "Account" --output text):$API_ID/prod/ANY/{proxy+}" \
                --region "$REGION"
            
            API_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/prod"
            log_info "API Gateway URL: $API_URL"
        else
            log_info "Using existing API Gateway: $API_ID"
            API_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/prod"
        fi
    fi
    
    # Clean up
    rm -rf "$TEMP_DIR" trust-policy.json 2>/dev/null || true
    
    # Get function details
    FUNCTION_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --query "Configuration.FunctionArn" --output text --region "$REGION")
    
    log_success "Lambda function deployed successfully!"
    echo
    echo "Function: $FUNCTION_NAME"
    echo "ARN: $FUNCTION_ARN"
    echo "Region: $REGION"
    echo "Runtime: $RUNTIME"
    echo "Handler: $HANDLER"
    echo "Memory: $MEMORY_SIZE MB"
    echo "Timeout: $TIMEOUT seconds"
    if [ "${API_GATEWAY:-false}" == "true" ]; then
        echo "API URL: $API_URL"
    fi
    echo
    echo "Test your function:"
    echo "aws lambda invoke --function-name $FUNCTION_NAME --payload '{}' response.json --region $REGION"
    echo
    echo "View logs:"
    echo "aws logs filter-log-events --log-group-name /aws/lambda/$FUNCTION_NAME --region $REGION"
}

main "$@"