// ==============================================================================
// module: s3_read_policy
// ==============================================================================
// STS で AssumeRoleWithWebIdentity した「後」に何ができるかを定義する IAM ポリシー。
// 最小権限の原則に従い、allowed_prefix 配下の読み取りだけを許可する。
// ==============================================================================

locals {
  // オブジェクト用 ARN。プレフィックス指定があればその配下だけに絞る
  object_arn_pattern = var.allowed_prefix == "" ? "${var.bucket_arn}/*" : "${var.bucket_arn}/${var.allowed_prefix}/*"

  // ListBucket 時に許可する s3:prefix
  list_prefix_pattern = var.allowed_prefix == "" ? "*" : "${var.allowed_prefix}/*"
}

data "aws_iam_policy_document" "this" {
  // バケット内の一覧取得。
  // s3:ListBucket は「バケットARN」に対する権限であってオブジェクトARNではない。
  // ここを間違えると一覧だけ AccessDenied になる、よくある落とし穴。
  statement {
    sid       = "ListBucketWithinPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [local.list_prefix_pattern]
    }
  }

  // オブジェクトの取得
  statement {
    sid    = "GetObjectsWithinPrefix"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [local.object_arn_pattern]
  }
}

resource "aws_iam_policy" "this" {
  name        = var.policy_name
  description = "S3 read-only permissions granted after AssumeRoleWithWebIdentity"
  policy      = data.aws_iam_policy_document.this.json

  tags = var.tags
}
