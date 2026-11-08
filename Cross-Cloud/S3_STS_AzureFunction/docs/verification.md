# 「S3 へは STS 経由でのみアクセスできる」ことの検証

Function が動くだけでは「STS 経由**のみ**」の証明にならない。
**STS を経由しない経路が実際に塞がっていること**を確認して初めて要件を満たす。

構築がまだの場合は先に [setup-guide.md](setup-guide.md) を実施すること。
テスト6 以外は AWS CLI だけで実施できる。

事前に値を用意しておく：

```powershell
$bucket = terraform -chdir=../terraform/aws output -raw bucket_name
$role   = terraform -chdir=../terraform/aws output -raw assume_role_arn
$akid   = terraform -chdir=../terraform/aws output -raw bootstrap_access_key_id
$secret = terraform -chdir=../terraform/aws output -raw bootstrap_secret_access_key
$extid  = "<terraform.tfvars に設定した external_id>"
$region = "ap-southeast-2"
```

---

## テスト1: STS を経由しない直接アクセス → 拒否されるべき

bootstrap ユーザーの長期キーをそのまま使って S3 を触る。

```powershell
$env:AWS_ACCESS_KEY_ID     = $akid
$env:AWS_SECRET_ACCESS_KEY = $secret
$env:AWS_SESSION_TOKEN     = $null       # 一時トークンなし = STS を経由していない
$env:AWS_DEFAULT_REGION    = $region

aws s3 ls "s3://$bucket/shared/"
```

**期待結果**：

```
An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
```

このユーザーには `sts:AssumeRole` しか許可されておらず、さらにバケットポリシーの Deny にも掛かる。
**長期キーが漏れても S3 には到達できない**ことがここで確認できる。

---

## テスト2: STS を経由する → 成功するべき

同じキーで、今度はロールを Assume してから触る。

```powershell
$sts = aws sts assume-role `
  --role-arn $role `
  --role-session-name "verification-test" `
  --external-id $extid `
  --duration-seconds 900 | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID     = $sts.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $sts.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $sts.Credentials.SessionToken

aws sts get-caller-identity
aws s3 ls "s3://$bucket/shared/"
aws s3 cp "s3://$bucket/shared/hello.txt" ./hello.txt
```

**期待結果**：

- `AccessKeyId` が **`ASIA`** で始まる（テスト1 の `AKIA` と対比）
- `get-caller-identity` の `Arn` が `arn:aws:sts::<account>:assumed-role/s3-sts-azure-s3-access-assumerole/verification-test`
- 一覧とダウンロードが成功する

同じ長期キーから出発して、**STS を挟んだかどうかだけ**で結果が変わる。これが要件そのもの。

---

## テスト3: ExternalId が違うと Assume できない

```powershell
$env:AWS_ACCESS_KEY_ID     = $akid
$env:AWS_SECRET_ACCESS_KEY = $secret
$env:AWS_SESSION_TOKEN     = $null

aws sts assume-role --role-arn $role --role-session-name "wrong-extid" --external-id "wrong-value"
```

**期待結果**：`AccessDenied`（信頼ポリシーの `sts:ExternalId` 条件で弾かれる）

ロール ARN とアクセスキーの両方を知っていても、合言葉がなければ通らない。

---

## テスト4: 許可プレフィックスの外は読めない（最小権限の確認）

テスト2 の一時クレデンシャルを設定した状態で、プレフィックス外を触る。

```powershell
aws s3api put-object --bucket $bucket --key "secret/confidential.txt" --body ./hello.txt
aws s3 ls "s3://$bucket/"
```

**期待結果**：どちらも `AccessDenied`

- 書き込みは許可していない（読み取り専用ロール）
- ルート直下の一覧は `s3:prefix` 条件（`shared/*`）を満たさない

---

## テスト5（発展）: 管理者権限でも Deny されることの確認

「バケットポリシーの Deny が IAM ポリシーより優先される」ことを直接確認する。
**一時的に IAM ユーザーを作るので、必ず後片付けまで実施すること。**

```powershell
# 管理者権限を持つテストユーザーを作る（SSO 管理者プロファイルで実行）
$p = "AdministratorAccess-339126664118"
aws iam create-user --user-name sts-lockdown-test --profile $p
aws iam attach-user-policy --user-name sts-lockdown-test `
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile $p
$k = aws iam create-access-key --user-name sts-lockdown-test --profile $p | ConvertFrom-Json

# そのユーザーでバケットを触る（IAM 上は全権限を持っている）
$env:AWS_ACCESS_KEY_ID     = $k.AccessKey.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $k.AccessKey.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $null
Start-Sleep -Seconds 15      # IAM の伝播待ち

aws s3 ls "s3://$bucket/shared/"
```

**期待結果**：`AccessDenied`

`AdministratorAccess` を持っていても、バケットポリシーの明示的 Deny が優先されて拒否される。
これが「S3 アクセスを STS 経由のみに強制できている」ことの決定的な証拠。

### 後片付け（必ず実行）

```powershell
$env:AWS_ACCESS_KEY_ID = $null; $env:AWS_SECRET_ACCESS_KEY = $null; $env:AWS_SESSION_TOKEN = $null

aws iam delete-access-key --user-name sts-lockdown-test --access-key-id $k.AccessKey.AccessKeyId --profile $p
aws iam detach-user-policy --user-name sts-lockdown-test `
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile $p
aws iam delete-user --user-name sts-lockdown-test --profile $p
```

---

## テスト6: Azure Function（外部）からの経路

ここまでは同一アカウント内からの検証。最後に「外部」からの経路を確認する。

```powershell
curl "$base/whoami?mode=oidc&code=$key"
curl "$base/download?key=hello.txt&mode=oidc&code=$key"
```

**期待結果**：`arn` が `assumed-role/s3-sts-azure-s3-access-oidc/...`、ファイルの中身が返る。

方式B では **Azure 側に AWS の長期認証情報が一切存在しない**状態でこれが成立している。
Function App の App Settings を確認しても、方式B に関わる値はロール ARN とスコープだけで、
シークレットは含まれていない。

```powershell
az functionapp config appsettings list -g $rg -n $app --query "[?contains(name,'AWS')].{name:name,value:value}" -o table
```

---

## 結果まとめ

| テスト | 経路 | 期待 |
|---|---|---|
| 1 | 長期キーで直接 S3 | ❌ AccessDenied |
| 2 | 長期キー → STS AssumeRole → S3 | ✅ 成功 |
| 3 | ExternalId 不一致で AssumeRole | ❌ AccessDenied |
| 4 | STS 経由だが許可プレフィックス外 | ❌ AccessDenied |
| 5 | AdministratorAccess で直接 S3 | ❌ AccessDenied |
| 6 | Azure Function → OIDC → STS → S3 | ✅ 成功 |

1・5 が `AccessDenied`、2・6 が成功していれば要件は満たされている。

---

## 後片付けの注意

環境変数に一時クレデンシャルが残ったままだと、以降の `terraform apply` が
そのクレデンシャルで動いて失敗する。検証が終わったら必ずクリアする：

```powershell
$env:AWS_ACCESS_KEY_ID = $null
$env:AWS_SECRET_ACCESS_KEY = $null
$env:AWS_SESSION_TOKEN = $null
```
