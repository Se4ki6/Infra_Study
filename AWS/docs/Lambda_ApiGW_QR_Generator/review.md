# Lambda_ApiGW_QR_Generator プロジェクトレビュー

**レビュー実施日:** 2026年1月17日<br>
**レビュー回数:** 2回目

---

## 📋 前回（1回目）からの修正状況

### ✅ 対応済み

1. **リソース名の環境別化** - すべてのリソース名に`var.environment`を追加
2. **Pythonランタイム更新** - `python3.13`に更新完了
3. **ZIPファイル管理** - `.gitignore`に必要な除外設定を追加
4. **Windows対応** - `build.ps1`が既に存在

### ⚠️ 未対応

1. **エラーハンドリング** - `handler.py`で入力バリデーションとエラー処理が未実装

---

---

## ✅ **良い点**

1. **適切なファイル分割** - Terraformコードが役割ごとに分離されており、メンテナンス性が高い
2. **環境分離** - dev/prod.tfvarsで環境を適切に管理し、リソース名にも環境変数を反映
3. **最小権限の原則** - LambdaにAWSLambdaBasicExecutionRoleのみを付与
4. **HTTP APIの採用** - REST APIより軽量で低コストなHTTP APIを使用
5. **ビルドスクリプト** - 依存関係を含めたZIPパッケージ作成が自動化（Windows/Linux両対応）
6. **最新ランタイム** - Python 3.13を使用しており長期サポートが保証される
7. **適切なGit管理** - ビルド成果物と機密情報を`.gitignore`で除外

---

## ⚠️ **残りの改善提案**

### 1. **エラーハンドリングの不足** ⭐ 最優先

**現状の問題:**
`handler.py`でURLバリデーションやエラーハンドリングがありません。現在は：

- `url`パラメータが必須でない（デフォルト値使用）
- URL長の制限チェックなし
- 例外発生時に適切なエラーレスポンスを返さない

**推奨修正:**

```python
import segno
import io
import base64
import json

def lambda_handler(event, context):
    try:
        # クエリパラメータのバリデーション
        query_params = event.get('queryStringParameters', {})
        if not query_params or 'url' not in query_params:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'url parameter is required',
                    'usage': '/generate?url=https://example.com'
                })
            }

        target_url = query_params['url']

        # URL長の制限（QRコード生成の限界を考慮）
        if len(target_url) > 2000:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'URL too long (max 2000 chars)'})
            }

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
                'Access-Control-Allow-Origin': '*',
                'Cache-Control': 'public, max-age=3600'  # 1時間キャッシュ
            },
            'body': qr_base64,
            'isBase64Encoded': True
        }

    except Exception as e:
        print(f"Error generating QR code: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }
```

**改善効果:**

- ✅ 必須パラメータチェック
- ✅ URL長制限によるDDoS対策
- ✅ ユーザーフレンドリーなエラーメッセージ
- ✅ CloudWatchへのエラーログ出力
- ✅ Cache-Controlヘッダーによるパフォーマンス向上

---

## 💡 **追加の最適化提案（オプション）**

### 2. **Lambda関数のタイムアウトとメモリ設定**

現在は明示的な設定がないため、デフォルト値が使用されています。

**推奨追加:**

```terraform
resource "aws_lambda_function" "qr_generator" {
  # ... 既存の設定 ...

  timeout     = 10  # QR生成は通常1-2秒で完了
  memory_size = 256 # 画像処理に十分なメモリ

  # コールドスタート対策（オプション）
  reserved_concurrent_executions = 1  # dev環境のみ
}
```

### 3. **CloudWatch Logs保持期間の設定**

コスト最適化のため、ログ保持期間を明示的に設定することを推奨します。

**推奨追加（lambda.tf）:**

```terraform
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.qr_generator.function_name}"
  retention_in_days = var.environment == "prod" ? 30 : 7
}
```

### 4. **API Gateway スロットリング設定**

DDoS対策として、リクエスト数の制限を推奨します。

**推奨追加（api_gateway.tf）:**

```terraform
resource "aws_apigatewayv2_stage" "lambda_api" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }
}
```

---

## 📊 **総合評価**

| 項目           | 状態 | 評価                             |
| -------------- | ---- | -------------------------------- |
| コード構成     | ✅   | 優秀                             |
| 環境管理       | ✅   | 優秀                             |
| セキュリティ   | ⚠️   | 要改善（エラーハンドリング）     |
| 保守性         | ✅   | 良好                             |
| ドキュメント   | ✅   | 良好                             |
| パフォーマンス | ⚠️   | 改善余地あり（キャッシュ未設定） |

**総合スコア:** 80/100

---

## 🎯 **次のアクション**

### 必須（本番リリース前）

1. ✅ リソース名の環境別化 → **完了**
2. ✅ Pythonランタイム更新 → **完了**
3. ✅ .gitignore設定 → **完了**
4. ⚠️ **エラーハンドリング実装** → **未完了（最優先）**

### 推奨（段階的改善）

5. Lambda関数のタイムアウト/メモリ設定
6. CloudWatch Logsの保持期間設定
7. API Gatewayのスロットリング設定

---

## 📝 **コメント**

前回レビューの指摘事項のうち、インフラ関連の修正は全て完了しており、素晴らしい対応でした。残る課題は**handler.pyのエラーハンドリング実装**のみです。

現在のコードは正常系は動作しますが、本番環境では想定外の入力や障害に対する堅牢性が必要です。上記のエラーハンドリングを実装すれば、本番リリース可能な品質になります。

特に以下の点で大きく改善されました：

- ✅ 環境ごとに独立したリソースが作成可能
- ✅ 最新のPythonランタイムで長期サポート確保
- ✅ 適切なGit管理でチーム開発に対応

次回のレビューでエラーハンドリングが実装されていれば、**本番リリースを推奨**できる状態になります。
