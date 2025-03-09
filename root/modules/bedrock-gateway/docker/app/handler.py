import os
import json
import boto3
from aws_lambda_powertools import Logger

logger = Logger()
bedrock = boto3.client('bedrock-runtime')

@logger.inject_lambda_context
def lambda_handler(event, context):
    try:
        # Basic health check
        if event.get('requestContext', {}).get('http', {}).get('path') == '/health':
            return {
                'statusCode': 200,
                'body': json.dumps({'status': 'healthy'})
            }

        # Your Bedrock integration logic here
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Bedrock Gateway running'})
        }

    except Exception as e:
        logger.exception("Error processing request")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        } 