# AWS Lambda Deployment

Deploy serverless functions to AWS Lambda with one command.

## What You Get

- **Lambda function** deployed to AWS
- **IAM role** with basic execution permissions
- **API Gateway** integration (optional)
- **Proper packaging** with dependencies
- **Automatic updates** for existing functions

## Quick Start

```bash
export FUNCTION_NAME="my-function"
export RUNTIME="nodejs18.x"
export API_GATEWAY="true"  # optional
./deploy.sh
```

## Requirements

### For Node.js Functions
Your project should have:
- `index.js` with a handler function
- `package.json` with dependencies (optional)

### AWS Setup
- AWS CLI installed and configured
- AWS credentials with Lambda permissions

## Example Function

```javascript
// index.js
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Hello from Lambda!',
            timestamp: new Date().toISOString()
        }),
        headers: {
            'Content-Type': 'application/json'
        }
    };
};
```

## Environment Variables

```bash
export FUNCTION_NAME="my-function"   # Lambda function name
export RUNTIME="nodejs18.x"         # Lambda runtime
export HANDLER="index.handler"       # Function handler
export MEMORY_SIZE="128"            # Memory in MB
export TIMEOUT="30"                 # Timeout in seconds
export REGION="us-east-1"           # AWS region
export API_GATEWAY="true"           # Create API Gateway (true/false)
```

## What Happens

1. **Package creation** - Function code and dependencies zipped
2. **IAM setup** - Role created with basic permissions
3. **Function deployment** - Lambda function created or updated
4. **API Gateway** - REST API created (if enabled)
5. **Permissions** - API Gateway allowed to invoke Lambda

## After Deployment

Your function will be available:
- Directly via Lambda: `aws lambda invoke`
- Via API Gateway: `https://xxx.execute-api.region.amazonaws.com/prod/`

### Testing Your Function

```bash
# Invoke directly
aws lambda invoke \
  --function-name my-function \
  --payload '{"key": "value"}' \
  response.json

# View response
cat response.json

# Check logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/my-function
```

## API Gateway Integration

If you enable API Gateway (`API_GATEWAY=true`), the script:
1. Creates a new REST API
2. Sets up a catch-all proxy resource
3. Configures Lambda integration
4. Deploys to a "prod" stage
5. Sets up necessary permissions

Your API will be available at the URL shown after deployment.

## Function Updates

To update an existing function:
1. Modify your code
2. Run the script again with the same function name
3. The function code and configuration will be updated

## Troubleshooting

**Deployment failed?**
- Check AWS credentials: `aws sts get-caller-identity`
- Verify IAM permissions for Lambda and IAM roles
- Check for syntax errors in your function code

**Function not executing?**
- Check CloudWatch logs: `aws logs filter-log-events --log-group-name /aws/lambda/your-function`
- Verify handler name matches your code
- Check timeout settings for long-running functions

**API Gateway not working?**
- Test Lambda directly first to isolate the issue
- Check API Gateway logs in CloudWatch
- Verify Lambda permissions allow API Gateway invocation

## Advanced Usage

### Environment Variables for Lambda
```bash
# Add environment variables to your function
aws lambda update-function-configuration \
  --function-name my-function \
  --environment "Variables={KEY1=value1,KEY2=value2}"
```

### Custom IAM Policies
```bash
# Attach additional policies to the Lambda role
aws iam attach-role-policy \
  --role-name lambda-basic-execution \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

### VPC Configuration
```bash
# Configure Lambda to run in a VPC
aws lambda update-function-configuration \
  --function-name my-function \
  --vpc-config SubnetIds=subnet-id1,subnet-id2,SecurityGroupIds=sg-id
```

Perfect for serverless APIs, event processing, and backend functions.