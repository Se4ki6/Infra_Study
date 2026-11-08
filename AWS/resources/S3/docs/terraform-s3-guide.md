# Terraform 初心者ガイド - S3 バケットプロジェクト

## 📚 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [ファイル構成](#ファイル構成)
3. [各ファイルの詳細説明](#各ファイルの詳細説明)
4. [Terraform の基本概念](#terraform-の基本概念)
5. [実行手順](#実行手順)
6. [よくある質問](#よくある質問)

---

## プロジェクト概要

このプロジェクトは、**Terraform**を使用して AWS S3 バケットを作成・管理します。以下の機能を実装しています：

- ✅ セキュアな S3 バケットの作成
- ✅ データのバージョン管理
- ✅ 自動暗号化
- ✅ パブリックアクセスのブロック
- ✅ ローカルファイルの自動アップロード

---

## ファイル構成

```
S3/
├── main.tf              # メイン設定ファイル（リソース定義）
├── variables.tf         # 変数定義ファイル
├── terraform.tfvars     # 変数の値を設定するファイル
├── README.md            # プロジェクトの説明書
├── testfile.txt         # テスト用ファイル
├── docs/                # ドキュメント格納フォルダ
└── upload_file/         # S3にアップロードするファイルを格納
    ├── example.txt
    ├── example2.txt
    └── example3.txt
```

### 各ファイルの役割

| ファイル名         | 役割                                       | 重要度 |
| ------------------ | ------------------------------------------ | ------ |
| `main.tf`          | AWS リソースの定義（実際に作成するもの）   | ⭐⭐⭐ |
| `variables.tf`     | 変数の定義（どんなパラメータを受け取るか） | ⭐⭐   |
| `terraform.tfvars` | 変数の値を設定（実際の値を指定）           | ⭐⭐⭐ |
| `README.md`        | プロジェクトの説明書                       | ⭐     |

---

## 各ファイルの詳細説明

### 1. main.tf - メイン設定ファイル

このファイルには、AWS に作成する**全てのリソース**が定義されています。

#### 📌 構成要素

##### (1) Terraform ブロック

```terraform
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**説明:**

- `required_version`: 使用する Terraform のバージョンを指定
- `required_providers`: AWS を操作するためのプラグイン（プロバイダー）を指定
- `version = "~> 5.0"`: バージョン 5.x を使用（5.0 以上、6.0 未満）

**初心者向け解説:** これは「このプロジェクトを実行するための前提条件」を宣言しています。

---

##### (2) Provider ブロック

```terraform
provider "aws" {
  region = "ap-southeast-2"
}
```

**説明:**

- `region`: AWS のリージョンを指定（ap-southeast-2 はシドニーリージョン）

**初心者向け解説:** 「どこの AWS データセンターでリソースを作成するか」を指定しています。

---

##### (3) S3 バケット - メインリソース

```terraform
resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

**説明:**

- `resource`: リソースを定義するキーワード
- `"aws_s3_bucket"`: リソースタイプ（S3 バケット）
- `"example"`: このリソースの名前（Terraform 内部での識別名）
- `bucket`: 実際のバケット名（**AWS 全体でグローバルに一意である必要がある**）
- `var.bucket_name`: `variables.tf`で定義された変数を参照
- `tags`: リソースに付けるラベル（管理や検索に使用）

**初心者向け解説:**

- バケット名は世界中で唯一の名前でなければなりません
- 例: `my-company-dev-bucket-20251122` のように日付を付けると重複しにくい
- タグは「付箋」のようなもので、リソースを分類・管理するために使用

---

##### (4) バージョニング設定

```terraform
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

**説明:**

- バージョニングを有効化すると、ファイルの変更履歴が保持される
- 誤って削除や上書きしてもデータを復元できる

**初心者向け解説:**
Git のようにファイルの履歴を保存する機能です。例えば：

1. `file.txt` をアップロード → バージョン 1
2. `file.txt` を更新 → バージョン 2
3. 誤って削除 → バージョン 1 や 2 から復元可能

**メリット:**

- ✅ 誤削除からの保護
- ✅ 変更履歴の追跡
- ✅ 以前のバージョンへのロールバック

---

##### (5) 暗号化設定

```terraform
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.example.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**説明:**

- サーバーサイド暗号化（SSE）を設定
- `AES256`: AWS S3 が管理する暗号化キーを使用
- アップロードされたファイルは自動的に暗号化される

**初心者向け解説:**
保存されるデータを「金庫に入れる」ようなイメージです。

- ファイルをアップロード → AWS が自動的に暗号化して保存
- ファイルをダウンロード → AWS が自動的に復号化

**セキュリティのメリット:**

- ✅ データ漏洩のリスク軽減
- ✅ コンプライアンス要件への対応
- ✅ 自動的に実行されるため手間なし

---

##### (6) パブリックアクセスブロック

```terraform
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**説明:**
4 つの設定全てを`true`にすることで、バケットを完全にプライベートにします。

**初心者向け解説:**
これは「セキュリティの門番」です。以下の 4 つの設定で外部からのアクセスを完全にブロック：

1. **block_public_acls**: 新しいパブリック ACL（アクセス制御リスト）の適用を防ぐ
2. **block_public_policy**: 新しいパブリックポリシーの適用を防ぐ
3. **ignore_public_acls**: 既存のパブリック ACL を無視する
4. **restrict_public_buckets**: パブリックバケットへのアクセスを制限

**なぜ重要？**

- ❌ 設定ミスによる情報漏洩を防ぐ
- ❌ 意図しない公開を防ぐ
- ✅ セキュリティベストプラクティス

---

##### (7) ファイルアップロード

```terraform
resource "aws_s3_object" "upload_file" {
  for_each = fileset(var.upload_folder, "**")

  bucket = aws_s3_bucket.example.id
  key    = var.s3_prefix == "" ? each.value : "${var.s3_prefix}/${each.value}"
  source = "${var.upload_folder}/${each.value}"
  etag   = filemd5("${var.upload_folder}/${each.value}")
  content_type = "text/plain"
}
```

**説明:**

- `for_each`: ループ処理（複数ファイルを一度に処理）
- `fileset()`: 指定フォルダ内の全ファイルを取得する関数
- `"**"`: 全てのファイルとサブフォルダを再帰的に検索
- `key`: S3 内でのファイルパス
- `source`: ローカルファイルのパス
- `etag`: ファイルの MD5 ハッシュ（整合性チェック用）
- `content_type`: ファイルの種類（MIME タイプ）

**初心者向け解説:**
これは「自動アップロード機能」です。

**動作の流れ:**

1. `upload_file/` フォルダ内の全ファイルをスキャン
2. 各ファイルに対して S3 オブジェクトを作成
3. ファイルをアップロード
4. MD5 ハッシュで整合性を確認

**例:**

```
upload_file/
├── example.txt      → S3: s3://my-bucket/example.txt
├── example2.txt     → S3: s3://my-bucket/example2.txt
└── subfolder/
    └── file.txt     → S3: s3://my-bucket/subfolder/file.txt
```

**三項演算子の説明:**

```terraform
key = var.s3_prefix == "" ? each.value : "${var.s3_prefix}/${each.value}"
```

- `var.s3_prefix == ""`: s3_prefix が空文字列なら
  - `? each.value`: ファイル名のみ（ルートにアップロード）
  - `: "${var.s3_prefix}/${each.value}"`: プレフィックス付きでアップロード

---

### 2. variables.tf - 変数定義ファイル

このファイルは「受け取るパラメータの型や説明」を定義します。

```terraform
variable "bucket_name" {
  description = "S3バケットの名前"
  type        = string
  // デフォルト値なし = 必須パラメータ
}

variable "environment" {
  description = "環境名 (dev, staging, prod など)"
  type        = string
  default     = "dev"
}

variable "upload_folder" {
  description = "アップロードするファイルが格納されているフォルダのパス"
  type        = string
  default     = "upload_file"
}

variable "s3_prefix" {
  description = "S3内でのファイルのプレフィックス (フォルダパス)"
  type        = string
  default     = ""
}
```

#### 📌 変数の構成要素

| 要素          | 説明                                             | 必須 |
| ------------- | ------------------------------------------------ | ---- |
| `description` | 変数の説明（ドキュメント用）                     | ❌   |
| `type`        | データ型（string, number, bool, list, map など） | ❌   |
| `default`     | デフォルト値（省略時の値）                       | ❌   |
| `validation`  | 入力値の検証ルール                               | ❌   |

**初心者向け解説:**

変数定義は「関数のシグネチャ」のようなものです：

```
関数定義:
function createBucket(bucketName: string, environment: string = "dev") { }

Terraform変数定義:
variable "bucket_name" { type = string }
variable "environment" { type = string, default = "dev" }
```

**デフォルト値の有無による違い:**

- ✅ デフォルト値**あり**: 値を指定しなくても OK（省略可能）
- ❌ デフォルト値**なし**: 必ず値を指定する必要がある（必須パラメータ）

---

### 3. terraform.tfvars - 変数の値設定ファイル

このファイルは「変数に実際の値を代入」します。

```terraform
bucket_name   = "my-unique-bucket-name-20251122"
environment   = "dev"
upload_folder = "upload_file"
s3_prefix     = ""
```

**初心者向け解説:**

このファイルは「設定ファイル」です。プログラムで言うと：

```python
# variables.tf = 変数定義
bucket_name: str
environment: str = "dev"

# terraform.tfvars = 値の代入
bucket_name = "my-unique-bucket-name-20251122"
environment = "dev"
```

#### 🔒 セキュリティに関する注意

**このファイルに含めてはいけない情報:**

- ❌ AWS アクセスキー
- ❌ シークレットキー
- ❌ パスワード
- ❌ 個人情報

**ベストプラクティス:**

- 機密情報は環境変数や AWS Secrets Manager を使用
- 必要に応じて `.gitignore` に追加
  ```
  # .gitignore
  *.tfvars
  !terraform.tfvars.example
  ```

---

## Terraform の基本概念

### 🏗️ リソース（Resource）

AWS に作成する「もの」です。

```terraform
resource "リソースタイプ" "リソース名" {
  設定項目 = 値
}
```

**例:**

```terraform
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-bucket-name"
}
```

### 🔗 リソース参照

他のリソースを参照するには `<リソースタイプ>.<リソース名>.<属性>` を使用：

```terraform
# バケットを作成
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}

# そのバケットのIDを参照
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id  # ← ここで参照
}
```

### 🎯 変数の使用

変数は `var.<変数名>` で参照：

```terraform
# variables.tf
variable "bucket_name" {
  type = string
}

# main.tf
resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name  # ← 変数を使用
}
```

### 🔄 ループ処理（for_each）

複数のリソースを一度に作成：

```terraform
resource "aws_s3_object" "files" {
  for_each = fileset("upload_file", "**")

  bucket = aws_s3_bucket.example.id
  key    = each.value  # ← 各ファイル名
  source = "upload_file/${each.value}"
}
```

### 📊 Terraform の実行フロー

```
1. terraform init    → プラグインのダウンロード（初回のみ）
   ↓
2. terraform plan    → 実行計画の確認（何が作られるか確認）
   ↓
3. terraform apply   → 実際にリソースを作成
   ↓
4. terraform destroy → リソースを削除（不要になったら）
```

---

## 実行手順

### ステップ 1: 初期化

```powershell
terraform init
```

**何が起こる？**

- AWS プロバイダーのダウンロード
- `.terraform/` フォルダの作成
- 依存関係の解決

**出力例:**

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.31.0...
Terraform has been successfully initialized!
```

---

### ステップ 2: プランの確認

```powershell
terraform plan
```

**何が起こる？**

- 現在の状態と目的の状態を比較
- 何が作成/変更/削除されるかを表示
- **実際には何も変更しない**（ドライラン）

**出力の見方:**

```
Terraform will perform the following actions:

  # aws_s3_bucket.example will be created
  + resource "aws_s3_bucket" "example" {
      + bucket = "my-unique-bucket-name-20251122"
      + ...
    }

Plan: 6 to add, 0 to change, 0 to destroy.
```

**記号の意味:**

- `+` : 作成される
- `-` : 削除される
- `~` : 変更される
- `±` : 再作成される（削除して作成）

---

### ステップ 3: デプロイ

```powershell
terraform apply
```

**何が起こる？**

1. プランを再計算して表示
2. 確認プロンプト: `Enter a value: yes`
3. リソースを実際に作成
4. 状態を `terraform.tfstate` に保存

**自動承認（確認スキップ）:**

```powershell
terraform apply -auto-approve
```

---

### ステップ 4: 状態の確認

```powershell
# 作成されたリソースの一覧を表示
terraform state list

# 特定のリソースの詳細を表示
terraform state show aws_s3_bucket.example
```

---

### ステップ 5: 削除（不要になったら）

```powershell
terraform destroy
```

**何が起こる？**

- 全てのリソースを削除
- 確認プロンプト: `Enter a value: yes`

**⚠️ 注意:** この操作は元に戻せません！

---

## よくある質問

### Q1: バケット名が既に使用されているエラー

**エラーメッセージ:**

```
Error: creating Amazon S3 Bucket: BucketAlreadyExists
```

**解決方法:**
`terraform.tfvars` のバケット名を変更してください：

```terraform
bucket_name = "my-unique-bucket-name-20251122-v2"
```

バケット名は **AWS 全体で一意** である必要があります。

---

### Q2: 認証エラーが発生する

**エラーメッセージ:**

```
Error: No valid credential sources found
```

**解決方法:**
AWS CLI で認証情報を設定：

```powershell
aws configure
```

または、環境変数を設定：

```powershell
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_DEFAULT_REGION="ap-southeast-2"
```

---

### Q3: terraform.tfstate とは？

**説明:**
Terraform が現在の状態を記録するファイルです。

**重要なポイント:**

- ✅ このファイルは自動生成される
- ✅ 手動で編集しない
- ✅ チーム開発の場合は S3 などで共有する
- ⚠️ 機密情報が含まれる可能性がある → `.gitignore` に追加

**チーム開発の場合:**

```terraform
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "s3/terraform.tfstate"
    region = "ap-southeast-2"
  }
}
```

---

### Q4: ファイルを追加したらどうなる？

**手順:**

1. `upload_file/` フォルダに新しいファイルを追加
2. `terraform plan` を実行
3. 新しいファイルが追加されることを確認
4. `terraform apply` を実行

**自動検出:**
`fileset()` 関数が自動的に新しいファイルを検出します。

---

### Q5: 特定のファイルだけアップロードしたい

**現在の設定:**

```terraform
for_each = fileset(var.upload_folder, "**")  # 全ファイル
```

**特定の拡張子のみ:**

```terraform
for_each = fileset(var.upload_folder, "*.txt")  # .txtファイルのみ
```

**パターン例:**

- `"**"` : 全ファイル（サブフォルダ含む）
- `"*.txt"` : .txt ファイルのみ
- `"*.{txt,pdf}"` : .txt と.pdf ファイル
- `"docs/**"` : docs フォルダ内の全ファイル

---

### Q6: コストはかかる？

**S3 の料金体系:**

- ストレージ: 保存されているデータ量に応じて課金
- リクエスト: PUT/GET 等のリクエスト回数に応じて課金
- データ転送: ダウンロード量に応じて課金

**無料枠（AWS Free Tier）:**

- 5GB のストレージ
- 20,000 GET リクエスト
- 2,000 PUT リクエスト
- 15GB のデータ転送（アウト）

**このプロジェクトの場合:**
小さなテキストファイルを数個アップロードする程度なら、ほぼ無料枠内で収まります。

**コスト削減のヒント:**

- 不要なバケットは `terraform destroy` で削除
- 大きなファイルのアップロードは避ける
- バージョニングは必要な場合のみ有効化

---

### Q7: 本番環境と dev 環境を分けたい

**方法 1: terraform.tfvars を分ける**

```
terraform.dev.tfvars
terraform.prod.tfvars
```

**実行:**

```powershell
# dev環境
terraform apply -var-file="terraform.dev.tfvars"

# prod環境
terraform apply -var-file="terraform.prod.tfvars"
```

**方法 2: ワークスペースを使う**

```powershell
# dev環境
terraform workspace new dev
terraform workspace select dev
terraform apply

# prod環境
terraform workspace new prod
terraform workspace select prod
terraform apply
```

---

### Q8: エラーが出た時の対処法

**一般的なトラブルシューティング:**

1. **プロバイダーのキャッシュをクリア:**

   ```powershell
   Remove-Item -Recurse -Force .terraform
   terraform init
   ```

2. **状態ファイルをリフレッシュ:**

   ```powershell
   terraform refresh
   ```

3. **特定のリソースを再作成:**

   ```powershell
   terraform taint aws_s3_bucket.example
   terraform apply
   ```

4. **デバッグログを有効化:**
   ```powershell
   $env:TF_LOG="DEBUG"
   terraform apply
   ```

---

## 📚 参考リンク

### 公式ドキュメント

- [Terraform 公式ドキュメント](https://www.terraform.io/docs)
- [AWS Provider ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [S3 リソース](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

### 学習リソース

- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [AWS S3 ドキュメント](https://docs.aws.amazon.com/s3/)

---

## 📝 まとめ

### Terraform の 3 つの重要ファイル

1. **main.tf**: 何を作るか（リソース定義）
2. **variables.tf**: どんなパラメータを受け取るか（変数定義）
3. **terraform.tfvars**: 実際の値は何か（値の代入）

### 基本コマンド

```powershell
terraform init     # 初期化（最初に1回だけ）
terraform plan     # 確認（何が起こるか見る）
terraform apply    # 実行（実際に作成）
terraform destroy  # 削除（全て削除）
```

### セキュリティのポイント

- ✅ パブリックアクセスをブロック
- ✅ 暗号化を有効化
- ✅ バージョニングでデータ保護
- ✅ タグでリソース管理
- ❌ terraform.tfstate を公開しない
- ❌ アクセスキーをコードに書かない

---

## 🎓 次のステップ

このプロジェクトをマスターしたら、次は以下に挑戦してみましょう：

1. **ライフサイクルルールの追加**: 古いバージョンを自動削除
2. **CloudFront との連携**: S3 を静的ウェブサイトとして公開
3. **Lambda トリガー**: ファイルアップロード時の自動処理
4. **複数環境の管理**: dev/staging/prod の分離
5. **モジュール化**: 再利用可能なコンポーネントとして整理

---

**作成日**: 2025 年 11 月 22 日<br>
**バージョン**: 1.0<br>
**対象**: Terraform 初心者
