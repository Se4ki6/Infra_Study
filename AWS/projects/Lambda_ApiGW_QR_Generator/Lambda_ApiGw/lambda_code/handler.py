import segno
import io
import base64
import json

def lambda_handler(event, context):
    # クエリパラメータからURLを取得
    query_params = event.get('queryStringParameters', {})
    target_url = query_params.get('url', 'https://google.com') if query_params else 'https://google.com'

    # QRコードをメモリ上で生成
    out = io.BytesIO()
    qrcode = segno.make(target_url)
    qrcode.save(out, kind='png', scale=5)

    # Base64エンコード
    qr_base64 = base64.b64encode(out.getvalue()).decode('utf-8')

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'image/png',
            'Access-Control-Allow-Origin': '*'
        },
        'body': qr_base64,
        'isBase64Encoded': True
    }
