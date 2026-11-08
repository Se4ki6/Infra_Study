import json

def lambda_handler(event, context):
    print("Function started")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Terraform Lambda!')
    }