// Example AWS Lambda function
// Simple API endpoint that returns a greeting

exports.handler = async (event) => {
    console.log('Event received:', JSON.stringify(event, null, 2));
    
    // Get name from query string or path parameter
    let name = 'World';
    
    if (event.queryStringParameters && event.queryStringParameters.name) {
        name = event.queryStringParameters.name;
    } else if (event.pathParameters && event.pathParameters.name) {
        name = event.pathParameters.name;
    } else if (event.body) {
        try {
            const body = JSON.parse(event.body);
            if (body.name) {
                name = body.name;
            }
        } catch (error) {
            console.error('Error parsing body:', error);
        }
    }
    
    // Create response
    const response = {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*', // For CORS support
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
        },
        body: JSON.stringify({
            message: `Hello, ${name}!`,
            timestamp: new Date().toISOString()
        })
    };
    
    return response;
};