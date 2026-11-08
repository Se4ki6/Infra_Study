# main.tf - Terraform基本設定の解説

## 概要
このファイルは、Terraformのバージョン要件、プロバイダー設定、AWSプロバイダーの初期化など、プロジェクト全体の基礎となる設定を定義しています。すべての`.tf`ファイルの中で最初に読み込まれるべき重要な設定です。

---

## リソース構成

### 1. terraform ブロック
```terraform
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### `required_version = ">= 1.0.0"`
**目的**: Terraformのバージョン要件を指定

**設定の意味**:
- このプロジェクトはTerraform 1.0.0以降で動作することを保証
- チームメンバー全員が互換性のあるバージョンを使用することを強制
- CI/CDパイプラインでのバージョン統一

**バージョン指定の例**:
```terraform
required_version = ">= 1.0.0"        # 1.0.0以上
required_version = ">= 1.0.0, < 2.0.0"  # 1.x系のみ
required_version = "~> 1.5.0"        # 1.5.x系のみ（1.6.0は不可）
required_version = "= 1.5.7"         # 厳密に1.5.7のみ
```

**ベストプラクティス**:
- メジャーバージョンを固定して、破壊的変更を避ける
- マイナーバージョンは柔軟に（`>= 1.0.0`など）
- 本番環境では厳密なバージョン指定を検討

---

#### `required_providers`
**目的**: 使用するTerraformプロバイダーとそのバージョンを宣言

**AWSプロバイダーの設定**:
```terraform
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
}
```

##### `source = "hashicorp/aws"`
- プロバイダーの取得元を指定
- 形式: `namespace/provider`
- `hashicorp/aws`は[Terraform Registry](https://registry.terraform.io/)の公式AWSプロバイダー

##### `version = "~> 5.0"`
- AWSプロバイダーのバージョン制約
- `~> 5.0`は「5.0.x系」を意味（Pessimistic Constraint Operator）
  - 5.0.0, 5.0.1, 5.1.0 ✅ 互換性あり
  - 6.0.0 ❌ 非互換（メジャーバージョンアップ）

**バージョン指定演算子**:
```terraform
version = "5.0.0"      # 厳密に5.0.0のみ
version = ">= 5.0.0"   # 5.0.0以上
version = "~> 5.0"     # 5.x系（5.0.0 ~ 5.99.99）
version = "~> 5.0.0"   # 5.0.x系（5.0.0 ~ 5.0.99）
version = ">= 5.0, < 6.0"  # 5.x系（複数条件）
```

**複数プロバイダーの例**:
```terraform
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
  random = {
    source  = "hashicorp/random"
    version = "~> 3.5"
  }
  archive = {
    source  = "hashicorp/archive"
    version = "~> 2.4"
  }
}
```

---

### 2. provider "aws" ブロック
```terraform
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
```
**目的**: AWSプロバイダーの具体的な設定（認証情報、リージョンなど）

#### `region = var.aws_region`
**目的**: AWSリソースを作成するリージョンを指定

**設定値**:
- `var.aws_region`は変数から取得（variables.tfで定義）
- デフォルト値: `"ap-northeast-1"` (東京リージョン)

**リージョンの選択基準**:
- **レイテンシ**: ユーザーに近いリージョン
- **コスト**: リージョンによって料金が異なる
- **サービス提供状況**: 一部のサービスは特定リージョンのみ
- **データ主権**: 法規制による制約

**主要リージョン一覧**:
```
us-east-1      - バージニア北部（最も安価、多くの新サービスが最初にリリース）
us-west-2      - オレゴン
ap-northeast-1 - 東京
ap-northeast-2 - ソウル
ap-southeast-1 - シンガポール
eu-west-1      - アイルランド
```

---

#### `profile = var.aws_profile`
**目的**: AWS認証情報のプロファイルを指定

**AWS認証方法**:
1. **プロファイル** (このファイルで使用)
2. 環境変数 (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
3. IAMロール (EC2、ECS、Lambda等で自動取得)
4. SSO (AWS IAM Identity Center)

**プロファイルの設定** (~/.aws/credentials):
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[AdministratorAccess-339126664118]
# AWS SSOの場合、`aws sso login`でトークンを取得
```

**プロファイルの使用例**:
```bash
# 指定したプロファイルでTerraformを実行
terraform plan

# AWS CLIでも同じプロファイルを使用
aws s3 ls --profile AdministratorAccess-339126664118
```

**セキュリティのベストプラクティス**:
- ルートアカウントの認証情報は使用しない
- IAMユーザーに最小限の権限を付与
- アクセスキーは定期的にローテーション
- 本番環境ではIAMロールを使用
- 認証情報をGitにコミットしない（`.gitignore`に追加）

---

### その他の有用なプロバイダー設定

#### デフォルトタグ（推奨）
```terraform
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "your-team"
    }
  }
}
```
**利点**:
- すべてのリソースに自動的にタグが付与される
- コスト配分とリソース管理が容易
- タグの付け忘れを防止

---

#### 複数リージョンのプロバイダー
```terraform
# デフォルト（東京）
provider "aws" {
  region  = "ap-northeast-1"
  profile = var.aws_profile
}

# セカンダリ（米国東部）- CloudFront証明書用
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile
}

# 使用例
resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.us_east_1  # エイリアスを指定
  domain_name       = "example.com"
  validation_method = "DNS"
}
```

---

#### AssumeRoleによる権限委譲
```terraform
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/TerraformDeployRole"
    session_name = "terraform-session"
  }
}
```
**ユースケース**:
- マルチアカウント環境での権限管理
- CI/CDパイプラインでの安全なデプロイ
- 最小権限の原則を適用

---

## Terraformの初期化

### `terraform init`
このコマンドは、`main.tf`の設定を読み込んで初期化を行います：

```bash
terraform init
```

**実行内容**:
1. `.terraform`ディレクトリを作成
2. `required_providers`で指定されたプロバイダーをダウンロード
3. バックエンド（状態ファイルの保存場所）を初期化
4. プラグインのインストール

**出力例**:
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.31.0...
- Installed hashicorp/aws v5.31.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

---

## バックエンド設定（推奨）

現在の設定では、Terraformの状態ファイル（`terraform.tfstate`）はローカルに保存されます。チーム開発や本番環境では、リモートバックエンドを使用することを強く推奨します。

### S3バックエンドの設定例
```terraform
terraform {
  required_version = ">= 1.0.0"

  # S3をバックエンドとして使用
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "s3-apigw-lambda/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"  # ロック管理用
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**S3バックエンドの利点**:
- 状態ファイルの共有（チーム開発）
- 自動バックアップ（S3のバージョニング）
- 暗号化（`encrypt = true`）
- ロック機能（DynamoDB）で同時実行を防止

**DynamoDBテーブルの作成**:
```terraform
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

---

## アーキテクチャ全体での役割

```
[main.tf] ← 基盤設定
   ├─ Terraformバージョン管理
   ├─ プロバイダー設定（AWS認証）
   └─ リージョン指定
      ↓
[variables.tf] - 変数定義
[s3.tf] - S3リソース
[api_gateway.tf] - API Gatewayリソース
[lambda.tf] - Lambda関数
[outputs.tf] - 出力値
```

---

## ベストプラクティス

### 1. 環境ごとのプロバイダー設定
```terraform
# dev環境
provider "aws" {
  region  = "ap-northeast-1"
  profile = "dev-profile"

  default_tags {
    tags = {
      Environment = "dev"
    }
  }
}

# prod環境（別ファイル）
provider "aws" {
  region  = "ap-northeast-1"
  profile = "prod-profile"

  default_tags {
    tags = {
      Environment = "prod"
    }
  }
}
```

### 2. Terraformバージョンの固定（.terraform-version）
```
1.5.7
```
`tfenv`などのバージョンマネージャーで自動的に適用されます。

### 3. プロバイダーのバージョンロック
`terraform init`実行後、`.terraform.lock.hcl`が生成されます：
```hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.31.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:abc...",
    "zh:def...",
  ]
}
```
このファイルをGitにコミットして、チーム全員で同じバージョンを使用します。

### 4. 認証情報の管理
```bash
# .gitignoreに追加
*.tfvars        # 機密情報を含む変数ファイル
.terraform/     # プロバイダープラグイン
terraform.tfstate*  # 状態ファイル（リモートバックエンド使用時）
```

---

## 関連ファイル

- [variables.tf](./variable.tf.description.md): このファイルで参照される変数の定義
- [outputs.tf](./outputs.tf.description.md): デプロイ後の出力値
- [プロジェクト README](../../projects/S3_APIGW_Lambda_SimpleApp/README.md): 変数の実際の値

---

## デプロイ手順

### 1. 初期化
```bash
terraform init
```

### 2. 設定の検証
```bash
terraform validate
```

### 3. 計画の確認
```bash
terraform plan
```

### 4. デプロイ実行
```bash
terraform apply
```

### 5. リソースの削除
```bash
terraform destroy
```

---

## トラブルシューティング

### 問題: `terraform init`で認証エラー
**原因**: AWSプロファイルまたは認証情報が正しくない
**解決策**:
```bash
# プロファイルの確認
aws configure list --profile AdministratorAccess-339126664118

# SSOの場合はログイン
aws sso login --profile AdministratorAccess-339126664118
```

### 問題: プロバイダーのバージョン競合
**原因**: `.terraform.lock.hcl`とプロバイダー設定の不一致
**解決策**:
```bash
terraform init -upgrade
```

### 問題: リージョンが正しくない
**原因**: `var.aws_region`の値が間違っている
**解決策**: `terraform.tfvars`または`variables.tf`を確認

### 問題: プロバイダー設定が反映されない
**原因**: `terraform init`の実行が必要
**解決策**: プロバイダー設定変更後は必ず`terraform init`を実行

---

## 参考リンク

- [Terraform AWSプロバイダー公式ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraformバックエンド設定](https://developer.hashicorp.com/terraform/language/settings/backends)
- [AWSリージョン一覧](https://docs.aws.amazon.com/general/latest/gr/rande.html)
