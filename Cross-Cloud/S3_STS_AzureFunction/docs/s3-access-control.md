# S3 アクセス制限の仕組み（詳細）

この構成が「S3 バケットへのアクセスを STS 経由の一時クレデンシャルのみに限定する」ために
実際に何を設定しているかを、IAM ポリシーの評価ロジックのレベルまで掘り下げて説明する。

READMEが手順・アーキテクチャ概要、[verification.md](verification.md) が「本当に塞がっているか」の
実地検証なのに対し、このドキュメントは**制御の中身そのもの**（何が・なぜ・どう書かれているか）に絞る。
会社アカウントなど別環境で同様の制限を再現する際のリファレンスとして使うことを想定している。

---

## 1. 前提: なぜ IAM ポリシーだけでは「STS 経由のみ」を強制できないか

IAM ユーザー/ロールにアタッチする IAM ポリシー（Identity-based policy）は、
「そのユーザー/ロールに何を許可するか」しか定義できない。

このプロジェクトでは Assume 後のロールに `s3:GetObject` 等を許可する
[s3_read_policy](../terraform/modules/aws/s3_read_policy/main.tf) を用意しているが、
**このポリシーはロールが持つ権限を追加するだけで、同じ AWS アカウント内の他の IAM ユーザーや
ロール（例えば管理者）が自分自身の権限でバケットを直接触るのを止める効力は無い**。
管理者が `AdministratorAccess` を持っていれば、IAM ポリシー側にどんな制約を書いても
そのユーザーは素の `s3:GetObject` でバケットに到達できてしまう。

「許可した経路以外は誰も通さない」を実現するには、**リソース側**（S3 バケット自体）に
制約を掛ける必要がある。それがバケットポリシー（Resource-based policy）であり、
その中でも**明示的 Deny** が鍵になる。

### IAM ポリシー評価の優先順位

AWS の権限評価は次の順序で行われる（すべてのポリシータイプを横断した最終ルール）。

```
明示的 Deny  >  明示的 Allow  >  暗黙の Deny（デフォルト）
```

明示的 Deny が一つでもヒットすると、他にどれだけ Allow があっても、
たとえそれが `AdministratorAccess` のような強力な Allow であっても、最終結果は Deny になる。
このプロジェクトはこの性質を利用して、「バケットポリシーに Deny を置く」ことで
IAM 側の権限に関係なく通行止めを作っている。

---

## 2. 制御の実体: `s3_bucket_lockdown` モジュール

実装: [terraform/modules/aws/s3_bucket_lockdown/main.tf](../terraform/modules/aws/s3_bucket_lockdown/main.tf)

このモジュールが `aws_s3_bucket_policy` として 1 つのポリシードキュメントをバケットにアタッチする。
中身は 2 つの Deny ステートメントから成る。

### 2-1. `DenyInsecureTransport` — HTTPS 以外を拒否（常時有効）

```hcl
statement {
  sid    = "DenyInsecureTransport"
  effect = "Deny"
  principals { type = "*", identifiers = ["*"] }
  actions   = ["s3:*"]
  resources = [bucket_arn, "${bucket_arn}/*"]

  condition {
    test     = "Bool"
    variable = "aws:SecureTransport"
    values   = ["false"]
  }
}
```

- **対象**: 全 principal（`*`）
- **条件**: リクエストが HTTPS でない（`aws:SecureTransport = false`）場合のみ発火
- `enable_lockdown` の値に関わらず常に適用される、独立した最低ラインの防御

### 2-2. `DenyAllExceptStsAssumedRoles` — STS ロール以外を全拒否（`enable_lockdown = true` の時のみ）

```hcl
dynamic "statement" {
  for_each = var.enable_lockdown ? [1] : []
  content {
    sid    = "DenyAllExceptStsAssumedRoles"
    effect = "Deny"
    principals { type = "*", identifiers = ["*"] }
    actions   = ["s3:*"]
    resources = [bucket_arn, "${bucket_arn}/*"]

    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values   = var.allowed_user_ids
    }
  }
}
```

これがこの構成の中核。読み方が独特なので分解する。

- **`StringNotLike`** = 「`aws:userId` が `allowed_user_ids` のどれにも一致しない場合」に条件が真になる
- 条件が真 → この Deny ステートメントが発火 → 該当リクエストは無条件で拒否
- つまり構文上は「許可リスト」に見えるが、実体は「**リストに載っていない全員への Deny**」

`aws:userId` は principal の種類によって形式が異なり、これが Deny の粒度を決める：

| Principal の種類 | `aws:userId` の値 | 備考 |
|---|---|---|
| IAM ユーザー | `AIDAXXXXXXXXXXXX` | ユーザー固有の一意な ID |
| **Assume したロール（セッション）** | `AROAXXXXXXXXXXXX:<セッション名>` | ロールの一意 ID + `:` + `RoleSessionName` |
| ルートユーザー | `<AWS アカウント ID>`（12桁） | |

`StringNotLike` は `?` `*` のワイルドカードを解釈できるため、
`allowed_user_ids` に `"AROAXXXXXXXXXXXX:*"` のように**セッション名を問わず前方一致**させる
パターンを入れておける。これにより「このロール ID を Assume した session なら誰でも許可対象」
という粒度で許可リストを組める（`role_unique_id` はロールを作り直すたびに変わるので、
`unique_id` そのものは変わらない限り再 apply しても許可リストは安定する）。

### `enable_lockdown = false` の場合

`DenyAllExceptStsAssumedRoles` ステートメント自体が生成されない（`dynamic` ブロックの `for_each` が空リスト）。
`DenyInsecureTransport` だけが残るので、HTTPS 強制はされるが「誰でも触れる」に戻る
（実際にはバケット自体がパブリックアクセスブロック済みなので、アカウント内の principal で
IAM 権限を持つ者のみが対象になる）。

### 安全弁: `precondition`

```hcl
lifecycle {
  precondition {
    condition     = !var.enable_lockdown || length(var.allowed_user_ids) > 0
    error_message = "enable_lockdown = true の場合、allowed_user_ids を空にはできません（全 principal が締め出されます）。"
  }
}
```

`enable_lockdown = true` なのに `allowed_user_ids` が空だと、`StringNotLike` の比較対象が無いため
**全 principal が Deny 対象**になり、Terraform 実行者自身も含めて誰もバケットを触れなくなる。
これを `plan`/`apply` の時点で機械的に検知して止める。

---

## 3. 許可リストの組み立て: 「自分自身を締め出さない」ロジック

実装: [terraform/aws/main.tf](../terraform/aws/main.tf) の `locals`

`allowed_user_ids` に何を入れるかを間違えると、Terraform を実行した本人がロックアウトされる
（Deny は `AdministratorAccess` より優先されるため、IAM 側から復旧できない）。
このリスクを避けるため、root モジュールは **Terraform 実行者を自動的に許可リストへ含める**。

```hcl
data "aws_caller_identity" "current" {}

locals {
  caller_user_id = data.aws_caller_identity.current.user_id

  caller_allowed_user_ids = distinct(compact([
    local.caller_user_id,                         // 現在の IAM ユーザー / セッションそのまま
    "${split(":", local.caller_user_id)[0]}:*",   // 同じロールIDのセッション全般（SSO/Assumeロール対策）
    data.aws_caller_identity.current.account_id,  // ルートユーザー（最後の逃げ道）
  ]))

  sts_role_unique_ids = concat(
    module.sts_access_key_flow[*].role_unique_id,
    module.sts_oidc_flow[*].role_unique_id,
  )

  bucket_allowed_user_ids = distinct(concat(
    local.caller_allowed_user_ids,
    [for id in local.sts_role_unique_ids : "${id}:*"],
    var.additional_allowed_user_ids,
  ))
}
```

最終的に `allowed_user_ids` に入るのは 3 系統：

1. **Terraform 実行者**（IAM ユーザーそのまま、または SSO ロールのセッション全般＋ロールIDワイルドカード）
2. **有効化されている STS ロールの `unique_id`**（`sts_access_key_flow` / `sts_oidc_flow` のうち `count = 1` のもの）
3. **`additional_allowed_user_ids`**（CI やほかのプロファイルなど、手動で追加したい ID）

Terraform 実行者が SSO ロール（`AssumeRoleWithSAML` 等）の場合、セッション名がログインの度に
変わりうるため、`"${split(":", user_id)[0]}:*"` で **ロール ID 部分だけを固定してワイルドカード化**
している。これがないと「さっき apply できたのに次のログインでロックアウトされた」が起こる。

方式A/方式Bを `enable_access_key_flow` / `enable_oidc_flow` で無効化すると、対応するモジュールの
`count = 0` になり `role_unique_id` を出力しないため、**許可リストからも自動的に外れる**。
無効化したロールを Assume 経路として残さない、という一貫性がここで保たれている。

---

## 4. バケット自体の安全側設定（`s3_secure_bucket`）

実装: [terraform/modules/aws/s3_secure_bucket/main.tf](../terraform/modules/aws/s3_secure_bucket/main.tf)

バケットポリシーの Deny とは別に、バケット単体で完結する保護も入れている。これらは
「STS 経由の強制」そのものではなく、一般的なセキュアベースラインとしての設定。

| リソース | 設定 | 目的 |
|---|---|---|
| `aws_s3_bucket_versioning` | `Enabled` | 誤削除・誤上書きからの復旧余地を残す |
| `aws_s3_bucket_server_side_encryption_configuration` | SSE-S3 (`AES256`) | 保存データの暗号化 |
| `aws_s3_bucket_public_access_block` | 4項目すべて `true` | ACL/バケットポリシーによる公開を構成レベルで封殺 |
| `aws_s3_bucket_ownership_controls` | `BucketOwnerEnforced` | ACL を無効化しバケット所有者にオブジェクト所有権を統一（クロスアカウントでの ACL 抜け道を無くす） |

`aws_s3_bucket_public_access_block` はバケットポリシーで誤って `Principal: "*"` の Allow を
書いてしまった場合の**保険**として働く。今回のポリシーは Deny しか書いていないので直接の
依存関係はないが、多層防御として維持している。

---

## 5. Assume 後に持てる権限（`s3_read_policy`）— 最小権限

実装: [terraform/modules/aws/s3_read_policy/main.tf](../terraform/modules/aws/s3_read_policy/main.tf)

バケットポリシーの Deny を通過した後（＝許可された STS ロールとして振る舞っている状態）でも、
できることは **`allowed_prefix` 配下の読み取りのみ**に絞られている。方式A・方式B のロールは
両方ともこの同じ IAM ポリシーをアタッチする。

```hcl
// バケット一覧（ListBucket は "バケット ARN" に対する権限。s3:prefix 条件で絞る）
statement {
  actions   = ["s3:ListBucket"]
  resources = [bucket_arn]
  condition {
    test     = "StringLike"
    variable = "s3:prefix"
    values   = ["${allowed_prefix}/*"]
  }
}

// オブジェクト取得（GetObject/GetObjectVersion は "オブジェクト ARN" に対する権限）
statement {
  actions   = ["s3:GetObject", "s3:GetObjectVersion"]
  resources = ["${bucket_arn}/${allowed_prefix}/*"]
}
```

ここでの実務上の注意点（トラブルシューティングでも頻出）：

- **`s3:ListBucket` はバケット ARN に対する権限**であり、オブジェクト ARN（`arn:...:bucket/*`）に
  付けても効かない。「一覧だけ `AccessDenied` になる」のはこの取り違えがほぼ全て。
- 一覧を `allowed_prefix` 配下だけに絞るには、リソースではなく **`s3:prefix` 条件**を使う
  （`ListBucket` はバケット全体に対する API なので、条件でしかフィルタできない）。
- 書き込み系（`PutObject` / `DeleteObject`）は一切許可していない＝完全な読み取り専用ロール。

---

## 6. Assume する経路の入口を絞る: 信頼ポリシー（Trust Policy）

バケットポリシーの Deny は「バケットに何が届くか」を制御するが、その手前の
「そもそも誰がこのロールを Assume できるか」は各ロールの **信頼ポリシー**（`assume_role_policy`）
が制御する。二重のゲートになっている。

### 方式A: `sts_access_key_flow`（アクセスキー + `sts:AssumeRole`）

実装: [terraform/modules/aws/sts_access_key_flow/main.tf](../terraform/modules/aws/sts_access_key_flow/main.tf)

```
bootstrap IAM ユーザー（S3権限なし、sts:AssumeRole のみ許可）
        │ sts:AssumeRole + ExternalId
        ▼
s3-access-assumerole ロール（信頼条件: Principal=bootstrapユーザー, ExternalId一致）
        │
        ▼
一時クレデンシャル（ASIA...）
```

- `bootstrap` ユーザー自身には S3 権限が一切無い。アクセスキーが漏洩しても、
  それだけでは S3 に到達できず、まず `sts:AssumeRole` を叩く必要がある。
- 信頼ポリシーには `sts:ExternalId` 条件を付けられる。ロール ARN とアクセスキーの両方を
  知っていても、この「合言葉」を知らなければ Assume 自体が `AccessDenied` になる
  （いわゆる「混乱した代理人 (confused deputy) 問題」対策）。
- 長期のアクセスキー（`AKIA...`）が Function App の設定に残る構成のため、
  本番では非推奨（方式B を使う）。

### 方式B: `sts_oidc_flow`（OIDC フェデレーション + `sts:AssumeRoleWithWebIdentity`）

実装: [terraform/modules/aws/sts_oidc_flow/main.tf](../terraform/modules/aws/sts_oidc_flow/main.tf)

```
Azure Function（マネージドID）
        │ ① Entra ID から JWT 取得
        │ ② AssumeRoleWithWebIdentity（JWT 添付。署名は不要）
        ▼
IAM OIDC プロバイダ（issuer = Entra ID、client_id_list = aud を検証）
        │
        ▼
s3-access-oidc ロール（信頼条件: aud 一致 + sub 一致）
        │
        ▼
一時クレデンシャル（ASIA...）
```

- `aws_iam_openid_connect_provider` が Entra ID を信頼する OIDC プロバイダとして登録される。
  `thumbprint_list` は Entra ID の TLS 証明書チェーンから動的に取得している
  （証明書更新のたびに壊れないようハードコードを避けている）。
- 信頼ポリシーの条件は 2 段構え：
  - **`aud`**（必須）: トークンの宛先。登録したアプリ（Entra ID 側の App Registration）以外に
    発行されたトークンを弾く。
  - **`sub`**（`azure_function_principal_id` を設定した場合のみ）: トークンの主体
    ＝マネージドID のオブジェクトID。これが無いと「同じテナント内の任意のIDが発行した
    トークンなら誰でも Assume できる」状態になるため、実運用では必ず設定する。
- **長期の AWS 認証情報がどこにも存在しない。** Function App の設定にはロール ARN しか
  無く、シークレットに相当するものは Entra ID 側が管理する短命トークンのみ。

いずれの方式でも、Assume に成功して得られる一時クレデンシャルの `AccessKeyId` は
必ず `ASIA` で始まる（長期キーの `AKIA` と区別できる）。これが「STS を経由したか」の
外形的な判定材料になっている（[S3AccessService.cs](../src/S3StsDownload/Services/S3AccessService.cs)
の `GetCallerIdentityAsync` が返す `arn` / `userId` も同じ目的）。

---

## 7. アプリケーション側の多層防御

バケットポリシー・IAM ポリシーがサーバー側の制御なのに対し、
[S3AccessService.cs](../src/S3StsDownload/Services/S3AccessService.cs) の `BuildObjectKey` は
アプリケーション層でもう一段防御を入れている。

```csharp
// ".." によるプレフィックス外への脱出を禁止する
if (key.Split('/').Any(segment => segment is ".."))
{
    throw new ArgumentException("key に '..' を含めることはできません。");
}
```

IAM 側で `allowed_prefix` 配下にしかアクセスできないため、仮にここを通過しても
最終的には Deny/AccessDenied で止まるはずだが、パストラバーサル文字列をそのまま
S3 API に渡さない、というアプリケーションレベルの最小限の入力検証を重ねている。

---

## 8. まとめ: リクエストが通るまでの評価フロー

Azure Function からの `GetObject` 呼び出しを例に、実際に評価される順序を追うと：

```
① Function App が Entra ID から JWT を取得
② AssumeRoleWithWebIdentity 呼び出し
     └─ IAM OIDCプロバイダの信頼ポリシー: aud/sub 条件を満たすか？
        満たさない → IDPRejectedClaim / InvalidIdentityToken で終了
③ 一時クレデンシャル（ASIA...）取得
④ S3 GetObject 呼び出し（一時クレデンシャルで署名）
     ├─ バケットポリシー: DenyInsecureTransport に該当するか？
     │     該当（非HTTPS） → 即 Deny
     ├─ バケットポリシー: DenyAllExceptStsAssumedRoles
     │     aws:userId が allowed_user_ids に StringNotLike で「一致しない」か？
     │     一致しない（＝許可リスト外）→ 即 Deny
     ├─ IAM ポリシー（s3_read_policy）: allowed_prefix 配下の GetObject を Allow しているか？
     │     していない → 暗黙の Deny
     └─ すべて通過 → オブジェクトを返す
```

**「明示的 Deny が最優先」という 1 つの原則から、この構成全体（バケットポリシー・信頼ポリシー・
IAM ポリシーの 3 層）が組み立てられている**、というのがこの構成の要点。
