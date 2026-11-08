# --------------------------------------------------------------------------------
# CloudFront Origin Access Control (OAC)
# S3バケットへのアクセスをCloudFront経由のみに制限するための認証設定です。
# 以前のOAI (Origin Access Identity) の後継機能で、よりセキュアで柔軟な設定が可能です。
# --------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-oac-${var.bucket_name}"
  description                       = "S3 OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # 常にリクエストに署名する
  signing_protocol                  = "sigv4"  # 署名プロトコル (Signature Version 4)
}

# --------------------------------------------------------------------------------
# CloudFront Distribution
# コンテンツ配信ネットワーク (CDN) の設定です。
# S3をオリジンとし、HTTPSでの配信、キャッシュ、WAFによる保護を提供します。
# --------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "s3_distribution" {
  # オリジン設定: コンテンツの取得元 (S3バケット) を指定
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "S3-${var.bucket_name}"
  }

  enabled             = true                                 # ディストリビューションを有効化
  is_ipv6_enabled     = true                                 # IPv6を有効化
  default_root_object = "index.html"                         # ルートアクセス時に返すオブジェクト
  web_acl_id          = aws_wafv2_web_acl.ip_restriction.arn # WAF (IP制限) を適用

  # デフォルトのキャッシュ動作設定
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"] # 許可するHTTPメソッド
    cached_methods   = ["GET", "HEAD"] # キャッシュするHTTPメソッド
    target_origin_id = "S3-${var.bucket_name}"

    # クエリ文字列やCookieの転送設定 (静的サイトなので転送しない)
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # HTTPアクセスをHTTPSにリダイレクト
    min_ttl                = 0                   # 最小キャッシュ時間 (秒)
    default_ttl            = 3600                # デフォルトキャッシュ時間 (1時間)
    max_ttl                = 86400               # 最大キャッシュ時間 (24時間)
  }

  # カスタムエラーレスポンス (403 Forbidden -> 404 Not Found + error.html)
  # S3の非公開オブジェクトへのアクセスは403になるため、それを404として扱いエラーページを表示
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 10
  }

  # カスタムエラーレスポンス (404 Not Found -> 404 Not Found + error.html)
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 10
  }

  # 地理的制限 (今回は制限なし)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL/TLS証明書設定 (CloudFrontのデフォルト証明書を使用)
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
