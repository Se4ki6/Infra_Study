# トラブルシューティング: AssumeRoleWithWebIdentityのAccessDenied

対象: [S3_OIDC_AzureFunction](../README.md) の最終ステップ、AWS STSの`AssumeRoleWithWebIdentity`。

**現在の状態（2026-09-12時点）: 解決済み。** 原因は信頼ポリシーのCondition条件キーの末尾スラッシュだった（詳細は8節）。`/api/files`・`/api/download/{key}`ともにエンドツーエンドで動作確認済み。

---

## 1. 症状

Azure Functionの`/api/files`・`/api/download/{key}`エンドポイントが、S3アクセスの直前で失敗する。

```
botocore.exceptions.ClientError: An error occurred (AccessDenied) when calling
the AssumeRoleWithWebIdentity operation: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

`/api/token-claims`は常に成功しており、Azure側のトークン発行自体は問題ない。

---

## 2. 解決済みの問題（今回のセッションで発見・修正した3つの本物のバグ）

このAccessDenied自体は未解決だが、その手前で以下3つの本物のバグを発見・修正した。これらは対処済みで、今後同じ問題を踏まないためのメモとして残す。

### 2-1. Terraformの`azuread_application`が`identifier_uris`をクリアし続けるバグ

`terraform/modules/azure/entra_app/main.tf`で、`azuread_application`リソースが`identifier_uris`属性を自分の管轄だと誤認識し、**関係ない変更のapplyのたびに、別リソース(`azuread_application_identifier_uri`)が設定したURIを黙って消していた**。

- 症状: 一度設定した`aud`（`api://<client-id>`）が、何かのapply後に空になり、次にトークンを要求すると`invalid_scope`エラーになる
- 修正: `azuread_application`リソースに`lifecycle { ignore_changes = [identifier_uris] }`を追加

### 2-2. AWS IAM OIDCプロバイダのサムプリント取得元の誤り

`terraform/modules/aws/sts_oidc_flow/main.tf`が、`sts.windows.net`の**Webサイット用TLS証明書**（DigiCert発行）からサムプリントを取っていた。しかしAWS公式ドキュメントの推奨は「上位の中間CA」の証明書であり、正しくは`data.tls_certificate.azure.certificates[0]`（チェーンの先頭）を使うべきだった。

- 結論として、これは最終的なAccessDeniedの原因ではなかったが、放置すべきでない設定ミスなので修正済み

### 2-3. `InvalidIdentityToken`の真因: OIDCプロバイダURLの末尾スラッシュ

**これが一番時間を溶かした問題。** AWSのIAM OIDCプロバイダに登録する`url`は、JWTの`iss`クレームと**完全一致**している必要があり、AWSは末尾スラッシュを正規化してくれない。

- Azure AD v1トークンの`iss`は `https://sts.windows.net/<tenant>/`（末尾スラッシュ**あり**）
- 旧コードは `https://sts.windows.net/<tenant>`（スラッシュ**なし**）で登録していた
- この不一致により、署名・証明書・サムプリントを何度変えても直らない`InvalidIdentityToken`が発生していた
- 修正: `terraform/modules/aws/sts_oidc_flow/main.tf`の`issuer_url`ローカル変数にv1用の末尾スラッシュを追加し、信頼ポリシーの条件キー用プレフィックス（`condition_prefix`）は逆に`trimsuffix`でスラッシュを除去するよう分離した

この修正により、**トークン検証（署名・iss/aud/subの照合）は完全に成功するようになった**。CloudTrailでも`identityProvider`が正しいOIDCプロバイダARNと一致していることを確認済み。

---

## 3. 現在の問題: AssumeRoleWithWebIdentityのAccessDenied

トークン検証が通った**後**の認可ステップで、以下のエラーが一貫して発生する。

```json
{"Error":{"Code":"AccessDenied","Message":"Not authorized to perform sts:AssumeRoleWithWebIdentity","Type":"Sender"}}
```

### 再現方法（当時。`debug-raw-msi`は解決後に削除済み）

```bash
export AWS_PROFILE=AdministratorAccess-339126664118

# Function Appから生のトークンを取得（デバッグ用エンドポイント。現在は削除済み）
CODE="<function-key>"
curl -s "https://func-s3oidc-x187ag.azurewebsites.net/api/debug-raw-msi?code=$CODE" | \
  python3 -c "import json,sys; print(json.loads(json.load(sys.stdin)['response_body'])['access_token'])" > /tmp/token.txt

# AssumeRoleWithWebIdentityを直接呼ぶ → AccessDenied
aws sts assume-role-with-web-identity \
  --role-arn "arn:aws:iam::339126664118:role/s3-oidc-s3-access-oidc" \
  --role-session-name "repro" \
  --web-identity-token "$(cat /tmp/token.txt)"
```

現在同様の切り分けを行う場合は、`/api/token-claims`のレスポンスからJWTそのものは取得できない（クレームのみ返す設計）ため、[docs/verification.md](./verification.md)の手順4（`token-claims`相当の生JWTを別途入手した上でSTSを直接叩く）を参照。

### 唯一の成功例（再現不可）

2026-09-05のセッション中、OIDCプロバイダを`delete → create`で作り直した**直後の一回だけ**、条件付き信頼ポリシーのまま成功し、正常な一時クレデンシャルが返ってきた。以降、設定を一切変えていないにもかかわらず、同じ呼び出しが再び失敗するようになった。

---

## 4. 除外できた原因（すべて検証済み・シロ）

| 疑ったもの | 検証方法 | 結果 |
|---|---|---|
| トークンの署名が不正 | JWKSの公開鍵で手動暗号検証 | ✅ 正当な署名 |
| `aud`/`sub`の不一致 | トークンとtrust policyのconditionをバイト単位で比較 | ✅ 完全一致 |
| OIDCプロバイダURLの不一致 | `iss`とプロバイダの`Url`を比較 | ✅ 完全一致（末尾スラッシュ含む） |
| サムプリントの誤り | 複数パターン（Webサイト証明書のleaf/中間CA、JWKS署名証明書、組み合わせ）を総当たり | ✅ どれでも同じ結果（影響なし） |
| ロール固有の問題 | 別名の新規ロール(`s3-oidc-s3-access-oidc-v2`)を作成して即テスト | ✅ 新規ロールでも即座に同じAccessDenied |
| OIDCプロバイダ固有の問題（キャッシュ等） | プロバイダをdelete→createで作り直し | △ 直後の1回だけ成功、以降失敗（下記参照） |
| IAMの反映待ち（結果整合性） | 10分待機後・1週間待機後に再テスト | ✅ 時間経過では改善しない |
| 自分のAWS認証情報での署名が悪さをしている | `--no-sign-request`、生のHTTP POSTで無署名リクエスト | △ 一度だけ無署名で成功したが再現不可。その後は無署名でも失敗 |
| Function側のboto3が意図せず署名している | `Config(signature_version=UNSIGNED)`を明示指定して再デプロイ | ✅ 明示的に無署名にしても同じAccessDenied |
| Organizationのservice control policy (SCP) | このAWSアカウントは組織の**管理アカウント自体**（SCPはメンバーアカウントにのみ適用され、管理アカウントは対象外） | ✅ 該当なし |
| Resource control policy (RCP) | `aws organizations list-policies --filter RESOURCE_CONTROL_POLICY` | ✅ 存在しない。`list-roots`でも有効なポリシータイプは0件 |
| SSOロールの権限境界（Permissions Boundary） | `aws iam get-role`で確認 | ✅ 設定なし |
| AWSの「共有OIDCプロバイダ」向け追加条件(`sts:RoleSessionName`必須化) | [IAM公式ドキュメント](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_secure-by-default.html)の該当表を確認し、`sts:RoleSessionName`条件を追加してテスト | ✅ 該当なし（表に載っているのはAzure Sentinel専用の別テナントID）。条件を追加しても変化なし |
| リージョンが有効化されていない | `aws account list-regions`で確認 | ✅ `ap-northeast-1`・`ap-southeast-2`とも`ENABLED_BY_DEFAULT` |
| トークンの有効期限切れ・クロックスキュー | `iat`/`nbf`/`exp`と現在時刻を精密に比較 | ✅ 問題なし |
| Entra側のアプリ割り当て（Enterprise Application） | `appRoleAssignmentRequired`を確認 | ✅ `false`。そもそも割り当て不要な設定で、Azure側のトークン発行自体が成功し続けていることからも無関係と判断 |

---

## 5. 現在のリソース状態（AWS）

| リソース | 値 |
|---|---|
| OIDCプロバイダ | `arn:aws:iam::339126664118:oidc-provider/sts.windows.net/d92d8acd-a3c2-4792-8c72-a8b1f153297c/`（末尾スラッシュあり） |
| ClientIDList | `api://f815cc1c-e657-4182-b41e-a58d4069906d` |
| ThumbprintList | `1b511abead59c6ce207077c0bf0e0043b1382612` |
| IAMロール（本番） | `arn:aws:iam::339126664118:role/s3-oidc-s3-access-oidc` |
| IAMロール（検証用、最小再現ケース） | `arn:aws:iam::339126664118:role/s3-oidc-s3-access-oidc-v2` |
| 信頼ポリシーCondition | `sts.windows.net/d92d8acd-a3c2-4792-8c72-a8b1f153297c:aud` = `api://f815cc1c-e657-4182-b41e-a58d4069906d`<br>`sts.windows.net/d92d8acd-a3c2-4792-8c72-a8b1f153297c:sub` = `59851f7c-c8d9-4590-ad95-ef14533cd6c7` |
| AWSアカウント | `339126664118`（Organizationの管理アカウント） |

トークン側（Azure）:

| クレーム | 値 |
|---|---|
| `iss` | `https://sts.windows.net/d92d8acd-a3c2-4792-8c72-a8b1f153297c/` |
| `aud` | `api://f815cc1c-e657-4182-b41e-a58d4069906d` |
| `sub` | `59851f7c-c8d9-4590-ad95-ef14533cd6c7` |
| `ver` | `1.0` |
| `kid` | `T5h40q7G0x49qn41lM9-kKjpD98` |

---

## 6. CloudTrailの参考RequestId（AWSサポート提出用）

すべて`eventSource: sts.amazonaws.com`, `eventName: AssumeRoleWithWebIdentity`, `errorCode: AccessDenied`, `errorMessage: Not authorized to perform sts:AssumeRoleWithWebIdentity`。

| 日時(UTC) | RequestId |
|---|---|
| 2026-09-12T02:27:33Z | `dbe8d7ce-fd71-4a61-86da-9a9b9a36415b` |
| 2026-09-12T02:25:42Z | `ba1d65cc-99c1-4eb0-b20d-56478bda722c` |
| 2026-09-12T02:25:35Z | `14e7a0de-86d8-4146-a62f-ca8070ccba4c` |
| 2026-09-12T02:25:29Z | `d0556f10-d0da-4761-abeb-f1d9dd6ca5af` |
| 2026-09-12T02:25:23Z | `b8355467-b825-4ebe-84f3-14de01d74f95` |
| 2026-09-05T05:41:12Z | `53dc1e27-a434-4941-963f-4b6f802bdf31` |
| 2026-09-05T05:40:55Z | `2cf9fe71-8091-4e77-9cab-4f6201afe21b` |
| 2026-09-05T05:40:32Z | `70c7b383-6d4a-4448-8e8f-67319b61dad9` |

再取得コマンド:

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 10
```

---

## 7. 根本原因（2026-09-12特定）

CloudTrailのイベントを見ると、失敗した呼び出しでも`userIdentity.principalId`が`<oidc-provider-arn>:<aud>:<sub>`の形で正しく解決されていた。つまりトークンの署名検証・`ClientIDList`・サムプリント照合はすべて成功しており、`AccessDenied`は信頼ポリシーの**Condition評価**でのみ発生していた。

検証用ロール`s3-oidc-s3-access-oidc-v2`で切り分けたところ:

| 信頼ポリシーのCondition | 結果 |
|---|---|
| なし（Principal + Actionのみ） | ✅ 成功 |
| `sts.windows.net/<tenant>:aud`（末尾スラッシュなし） | ❌ AccessDenied |
| `sts.windows.net/<tenant>/:aud`（末尾スラッシュ**あり**） | ✅ 成功 |

**結論:** AWSは信頼ポリシーの条件キーを「OIDCプロバイダに登録したURL（スキームのみ除去）」からそのまま組み立てる。今回はv1トークン対応のため登録URLを`https://sts.windows.net/<tenant>/`（末尾スラッシュあり）にしていたが、信頼ポリシーの条件キー側だけ`trimsuffix`でスラッシュを除去していたため、両者が永遠に一致しない条件になっていた。トークン検証は通るのに認可だけ拒否される、という今回の症状はこれで完全に説明できる。「プロバイダ再作成直後の1回だけ成功」は、再作成直後の一瞬だけ古いポリシー評価がキャッシュされていた偶然と考えられる。

修正: [terraform/modules/aws/sts_oidc_flow/main.tf](../terraform/modules/aws/sts_oidc_flow/main.tf)の`condition_prefix`から`trimsuffix`を除去。本番ロールに`terraform apply`し、`/api/files`・`/api/download/{key}`ともにエンドツーエンドで成功を確認。

## 8. 副次的に発覚したバグ（AssumeRole修正後に発覚）

`AssumeRoleWithWebIdentity`が通るようになった後、`/api/files`が今度は`s3:ListBucket`の`AccessDenied`で失敗した。IAMポリシー`s3-oidc-s3-read`が`s3:prefix StringLike "downloads/*"`を要求しているのに、Function Appの`AWS_S3_PREFIX`が空文字だったため。

修正:
- [terraform/azure/terraform.tfvars](../terraform/azure/terraform.tfvars) に `aws_s3_prefix = "downloads"` を追加
- [function_app.py](../src/s3_oidc_download/function_app.py) の `list_files` で、S3への`Prefix`パラメータにだけ末尾スラッシュを補うよう修正（`download`側の`_full_key`は末尾スラッシュなし前提のままで整合）

## 9. 後片付け（要対応）

診断用に残していたものは、解決した今、削除を推奨:

- Function App (`func-s3oidc-x187ag`) の `debug-raw-msi` エンドポイント（`?scope=`で任意のscopeのトークンを取得可能。認証なしで呼べるため放置は非推奨）
- `token-claims` エンドポイントの `?scope=` オーバーライド
- 検証用IAMロール `s3-oidc-s3-access-oidc-v2`（最小再現ケース。もう不要）
