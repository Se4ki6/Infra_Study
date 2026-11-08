# 会社アカウントでの AssumeRole 検証ガイド

Azure Function は使わず、**S3 バケットロックダウン + AssumeRole の制限だけ**を
会社の AWS アカウントに再現し、AWS CLI だけで動作を検証する手順。

対象読者は、既に個人検証用アカウントで [setup-guide.md](setup-guide.md) を一通り終え、
[s3-access-control.md](s3-access-control.md) で仕組みを理解した上で、
同じ制限を別アカウントで確認したい人。

使うのは既存の `terraform/aws` 配下のモジュールのみ（`terraform/azure` は使わない）。
方式A（IAM ユーザーのアクセスキー + `sts:AssumeRole`）と、
その入口を絞る `s3_bucket_lockdown` だけを有効化する。

---

## 0. 実行前に必ず確認すること

このリポジトリの `terraform/aws` は **ローカル state**（`terraform/aws/terraform.tfstate`）を使う
（[provider.tf](../terraform/aws/provider.tf) に `backend` の指定が無い＝デフォルトのローカルバックエンド）。

個人検証用アカウントに対して既に `apply` 済みの state がある状態で、
**同じディレクトリ・同じ state のまま** プロファイルだけ会社アカウントに切り替えて `apply` すると、
Terraform は「個人アカウントの state に記録されたリソースが跡形もなく消えた」と解釈し、
最悪の場合 `bucket_name` が同名であれば会社アカウント側の別バケットに対して
予期しない operation を行いかねない。**必ず state を分離する。**

```powershell
cd terraform/aws
terraform workspace new company
terraform workspace show   # "company" になっていることを確認
```

以後の `plan` / `apply` / `destroy` はすべてこの `company` ワークスペースの中で完結し、
個人検証用アカウントの state（`default` ワークスペース）には一切触れない。
作業を個人アカウントに戻すときは:

```powershell
terraform workspace select default
```

も忘れずに。**`terraform workspace show` で今どちらを向いているか、apply の直前に必ず確認する習慣をつける。**

---

## 1. 前提

| 項目 | 内容 |
|---|---|
| 会社アカウントでの必要権限 | S3・IAM（バケット/ロール/ユーザー/ポリシーの作成）。詳細は下記 1-1 |
| AWS CLI プロファイル | 会社アカウント用に設定済み（`aws configure` または `aws configure sso`） |
| Terraform | >= 1.9（個人検証用と共通のインストールでよい） |

### 1-1. 依頼する IAM 権限

この構成が実際に呼び出す API から逆算すると、必要なのは大きく分けて
「**特定の S3 バケット 1 個に対するフル操作**」と
「**特定の名前パターンの IAM リソース（ロール／ユーザー／ポリシー）に対する作成・削除**」の 2 つだけ。
`AdministratorAccess` のような広い権限をもらう必要はない。

IAM 管理者・セキュリティ担当に依頼する際は、以下のカスタムポリシーをそのまま渡せる。
`<ACCOUNT_ID>` は会社アカウントのID、`<NAME_PREFIX>` は `terraform.tfvars.company` の
`name_prefix`（例: `s3-sts-test`）、`<BUCKET_NAME>` は `bucket_name` に置き換える。
apply・destroy の両方に必要な権限を含めてある。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3BucketFullAccessScoped",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::<BUCKET_NAME>",
        "arn:aws:s3:::<BUCKET_NAME>/*"
      ]
    },
    {
      "Sid": "IamRoleAndUserManagementScoped",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreateUser",
        "iam:GetUser",
        "iam:DeleteUser",
        "iam:TagUser",
        "iam:UntagUser",
        "iam:PutUserPolicy",
        "iam:GetUserPolicy",
        "iam:DeleteUserPolicy",
        "iam:ListUserPolicies",
        "iam:CreateAccessKey",
        "iam:ListAccessKeys",
        "iam:DeleteAccessKey"
      ],
      "Resource": [
        "arn:aws:iam::<ACCOUNT_ID>:role/<NAME_PREFIX>-*",
        "arn:aws:iam::<ACCOUNT_ID>:user/<NAME_PREFIX>-*"
      ]
    },
    {
      "Sid": "IamPolicyManagementScoped",
      "Effect": "Allow",
      "Action": [
        "iam:CreatePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicyVersion",
        "iam:DeletePolicy",
        "iam:TagPolicy",
        "iam:UntagPolicy"
      ],
      "Resource": "arn:aws:iam::<ACCOUNT_ID>:policy/<NAME_PREFIX>-*"
    },
    {
      "Sid": "CallerIdentity",
      "Effect": "Allow",
      "Action": "sts:GetCallerIdentity",
      "Resource": "*"
    }
  ]
}
```

補足:

- `S3BucketFullAccessScoped` を `s3:*` にしているのは、Terraform の AWS provider がバケットの
  状態確認（drift 検出）のために ACL・ロギング・ライフサイクル等、非常に多くの `Get*` を呼ぶため。
  個別に列挙すると provider のバージョンアップで抜けが発生しやすく、対象を「このバケット 1 個」
  に絞ってあるので範囲としては十分小さい。
- IAM 側はあえて `iam:*` にせず個別列挙にしてある。`iam:PassRole` や他人のポリシーへの
  `AttachUserPolicy` は含まれないため、ロール/ユーザーの権限昇格の踏み台にはならない設計。
- 検証が終わったら（[7. 後片付け](#7-後片付け) の `destroy` 完了後）、このポリシー自体も
  忘れずに剥奪してもらうこと。**一時的な権限**として依頼するのが望ましい。
- 会社によっては「個別権限の申請より、期間限定で `PowerUserAccess` を借りる方が早い」場合もある。
  その場合も IAM 変更（`iam:*FullAccess` や `AdministratorAccess`）までは不要、という点だけは
  申請時に明確にしておくとレビューが通りやすい。

会社アカウント用プロファイルの動作確認：

```powershell
aws sts get-caller-identity --profile <会社アカウント用プロファイル名>
```

`Account` が会社アカウントの ID になっていることを確認する。

---

## 2. tfvars を用意する

会社アカウント向けのサンプルを [terraform/aws/terraform.tfvars.company.example](../terraform/aws/terraform.tfvars.company.example)
に用意してある。Azure 系の変数は `enable_oidc_flow = false` にしてあるので、
方式A とロックダウンだけが作られる（[terraform/aws/variables.tf](../terraform/aws/variables.tf) の
`azure_tenant_id` 等のバリデーションも `enable_oidc_flow = false` なら発火しない）。

```powershell
cd terraform/aws
cp terraform.tfvars.company.example terraform.tfvars.company
```

`terraform.tfvars.company` を編集する（`CHANGE_ME` を全て置き換える）：

- `aws_profile` — 会社アカウント用プロファイル名
- `bucket_name` — グローバルに一意な名前（会社の命名規則があればそれに従う）
- `external_id` — 自分で生成したランダム文字列
  ```powershell
  -join ((1..32) | ForEach-Object { "{0:x}" -f (Get-Random -Maximum 16) })
  ```
- 必要なら `additional_allowed_user_ids` に会社の管理者プロファイルなどを追加

---

## 3. apply する

**`terraform workspace show` が `company` になっていることを再確認してから**実行する。

```powershell
terraform init
terraform plan  -var-file="terraform.tfvars.company"
terraform apply -var-file="terraform.tfvars.company"
```

`plan` の出力で作られるリソースを確認する：

- `aws_s3_bucket` ×1（+ versioning / SSE / public access block / ownership controls）
- `aws_s3_bucket_policy` ×1（ロックダウン本体）
- `aws_iam_policy` ×1（S3 読み取り専用）
- `aws_iam_role` ×1（`<name_prefix>-s3-access-assumerole`）
- `aws_iam_user` ×1（`<name_prefix>-bootstrap`）+ `aws_iam_access_key` ×1

Azure 関連（OIDC プロバイダ、方式B のロール）は `enable_oidc_flow = false` なので作られない。

出力値を控える：

```powershell
terraform output assume_role_arn
terraform output bucket_name
terraform output bucket_lockdown_allowed_user_ids
terraform output -raw bootstrap_access_key_id
terraform output -raw bootstrap_secret_access_key
```

---

## 4. AssumeRole 制限の検証（AWS CLI）

[verification.md](verification.md) のテスト1〜5 と同じ内容を、会社アカウントのプロファイルを
指定して実施する。値を変数にセットする：

```powershell
terraform workspace select company   # 念のため再確認
$bucket = terraform output -raw bucket_name
$role   = terraform output -raw assume_role_arn
$akid   = terraform output -raw bootstrap_access_key_id
$secret = terraform output -raw bootstrap_secret_access_key
$extid  = "<terraform.tfvars.company に設定した external_id>"
$region = terraform output -raw aws_region
```

### テスト1: 長期キーで直接 S3 → 拒否されるべき

```powershell
$env:AWS_ACCESS_KEY_ID     = $akid
$env:AWS_SECRET_ACCESS_KEY = $secret
$env:AWS_SESSION_TOKEN     = $null
$env:AWS_DEFAULT_REGION    = $region

aws s3 ls "s3://$bucket/shared/"
```

期待結果: `AccessDenied`（`bootstrap` ユーザーには `sts:AssumeRole` しか許可されておらず、
バケットポリシーの Deny にも掛かる）。

### テスト2: STS 経由 → 成功するべき

```powershell
$sts = aws sts assume-role `
  --role-arn $role `
  --role-session-name "company-verification-test" `
  --external-id $extid `
  --duration-seconds 900 | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID     = $sts.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $sts.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $sts.Credentials.SessionToken

aws sts get-caller-identity
aws s3 ls "s3://$bucket/shared/"
```

期待結果: `AccessKeyId` が `ASIA` で始まり、`Arn` が
`arn:aws:sts::<会社アカウントID>:assumed-role/<name_prefix>-s3-access-assumerole/company-verification-test`、
一覧取得が成功する。

> `sample_files_folder` を空文字にした場合、`shared/` 配下にサンプルファイルは無いので
> 一覧は空配列で返るのが正常（`AccessDenied` にならず 0 件で返れば OK）。
> ファイルを置いて確認したい場合は `terraform.tfvars.company` に
> `sample_files_folder = "../../sample_files"` を追加して再 apply する。

### テスト3: ExternalId 不一致 → Assume できない

```powershell
$env:AWS_ACCESS_KEY_ID     = $akid
$env:AWS_SECRET_ACCESS_KEY = $secret
$env:AWS_SESSION_TOKEN     = $null

aws sts assume-role --role-arn $role --role-session-name "wrong-extid" --external-id "wrong-value"
```

期待結果: `AccessDenied`。

### テスト4: 許可プレフィックス外は読めない

テスト2 の一時クレデンシャルのまま：

```powershell
aws s3api put-object --bucket $bucket --key "secret/confidential.txt" --body <適当なローカルファイル>
aws s3 ls "s3://$bucket/"
```

期待結果: どちらも `AccessDenied`（書き込み権限なし／`s3:prefix` 条件外）。

### テスト5（発展・要注意）: 会社の管理者権限でも Deny されることの確認

**会社アカウントに一時的な IAM ユーザーを作成する。実施前に会社のポリシー・上長の許可を確認すること。**
テスト用ユーザーの命名・作成は必ず会社の運用ルールに従う。

```powershell
$p = "<会社アカウント用の管理者プロファイル>"
aws iam create-user --user-name sts-lockdown-test --profile $p
aws iam attach-user-policy --user-name sts-lockdown-test `
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile $p
$k = aws iam create-access-key --user-name sts-lockdown-test --profile $p | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID     = $k.AccessKey.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $k.AccessKey.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $null
Start-Sleep -Seconds 15

aws s3 ls "s3://$bucket/shared/"
```

期待結果: `AccessDenied`（`AdministratorAccess` を持っていてもバケットポリシーの明示的 Deny が優先される）。

**後片付け（必ず実行）**：

```powershell
$env:AWS_ACCESS_KEY_ID = $null; $env:AWS_SECRET_ACCESS_KEY = $null; $env:AWS_SESSION_TOKEN = $null

aws iam delete-access-key --user-name sts-lockdown-test --access-key-id $k.AccessKey.AccessKeyId --profile $p
aws iam detach-user-policy --user-name sts-lockdown-test `
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile $p
aws iam delete-user --user-name sts-lockdown-test --profile $p
```

---

## 5. 結果まとめ

| テスト | 経路 | 期待 |
|---|---|---|
| 1 | 長期キーで直接 S3 | ❌ AccessDenied |
| 2 | 長期キー → STS AssumeRole → S3 | ✅ 成功 |
| 3 | ExternalId 不一致で AssumeRole | ❌ AccessDenied |
| 4 | STS 経由だが許可プレフィックス外 | ❌ AccessDenied |
| 5 | AdministratorAccess で直接 S3 | ❌ AccessDenied |

1・3・4・5 が `AccessDenied`、2 が成功していれば「S3 アクセスは AssumeRole 経由のみ」が
会社アカウントでも再現できている。仕組み自体の解説は [s3-access-control.md](s3-access-control.md) を参照。

---

## 6. ロックアウトした場合

`enable_bucket_lockdown = true` は明示的 Deny を置くため、`allowed_user_ids` の設定を誤ると
自分自身も操作できなくなりうる。[README.md](../README.md) の「8. ロックアウトからの復旧」と同じ対処：

```powershell
terraform workspace select company
terraform output bucket_lockdown_allowed_user_ids
aws sts get-caller-identity --query UserId --output text --profile <会社アカウント用プロファイル>
```

一時的に無効化：

```powershell
terraform apply -var-file="terraform.tfvars.company" -var="enable_bucket_lockdown=false"
```

それでも復旧しない場合は、会社アカウントの**ルートユーザー**（または、それに準ずる
バケットポリシー削除権限を持つ管理者）に依頼してバケットポリシーを削除してもらう。

---

## 7. 後片付け

検証が終わったら必ず削除する。会社アカウントにリソースを残さないこと。

```powershell
terraform workspace select company
terraform destroy -var-file="terraform.tfvars.company"
```

> バージョニングが有効なため、オブジェクトが残っていると削除に失敗することがある。
> その場合は先にバージョンを含めてオブジェクトを空にしてから `destroy` する。

destroy 後、不要になった workspace も削除しておく：

```powershell
terraform workspace select default
terraform workspace delete company
```

環境変数に一時クレデンシャルが残っていると以降の操作に影響するため、必ずクリアする：

```powershell
$env:AWS_ACCESS_KEY_ID = $null
$env:AWS_SECRET_ACCESS_KEY = $null
$env:AWS_SESSION_TOKEN = $null
```
