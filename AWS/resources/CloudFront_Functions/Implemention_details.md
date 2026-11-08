# CloudFront Functions URL Rewrite Implementation Guide

`docs\cloudfront\about_CloudFront_Functions.md` に記載されている「URL 書き換え（index.html の補完）」を再現するための手順です。

## 手順の概要

1.  **CloudFront Function のコード作成**: JavaScript ファイルを作成します。
2.  **Terraform コードの修正**: CloudFront Function リソースを定義し、CloudFront ディストリビューションに関連付けます。
3.  **デプロイ**: Terraform でリソースを作成します。
4.  **動作確認**: 実際にアクセスして URL が書き換わっているか確認します。

---

## 詳細手順

### 1. CloudFront Function のコード作成

まず、URL 書き換えロジックを含む JavaScript ファイルを作成します。

`CloudFront_Functions/function.js` というファイルを新規作成し、以下の内容を記述します。

```javascript
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // URLが / で終わっている場合、index.html を付与
  if (uri.endsWith("/")) {
    request.uri += "index.html";
  }
  // 拡張子がないURLの場合、/index.html を付与
  else if (!uri.includes(".")) {
    request.uri += "/index.html";
  }

  return request;
}
```

### 2. Terraform コードの修正 (`main.tf`)

`CloudFront_Functions/main.tf` を編集し、CloudFront Function のリソース定義と、既存の CloudFront ディストリビューションへの紐付けを追加します。

**追加するリソース:**

```hcl
resource "aws_cloudfront_function" "rewrite_url" {
  name    = "rewrite-url-function"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite URL to append index.html"
  publish = true
  code    = file("${path.module}/function.js")
}
```

**修正する箇所 (aws_cloudfront_distribution リソース内):**

`default_cache_behavior` ブロック内に `function_association` を追加します。

```hcl
  default_cache_behavior {
    # ... (既存の設定) ...

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_url.arn
    }
  }
```

### 3. デプロイ

ターミナルで `CloudFront_Functions` ディレクトリに移動し、Terraform コマンドを実行します。

```powershell
cd CloudFront_Functions
terraform init  # 初回のみ、またはプロバイダ変更時
terraform apply
```

`Apply complete!` と表示されればデプロイ完了です。

### 4. 動作確認

ブラウザまたは `curl` コマンドを使って、CloudFront のドメインに対して以下のパターンでアクセスし、正しくページが表示されるか（S3 上の `index.html` が返されるか）確認します。

- `https://<CloudFront-Domain>/` -> `index.html` が表示されるはず
- `https://<CloudFront-Domain>/subdir` -> `subdir/index.html` が表示されるはず（S3 にファイルがあれば）
