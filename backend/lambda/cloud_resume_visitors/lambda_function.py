import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cloud-resume-visitors')

CORS_HEADERS = {
    'Access-Control-Allow-Origin': 'https://randy-sykes.me',
    'Content-Type': 'application/json'
}

def lambda_handler(event, context):
    try:
        if event.get('httpMethod') == 'GET':
            response = table.get_item(Key={'id': 'visitor_count'})
            item = response.get('Item')
            count = int(item['count']) if item else 0
        else:
            response = table.update_item(
                Key={'id': 'visitor_count'},
                UpdateExpression='ADD #c :incr',
                ExpressionAttributeNames={'#c': 'count'},
                ExpressionAttributeValues={':incr': 1},
                ReturnValues='UPDATED_NEW'
            )
            count = int(response['Attributes']['count'])
    except ClientError:
        return {
            'statusCode': 500,
            'headers': CORS_HEADERS,
            'body': json.dumps({'error': 'Unable to reach visitor counter database'})
        }

    return {
        'statusCode': 200,
        'headers': CORS_HEADERS,
        'body': json.dumps({'count': count})
    }
