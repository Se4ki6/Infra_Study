import json

def lambda_handler(event, context):
    # API Gatewayからのリクエスト情報を取得
    print("Received event: " + json.dumps(event, indent=2))

    # レスポンスボディの作成
    body = {
        "message": "Hello from Lambda!",
        "input": event
    }

    # プロキシ統合用レスポンス
    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            # CORS設定: 全ドメインからのアクセスを許可
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps(body)
    }

    return response
