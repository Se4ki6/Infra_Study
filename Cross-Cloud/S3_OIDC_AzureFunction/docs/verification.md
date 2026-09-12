# 動作確認手順

> 手順1〜3・6は [scripts/verify.sh.example](../scripts/verify.sh.example) にスクリプト化してある。
> `cp scripts/verify.sh.example scripts/verify.sh` して値を埋めれば実行できる（`verify.sh`はfunction-keyを含むためgit管理外）。

デプロイ済みの環境（またはTerraform apply / Functionコード再デプロイの直後）が、OIDCフェデレーションの一連の流れ通りに動いているかを確認する手順。上から順に実行すれば、途中で失敗した段階からどこに問題があるかを切り分けられる。

前提: `terraform -chdir=terraform/azure output` から `function_app_name` を、Azure PortalまたはCLIから対象Functionの `function-key` を控えておく。

```bash
FUNC_NAME=$(terraform -chdir=terraform/azure output -raw function_app_name)
FUNC_URL="https://${FUNC_NAME}.azurewebsites.net"
CODE="<function-key>"
```

## 1. トークンの中身を確認する（Azure側単体）

```bash
curl -s "$FUNC_URL/api/token-claims?code=$CODE"
```

期待するレスポンス:

```json
{
  "iss": "https://sts.windows.net/<tenant-id>/",
  "aud": "api://<client-id>",
  "sub": "<managed-identity-object-id>",
  "appid": null
}
```

- ここが失敗する（500）場合、AWSは一切関係ない。マネージドIDの有効化、Entra Appの`identifier_uris`設定を疑う
- `iss`/`aud`/`sub`は、`terraform/aws`側の`azure_tenant_id` / `azure_oidc_audience` / `azure_function_principal_id`と完全一致している必要がある（1文字でもずれるとこの先すべて失敗する）

## 2. ファイル一覧取得（AssumeRoleWithWebIdentity + ListBucket）

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}\n" "$FUNC_URL/api/files?code=$CODE"
```

期待する結果: `HTTP_STATUS:200` と `["downloads/hello.txt"]`（サンプルファイルをアップロードした場合）

- `AssumeRoleWithWebIdentity`の`AccessDenied` → IAM信頼ポリシーのCondition（`aud`/`sub`、特にOIDCプロバイダURLの末尾スラッシュ）を疑う。詳細は[troubleshooting-assumerole-accessdenied.md](./troubleshooting-assumerole-accessdenied.md)
- `ListBucket`の`AccessDenied`（1のトークン検証は通ったのにここで落ちる場合） → IAMポリシー`s3-oidc-s3-read`の`s3:prefix`条件と、Function Appの`AWS_S3_PREFIX`設定が一致しているか確認する

## 3. ファイルダウンロード（GetObject）

```bash
curl -s -o /tmp/hello.txt -w "HTTP_STATUS:%{http_code}\n" "$FUNC_URL/api/download/hello.txt?code=$CODE"
cat /tmp/hello.txt
```

期待する結果: `HTTP_STATUS:200` とサンプルファイルの中身がそのまま出力される

## 4. （任意・AWS側の切り分け用）AssumeRoleWithWebIdentityを直接叩く

Functionを経由せず、生のJWTでSTSを直接叩くことで「Azure側のトークン発行」と「AWS側の認可」を完全に切り分けられる。2で失敗する場合に、原因がAzure/AWSどちらにあるかを特定するのに使う。

```bash
export AWS_PROFILE=<検証に使うプロファイル>

# token-claims と同じスコープの生トークンをどこかで入手した上で
aws sts assume-role-with-web-identity \
  --role-arn "$(terraform -chdir=terraform/aws output -raw web_identity_role_arn)" \
  --role-session-name "manual-verify" \
  --web-identity-token "$(cat /path/to/token.txt)"
```

成功すれば一時クレデンシャル(`AccessKeyId`/`SecretAccessKey`/`SessionToken`)が返る。ここが失敗する場合は完全にAWS側（信頼ポリシー・OIDCプロバイダ）の問題。

## 5. Terraformのドリフト確認（設定が意図通りに反映されているかの健全性チェック）

```bash
terraform -chdir=terraform/aws plan
terraform -chdir=terraform/azure plan
```

`No changes.`にならない場合、apply漏れがあるか、手動でコンソール等から変更が入っている（ドリフト）ため、内容を確認してからapplyする。

## 6. パブリックアクセスが無効になっていることの確認

```bash
aws s3api get-public-access-block --bucket "$(terraform -chdir=terraform/aws output -raw s3_bucket_name)"
```

`BlockPublicAcls` / `BlockPublicPolicy` / `IgnorePublicAcls` / `RestrictPublicBuckets` が全て`true`であること。

---

すべて通れば、Azure Managed Identity → Entra ID OIDCトークン発行 → AWS STS AssumeRoleWithWebIdentity → S3 ListBucket/GetObject の一連の流れが、長期のAWSアクセスキーなしで動作していることが確認できたことになる。
