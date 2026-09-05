# セットアップガイド

## 全体の流れ

このリポジトリは「AzureのマネージドIDが、長期のAWS認証情報なしにS3のファイルをダウンロードできること」を実証する構成。

鍵になるのは **OIDCフェデレーション（AssumeRoleWithWebIdentity）**:

1. Azure FunctionのマネージドIDが、自分の宛先（`aud`）に対するJWTをEntra IDから取得する
2. そのJWTを持ってAWS STSの `AssumeRoleWithWebIdentity` を呼ぶ
3. AWS側のIAM OIDCプロバイダがJWTの署名をEntra IDの公開鍵で検証し、信頼ポリシーの `aud` / `sub` 条件と照合する
4. 条件を満たせば、一時的なAWS認証情報（AccessKey/SecretKey/SessionToken）が返る
5. その一時認証情報でS3の `GetObject` を呼ぶ

Azure・AWSどちらのAppSettingsにも、パスワードやアクセスキーに相当する秘密情報は登場しない。

## なぜ3段階でapplyするのか

- AWS側のIAM信頼ポリシーは、Azure側の `aud`（Entra Appの識別子）と `sub`（Function Appのマネージド ID オブジェクトID）を条件に使う
- Azure側のFunction Appは、AWS側のIAMロールARNをアプリケーション設定として持つ

つまり両者が互いの出力値を必要とする、典型的な「鶏と卵」の関係にある。これを解決するため:

```
1. terraform/azure apply（AWS側の値は空）
     └─ entra_app_identifier_uri, function_app_principal_id を得る
2. terraform/aws apply（1の値を使う）
     └─ web_identity_role_arn を得る
3. terraform/azure apply（2の値でapp_settingsを更新）
```

## 手順

### 0. 前提条件

- Terraform >= 1.5
- `aws configure` 済みのAWS CLI（S3・IAM・OIDCプロバイダを作成できる権限）
- `az login` 済みのAzure CLI（Entra IDアプリ登録・リソースグループ作成ができる権限。Entra側の操作にはテナントの権限が必要な場合がある）
- Azure Functions Core Tools（`func` コマンド。コードのデプロイに使用）

### 1. Azure側 1回目のapply

```bash
cd terraform/azure
cp terraform.tfvars.example terraform.tfvars
# name_prefix, location, aws_region, aws_s3_bucket を編集
# aws_web_identity_role_arn はこの時点では "" のまま
terraform init
terraform apply
```

apply後、以下を控える:

```bash
terraform output entra_app_identifier_uri     # AWS側の azure_oidc_audience に使う
terraform output function_app_principal_id    # AWS側の azure_function_principal_id に使う
terraform output -raw entra_app_client_id     # ここまで含めてテナントIDも az account show で控えておく
az account show --query tenantId -o tsv       # AWS側の azure_tenant_id に使う
```

### 2. AWS側のapply

```bash
cd ../aws
cp terraform.tfvars.example terraform.tfvars
# bucket_name（グローバル一意）、azure_tenant_id、azure_oidc_audience、
# azure_function_principal_id を1で控えた値に編集
terraform init
terraform apply
terraform output web_identity_role_arn
```

### 3. Azure側 2回目のapply

```bash
cd ../azure
# terraform.tfvars の aws_web_identity_role_arn に2の web_identity_role_arn を設定
terraform apply
```

これでFunction Appの環境変数 `AWS_WEB_IDENTITY_ROLE_ARN` が埋まる。

### 4. Functionコードのデプロイ

```bash
cd ../../src/s3_oidc_download
func azure functionapp publish $(terraform -chdir=../../terraform/azure output -raw function_app_name)
```

## 検証

### トークンの中身を確認する（重要）

一番つまずきやすいのは「トークンのバージョン（v1/v2）」の思い込み違い。マネージドIDが実際に取得するトークンの `iss` / `aud` / `sub` を、Terraformで設定した値と突き合わせる:

```bash
curl "https://<function_app_name>.azurewebsites.net/api/token-claims?code=<function-key>"
```

レスポンス例:

```json
{
  "iss": "https://sts.windows.net/<tenant-id>/",
  "aud": "api://<client-id>",
  "sub": "<managed-identity-object-id>",
  "appid": null
}
```

- `iss` が `sts.windows.net` なら `azure_token_version = "v1"`（デフォルト）のままでよい
- `aud` が `terraform/aws` の `azure_oidc_audience` と完全一致しているか
- `sub` が `azure_function_principal_id` と完全一致しているか

一致していなければAWS側を修正して再applyする。

### ファイル一覧・ダウンロード

```bash
curl "https://<function_app_name>.azurewebsites.net/api/files?code=<function-key>"
curl "https://<function_app_name>.azurewebsites.net/api/download/hello.txt?code=<function-key>" -o hello.txt
```

### パブリックアクセスが無効になっていることの確認

```bash
aws s3api get-public-access-block --bucket <bucket_name>
# BlockPublicAcls/BlockPublicPolicy/IgnorePublicAcls/RestrictPublicBuckets が全てtrueであること

aws s3api get-object --bucket <bucket_name> --key downloads/hello.txt out.txt
# ここは自分のAWS認証情報で読めるかどうかの確認。Assumeしたロール以外からのアクセスを
# 完全に塞ぎたい場合は、別途バケットポリシーでの明示的Denyが必要（このリポジトリの範囲外）
```

## トラブルシューティング

| 症状 | 原因の候補 |
|---|---|
| `AccessDenied` (AssumeRoleWithWebIdentity) | `aud`/`sub` の不一致。`/api/token-claims` の実測値とAWS側の変数を突き合わせる |
| `InvalidIdentityToken` | OIDCプロバイダのURLとトークンの `iss` が食い違っている（v1/v2の取り違え） |
| Function起動時に認証情報が取得できない | マネージドIDが有効化される前にデプロイした場合、反映まで数分かかることがある |
| `AWS_WEB_IDENTITY_ROLE_ARN` が空のまま | 手順3（Azure側2回目のapply）を実行し忘れている |

Application Insights（Function Appの「監視」→「ログ」）で、STS呼び出し時の例外スタックトレースを確認できる。
