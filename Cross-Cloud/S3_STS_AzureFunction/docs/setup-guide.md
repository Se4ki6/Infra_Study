# セットアップガイド

`S3_STS_AzureFunction` を最初から動かすまでの手順書。
README の「デプロイ手順」を、実際に手を動かす前提で細かく分解したもの。

所要時間の目安：**60〜90 分**（Azure Functions の初回デプロイ待ちを含む）

---

## 0. 全体の流れ

AWS と Azure が互いの出力値を必要とするため、一直線には進まない。

```
STEP 1  Azure を作る          … Entra ID の値（tenant / audience / principal id）を得る
   ↓
STEP 2  AWS を作る            … STEP 1 の値を使って OIDC プロバイダとロールを作る
   ↓
STEP 3  Azure を再 apply      … STEP 2 の値（ロール ARN / キー）を Function App に流し込む
   ↓
STEP 4  コードをデプロイ
   ↓
STEP 5  トークンを実測して AWS を微調整   ← 方式B はここで 1 回やり直すのが普通
   ↓
STEP 6  動作確認
```

**STEP 5 でのやり直しは失敗ではなく想定内**。マネージドIDが v1 / v2 どちらのトークンを返すかは
環境によって変わるため、実測してから合わせる設計にしてある。

---

## 1. 事前準備

### 1-1. ツールの確認

```powershell
terraform version      # >= 1.9
aws --version          # v2
az version             # 2.x
dotnet --list-sdks     # 8.0 以上
```

`dotnet` が 9 / 10 しか無くても問題ない。プロジェクトは `net8.0` を狙うが、
必要な参照アセンブリは `dotnet restore` が自動取得する。

### 1-2. AWS にログイン

```powershell
aws sso login --profile AdministratorAccess-339126664118
aws sts get-caller-identity --profile AdministratorAccess-339126664118
```

> SSO セッションは数時間で切れる。作業中に `ExpiredToken` が出たら `aws sso login` をやり直す。

必要な権限：S3・IAM（ロール／ユーザー／ポリシー／OIDC プロバイダの作成）。
`AdministratorAccess` なら足りる。

### 1-3. Azure にログイン

```powershell
az login
az account show --query "{subscription:name, id:id, tenant:tenantId}" -o table
```

複数サブスクリプションがある場合は明示的に選ぶ：

```powershell
az account set --subscription "<サブスクリプション名またはID>"
```

必要な権限：

| 対象 | 必要なロール |
|---|---|
| サブスクリプション | **共同作成者 (Contributor)** — リソース作成のため |
| Entra ID | **アプリケーション管理者** 相当、またはアプリ登録が許可されたユーザー |

Entra ID のアプリ登録が一般ユーザーに許可されているかの確認：

```powershell
az rest --method GET --url "https://graph.microsoft.com/v1.0/policies/authorizationPolicy" --query "defaultUserRolePermissions.allowedToCreateApps"
```

`false` が返る場合は、テナント管理者にアプリ登録の許可か
**アプリケーション管理者**ロールの付与を依頼する必要がある。

---

## 2. 作成されるリソースと費用

### AWS

| リソース | 用途 | 費用 |
|---|---|---|
| S3 バケット + サンプル 2 ファイル | 対象データ | ほぼゼロ（数 KB） |
| バケットポリシー | **STS 経由の強制** | 無料 |
| IAM ポリシー（S3 読み取り） | Assume 後の権限 | 無料 |
| IAM ロール ×2（方式A / 方式B） | Assume される側 | 無料 |
| IAM ユーザー + アクセスキー（方式A） | Assume する側 | 無料 |
| IAM OIDC プロバイダ（方式B） | Entra ID の信頼 | 無料 |

STS の `AssumeRole` / `AssumeRoleWithWebIdentity` 自体も無料。**AWS 側の費用は実質ゼロ**。

### Azure

| リソース | 用途 | 費用 |
|---|---|---|
| Function App（Y1 従量課金） | 実行環境 | 月 100 万実行まで無料枠 |
| Storage Account | Functions ランタイム必須 | 数十円/月 |
| Log Analytics ワークスペース | ログ基盤 | **月 5 GB まで無料、超過は従量** |
| Application Insights | STS 呼び出しの追跡 | 取り込み量に応じて課金 |
| Entra ID アプリ登録 + SP | OIDC の宛先 | 無料 |

> **注意**：課金が伸びるとすればログ取り込みだけ。ハンズオン用途なら無料枠に収まるが、
> 放置せず終わったら `terraform destroy` すること（README 10章）。

---

## 3. STEP 1 — Azure を作る

```powershell
cd Cross-Cloud/S3_STS_AzureFunction/terraform/azure
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集する。**この時点では AWS 系の値はすべて空のままでよい。**

```hcl
azure_subscription_id = ""          # 空なら az login の既定サブスクリプション
azure_tenant_id       = ""
location              = "japaneast"
environment           = "dev"
name_prefix           = "s3sts"

entra_requested_token_version = 1   # まず 1 で作る。STEP 5 で実測して必要なら 2 に変える
```

```powershell
terraform init
terraform plan      # 作成されるリソースを確認
terraform apply
```

### 出力値を控える

```powershell
terraform output azure_tenant_id
terraform output function_principal_id
terraform output aws_oidc_audience
```

---

## 4. STEP 2 — AWS を作る

```powershell
cd ../aws
cp terraform.tfvars.example terraform.tfvars
```

### 4-1. ExternalId を生成する

方式A の「合言葉」。必ず自分で生成した値に置き換える。

```powershell
-join ((1..32) | ForEach-Object { "{0:x}" -f (Get-Random -Maximum 16) })
```

### 4-2. tfvars を埋める

STEP 1 の出力値をここに転記する。**対応関係を間違えやすいので表で確認**：

| `terraform/azure` の出力 | → | `terraform/aws/terraform.tfvars` |
|---|---|---|
| `azure_tenant_id` | → | `azure_tenant_id` |
| `aws_oidc_audience` | → | `azure_oidc_audience` |
| `function_principal_id` | → | `azure_function_principal_id` |

```hcl
bucket_name    = "s3-sts-azure-demo-20260822"   # グローバルに一意な名前に変える
allowed_prefix = "shared"

enable_access_key_flow = true
external_id            = "<4-1 で生成した値>"

enable_oidc_flow            = true              # example では false なので true に変える
azure_tenant_id             = "<STEP 1 の出力>"
azure_token_version         = "v1"              # entra_requested_token_version と揃える
azure_oidc_audience         = "<STEP 1 の出力>"
azure_function_principal_id = "<STEP 1 の出力>"

enable_bucket_lockdown = true
```

> `enable_oidc_flow = true` にして `azure_tenant_id` などが空だと、
> `plan` の時点で変数バリデーションが止めてくれる。

### 4-3. 転記を楽にする

STEP 1 のディレクトリから、そのまま貼れる形で出力できる：

```powershell
cd ../azure
@"
azure_tenant_id             = "$(terraform output -raw azure_tenant_id)"
azure_oidc_audience         = "$(terraform output -raw aws_oidc_audience)"
azure_function_principal_id = "$(terraform output -raw function_principal_id)"
"@
cd ../aws
```

### 4-4. apply

```powershell
terraform init
terraform plan
terraform apply
```

### 4-5. 出力値を控える

```powershell
terraform output assume_role_arn
terraform output web_identity_role_arn
terraform output -raw bootstrap_access_key_id
terraform output -raw bootstrap_secret_access_key
```

ロックダウンの許可リストも確認しておく（自分が入っているか）：

```powershell
terraform output bucket_lockdown_allowed_user_ids
aws sts get-caller-identity --query UserId --output text
```

---

## 5. STEP 3 — Azure に AWS の値を戻す

`terraform/azure/terraform.tfvars` を再度編集する。

| `terraform/aws` の出力 | → | `terraform/azure/terraform.tfvars` |
|---|---|---|
| `bucket_name` | → | `aws_s3_bucket` |
| `allowed_prefix` | → | `aws_s3_prefix` |
| `aws_region` | → | `aws_region` |
| `assume_role_arn` | → | `aws_assume_role_arn` |
| `bootstrap_access_key_id` | → | `aws_bootstrap_access_key_id` |
| `bootstrap_secret_access_key` | → | `aws_bootstrap_secret_access_key` |
| `web_identity_role_arn` | → | `aws_web_identity_role_arn` |
| （aws の tfvars の `external_id`） | → | `aws_external_id` |

> 最後の行だけ出力ではなく **入力値の転記**。`external_id` は AWS 側で
> `sensitive` 変数として扱っており出力していないため、tfvars からコピーする。

貼れる形で出力する：

```powershell
cd ../aws
@"
aws_region                      = "$(terraform output -raw aws_region)"
aws_s3_bucket                   = "$(terraform output -raw bucket_name)"
aws_s3_prefix                   = "$(terraform output -raw allowed_prefix)"
aws_assume_role_arn             = "$(terraform output -raw assume_role_arn)"
aws_bootstrap_access_key_id     = "$(terraform output -raw bootstrap_access_key_id)"
aws_bootstrap_secret_access_key = "$(terraform output -raw bootstrap_secret_access_key)"
aws_web_identity_role_arn       = "$(terraform output -raw web_identity_role_arn)"
"@
cd ../azure
```

```powershell
terraform apply
```

---

## 6. STEP 4 — コードをデプロイ

```powershell
cd ../../scripts
./deploy.ps1
```

`dotnet publish` → zip → `az functionapp deployment source config-zip` を実行する。
Azure Functions Core Tools (`func`) は不要。

デプロイ直後はランタイムの起動待ちで数十秒ほど 503 が返ることがある。

---

## 7. STEP 5 — トークンを実測して AWS を合わせる

**方式B で最も詰まるポイント。** ここは 1 回やり直すのが正常な流れ。

```powershell
cd ..
$rg   = terraform -chdir=terraform/azure output -raw resource_group_name
$app  = terraform -chdir=terraform/azure output -raw function_app_name
$base = terraform -chdir=terraform/azure output -raw function_app_base_url
$key  = az functionapp keys list -g $rg -n $app --query "functionKeys.default" -o tsv

curl "$base/token-claims?code=$key"
```

レスポンスの `awsTerraformValues` が、**AWS 側にあるべき値の実測結果**：

```json
{
  "claims": {
    "iss": "https://sts.windows.net/xxxxxxxx-.../",
    "aud": "api://yyyyyyyy-...",
    "sub": "zzzzzzzz-..."
  },
  "awsTerraformValues": {
    "azure_token_version": "v1",
    "azure_tenant_id": "xxxxxxxx-...",
    "azure_oidc_audience": "api://yyyyyyyy-...",
    "azure_function_principal_id": "zzzzzzzz-..."
  }
}
```

### 判定

`terraform/aws/terraform.tfvars` の 4 つの値と `awsTerraformValues` を突き合わせる。

- **一致している** → STEP 6 へ進む
- **食い違っている** → `terraform.tfvars` を実測値に書き換えて `terraform -chdir=terraform/aws apply`

特に `azure_token_version` は要注意。`iss` に `/v2.0` が含まれていれば `v2`、
`sts.windows.net` なら `v1`。ここが違うと `InvalidIdentityToken` になる。

### トークン自体が取れない場合

`token-claims` がエラーを返すときは、Entra ID 側の問題：

```powershell
az monitor app-insights query -g $rg `
  --apps (terraform -chdir=terraform/azure output -raw application_insights_name) `
  --analytics-query "traces | where timestamp > ago(15m) | order by timestamp desc | take 20"
```

よくある原因は、サービスプリンシパルの作成がまだ反映されていないこと。
数分待って再試行する。

---

## 8. STEP 6 — 動作確認

```powershell
# STS 経由になっているか（arn が assumed-role/... 、accessKeyId が ASIA... なら成功）
curl "$base/whoami?mode=oidc&code=$key"
curl "$base/whoami?mode=accesskey&code=$key"

# ファイル一覧
curl "$base/files?mode=oidc&code=$key"

# ダウンロード
curl "$base/download?key=hello.txt&mode=oidc&code=$key"
```

### 完了チェックリスト

- [ ] `whoami?mode=oidc` の `arn` が `arn:aws:sts::<account>:assumed-role/...-s3-access-oidc/...`
- [ ] `whoami?mode=accesskey` の `arn` が `.../...-s3-access-assumerole/...`
- [ ] どちらも `accessKeyId` が **`ASIA`** で始まる（`AKIA` なら STS を経由していない）
- [ ] `files` がサンプル 2 件を返す
- [ ] `download` が `hello.txt` の中身を返す

ここまで通ったら、**「STS 経由でなければ入れない」側の検証**を
[verification.md](verification.md) で行う。動くことの確認だけでは要件を満たしたことにならない。

---

## 9. よくある詰まりどころ

| 症状 | 原因と対処 |
|---|---|
| `plan` で `azure_tenant_id が必須です` | `enable_oidc_flow = true` なのに STEP 1 の値が未転記。STEP 2 の表を確認 |
| `InvalidIdentityToken` | issuer 不一致。STEP 5 で `azure_token_version` を実測値に合わせる |
| `IDPRejectedClaim` | `aud` / `sub` 不一致。STEP 5 の `awsTerraformValues` を全部転記し直す |
| STS が `AccessDenied`（方式A） | `external_id` が AWS 側と Azure 側で食い違っている |
| S3 が `AccessDenied` | `/api/whoami` の `userId` と `bucket_lockdown_allowed_user_ids` を突き合わせる |
| `ExpiredToken`（terraform 実行時） | `aws sso login --profile ...` をやり直す |
| Function が 503 | 起動待ち。1〜2 分待って再試行 |
| ロール作成直後だけ失敗 | IAM の伝播待ち。数十秒おいて再試行 |
| 自分が S3 を触れなくなった | README 8章「ロックアウトからの復旧」 |

---

## 10. やり直したいとき

Terraform の状態は AWS / Azure で独立しているので、片方だけ作り直せる。

```powershell
# AWS だけ作り直す（Azure はそのまま）
terraform -chdir=terraform/aws destroy
terraform -chdir=terraform/aws apply
# → ロール ARN とアクセスキーが変わるので STEP 3 からやり直す

# Azure だけ作り直す
terraform -chdir=terraform/azure destroy
terraform -chdir=terraform/azure apply
# → principal id と audience が変わるので STEP 2 からやり直す
```

> バケットにバージョニングを有効化しているため、オブジェクトが残っていると
> バケット削除に失敗することがある。その場合は先にバージョンを含めて空にする。

全部消すときは **Azure → AWS の順**。逆にすると Function が S3 を参照できない状態で残る。
