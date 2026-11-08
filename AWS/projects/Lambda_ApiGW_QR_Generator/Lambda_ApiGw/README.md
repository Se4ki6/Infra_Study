# Lambda_ApiGW_QR_Generator

URLを入力するとQRコードを生成して返すサーバーレスAPIです。AWS Lambda + API Gateway (HTTP API)を使用し、Terraformでインフラを管理しています。

## 📋 概要

このプロジェクトは、クエリパラメータで指定されたURLからQRコード画像を生成するシンプルなAPIです。

### 主な機能

- **QRコード生成**: URLを受け取り、PNG形式のQRコード画像を返却
- **サーバーレス**: AWS Lambdaを使用した完全マネージド構成
- **低コスト**: HTTP APIを採用し、REST APIより約70%低コスト
- **環境分離**: dev/prod環境を簡単に切り替え可能

### 使用技術

- **AWS Lambda** (Python 3.13)
- **API Gateway** (HTTP API)
- **Terraform** (Infrastructure as Code)
- **segno** (QRコード生成ライブラリ)

---

## 🚀 使用方法

### 前提条件

- AWS CLIの設定完了（認証情報設定済み）
- Terraform v1.0以上
- PowerShell（Windows）またはBash（Linux/Mac）
- Python 3.13（ビルド用）
- pip（Pythonパッケージマネージャー）

### デプロイ手順

#### 1. 初回ビルド（必須）

**初回のみ、Lambdaデプロイパッケージを手動でビルドする必要があります：**

```powershell
# Windows
.\script\build.ps1

# Linux/Mac
./script/build.sh
```

このスクリプトは以下を実行します：

- `requirements.txt`に記載された依存ライブラリをインストール
- Lambda関数コード（`handler.py`）と一緒にZIPファイルを作成
- `lambda_function_payload.zip`を生成

**注意:** 2回目以降は、`terraform apply`時に自動的にビルドされます（`handler.py`または`requirements.txt`に変更があった場合のみ）。

#### 2. 環境変数の設定

`dev.tfvars`または`prod.tfvars`を編集：

```hcl
environment = "dev"  # または "prod"
aws_region  = "ap-northeast-1"
is_windows  = true   # Windows環境の場合true、Linux/Macの場合false
```

#### 2. 環境変数の設定

`dev.tfvars`または`prod.tfvars`を編集：

```hcl
environment = "dev"  # または "prod"
aws_region  = "ap-northeast-1"
is_windows  = true   # Windows環境の場合true、Linux/Macの場合false
```

#### 3. Terraformでデプロイ

```powershell
# 初期化
terraform init

# 計画確認（dev環境の場合）
terraform plan -var-file="dev.tfvars"

# 適用
terraform apply -var-file="dev.tfvars"
```

**注意:** `handler.py`または`requirements.txt`に変更があった場合、Terraformが自動的に再ビルドを実行します。

#### 4. APIエンドポイントの確認

デプロイ完了後、API URLが出力されます：

```
api_endpoint = "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/generate"
```

### API疎通確認（テスト）

デプロイ後、APIが正常に動作しているか確認できます。

**自動テストスクリプト:**

```powershell
# Windows
.\script\test.ps1 "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com"

# Linux/Mac
./script/test.sh "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com"
```

テストスクリプトは以下を確認します：

- HTTPステータスコード200が返るか
- レスポンスヘッダーの確認
- 成功/失敗を色付きで表示

**terraform apply後の出力例:**

```
test_command_windows = ".\test.ps1 \"https://xxxxx.execute-api.ap-northeast-1.amazonaws.com\""
```

出力されたコマンドをそのままコピー＆ペーストして実行できます。

### API使用例

**QRコード画像をダウンロード:**

```powershell
# curlでリクエスト
curl "https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/generate?url=https://github.com" --output qr.png
```

**ブラウザから直接アクセス:**

```
https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/generate?url=https://example.com
```

**レスポンス:**

- `200 OK` - PNG画像（Base64エンコード済み）
- `Content-Type: image/png`

---

## 📊 最新コードレビュー（第2回）

**実施日:** 2026年1月17日<br>
**総合スコア:** 80/100

### ✅ 良い点

1. **適切なファイル分割** - Terraformコードが役割ごとに整理されメンテナンス性が高い
2. **環境分離** - dev/prod.tfvarsで環境を適切に管理
3. **最小権限の原則** - Lambda IAMロールが適切に設定
4. **HTTP APIの採用** - REST APIより軽量で低コスト
5. **最新ランタイム** - Python 3.13を使用
6. **ビルドスクリプト** - Windows/Linux両対応の自動化

### ⚠️ 改善が必要な項目

#### 1. エラーハンドリング（最優先）⭐

**現状の課題:**

- `url`パラメータのバリデーションがない
- URL長の制限チェックがない
- 例外発生時のエラーレスポンスが未実装

**必要な対応:**

- 必須パラメータチェック
- URL長制限（max 2000文字）によるDDoS対策
- ユーザーフレンドリーなエラーメッセージ
- CloudWatchへのエラーログ出力

#### 2. Lambda関数の最適化（推奨）

- タイムアウト設定（推奨: 10秒）
- メモリサイズ設定（推奨: 256MB）
- CloudWatch Logsの保持期間設定

#### 3. API Gatewayのスロットリング（推奨）

- バーストリミット設定（推奨: 100）
- レートリミット設定（推奨: 50 req/sec）

詳細は [review.md](../docs/Lambda_ApiGW_QR_Generator/review.md) を参照してください。

---

## 📝 ToDo

### 必須（本番リリース前）

- [ ] **handler.pyのエラーハンドリング実装**（最優先）
  - 必須パラメータバリデーション
  - URL長制限チェック
  - 例外処理の追加
  - Cache-Controlヘッダーの追加

### 推奨（段階的改善）

- [ ] Lambda関数のタイムアウト/メモリ設定
- [ ] CloudWatch Logsの保持期間設定
- [ ] API Gatewayのスロットリング設定
- [ ] main.tfで処理順や関連性を分かりやすく記述
- [ ] ZIPファイルの差分チェック機能（パフォーマンス最適化）

### 完了済み

- [x] リソース名の環境別化（`var.environment`追加）
- [x] Pythonランタイム更新（python3.13）
- [x] ZIPファイル管理（.gitignore設定）
- [x] Windows対応（build.ps1作成）
- [x] lambdaフォルダの命名改善（lambda_codeに変更）
- [x] READMEの作成
- [x] curlでの疎通確認用テストスクリプト（test.ps1/test.sh）
- [x] シェルスクリプトのTerraform側での自動実行

詳細は [todo.md](../docs/Lambda_ApiGW_QR_Generator/todo.md) を参照してください。

---

## 📁 ファイル構成

```
Lambda_ApiGW_QR_Generator/
├── main.tf              # プロバイダー設定
├── lambda.tf            # Lambda関連リソース定義（ZIPビルド自動化含む）
├── api_gateway.tf       # API Gateway関連リソース定義
├── outputs.tf           # 出力値定義
├── variable.tf          # 変数定義
├── dev.tfvars           # 開発環境用変数
├── prod.tfvars          # 本番環境用変数
├── script/
│   ├── build.ps1        # ビルドスクリプト（Windows）※Terraformから自動実行
│   ├── build.sh         # ビルドスクリプト（Linux/Mac）※Terraformから自動実行
│   ├── test.ps1         # API疎通確認テスト（Windows）
│   └── test.sh          # API疎通確認テスト（Linux/Mac）
├── lambda_code/
│   ├── handler.py       # Lambdaハンドラー
│   └── requirements.txt # Python依存関係
└── README.md            # このファイル
```

---

## 🔧 リソース構成

### Lambda Function

- **関数名**: `qr-generator-{environment}`
- **ランタイム**: Python 3.13
- **ハンドラー**: `handler.lambda_handler`
- **IAMロール**: AWSLambdaBasicExecutionRole

### API Gateway

- **タイプ**: HTTP API
- **API名**: `qr-generator-api-{environment}`
- **ルート**: `GET /generate`
- **統合**: Lambda Proxy統合

---

## 💰 コスト見積もり

**月間100万リクエストの場合:**

- Lambda: 約$0.20
- API Gateway (HTTP API): 約$1.00
- CloudWatch Logs: 約$0.50

**合計: 約$1.70/月**

---

## 🔐 セキュリティ考慮事項

- ✅ 最小権限IAMポリシー適用
- ✅ CORS設定によるオリジン制御
- ⚠️ 入力バリデーション（要実装）
- ⚠️ レート制限（要実装）

---

## 📚 参考資料

- [設計ドキュメント](../docs/Lambda_ApiGW_QR_Generator/design.md)
- [コードレビュー](../docs/Lambda_ApiGW_QR_Generator/review.md)
- [ToDo](../docs/Lambda_ApiGW_QR_Generator/todo.md)
- [AWS Lambda公式ドキュメント](https://docs.aws.amazon.com/lambda/)
- [API Gateway HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)

---

## 📄 ライセンス

このプロジェクトは個人学習用です。
