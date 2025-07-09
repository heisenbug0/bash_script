# AWS Lambda Example Function

This is a simple example Lambda function that can be deployed using the deployment script.

## Function Overview

This function:
- Accepts HTTP requests via API Gateway
- Returns a greeting message
- Supports query parameters, path parameters, and JSON body
- Includes CORS headers for browser access

## How to Deploy

```bash
# Copy the example files to your working directory
cp -r example/* .

# Deploy the function
export FUNCTION_NAME="hello-world"
export API_GATEWAY="true"
./deploy.sh
```

## Testing the Function

### Via AWS CLI
```bash
# Invoke directly
aws lambda invoke \
  --function-name hello-world \
  --payload '{"queryStringParameters":{"name":"Alice"}}' \
  response.json

# View response
cat response.json
```

### Via API Gateway URL
After deployment, you'll receive an API Gateway URL. You can test it with:

```bash
# Using curl
curl "https://your-api-id.execute-api.region.amazonaws.com/prod?name=Alice"

# Or open in a browser
https://your-api-id.execute-api.region.amazonaws.com/prod?name=Alice
```

## Customizing the Function

Edit `index.js` to modify the function's behavior:

```javascript
exports.handler = async (event) => {
    // Your custom logic here
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: "Your custom response"
        })
    };
};
```

## Adding Dependencies

If your function needs external packages:

1. Add them to `package.json`:
   ```json
   "dependencies": {
     "axios": "^1.3.4",
     "uuid": "^9.0.0"
   }
   ```

2. Install locally before deploying:
   ```bash
   npm install
   ```

3. Deploy as usual:
   ```bash
   ./deploy.sh
   ```

The deployment script will include all dependencies in the deployment package.

## Next Steps

- Add environment variables for configuration
- Connect to other AWS services like DynamoDB
- Set up scheduled events with CloudWatch Events
- Implement authentication with API Gateway authorizers