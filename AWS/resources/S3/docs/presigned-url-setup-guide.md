# S3 署名付き URL セットアップガイド

最終更新: 2025-11-29

## ✅ 実装完了状況

| ステップ   | 内容                           | 状態    |
| ---------- | ------------------------------ | ------- |
| ステップ 1 | IAM ポリシー・ユーザー・ロール | ✅ 完了 |
| ステップ 2 | 画像専用プレフィックス設定     | ✅ 完了 |
| ステップ 3 | URL 生成スクリプト             | ✅ 完了 |

---

## 🚀 実行手順

### 1. Terraform でインフラをデプロイ

```powershell
cd C:\Users\sksrd\Programing\AWS\S3

# 設定の確認
terraform plan

# デプロイ実行
terraform apply
```

### 2. IAM 認証情報を取得

```powershell
# アクセスキーIDの取得
terraform output -raw iam_access_key_id

# シークレットキーの取得
terraform output -raw iam_secret_access_key
```

### 3. Python 環境のセットアップ

```powershell
cd C:\Users\sksrd\Programing\AWS\S3\scripts

# 依存パッケージのインストール（仮想環境が有効な状態で）
pip install -r requirements.txt
```

### 4. 環境変数ファイルの作成

```powershell
# .env.example をコピーして .env を作成
Copy-Item .env.example .env
```

`.env` ファイルを編集して、取得した認証情報を設定：

```dotenv
# AWS認証情報（terraform outputで取得した値を入力）
AWS_ACCESS_KEY_ID=実際のアクセスキーID
AWS_SECRET_ACCESS_KEY=実際のシークレットキー
AWS_REGION=ap-southeast-2

# S3設定（terraform.tfvarsのbucket_nameを入力）
S3_BUCKET_NAME=あなたのバケット名
S3_IMAGES_PREFIX=images

# 署名付きURLの有効期限（秒）
PRESIGNED_URL_EXPIRATION=3600
```

### 5. 署名付き URL の生成

```powershell
# 利用可能な画像のリスト表示
python generate_presigned_url.py --list

# 特定の画像の署名付きURL生成
python generate_presigned_url.py zushihokki1.png
```

---

## 📁 ファイル構成

```
S3/
├── iam.tf              ← IAMポリシー/ユーザー/ロール定義
├── main.tf             ← S3バケット + 画像アップロード設定
├── variables.tf        ← 変数定義
├── outputs.tf          ← 出力定義
├── terraform.tfvars    ← 設定値
├── scripts/
│   ├── generate_presigned_url.py  ← URL生成スクリプト
│   ├── requirements.txt           ← Python依存パッケージ
│   └── .env.example               ← 環境変数テンプレート
└── upload_file/
    └── images/
        ├── zushihokki1.png
        ├── zushihokki2.jpg
        └── zushihokki3.gif
```

---

## ⚠️ 重要な注意事項

1. **`.env` ファイルは Git にコミットしない**（`.gitignore` に追加済みか確認）
2. **アクセスキーは安全に保管**する
3. **本番環境では IAM ロールの使用を推奨**（`create_iam_role = true` に変更）

---

## 🔧 スクリプト使用方法

### 画像リストの表示

```powershell
python generate_presigned_url.py --list
```

出力例：

```
利用可能な画像ファイル（バケット: your-bucket-name）:
------------------------------------------------------------
  zushihokki1.png
  zushihokki2.jpg
  zushihokki3.gif
```

### 署名付き URL の生成

```powershell
python generate_presigned_url.py zushihokki1.png
```

出力例：

```
================================================================================
署名付きURL生成成功
================================================================================
オブジェクトキー: images/zushihokki1.png
有効期限: 3600秒 (60分)
期限切れ日時: 2025-11-29T15:30:00.000000

署名付きURL:
--------------------------------------------------------------------------------
https://your-bucket.s3.ap-southeast-2.amazonaws.com/images/zushihokki1.png?...
--------------------------------------------------------------------------------

このURLは上記の有効期限まで使用できます。
================================================================================
```

---

## 🔍 トラブルシューティング

### 認証エラー

**エラー**: `NoCredentialsError: Unable to locate credentials`

**解決方法**:

- `.env` ファイルが正しく設定されているか確認
- AWS 認証情報が有効か確認
- `terraform output` で IAM アクセスキーを再取得

### 権限エラー

**エラー**: `AccessDenied: Access Denied`

**解決方法**:

- IAM ポリシーが正しくアタッチされているか確認
- バケット名が正しいか確認
- `terraform apply` を再実行

### オブジェクトが見つからない

**エラー**: `404 Not Found` または `オブジェクトが見つかりません`

**解決方法**:

```powershell
# S3内のオブジェクトを確認
aws s3 ls s3://your-bucket-name/images/ --recursive

# Terraformで再アップロード
terraform apply
```

---

## 📚 関連ドキュメント

- [presigned-url-implementation-plan.md](../plan/presigned-url-implementation-plan.md) - 詳細な実装プラン
- [presigned-url-automation.md](./presigned-url-automation.md) - 自動化について
- [terraform-s3-guide.md](./terraform-s3-guide.md) - Terraform S3 ガイド
