// ==============================================================================
// module: sts_access_key_flow  (方式A)
// ==============================================================================
//   IAM ユーザー (bootstrap)           IAM ロール (s3-access)
//   権限は sts:AssumeRole *だけ*  ──▶  S3 読み取り
//   → S3 には一切触れない              (+ ExternalId で保護)
//
// 学習ポイント: bootstrap ユーザー自身には S3 権限が無い。
// アクセスキーが漏れても、ExternalId を知らなければロールを Assume できず S3 に到達できない。
//
// ただし長期キーが残る構成なので、本番では方式B (sts_oidc_flow) を使うこと。
// ==============================================================================

// ------------------------------------------------------------------------------
// Assume される側: S3 アクセス用ロール
// ------------------------------------------------------------------------------
resource "aws_iam_role" "this" {
  name                 = "${var.name_prefix}-s3-access-assumerole"
  description          = "S3 read-only role assumed externally via long-lived access key (flow A)"
  max_session_duration = var.max_session_duration

  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = var.tags
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

    // ロール ARN とアクセスキーの両方を知っていても、合言葉がなければ通らない
    dynamic "condition" {
      for_each = var.external_id == "" ? [] : [1]

      content {
        test     = "StringEquals"
        variable = "sts:ExternalId"
        values   = [var.external_id]
      }
    }
  }
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.this.name
  policy_arn = var.s3_read_policy_arn
}

// ------------------------------------------------------------------------------
// Assume する側: bootstrap IAM ユーザー
// ------------------------------------------------------------------------------
resource "aws_iam_user" "bootstrap" {
  name = "${var.name_prefix}-bootstrap"
  tags = var.tags
}

// このユーザーに許可するのは「上のロールを Assume すること」のみ。
// S3 の権限は一切与えない。
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
        Resource = aws_iam_role.this.arn
      }
    ]
  })
}

resource "aws_iam_access_key" "bootstrap" {
  user = aws_iam_user.bootstrap.name
}
