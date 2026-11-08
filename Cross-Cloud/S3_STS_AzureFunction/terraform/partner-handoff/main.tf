// ==============================================================================
// バッチ連携用: S3 を AssumeRole 経由のみに限定して公開する
// ==============================================================================
// このディレクトリ単体で完結する Terraform 構成。連携先 (バッチ側) は AWS アカウントを
// 持たないため、こちら側のアカウントに次の 4 点セットを作り、その結果 (ARN・アクセスキー・
// ExternalId) を安全な経路で連携先に渡す。
//
//   1. S3 バケット本体 (新規作成) + 安全側の基本設定
//   2. バケットポリシー: AssumeRole したセッション以外を明示的 Deny (= 外部からの直接アクセスを封殺)
//   3. AssumeRole で得られる権限: allowed_prefix 配下の読み取りのみ (最小権限)
//   4. AssumeRole する側: bootstrap IAM ユーザー (S3 権限は一切持たない。sts:AssumeRole のみ許可)
//      + ExternalId による確認 (混乱した代理人対策)
//
// 評価順序:  明示的 Deny  >  明示的 Allow  >  暗黙の Deny
// バケットポリシーの Deny はアカウント内の AdministratorAccess すら上書きする。
// 詳細な解説は引き渡し元リポジトリの docs/s3-access-control.md を参照。
// ==============================================================================

// 現在 Terraform を実行している principal。
// ロックダウン時に「実行者自身を締め出さない」ために使う
data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(var.tags, {
    Project     = "s3-assumerole-handoff"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  caller_user_id = data.aws_caller_identity.current.user_id

  // aws:userId は principal の種類で形式が違う:
  //   IAM ユーザー      : "AIDAXXXXXXXXXXXX"
  //   Assume したロール : "AROAXXXXXXXXXXXX:<セッション名>"
  //   ルートユーザー    : "<AWS アカウントID>"
  // SSO ロールなどセッション名が変わりうる場合に備え、ロール ID 部分のワイルドカードも入れておく
  caller_allowed_user_ids = distinct(compact([
    local.caller_user_id,
    "${split(":", local.caller_user_id)[0]}:*",
    data.aws_caller_identity.current.account_id,
  ]))

  bucket_allowed_user_ids = distinct(concat(
    local.caller_allowed_user_ids,
    ["${aws_iam_role.assume_role.unique_id}:*"],
    var.additional_allowed_user_ids,
  ))
}

// ------------------------------------------------------------------------------
// 1. S3 バケット本体
// ------------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(local.common_tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// パブリックアクセスは全面ブロック。バケットポリシーの誤設定に対する保険としても機能する
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// ACL を無効化し、所有権をバケット所有者に統一する
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

// ------------------------------------------------------------------------------
// 2. バケットポリシー: AssumeRole したセッション以外を Deny
// ------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "lockdown" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_lockdown.json
}

data "aws_iam_policy_document" "bucket_lockdown" {
  // 常時: HTTPS 以外を拒否
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  // enable_bucket_lockdown = true の場合のみ: 許可リスト外の全 principal を拒否
  dynamic "statement" {
    for_each = var.enable_bucket_lockdown ? [1] : []

    content {
      sid    = "DenyAllExceptAssumedRole"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions   = ["s3:*"]
      resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

      condition {
        test     = "StringNotLike"
        variable = "aws:userId"
        values   = local.bucket_allowed_user_ids
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !var.enable_bucket_lockdown || length(local.bucket_allowed_user_ids) > 0
      error_message = "enable_bucket_lockdown = true の場合、許可リストを空にはできません (全 principal が締め出されます)。"
    }
  }
}

// ------------------------------------------------------------------------------
// 3. AssumeRole 後に使える権限 (最小権限: allowed_prefix 配下の読み取りのみ)
// ------------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_read" {
  // s3:ListBucket は「バケット ARN」に対する権限。オブジェクト ARN に付けても効かない
  statement {
    sid       = "ListBucketWithinPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [var.allowed_prefix == "" ? "*" : "${var.allowed_prefix}/*"]
    }
  }

  statement {
    sid    = "GetObjectsWithinPrefix"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      var.allowed_prefix == "" ? "${aws_s3_bucket.this.arn}/*" : "${aws_s3_bucket.this.arn}/${var.allowed_prefix}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_read" {
  name        = "${var.name_prefix}-s3-read"
  description = "S3 read-only permissions granted after assuming the role via STS AssumeRole"
  policy      = data.aws_iam_policy_document.s3_read.json

  tags = local.common_tags
}

// ------------------------------------------------------------------------------
// 4. Assume される側のロールと、Assume する側の bootstrap ユーザー
// ------------------------------------------------------------------------------
resource "aws_iam_role" "assume_role" {
  name                 = "${var.name_prefix}-s3-access-assumerole"
  description          = "S3 read-only role assumed externally via long-lived access key (partner batch)"
  max_session_duration = var.session_duration_seconds

  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "AllowBootstrapUserToAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.bootstrap.arn]
    }

    // ExternalId: ロール ARN とアクセスキーの両方を知っていても、合言葉がなければ通らない
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.assume_role.name
  policy_arn = aws_iam_policy.s3_read.arn
}

// bootstrap ユーザーには S3 権限を一切与えない。許可するのは「上のロールを Assume すること」のみ
resource "aws_iam_user" "bootstrap" {
  name = "${var.name_prefix}-bootstrap"
  tags = local.common_tags
}

resource "aws_iam_user_policy" "assume_only" {
  name = "${var.name_prefix}-bootstrap-assume-only"
  user = aws_iam_user.bootstrap.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAssumeS3AccessRoleOnly"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.assume_role.arn
      }
    ]
  })
}

resource "aws_iam_access_key" "bootstrap" {
  user = aws_iam_user.bootstrap.name
}
