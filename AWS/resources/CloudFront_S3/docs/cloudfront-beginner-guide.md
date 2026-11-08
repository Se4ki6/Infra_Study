# CloudFront 初心者ガイド

最終更新: 2025-12-13

## 📚 目次

1. [CloudFront とは](#cloudfrontとは)
2. [基本概念](#基本概念)
3. [S3 との連携](#s3との連携)
4. [セキュリティ設定](#セキュリティ設定)
5. [キャッシュ戦略](#キャッシュ戦略)
6. [カスタムドメイン・SSL](#カスタムドメインssl)
7. [エラーページ設定](#エラーページ設定)
8. [パフォーマンス最適化](#パフォーマンス最適化)
9. [コスト管理](#コスト管理)
10. [トラブルシューティング](#トラブルシューティング)

---

## CloudFront とは

Amazon CloudFront は、AWS が提供するコンテンツ配信ネットワーク（CDN）サービスです。

### 主な特徴

- **グローバル配信**: 世界中に分散された 400 以上のエッジロケーションから高速にコンテンツを配信
- **低レイテンシ**: ユーザーに最も近いエッジロケーションからコンテンツを配信
- **セキュリティ**: DDoS 対策、WAF 統合、SSL/TLS 暗号化をサポート
- **柔軟な料金体系**: 転送量に応じた従量課金

### 使用ケース

- 静的ウェブサイトのホスティング
- 画像・動画の配信
- API アクセラレーション
- ソフトウェアダウンロードの配信
- ライブストリーミング

---

## 基本概念

### ディストリビューション

CloudFront の基本単位。コンテンツ配信の設定を管理します。

**種類**:

- **Web ディストリビューション**: 一般的な Web コンテンツ配信
- **RTMP ディストリビューション**: ストリーミングメディア配信（廃止予定）

### オリジン

コンテンツの元となるサーバーです。

**サポートされるオリジン**:

- Amazon S3 バケット
- EC2 インスタンス
- Elastic Load Balancer
- カスタム HTTP/HTTPS サーバー

### エッジロケーション

コンテンツがキャッシュされる世界各地のデータセンターです。

**リージョナルエッジキャッシュ**:

- エッジロケーションとオリジンの間にある中間キャッシュ層
- より大容量のキャッシュを保持

### キャッシュ動作（Cache Behavior）

リクエストのパターンに基づいてコンテンツの処理方法を定義します。

```
パターン例:
- デフォルト: *
- 画像: *.jpg, *.png, *.gif
- API: /api/*
- 静的コンテンツ: /static/*
```

---

## S3 との連携

### 基本的な構成

```
ユーザー
  ↓
CloudFront（エッジロケーション）
  ↓
S3バケット（オリジン）
```

### S3 バケットをオリジンとして設定

**必要な設定**:

1. **S3 バケットの作成**

   - パブリックアクセスはブロック（推奨）
   - CloudFront からのアクセスのみ許可

2. **CloudFront ディストリビューションの作成**

   ```hcl
   # Terraformの例
   resource "aws_cloudfront_distribution" "s3_distribution" {
     origin {
       domain_name = aws_s3_bucket.website.bucket_regional_domain_name
       origin_id   = "S3-my-bucket"

       s3_origin_config {
         origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
       }
     }
   }
   ```

3. **バケットポリシーの設定**
   - CloudFront OAI/OAC からのアクセスを許可

### ウェブサイトホスティングの設定

**S3 ウェブサイトエンドポイント vs リージョナルエンドポイント**:

| 項目                     | ウェブサイトエンドポイント                    | リージョナルエンドポイント            |
| ------------------------ | --------------------------------------------- | ------------------------------------- |
| URL 形式                 | `bucket-name.s3-website-region.amazonaws.com` | `bucket-name.s3.region.amazonaws.com` |
| インデックスドキュメント | 自動対応                                      | CloudFront で設定必要                 |
| エラードキュメント       | 自動リダイレクト                              | CloudFront で設定必要                 |
| OAI/OAC                  | 非対応                                        | 対応                                  |
| セキュリティ             | 低（パブリックアクセス必要）                  | 高（プライベート可）                  |

**推奨**: リージョナルエンドポイント + OAC

---

## セキュリティ設定

### Origin Access Control (OAC)

**OAC とは**:

- S3 バケットへの直接アクセスを防ぎ、CloudFront 経由のみでアクセスを許可
- OAI（Origin Access Identity）の後継で、より強力なセキュリティ

**設定方法**:

```hcl
# OACの作成
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "my-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ディストリビューションに適用
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "S3-my-bucket"
  }
}

# S3バケットポリシー
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}
```

### AWS WAF（Web Application Firewall）

CloudFront と統合してセキュリティを強化します。

**主な機能**:

- SQL インジェクション対策
- クロスサイトスクリプティング（XSS）対策
- レート制限
- 地域ブロック
- IP アドレスブロック/許可

**基本設定**:

```hcl
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name  = "cloudfront-waf"
  scope = "CLOUDFRONT"  # CloudFrontの場合は必須

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfrontWAF"
    sampled_requests_enabled   = true
  }
}
```

### SSL/TLS 証明書

**オプション**:

1. **CloudFront デフォルト証明書**

   - `*.cloudfront.net` ドメイン用
   - 無料
   - カスタムドメインには使用不可

2. **AWS Certificate Manager（ACM）証明書**
   - カスタムドメイン用
   - 無料
   - **重要**: us-east-1 リージョンで作成する必要がある

```hcl
# ACM証明書（us-east-1リージョンで作成）
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.us_east_1
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFrontディストリビューションに適用
resource "aws_cloudfront_distribution" "s3_distribution" {
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
```

### Geo Restriction（地域制限）

特定の国からのアクセスを制限/許可します。

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"  # または "blacklist"
      locations        = ["JP", "US", "GB"]  # ISO 3166-1-alpha-2 コード
    }
  }
}
```

---

## キャッシュ戦略

### キャッシュの基本

**キャッシュのメリット**:

- オリジンへの負荷軽減
- レスポンス時間の短縮
- データ転送コストの削減

**キャッシュキー**:
リクエストを識別するための要素

- URL
- クエリ文字列
- リクエストヘッダー
- Cookie

### TTL（Time To Live）設定

キャッシュの有効期限を制御します。

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  default_cache_behavior {
    min_ttl     = 0
    default_ttl = 3600    # 1時間
    max_ttl     = 86400   # 24時間
  }
}
```

**推奨設定**:

| コンテンツタイプ  | TTL                    | 理由           |
| ----------------- | ---------------------- | -------------- |
| 静的画像・CSS・JS | 1 年（31536000 秒）    | 変更頻度が低い |
| HTML              | 短め（1 時間〜1 日）   | 更新が必要     |
| API レスポンス    | 0〜短時間              | 動的データ     |
| 動画              | 長め（1 週間〜1 ヶ月） | サイズが大きい |

### Cache-Control ヘッダー

オリジンから送信するヘッダーでキャッシュを制御します。

```
# S3オブジェクトのメタデータ設定例
Cache-Control: public, max-age=31536000, immutable
```

**主要なディレクティブ**:

- `public`: 任意のキャッシュでキャッシュ可能
- `private`: ブラウザのみキャッシュ可能
- `no-cache`: キャッシュ前に再検証が必要
- `no-store`: キャッシュしない
- `max-age=<秒>`: キャッシュの有効期限
- `immutable`: コンテンツが変更されないことを示す

### キャッシュポリシー

再利用可能なキャッシュ設定のテンプレートです。

**AWS マネージド ポリシー**:

- `CachingOptimized`: 静的コンテンツ向け
- `CachingDisabled`: キャッシュ無効
- `CachingOptimizedForUncompressedObjects`: 圧縮されていないオブジェクト向け

**カスタムポリシー**:

```hcl
resource "aws_cloudfront_cache_policy" "custom_policy" {
  name        = "my-cache-policy"
  min_ttl     = 1
  max_ttl     = 31536000
  default_ttl = 86400

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}
```

### キャッシュ無効化（Invalidation）

キャッシュされたコンテンツを強制的に削除します。

**方法**:

```powershell
# AWS CLI
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"

# 特定のファイルのみ
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/images/*" "/css/style.css"
```

**注意点**:

- 月 1000 回まで無料、それ以降は有料
- ワイルドカード（`/*`）は 1 パスとしてカウント
- 頻繁な無効化よりバージョニングを推奨

**バージョニング戦略**:

```
# ファイル名にバージョンを含める
style.css?v=1.2.3
style-1.2.3.css

# ハッシュ値を使用
style.abc123.css
```

---

## カスタムドメイン・SSL

### カスタムドメインの設定手順

1. **ACM 証明書の作成**（us-east-1 リージョン）

```hcl
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = "www.example.com"
  validation_method = "DNS"
}
```

2. **DNS 検証**

証明書の検証用 DNS レコードを追加します。

```hcl
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}
```

3. **CloudFront に証明書を適用**

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  aliases = ["www.example.com"]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
```

4. **DNS レコードの設定**

```hcl
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
```

### SSL/TLS のベストプラクティス

- **最小プロトコルバージョン**: TLSv1.2 以上を使用
- **SNI（Server Name Indication）**: `sni-only`を推奨（コスト削減）
- **証明書の更新**: ACM は自動更新（DNS 検証レコードを維持）

---

## エラーページ設定

### カスタムエラーレスポンス

ユーザーフレンドリーなエラーページを表示します。

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404  # 403を404として返す（セキュリティ）
    response_page_path    = "/error.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 500
    response_code         = 500
    response_page_path    = "/500.html"
    error_caching_min_ttl = 60
  }
}
```

### SPA（Single Page Application）対応

React、Vue、Angular などのクライアントサイドルーティング対応。

```hcl
resource "aws_cloudfront_distribution" "spa" {
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
}
```

### デフォルトルートオブジェクト

ルートパスへのアクセス時に返すファイルを設定します。

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  default_root_object = "index.html"
}
```

**制限事項**:

- ルート（`/`）のみに適用
- サブディレクトリ（`/about/`）には適用されない

**解決策**: Lambda@Edge でディレクトリリクエストをリライト

---

## パフォーマンス最適化

### 圧縮

CloudFront でコンテンツを自動圧縮してデータ転送量を削減します。

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  default_cache_behavior {
    compress = true  # Gzip/Brotli圧縮を有効化
  }
}
```

**圧縮されるコンテンツタイプ**:

- text/html
- text/css
- application/javascript
- application/json
- text/xml

### HTTP/2 と HTTP/3

最新の HTTP プロトコルで通信を高速化します。

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  http_version = "http2and3"  # HTTP/2とHTTP/3を有効化
}
```

**メリット**:

- 多重化により複数リソースを並列取得
- ヘッダー圧縮
- サーバープッシュ（HTTP/2）
- QUIC プロトコル（HTTP/3）

### Price Class（料金クラス）

使用するエッジロケーションを制限してコストを削減します。

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  price_class = "PriceClass_100"  # 北米・ヨーロッパのみ
}
```

**料金クラス**:

| クラス           | 対象地域                                 | 用途           |
| ---------------- | ---------------------------------------- | -------------- |
| `PriceClass_All` | すべての地域                             | グローバル配信 |
| `PriceClass_200` | 北米・ヨーロッパ・アジア・中東・アフリカ | 一般的な用途   |
| `PriceClass_100` | 北米・ヨーロッパ                         | コスト重視     |

### Origin Shield

追加のキャッシュ層を提供し、オリジンへの負荷を軽減します。

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-my-bucket"

    origin_shield {
      enabled              = true
      origin_shield_region = "ap-southeast-2"  # オリジンに近いリージョン
    }
  }
}
```

**メリット**:

- キャッシュヒット率の向上
- オリジンへのリクエスト数削減
- リージョン間のデータ転送コスト削減

**コスト**: 追加料金が発生（リクエスト数に応じて）

---

## コスト管理

### CloudFront の料金体系

**主な課金項目**:

1. **データ転送量（アウト）**: エッジロケーションからユーザーへの転送
2. **HTTPS リクエスト数**: リクエストごとの課金
3. **無効化リクエスト**: 月 1000 回以降は有料
4. **専用 IP カスタム SSL**: 使用する場合は月額料金

### コスト最適化のベストプラクティス

**1. キャッシュヒット率の向上**

```hcl
# 長めのTTLを設定
default_cache_behavior {
  min_ttl     = 0
  default_ttl = 86400   # 24時間
  max_ttl     = 31536000 # 1年
}
```

**2. 圧縮の有効化**

```hcl
default_cache_behavior {
  compress = true  # データ転送量を削減
}
```

**3. 適切な Price Class の選択**

```hcl
price_class = "PriceClass_100"  # 必要な地域のみ
```

**4. 無効化の最小化**

- バージョニングを使用
- ワイルドカードで一括無効化

**5. S3 から CloudFront への転送は無料**

- オリジンが S3 の場合、S3→CloudFront 間のデータ転送料金は無料
- ただし S3 のストレージ料金とリクエスト料金は発生

### コスト監視

**CloudWatch メトリクス**:

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cost" {
  alarm_name          = "cloudfront-high-cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BytesDownloaded"
  namespace           = "AWS/CloudFront"
  period              = 86400
  statistic           = "Sum"
  threshold           = 100000000000  # 100GB
  alarm_description   = "CloudFront data transfer exceeds 100GB"
}
```

**AWS Cost Explorer**:

- CloudFront の使用状況を可視化
- 地域別・サービス別のコスト分析

---

## トラブルシューティング

### よくある問題と解決方法

#### 1. 403 Forbidden エラー

**原因**:

- S3 バケットポリシーが正しく設定されていない
- OAI/OAC の設定ミス
- オブジェクトが存在しない

**解決方法**:

```powershell
# S3バケットポリシーを確認
aws s3api get-bucket-policy --bucket your-bucket-name

# CloudFront OACのARNを確認
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID

# オブジェクトの存在確認
aws s3 ls s3://your-bucket-name/ --recursive
```

#### 2. キャッシュが更新されない

**原因**:

- TTL が長すぎる
- Cache-Control ヘッダーの設定ミス

**解決方法**:

```powershell
# 無効化を実行
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"

# 特定のファイルのみ
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/index.html" "/css/style.css"
```

#### 3. SSL 証明書のエラー

**原因**:

- 証明書が us-east-1 リージョンにない
- DNS 検証が完了していない
- ドメイン名が一致していない

**解決方法**:

```powershell
# 証明書のステータス確認（us-east-1）
aws acm list-certificates --region us-east-1

# 証明書の詳細確認
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/xxx \
  --region us-east-1
```

#### 4. カスタムドメインでアクセスできない

**原因**:

- DNS レコードの設定ミス
- CloudFront ディストリビューションの Alias が設定されていない

**解決方法**:

```powershell
# DNSレコードの確認
nslookup www.example.com

# CloudFrontディストリビューションの設定確認
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID \
  | jq '.Distribution.DistributionConfig.Aliases'
```

#### 5. デプロイが完了しない

**CloudFront のデプロイには時間がかかる**:

- 通常 15〜20 分
- 変更内容によっては 30 分以上

**確認方法**:

```powershell
# ディストリビューションのステータス確認
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID \
  | jq '.Distribution.Status'

# "Deployed" になるまで待機
```

### デバッグツール

**1. CloudFront のレスポンスヘッダー**

```bash
curl -I https://d123456.cloudfront.net/

# 確認すべきヘッダー:
# X-Cache: Hit from cloudfront（キャッシュヒット）
# X-Cache: Miss from cloudfront（キャッシュミス）
# X-Amz-Cf-Pop: NRT57-C1（エッジロケーション）
```

**2. CloudWatch ログ**

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/"
  }
}
```

**3. Real-time Logs**

リアルタイムでリクエストログを確認できます（追加料金）。

```hcl
resource "aws_cloudfront_realtime_log_config" "example" {
  name          = "example-realtime-logs"
  sampling_rate = 100  # 100%のリクエストをログ

  endpoint {
    stream_type = "Kinesis"

    kinesis_stream_config {
      role_arn   = aws_iam_role.cloudfront_realtime_logs.arn
      stream_arn = aws_kinesis_stream.cloudfront_logs.arn
    }
  }

  fields = [
    "timestamp",
    "c-ip",
    "cs-method",
    "cs-uri-stem",
    "sc-status",
    "time-taken"
  ]
}
```

### パフォーマンス診断

**キャッシュヒット率の確認**:

```powershell
# CloudWatchメトリクスを取得
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=YOUR_DISTRIBUTION_ID \
  --start-time 2025-12-12T00:00:00Z \
  --end-time 2025-12-13T00:00:00Z \
  --period 3600 \
  --statistics Average
```

**目標**: 80%以上のキャッシュヒット率

---

## ベストプラクティスまとめ

### セキュリティ

✅ OAC（Origin Access Control）を使用して S3 を保護<br>
✅ AWS WAF を統合して攻撃を防御<br>
✅ TLSv1.2 以上を使用<br>
✅ 適切な CORS ヘッダーを設定<br>
✅ 地域制限で不要なアクセスをブロック

### パフォーマンス

✅ 圧縮を有効化<br>
✅ HTTP/2・HTTP/3 を有効化<br>
✅ 適切なキャッシュ TTL を設定<br>
✅ Cache-Control ヘッダーを最適化<br>
✅ Origin Shield でキャッシュヒット率を向上

### コスト

✅ 長めの TTL でキャッシュヒット率を向上<br>
✅ 適切な Price Class を選択<br>
✅ バージョニングで無効化を最小化<br>
✅ 不要なログを無効化<br>
✅ CloudWatch Alarm でコストを監視

### 運用

✅ Infrastructure as Code（Terraform）で管理<br>
✅ ログを有効化して分析<br>
✅ CloudWatch でメトリクスを監視<br>
✅ 定期的にキャッシュヒット率を確認<br>
✅ デプロイ前にステージング環境でテスト

---

## 参考リソース

### AWS 公式ドキュメント

- [Amazon CloudFront 開発者ガイド](https://docs.aws.amazon.com/ja_jp/cloudfront/)
- [CloudFront 料金](https://aws.amazon.com/jp/cloudfront/pricing/)
- [CloudFront FAQs](https://aws.amazon.com/jp/cloudfront/faqs/)

### Terraform ドキュメント

- [aws_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution)
- [aws_cloudfront_origin_access_control](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control)

### ツール

- [CloudFront Invalidation Calculator](https://calculator.aws/#/createCalculator/CloudFront)
- [AWS Simple Monthly Calculator](https://calculator.aws/)

---

## 次のステップ

1. **基本的なディストリビューションを作成**: S3 バケットをオリジンとして設定
2. **カスタムドメインを設定**: ACM 証明書と Route53 の設定
3. **セキュリティを強化**: OAC と WAF の導入
4. **パフォーマンスを最適化**: キャッシュ戦略の調整
5. **監視を設定**: CloudWatch アラームとログの有効化

---

## 関連ドキュメント

このリポジトリ内の関連ドキュメント:

- `cloudfront.tf` - CloudFront の Terraform 設定
- `waf.tf` - AWS WAF の設定
- `S3/docs/cache-control-strategies.md` - キャッシュ戦略の詳細

---

**質問やフィードバックがありましたら、お気軽にお知らせください！**
