# S3 署名付き URL の自動化方法

最終更新: 2025-11-29

## 概要

S3 の署名付き URL（Presigned URL）を毎回手動でスクリプト実行せずに自動化する方法について解説します。
署名付き URL は**アクセス時に動的に生成**するのがベストプラクティスです。

## 自動化オプション

### 1. AWS Lambda + API Gateway（推奨）

最も一般的で本番環境向けの方法です。

```
クライアント → API Gateway → Lambda → S3署名付きURL生成 → クライアントに返却
```

**メリット:**

- サーバーレスで運用コスト低
- スケーラブル
- セキュアな認証との統合が容易

**実装例:**

```python
import json
import boto3
import os

def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    bucket = os.environ['BUCKET_NAME']
    key = event['pathParameters']['filename']

    url = s3_client.generate_presigned_url(
        'get_object',
        Params={'Bucket': bucket, 'Key': f"images/{key}"},
        ExpiresIn=3600
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'url': url})
    }
```

### 2. アプリケーションバックエンド組み込み

既存の Web アプリケーションがある場合、バックエンドに組み込む方法。

**Flask の例:**

```python
from flask import Flask, jsonify
from presigned_url_generator import PresignedURLGenerator

app = Flask(__name__)
generator = PresignedURLGenerator()

@app.route('/api/images/<filename>/url')
def get_image_url(filename):
    result = generator.generate_presigned_url(filename)
    return jsonify(result)
```

**FastAPI の例:**

```python
from fastapi import FastAPI
from presigned_url_generator import PresignedURLGenerator

app = FastAPI()
generator = PresignedURLGenerator()

@app.get("/api/images/{filename}/url")
async def get_image_url(filename: str):
    return generator.generate_presigned_url(filename)
```

### 3. CloudFront + 署名付き Cookie/URL

大規模配信や CDN が必要な場合に推奨。

```
クライアント → CloudFront（署名付きURL/Cookie） → S3オリジン
```

**メリット:**

- 高速なコンテンツ配信
- エッジキャッシング
- 地理的に分散したアクセスに最適

### 4. 定期的なバッチ生成（非推奨）

cron ジョブなどで定期的に URL を生成する方法。

**注意:** 署名付き URL は有効期限があるため、この方法は限定的なユースケースのみ適切です。

## 現在のスクリプトの位置づけ

`scripts/generate_presigned_url.py` の主な用途:

| 用途         | 説明                     |
| ------------ | ------------------------ |
| 開発・テスト | ローカル環境での動作確認 |
| 管理者用途   | 必要時に手動で URL 発行  |
| プロトタイプ | Lambda 化の前段階として  |
| 学習目的     | boto3 の使い方を理解     |

## 推奨アーキテクチャ

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  クライアント  │────▶│ API Gateway  │────▶│   Lambda    │
└─────────────┘     └──────────────┘     └──────┬──────┘
       ▲                                        │
       │                                        ▼
       │                               ┌─────────────┐
       │◀─────── 署名付きURL ──────────│     S3      │
       │                               └─────────────┘
       │
       ▼
┌─────────────┐
│ 署名付きURLで │
│  画像を取得   │
└─────────────┘
```

## 実装の優先順位

1. **開発段階**: ローカルスクリプト（現在）
2. **ステージング**: Lambda + API Gateway
3. **本番環境**: Lambda + API Gateway + CloudFront（必要に応じて）

## 関連リソース

- [AWS Lambda 開発者ガイド](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Amazon API Gateway 開発者ガイド](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)
- [S3 署名付き URL - AWS SDK for Python](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-presigned-urls.html)
- [CloudFront 署名付き URL と署名付き Cookie](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html)
