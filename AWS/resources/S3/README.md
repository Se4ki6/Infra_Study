# S3バケット作成プロジェクト

このプロジェクトは、TerraformによるAWS S3バケットの作成と管理を行います。

## 概要

このTerraform構成は、セキュリティベストプラクティスに従ったS3バケットを作成し、ローカルファイルを自動的にアップロードします。

## 機能

- **S3バケットの作成**: グローバルに一意なバケット名でS3バケットを作成
- **バージョニング**: オブジェクトの変更履歴を保持し、誤削除や上書きからデータを保護
- **サーバーサイド暗号化**: AES256アルゴリズムによる自動暗号化でデータを保護
- **パブリックアクセスブロック**: 意図しない公開アクセスを防ぐセキュリティ設定
- **自動ファイルアップロード**: 指定フォルダ内の全ファイルを自動的にS3にアップロード

## 構成ファイル

### main.tf
メインの構成ファイルで、以下のリソースを定義しています：

#### 1. Terraform設定
- Terraformバージョン: >= 1.9.0
- AWSプロバイダー: ~> 5.0
- リージョン: ap-southeast-2

#### 2. S3バケット (`aws_s3_bucket`)
- グローバルに一意なバケット名
- タグによるリソース管理（Name, Environment, ManagedBy）

#### 3. バージョニング設定 (`aws_s3_bucket_versioning`)
- ステータス: Enabled
- オブジェクトの複数バージョンを保持
- データ保護のための推奨設定

#### 4. 暗号化設定 (`aws_s3_bucket_server_side_encryption_configuration`)
- アルゴリズム: AES256（AWS S3マネージドキー）
- 保存データの自動暗号化
- セキュリティ要件を満たすための設定

#### 5. パブリックアクセスブロック (`aws_s3_bucket_public_access_block`)
以下の4つの設定により完全なプライベートバケットを保証：
- `block_public_acls`: 新しいパブリックACLの適用をブロック
- `block_public_policy`: 新しいパブリックバケットポリシーの適用をブロック
- `ignore_public_acls`: 既存のパブリックACLを無視
- `restrict_public_buckets`: パブリックアクセスが許可されているバケットへのアクセスを制限

#### 6. ファイルアップロード (`aws_s3_object`)
- `fileset`関数で指定フォルダ内の全ファイルを自動検出
- `for_each`で各ファイルに対してリソースを作成
- `filemd5`ハッシュによる整合性検証
- コンテンツタイプ: text/plain

### variables.tf
変数定義ファイル：

| 変数名 | 型 | デフォルト値 | 説明 |
|--------|-----|-------------|------|
| `bucket_name` | string | なし（必須） | S3バケットの名前（グローバルに一意） |
| `environment` | string | "dev" | 環境名（dev, staging, prod など） |
| `upload_folder` | string | "upload_file" | アップロードするファイルが格納されているローカルフォルダのパス |
| `s3_prefix` | string | ""（空文字列） | S3内でのファイルのプレフィックス（フォルダパス） |

### terraform.tfvars
変数の実際の値を設定するファイル：

```terraform
bucket_name   = "my-unique-bucket-name-20251122"
environment   = "dev"
upload_folder = "upload_file"
s3_prefix     = ""
```

**注意**: このファイルには機密情報が含まれる可能性があるため、必要に応じて`.gitignore`に追加してください。

## 使用方法

### 前提条件
- Terraform >= 1.9.0 がインストールされていること
- AWS CLIが設定されていること（認証情報が適切に設定されていること）

### 初期化
```bash
terraform init
```

### プランの確認
```bash
terraform plan
```

### デプロイ
```bash
terraform apply
```

### 削除
```bash
terraform destroy
```

## ファイルアップロードについて

`upload_file`フォルダ内のファイルは、Terraform適用時に自動的にS3バケットにアップロードされます。

- サブディレクトリも再帰的に処理されます
- S3内のパスは`s3_prefix`変数で制御できます
- ファイルの整合性は`filemd5`ハッシュで検証されます

### アップロード例

ローカルファイル構造:
```
upload_file/
  ├── example.txt
  ├── example2.txt
  └── example3.txt
```

`s3_prefix = ""`の場合、S3内のパス:
```
s3://my-unique-bucket-name-20251122/example.txt
s3://my-unique-bucket-name-20251122/example2.txt
s3://my-unique-bucket-name-20251122/example3.txt
```

`s3_prefix = "uploaded"`の場合、S3内のパス:
```
s3://my-unique-bucket-name-20251122/uploaded/example.txt
s3://my-unique-bucket-name-20251122/uploaded/example2.txt
s3://my-unique-bucket-name-20251122/uploaded/example3.txt
```

## セキュリティ考慮事項

1. **バケット名**: グローバルに一意である必要があります。適切な命名規則（組織名-プロジェクト名-環境-日付など）を使用してください。

2. **パブリックアクセス**: デフォルトで完全にブロックされています。パブリックアクセスが必要な場合は、設定を慎重に変更してください。

3. **暗号化**: AES256による暗号化が有効です。より高度な暗号化が必要な場合は、AWS KMSの使用を検討してください。

4. **バージョニング**: 有効化されているため、誤削除や上書きからデータを保護できます。

5. **認証情報**: `terraform.tfvars`や`.terraform`ディレクトリをバージョン管理システムにコミットしないでください。

## 今後の改善点（ToDo）

- [ ] 三項演算子で開発環境と本番環境でパブリックアクセスブロック設定を変更する機能の実装
- [ ] ライフサイクルポリシーの追加（オブジェクトの自動削除や移行）
- [ ] CloudWatch によるモニタリング設定
- [ ] バケットポリシーの詳細設定

## トラブルシューティング

### バケット名が既に使用されている
エラー: `BucketAlreadyExists`
- 解決方法: `terraform.tfvars`の`bucket_name`をグローバルに一意な名前に変更してください。

### 認証エラー
エラー: `AuthorizationHeaderMalformed`
- 解決方法: AWS CLIの認証情報を確認し、適切なリージョンが設定されているか確認してください。

### ファイルアップロードの失敗
- 解決方法: `upload_folder`のパスが正しいか、ファイルが存在するか確認してください。

## ライセンス

このプロジェクトはTerraformで管理されています。

## 作成者

Terraform構成により自動管理
