import json

def lambda_handler(event, context):
    # TODO implement
    a=10
    b=10
    c=a+b
    return {
        'statusCode': 200,
        'body': json.dumps(c)
    }
