import json
from chunk_service import ChunkService

service = None

def lambda_handler(event, context):
    """AWS Lambda entry point for validating video chunk hashes.

    This handler manages the API Gateway event lifecycle: handles CORS preflight 
    requests, parses and validates the JSON payload, and delegates deduplication 
    logic to the ChunkService using a lazy-loading initialization strategy.

    Args:
        event (dict): AWS API Gateway Proxy event containing request data.
        context (LambdaContext): Runtime information provided by AWS Lambda.

    Returns:
        dict: An API Gateway-compliant response object containing the status code,
            CORS headers, and a serialized JSON body.
    """
    global service
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "")
    
    if http_method == "OPTIONS":
        return build_response(200, {})

    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return build_response(400, {'error': 'Invalid JSON'})

    hashes = body.get('hashes')
    if not isinstance(hashes, list) or not hashes:
        return build_response(400, {'error': 'Missing or invalid hashes'})

    try:
        if service is None:
            print("🚀 First invocation (Cold Start): Initializing ChunkService...")
            service = ChunkService()
        
        result = service.check_chunks(hashes)
        return build_response(200, result)
    except Exception as e:
        print(f"❌ Internal Server Error: {e}")
        return build_response(500, {'error': 'Internal server error'})

def build_response(status_code, body):
    """Construct a standardized API Gateway proxy response object.

    Args:
        status_code (int): The HTTP status code for the response.
        body (dict): The dictionary payload to be serialized into the JSON body.

    Returns:
        dict: Formatted proxy response dictionary equipped with full CORS headers.
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Request-ID',
            'Access-Control-Allow-Methods': 'POST, OPTIONS'
        },
        'body': json.dumps(body)
    }
