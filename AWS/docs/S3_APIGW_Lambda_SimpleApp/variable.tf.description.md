# variable.tf - 変数定義の解説

## 概要
このファイルは、Terraformプロジェクト全体で使用される変数を定義しています。変数を使用することで、コードの再利用性と柔軟性が向上し、環境ごとの設定変更が容易になります。

---

## 変数の構成

### 1. aws_region
```terraform
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}
```

#### 変数の属性

**`description`**
- 変数の説明文
- ドキュメントとして機能し、変数の目的を明確にする
- `terraform plan`や`terraform apply`実行時に表示される場合がある

**`type = string`**
- 変数の型を指定
- 型安全性を確保し、誤った値の設定を防止

**使用可能な型**:
```terraform
string  # 文字列: "ap-northeast-1"
number  # 数値: 256, 3.14
bool    # 真偽値: true, false
list    # リスト: ["item1", "item2"]
map     # マップ: { key1 = "value1", key2 = "value2" }
object  # オブジェクト: { name = string, age = number }
set     # セット: ["unique1", "unique2"]
tuple   # タプル: ["string", 123, true]
any     # 任意の型
```

**`default = "ap-northeast-1"`**
- デフォルト値（省略時の値）
- この値が設定されていると、`terraform.tfvars`や`-var`オプションで上書きしない限り、この値が使用される

#### 使用箇所
- [main.tf](../../projects/S3_APIGW_Lambda_SimpleApp/main.tf): プロバイダーのリージョン設定
  ```terraform
  provider "aws" {
    region = var.aws_region  # ← ここで使用
  }
  ```

#### 使用例とカスタマイズ

**別のリージョンにデプロイする場合**:

方法1: `terraform.tfvars`で上書き
```terraform
aws_region = "us-west-2"
```

方法2: コマンドライン引数で指定
```bash
terraform apply -var="aws_region=us-west-2"
```

方法3: 環境変数で指定
```bash
export TF_VAR_aws_region=us-west-2
terraform apply
```

**複数リージョン対応の例**:
```terraform
variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "ap-northeast-3"
}
```

---

### 2. project_name
```terraform
variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "serverless-demo"
}
```

#### 目的
- すべてのAWSリソース名に共通のプレフィックスとして使用
- リソースの識別と管理を容易にする
- 複数のプロジェクトやチームが同じAWSアカウントを使用する場合の名前空間分離

#### 使用箇所
このプロジェクト全体で広く使用されています：

**s3.tf**:
```terraform
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"
  # 例: "serverless-demo-frontend-a3b2c1d4"
}
```

**lambda.tf**:
```terraform
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"
  # 例: "serverless-demo-lambda-role"
}

resource "aws_lambda_function" "backend" {
  function_name = "${var.project_name}-api"
  # 例: "serverless-demo-api"
}
```

**api_gateway.tf**:
```terraform
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-api"
  # 例: "serverless-demo-api"
}
```

#### 命名規則のベストプラクティス

**推奨される命名形式**:
```terraform
# 小文字とハイフン
project_name = "my-awesome-project"  # ✅ Good

# 避けるべき形式
project_name = "My_Awesome_Project"  # ❌ アンダースコアと大文字
project_name = "my awesome project"  # ❌ スペース
project_name = "my.awesome.project"  # ❌ ドット（S3バケット名で問題）
```

**環境を含める場合**:
```terraform
variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "serverless-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# リソース名の構築
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-${var.environment}-frontend-${random_id.bucket_suffix.hex}"
  # 例: "serverless-demo-dev-frontend-a3b2c1d4"
}
```

---

### 3. aws_profile
```terraform
variable "aws_profile" {
  description = "AWS SSO Profile"
  type        = string
  default     = "AdministratorAccess-339126664118"
}
```

#### 目的
- AWS認証に使用するプロファイル名を指定
- 複数のAWSアカウントやIAMユーザーを切り替え可能
- AWS SSOを使用する場合に特に有用

#### 使用箇所
- [main.tf](../../projects/S3_APIGW_Lambda_SimpleApp/main.tf): プロバイダー設定
  ```terraform
  provider "aws" {
    profile = var.aws_profile  # ← ここで使用
  }
  ```

#### プロファイルの設定方法

**~/.aws/config**:
```ini
[profile AdministratorAccess-339126664118]
sso_start_url = https://my-company.awsapps.com/start
sso_region = ap-northeast-1
sso_account_id = 339126664118
sso_role_name = AdministratorAccess
region = ap-northeast-1
output = json
```

**~/.aws/credentials** (非SSO):
```ini
[AdministratorAccess-339126664118]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

#### 環境ごとのプロファイル管理

**複数環境の例**:
```terraform
# variables.tf
variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "default"
}

# dev.tfvars
aws_profile = "dev-profile"

# prod.tfvars
aws_profile = "prod-profile"
```

**使用方法**:
```bash
# 開発環境
terraform apply -var-file="dev.tfvars"

# 本番環境
terraform apply -var-file="prod.tfvars"
```

---

## 変数の値を設定する方法（優先順位順）

Terraformは、以下の順序で変数の値を決定します（後のものが優先）：

### 1. デフォルト値（最低優先度）
```terraform
variable "aws_region" {
  default = "ap-northeast-1"
}
```

### 2. 環境変数
```bash
export TF_VAR_aws_region="us-west-2"
export TF_VAR_project_name="my-project"
terraform apply
```

### 3. terraform.tfvars ファイル
```terraform
# terraform.tfvars
aws_region   = "ap-northeast-1"
project_name = "serverless-demo"
aws_profile  = "AdministratorAccess-339126664118"
```
このファイルは自動的に読み込まれます。

### 4. *.auto.tfvars ファイル
```terraform
# dev.auto.tfvars
environment = "dev"
```
`.auto.tfvars`で終わるファイルも自動的に読み込まれます。

### 5. -var-file オプション
```bash
terraform apply -var-file="prod.tfvars"
```

### 6. -var オプション（最高優先度）
```bash
terraform apply -var="aws_region=eu-west-1" -var="project_name=my-app"
```

### 7. インタラクティブ入力
デフォルト値がなく、値が指定されていない場合、Terraformが入力を求めます：
```bash
terraform apply
var.aws_region
  AWS region

  Enter a value: ap-northeast-1
```

---

## 高度な変数の使用例

### 1. 複雑な型の変数

#### リスト型
```terraform
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

# 使用例
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  availability_zone = var.availability_zones[count.index]
}
```

#### マップ型
```terraform
variable "lambda_config" {
  description = "Lambda function configuration"
  type = map(object({
    memory = number
    timeout = number
  }))
  default = {
    dev = {
      memory  = 128
      timeout = 10
    }
    prod = {
      memory  = 512
      timeout = 30
    }
  }
}

# 使用例
resource "aws_lambda_function" "backend" {
  memory_size = var.lambda_config[var.environment].memory
  timeout     = var.lambda_config[var.environment].timeout
}
```

#### オブジェクト型
```terraform
variable "s3_config" {
  description = "S3 bucket configuration"
  type = object({
    versioning_enabled = bool
    lifecycle_rules = list(object({
      days = number
      storage_class = string
    }))
  })
  default = {
    versioning_enabled = true
    lifecycle_rules = [
      {
        days = 30
        storage_class = "STANDARD_IA"
      }
    ]
  }
}
```

---

### 2. バリデーション

変数に制約を追加して、不正な値を防止できます：

```terraform
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"

  validation {
    condition     = can(regex("^(ap|us|eu)-(northeast|southeast|east|west|central)-[1-3]$", var.aws_region))
    error_message = "The aws_region must be a valid AWS region name."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "lambda_memory" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 128

  validation {
    condition     = var.lambda_memory >= 128 && var.lambda_memory <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}
```

---

### 3. 機密情報の扱い

#### sensitive 属性
```terraform
variable "api_key" {
  description = "API key for external service"
  type        = string
  sensitive   = true  # ログやプラン出力でマスクされる
}

# 使用例
resource "aws_lambda_function" "backend" {
  environment {
    variables = {
      API_KEY = var.api_key  # プラン出力では "(sensitive value)" と表示
    }
  }
}
```

**設定方法**:
```bash
# 環境変数で設定（推奨）
export TF_VAR_api_key="replace-with-api-key"
terraform apply

# または terraform.tfvars（.gitignoreに追加）
api_key = "secret-api-key-12345"
```

---

### 4. 条件付きリソース作成

```terraform
variable "enable_logging" {
  description = "Enable CloudWatch Logs"
  type        = bool
  default     = false
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  count             = var.enable_logging ? 1 : 0  # 条件付き作成
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 7
}
```

---

## ベストプラクティス

### 1. 変数の整理
```terraform
# 基本設定
variable "aws_region" { ... }
variable "aws_profile" { ... }

# プロジェクト設定
variable "project_name" { ... }
variable "environment" { ... }

# リソース固有の設定
variable "lambda_memory" { ... }
variable "lambda_timeout" { ... }
```

### 2. デフォルト値の提供
- 必須でない変数には、適切なデフォルト値を設定
- 頻繁に変更される値は、デフォルト値なしにして明示的な設定を強制

### 3. 説明の記述
- すべての変数に`description`を追加
- 何を設定すべきか、どんな影響があるかを明記

### 4. 型の明示
- 常に`type`を指定して、型安全性を確保
- 複雑な型には`validation`を追加

### 5. 機密情報の保護
- API キーやパスワードには`sensitive = true`を設定
- terraform.tfvarsを`.gitignore`に追加

---

## 関連ファイル

- [main.tf](./main.tf.description.md): 変数を使用するプロバイダー設定
- [s3.tf](./s3.tf.description.md): `project_name`を使用してS3バケット名を構築
- [lambda.tf](./lambda.tf.description.md): `project_name`を使用してLambda関数名を構築
- [api_gateway.tf](./api_gateway.tf.description.md): `project_name`を使用してAPI名を構築
- [プロジェクト README](../../projects/S3_APIGW_Lambda_SimpleApp/README.md): 変数の実際の値

---

## terraform.tfvars の例

```terraform
# terraform.tfvars
aws_region   = "ap-northeast-1"
project_name = "serverless-demo"
aws_profile  = "AdministratorAccess-339126664118"
```

**セキュリティ注意事項**:
```gitignore
# .gitignore
terraform.tfvars      # 機密情報を含む可能性
*.auto.tfvars         # 自動読み込みファイル
*.tfvars              # すべての変数ファイル（必要に応じて）
```

---

## トラブルシューティング

### 問題: 変数の値が反映されない
**原因**: 優先順位の理解不足
**解決策**: `-var`や`-var-file`オプションで明示的に指定

### 問題: 型エラー
```
Error: Invalid value for input variable
```
**原因**: 変数の型と設定値が一致しない
**解決策**: `type`定義を確認し、正しい型の値を設定

### 問題: バリデーションエラー
```
Error: Invalid value for variable
```
**原因**: `validation`ブロックの条件を満たしていない
**解決策**: エラーメッセージを確認し、有効な値を設定

### 問題: 環境変数が認識されない
**原因**: `TF_VAR_`プレフィックスの付け忘れ
**解決策**: `export TF_VAR_variable_name=value`の形式で設定

---

## 参考リンク

- [Terraform変数の公式ドキュメント](https://developer.hashicorp.com/terraform/language/values/variables)
- [Terraform型と値](https://developer.hashicorp.com/terraform/language/expressions/types)
- [入力変数のバリデーション](https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules)
