# --------------------------------------------------------------------------------
# WAF WebACL (IP制限)
# CloudFrontディストリビューションへのアクセスをIP制限するための設定です。
# 注意: CloudFront用のWAFはus-east-1リージョンに作成する必要があります。
# --------------------------------------------------------------------------------
resource "aws_wafv2_ip_set" "allowed_ips" {
  provider           = aws.us_east_1
  name               = "${var.bucket_name}-allowed-ips"
  description        = "Allowed IP addresses for CloudFront distribution"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.allowed_ip_addresses

  tags = {
    Name        = "${var.bucket_name}-allowed-ips"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_wafv2_web_acl" "ip_restriction" {
  provider    = aws.us_east_1
  name        = "${var.bucket_name}-ip-restriction"
  description = "IP restriction for CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    # デフォルトではブロック (許可されたIPのみアクセス可能)
    block {}
  }

  rule {
    name     = "AllowSpecificIPs"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.bucket_name}-allowed-ips"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.bucket_name}-ip-restriction"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.bucket_name}-ip-restriction"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
