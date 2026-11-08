# S3 × AWS STS × Azure Functions

**S3 への外部からのアクセスを AWS STS 経由のみに限定する**構成のハンズオン。

別 AWS アカウントの代役として **Azure Functions** から S3 のファイルをダウンロードする。
Azure は AWS から見れば完全な外部なので、これが動けば「外部から STS 経由で S3 に入れる」ことの実証になる。

---

## 1. この構成の要点

「S3 アクセスを STS 経由のみにする」は、**IAM ポリシーだけでは実現できない**。
IAM ポリシーは「そのロールに許可を与える」だけで、他の principal が直接バケットを触るのを止められないため。

強制しているのは **S3 バケットポリシーの明示的 Deny**：

```
評価順序:  明示的 Deny  >  明示的 Allow  >  暗黙の Deny
```

`aws:userId` が「許可した STS ロールのセッション」でも「管理者」でもなければ全拒否する
（[terraform/modules/aws/s3_bucket_lockdown/main.tf](terraform/modules/aws/s3_bucket_lockdown/main.tf) の `DenyAllExceptStsAssumedRoles`）。
この Deny はアカウント内の `AdministratorAccess` すら上書きする。

---

## 2. アーキテクチャ

### 方式A: アクセスキー + `sts:AssumeRole`

```
 Azure Function                          AWS
┌────────────────────┐                 ┌──────────────────────────────────────┐
│ App Settings に     │                 │ IAM ユーザー (bootstrap)              │
│ 長期アクセスキー     │────────────────▶│  権限は sts:AssumeRole *だけ*         │
└────────────────────┘   ① AssumeRole   │  → S3 には一切触れない                │
                          (+ ExternalId) │              │                       │
                                         │              ▼                       │
        ② 一時クレデンシャル ◀────────────│ IAM ロール s3-access-assumerole      │
           (ASIA... + SessionToken)      │              │ s3:GetObject          │
                                         │              ▼                       │
        ③ GetObject ────────────────────▶│            S3 バケット                │
                                         └──────────────────────────────────────┘
```

### 方式B: OIDC フェデレーション + `sts:AssumeRoleWithWebIdentity`（推奨）

```
 Azure Function (マネージドID)            AWS
┌────────────────────┐                 ┌──────────────────────────────────────┐
│ ① Entra ID から     │                 │ IAM OIDC プロバイダ                   │
│    JWT を取得       │                 │  issuer = Entra ID を信頼             │
└────────┬───────────┘                 │              │                       │
         │ ② AssumeRoleWithWebIdentity  │              ▼                       │
         │    (JWT を添付 / 署名なし)    │ IAM ロール s3-access-oidc            │
         └─────────────────────────────▶│  信頼条件: aud + sub が一致           │
                                         │              │                       │
        ③ 一時クレデンシャル ◀────────────│              ▼                       │
        ④ GetObject ────────────────────▶│            S3 バケット                │
                                         └──────────────────────────────────────┘
```

**長期の AWS 認証情報がどこにも存在しない。** これが本命の構成。

---

## 3. ディレクトリ構成

```
S3_STS_AzureFunction/
├── terraform/
│   ├── modules/
│   │   ├── aws/
│   │   │   ├── s3_secure_bucket/      # バケット本体 + 単体で完結する安全側設定
│   │   │   ├── s3_read_policy/        # Assume 後に使える S3 読み取り権限（両方式で共通）
│   │   │   ├── s3_bucket_lockdown/    # ★ Deny ポリシー = STS 経由の強制
│   │   │   ├── sts_access_key_flow/   # 方式A
│   │   │   └── sts_oidc_flow/         # 方式B
│   │   └── azure/
│   │       ├── entra_app/             # ★ OIDC トークンの aud になるアプリ登録
│   │       └── function_app/          # Function App 一式（AWS 非依存の汎用モジュール）
│   ├── aws/                    # ルートモジュール（AWS）
│   └── azure/                  # ルートモジュール（Azure）
├── src/S3StsDownload/          # .NET 8 isolated Function
│   ├── Services/               #   2 方式のクレデンシャル取得を差し替え可能に実装
│   └── Functions/              #   HTTP エンドポイント
├── sample_files/               # S3 に置く動作確認用ファイル
├── scripts/deploy.ps1          # zip デプロイ (Azure Functions Core Tools 不要)
└── docs/
    ├── setup-guide.md              # セットアップ手順書（事前準備・費用・詰まりどころ）
    ├── verification.md             # 「STS 経由のみ」であることの検証手順
    ├── s3-access-control.md        # S3 アクセス制限の仕組み詳細（バケットポリシー/IAM評価ロジック）
    └── company-account-testing.md  # 別 AWS アカウントで AssumeRole 制限だけを再現・検証する手順
```

### モジュール依存関係（AWS）

```
s3_secure_bucket ──bucket_arn──▶ s3_read_policy ──policy_arn──┬─▶ sts_access_key_flow
       │                                                       └─▶ sts_oidc_flow
       │                                                                │
       └──bucket_id / bucket_arn──▶ s3_bucket_lockdown ◀──role_unique_id─┘
```

**バケット本体とバケットポリシーを別モジュールにしている理由**：
バケットポリシーは STS ロールの `unique_id` を必要とし、STS ロールはバケットの ARN を必要とする。
同じモジュールに同居させると `バケット → ロール → バケット` でモジュール間が循環し、
Terraform がグラフを構築できない。
ロックダウンを分離することで依存が一方向になり、「アクセス制御はバケットの上に重ねる別の関心事」
という構造も明示できる。

| モジュール | 責務 | 主な出力 |
|---|---|---|
| `s3_secure_bucket` | バケット、バージョニング、暗号化、パブリックブロック、サンプル配置 | `bucket_id`, `bucket_arn` |
| `s3_read_policy` | Assume 後に使える最小権限の IAM ポリシー | `policy_arn` |
| `s3_bucket_lockdown` | HTTPS 強制 Deny + STS ロール以外の全拒否 Deny | `allowed_user_ids` |
| `sts_access_key_flow` | bootstrap ユーザー（`sts:AssumeRole` のみ）+ ロール | `role_arn`, `role_unique_id`, キー |
| `sts_oidc_flow` | IAM OIDC プロバイダ + Web Identity ロール | `role_arn`, `role_unique_id`, `issuer_url` |
| `entra_app` | Entra ID アプリ登録 + サービスプリンシパル | `token_scope`, `aws_oidc_audience` |
| `function_app` | Storage / Plan / App Insights / Function App + マネージドID | `principal_id`, `base_url` |

方式A・方式B は root 側の `count` で個別に無効化できる（`enable_access_key_flow` / `enable_oidc_flow`）。
無効化されたロールは `unique_id` を返さないため、ロックダウンの許可リストからも自動的に外れる。

---

## 4. 前提

| ツール | 確認コマンド |
|---|---|
| Terraform >= 1.9 | `terraform version` |
| AWS CLI v2（SSO ログイン済み） | `aws sso login --profile AdministratorAccess-339126664118` |
| Azure CLI（ログイン済み） | `az login` |
| .NET SDK 8 以上 | `dotnet --list-sdks` |

Entra ID でアプリ登録を作るため、**アプリケーション管理者相当の権限**が必要。

---

## 5. デプロイ手順

AWS と Azure が互いの値を必要とするため **3 段階**で流す。

> 事前準備（必要な権限の確認）、作成されるリソースと費用、出力値の転記対応表、
> 詰まったときの対処までを含めた詳細版は **[docs/setup-guide.md](docs/setup-guide.md)** にある。
> 初めて構築する場合はそちらを見ながら進めるとよい。以下は要点のみ。

### STEP 1 — Azure を先に作る（Entra ID の値を得る）

```powershell
cd terraform/azure
cp terraform.tfvars.example terraform.tfvars
# AWS 系の値は空のままでよい

terraform init
terraform apply
```

出力を控える：

```powershell
terraform output azure_tenant_id
terraform output function_principal_id
terraform output aws_oidc_audience
```

### STEP 2 — AWS を作る

```powershell
cd ../aws
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集：

- `bucket_name` — グローバルに一意な名前
- `external_id` — 自分で生成したランダム文字列（生成例）
  ```powershell
  -join ((1..32) | ForEach-Object { "{0:x}" -f (Get-Random -Maximum 16) })
  ```
- `enable_oidc_flow = true` にして、STEP 1 の 3 つの出力値を転記

```powershell
terraform init
terraform apply
```

出力を控える（機密値は `-raw` で取り出す）：

```powershell
terraform output assume_role_arn
terraform output web_identity_role_arn
terraform output -raw bootstrap_access_key_id
terraform output -raw bootstrap_secret_access_key
```

### STEP 3 — Azure に AWS の値を戻して再 apply → コードをデプロイ

`terraform/azure/terraform.tfvars` に STEP 2 の値を埋めて：

```powershell
cd ../azure
terraform apply
```

Function のコードを zip デプロイ：

```powershell
cd ../../scripts
./deploy.ps1
```

---

## 6. 動作確認

Function キーを取得：

```powershell
$rg   = terraform -chdir=terraform/azure output -raw resource_group_name
$app  = terraform -chdir=terraform/azure output -raw function_app_name
$base = terraform -chdir=terraform/azure output -raw function_app_base_url
$key  = az functionapp keys list -g $rg -n $app --query "functionKeys.default" -o tsv
```

### ① トークンのクレームを実測する（方式B の設定合わせ）

```powershell
curl "$base/token-claims?code=$key"
```

```json
{
  "claims": {
    "iss": "https://sts.windows.net/<tenant>/",
    "aud": "api://<client-id>",
    "sub": "<principal-id>"
  },
  "awsTerraformValues": { "azure_token_version": "v1", "...": "..." }
}
```

> **重要**: マネージドID が v1 と v2 のどちらのトークンを返すかは環境で変わる。
> `awsTerraformValues` の内容が `terraform/aws/terraform.tfvars` と食い違っていたら、
> そちらを実測値に合わせて `terraform apply` し直す。

### ② STS 経由になっていることを確認

```powershell
curl "$base/whoami?mode=oidc&code=$key"
curl "$base/whoami?mode=accesskey&code=$key"
```

`arn` が `arn:aws:sts::<account>:assumed-role/...` で、`accessKeyId` が **`ASIA`** で始まっていれば
一時クレデンシャルを使えている（長期キーなら `AKIA` で始まる）。

### ③ ファイル一覧とダウンロード

```powershell
curl "$base/files?mode=oidc&code=$key"
curl "$base/download?key=hello.txt&mode=oidc&code=$key"
```

### ④ 2 方式の比較

`?mode=` を切り替えて同じ結果が返ることを確認する。
レスポンスヘッダー `X-Sts-Mode` / `X-Assumed-Role-Arn` でどちらを通ったか分かる。

**「STS 経由でなければ本当に入れないのか」の検証は [docs/verification.md](docs/verification.md) を参照。**

---

## 7. 方式A と方式B の比較

| | 方式A: アクセスキー + AssumeRole | 方式B: OIDC + AssumeRoleWithWebIdentity |
|---|---|---|
| 長期認証情報 | **残る**（App Settings） | **無い** |
| STS API | `sts:AssumeRole` | `sts:AssumeRoleWithWebIdentity` |
| 呼び出しの署名 | 必要（アクセスキーで署名） | **不要**（トークンが身元） |
| なりすまし対策 | `ExternalId`（合言葉） | `aud` + `sub`（Entra ID の署名） |
| キー漏洩時 | ExternalId も漏れれば突破される | 該当なし |
| ローテーション | 手動 | 不要（トークンは自動失効） |
| セットアップ | 簡単 | Entra ID アプリ登録が必要 |
| **本番での推奨** | ✗ | **✓** |

方式A は「STS で権限を分離する」という考え方の理解には十分だが、
長期キーが残るため本番では使わない。慣れたら `enable_access_key_flow = false` にして方式B だけ残す。

---

## 8. ロックアウトからの復旧

`enable_bucket_lockdown = true` は**明示的 Deny** を置くため、設定を誤ると自分もバケットを操作できなくなる。

Terraform 実行者は自動的に例外リストに入る（[terraform/aws/main.tf](terraform/aws/main.tf) の `caller_allowed_user_ids`）が、
別のプロファイルや CI から触る場合は `additional_allowed_user_ids` に追加する必要がある。

現在の許可リストの確認：

```powershell
terraform -chdir=terraform/aws output bucket_lockdown_allowed_user_ids
aws sts get-caller-identity --query UserId --output text --profile <確認したいプロファイル>
```

**締め出された場合**: バケットポリシーの Deny を受けても、**ルートユーザー**は `DeleteBucketPolicy` を実行できる。
ルートでサインインし、S3 コンソールから対象バケットのバケットポリシーを削除すれば復旧する。

一時的に無効化したいだけなら：

```powershell
terraform -chdir=terraform/aws apply -var="enable_bucket_lockdown=false"
```

---

## 9. トラブルシューティング

| 症状 | 原因の候補 |
|---|---|
| `InvalidIdentityToken` | OIDC プロバイダの issuer がトークンの `iss` と不一致。`/api/token-claims` で実測し `azure_token_version` を合わせる |
| `IDPRejectedClaim` | 信頼ポリシーの `aud` / `sub` 条件が実際のクレームと不一致 |
| STS で `AccessDenied` | 方式A なら `ExternalId` の不一致 / 信頼ポリシーの Principal 誤り |
| S3 で `AccessDenied` | バケットポリシーの Deny 例外にロールの `AROA...:*` が無い、または `allowed_prefix` の外を読もうとしている。`/api/whoami` の `userId` と `bucket_lockdown_allowed_user_ids` を突き合わせる |
| `ListBucket` だけ失敗 | `s3:ListBucket` は**バケット ARN** に対する権限。オブジェクト ARN に付けても効かない |
| ロール作成直後だけ失敗 | IAM の伝播待ち。数十秒おいて再試行 |

詳細なログは Application Insights に出る：

```powershell
az monitor app-insights query -g $rg --apps appi-s3sts-<suffix> --analytics-query "traces | where timestamp > ago(30m) | order by timestamp desc | take 50"
```

---

## 10. 後片付け

```powershell
terraform -chdir=terraform/azure destroy
terraform -chdir=terraform/aws destroy
```

> バケットにバージョニングを有効化しているため、オブジェクトが残っていると
> バケット削除に失敗することがある。その場合は先にバージョンを含めて空にしてから `destroy` する。
