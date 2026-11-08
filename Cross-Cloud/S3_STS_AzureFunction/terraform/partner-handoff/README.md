# S3 AssumeRole 限定公開 — 連携用 Terraform

**このディレクトリ単体で完結する。** 他のディレクトリ (`../modules`, `../aws` など) には依存しないため、
このフォルダごとコピー/共有するだけで、他の環境でもそのまま `terraform init && apply` できる。

## これは何を作るか

連携先（バッチ側）は AWS アカウントを持たない前提で、こちら側の AWS アカウントに
「AssumeRole 経由でしか S3 に到達できない」状態を作り、その結果（ロール ARN・アクセスキー・
ExternalId）を連携先に渡すための構成。

作成されるもの:

1. **S3 バケット**（新規作成）+ バージョニング / SSE-S3 暗号化 / パブリックアクセス全ブロック / ACL 無効化
2. **バケットポリシー** — AssumeRole したセッション以外の全 principal を明示的 Deny
   （このアカウントの `AdministratorAccess` を持つ者でも直接は触れなくなる）
3. **IAM ポリシー** — `allowed_prefix` 配下の読み取り専用（`GetObject` / `GetObjectVersion` / `ListBucket`）
4. **IAM ロール**（Assume される側）— 上記ポリシーをアタッチ
5. **IAM ユーザー `bootstrap`**（Assume する側）— S3 権限は一切持たず、`sts:AssumeRole` のみ許可。
   信頼ポリシーに `sts:ExternalId` 条件を必須で付ける
6. **bootstrap ユーザーのアクセスキー**

なぜこれで「S3 はAssumeRole経由のみ」を強制できるのか、評価順序（明示的 Deny が最優先）の
詳細な解説は、引き渡し元リポジトリの `docs/s3-access-control.md` を参照。

## 使い方

```powershell
cd terraform/partner-handoff
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集する（`CHANGE_ME` を全て置き換える）。特に `external_id` は
必ず自分で生成したランダム値にすること（16文字未満だと `plan` の時点でエラーになる）。

```powershell
terraform init
terraform plan
terraform apply
```

## apply 後、連携先に渡す値

```powershell
terraform output assume_role_arn
terraform output bucket_name
terraform output allowed_prefix
terraform output -raw bootstrap_access_key_id
terraform output -raw bootstrap_secret_access_key
terraform output -raw external_id
```

**`bootstrap_secret_access_key` と `external_id` は、Slack・メール・チケットへの平文貼り付けを避け、
Azure Key Vault などのシークレットストア経由で連携先に渡すこと。**
`bootstrap_access_key_id` と `assume_role_arn` は単体では S3 に到達できない値なので機密度は低いが、
まとめてシークレットストアで管理して問題ない。

| 値 | 機密度 | 連携先での扱い |
|---|---|---|
| `assume_role_arn` | 低（単なる宛先の識別子） | 通常の設定値でよい |
| `bootstrap_access_key_id` | 低〜中 | Secret とセットで管理すると楽 |
| `bootstrap_secret_access_key` | **高** | シークレットストア必須 |
| `external_id` | 中（このアカウントの CloudTrail には平文で残る） | シークレットストア推奨 |

## ロックアウトに注意

`enable_bucket_lockdown = true`（デフォルト）は明示的 Deny を置くため、`apply` を実行した
本人は `data.aws_caller_identity.current` により自動的に許可リストへ入るが、**別の管理者
プロファイルや CI から後で触る場合は、事前に `additional_allowed_user_ids` へ追加しておくこと**。

締め出された場合、バケットポリシーの Deny を受けても**ルートユーザー**は `DeleteBucketPolicy`
を実行できるため、ルートでサインインしてバケットポリシーを削除すれば復旧できる。

一時的に無効化したいだけなら:

```powershell
terraform apply -var="enable_bucket_lockdown=false"
```

## 後片付け

連携が不要になったら:

```powershell
terraform destroy
```

> バージョニングが有効なため、オブジェクトが残っていると `destroy` に失敗することがある。
> その場合は先にバージョンを含めてオブジェクトを空にしてから再実行する。
